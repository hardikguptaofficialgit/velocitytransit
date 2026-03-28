import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/models.dart';
import '../services/backend_api_service.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.phone,
    required this.avatar,
    required this.isActive,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String name;
  final String role;
  final String phone;
  final String avatar;
  final bool isActive;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isDriver => role == 'driver' || role == 'admin';

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'passenger',
      phone: map['phone']?.toString() ?? '',
      avatar: map['avatar']?.toString() ?? '',
      isActive: map['isActive'] == true,
      createdAt: _tryParseDateTime(map['createdAt']),
    );
  }

  AppUserProfile copyWith({
    String? name,
    String? phone,
    String? avatar,
  }) {
    return AppUserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? client,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _client = client ?? http.Client(),
       _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final http.Client _client;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();
      await _auth.currentUser?.getIdToken(true);
      await _createUserProfile(user, name: name);
      await _registerWithBackend(name: name);
    }
    return _auth.currentUser;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _ensureUserProfile(user);
      await fetchCurrentProfile();
    }
    return user;
  }

  Future<User?> signInWithGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      throw Exception(
        'Google sign-in is currently supported on Android, iOS, macOS, and web builds.',
      );
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }
      final googleAuthentication = await googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuthentication.accessToken,
        idToken: googleAuthentication.idToken,
      );
      credential = await _auth.signInWithCredential(authCredential);
    }

    final user = credential.user;
    if (user != null) {
      await _ensureUserProfile(user);
      await fetchCurrentProfile();
    }
    return user;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<String?> getIdToken() async => _auth.currentUser?.getIdToken();

  Future<AppUserProfile> fetchCurrentProfile() async {
    final token = await getIdToken();
    if (token == null) {
      throw Exception('You need to sign in first.');
    }

    final response = await _client.get(
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/me?source=mobile_app'),
      headers: _headers(token),
    );
    final payload = _decodeBody(response.body);
    if (response.statusCode >= 400) {
      throw Exception(payload['error']?.toString() ?? 'Unable to load account');
    }

    return AppUserProfile.fromMap(Map<String, dynamic>.from(payload['user']));
  }

  Future<AppUserProfile> updateCurrentProfile({
    required String name,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You need to sign in first.');
    }

    await user.updateDisplayName(name);
    await user.reload();
    await BackendApiService(authService: this).updateProfile(name: name, phone: phone);
    return fetchCurrentProfile();
  }

  Future<void> _registerWithBackend({required String name}) async {
    final token = await getIdToken();
    if (token == null) return;

    final response = await _client.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/auth/register'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'source': 'mobile_app'}),
    );

    if (response.statusCode >= 400) {
      final payload = _decodeBody(response.body);
      throw Exception(payload['error']?.toString() ?? 'Unable to finish account setup');
    }
  }

  Future<void> _createUserProfile(User user, {String? name}) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': name ?? user.displayName ?? user.email?.split('@')[0] ?? '',
      'phone': '',
      'role': 'passenger',
      'avatar': user.photoURL ?? '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _ensureUserProfile(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _createUserProfile(user);
    }
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    return jsonDecode(body) as Map<String, dynamic>;
  }
}

DateTime? _tryParseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class SelectedRoleNotifier extends Notifier<AppRoleChoice?> {
  @override
  AppRoleChoice? build() => null;

  void setRole(AppRoleChoice? role) {
    state = role;
  }
}

final selectedRoleProvider =
    NotifierProvider<SelectedRoleNotifier, AppRoleChoice?>(
      SelectedRoleNotifier.new,
    );

final userProfileProvider = FutureProvider<AppUserProfile?>((ref) async {
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return ref.watch(authServiceProvider).fetchCurrentProfile();
});
