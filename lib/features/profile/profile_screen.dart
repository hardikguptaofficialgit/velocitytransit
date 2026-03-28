import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final transitState = ref.watch(transitProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        title: const Text('Profile'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }

          if (!_isEditing) {
            _nameController.text = profile.name;
            _phoneController.text = profile.phone;
          }

          final transitNotifier = ref.read(transitProvider.notifier);
          final activeBus = transitState.activeAssignment == null
              ? null
              : transitNotifier.getBus(transitState.activeAssignment!.busId);
          final unreadAlerts =
              transitState.alerts.where((alert) => !alert.isRead).length;
          final currentUser = FirebaseAuth.instance.currentUser;
          final authProviders = currentUser?.providerData
                  .map((provider) => _providerLabel(provider.providerId))
                  .where((label) => label.isNotEmpty)
                  .toSet()
                  .toList() ??
              const <String>[];
          final rideHistory = _buildRideHistory(transitState);
          final profileCompletion = _profileCompletionScore(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(
                  profile: profile,
                  unreadAlerts: unreadAlerts,
                  favoritesCount: transitState.favorites.length,
                  rideCount: rideHistory.length,
                ),
                const SizedBox(height: 18),
                _sectionTitle('Account Details'),
                const SizedBox(height: 10),
                _fieldCard('Full Name', _nameController, enabled: _isEditing),
                const SizedBox(height: 12),
                _fieldCard('Phone', _phoneController, enabled: _isEditing),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  if (_isEditing) {
                                    _nameController.text = profile.name;
                                    _phoneController.text = profile.phone;
                                  }
                                  _isEditing = !_isEditing;
                                });
                              },
                        child: Text(_isEditing ? 'Cancel' : 'Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: !_isEditing || _isSaving ? null : _saveProfile,
                        child: Text(_isSaving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle('Security'),
                const SizedBox(height: 10),
                _securityCard(
                  items: [
                    _SecurityItem(
                      icon: Icons.verified_user_rounded,
                      label: 'Account status',
                      value: profile.isActive ? 'Protected' : 'Inactive',
                      tone: profile.isActive ? AppColors.success : AppColors.warning,
                    ),
                    _SecurityItem(
                      icon: Icons.mark_email_read_rounded,
                      label: 'Email verification',
                      value: currentUser?.emailVerified == true
                          ? 'Verified'
                          : 'Pending verification',
                      tone: currentUser?.emailVerified == true
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    _SecurityItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Sign-in method',
                      value: authProviders.isEmpty ? 'Email login' : authProviders.join(', '),
                      tone: AppColors.primary,
                    ),
                    _SecurityItem(
                      icon: Icons.account_circle_outlined,
                      label: 'Profile completion',
                      value: '$profileCompletion% complete',
                      tone: AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle('Ride History'),
                const SizedBox(height: 10),
                if (rideHistory.isEmpty)
                  _emptyCard(
                    title: 'No rides yet',
                    subtitle:
                        'Your recent trips, favorite commutes, and tracked routes will appear here.',
                    icon: Icons.history_rounded,
                  )
                else
                  ...rideHistory.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _rideHistoryCard(entry),
                    ),
                  ),
                const SizedBox(height: 12),
                _sectionTitle('Saved Commutes'),
                const SizedBox(height: 10),
                if (transitState.favorites.isEmpty)
                  _emptyCard(
                    title: 'No saved routes',
                    subtitle:
                        'Favorite routes will help you jump back into your daily commute faster.',
                    icon: Icons.favorite_border_rounded,
                  )
                else
                  ...transitState.favorites.map(
                    (favorite) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _favoriteCard(favorite),
                    ),
                  ),
                const SizedBox(height: 12),
                _sectionTitle('Live Transit Summary'),
                const SizedBox(height: 10),
                _summaryGrid(
                  items: [
                    _SummaryItem(
                      label: 'Active route',
                      value: activeBus?.routeName ?? 'No live trip',
                    ),
                    _SummaryItem(
                      label: 'Assigned bus',
                      value: transitState.activeAssignment?.busNumber ?? 'Not assigned',
                    ),
                    _SummaryItem(
                      label: 'Driver',
                      value: activeBus?.driverName ??
                          transitState.activeAssignment?.driverName ??
                          'Unavailable',
                    ),
                    _SummaryItem(
                      label: 'Unread alerts',
                      value: '$unreadAlerts alerts',
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      ref.invalidate(userProfileProvider);
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.roleSelection,
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updateCurrentProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildHeroCard({
    required AppUserProfile profile,
    required int unreadAlerts,
    required int favoritesCount,
    required int rideCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFFFF4EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryMuted,
            child: Text(
              profile.name.isEmpty ? 'U' : profile.name[0].toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.email,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _chip('Role', profile.role.toUpperCase()),
              _chip('Status', profile.isActive ? 'ACTIVE' : 'INACTIVE'),
              _chip('Alerts', '$unreadAlerts unread'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _miniMetric('Rides', '$rideCount')),
              const SizedBox(width: 10),
              Expanded(child: _miniMetric('Favorites', '$favoritesCount')),
              const SizedBox(width: 10),
              Expanded(child: _miniMetric('Phone', profile.phone.isEmpty ? 'Add' : 'Saved')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldCard(String label, TextEditingController controller, {required bool enabled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _securityCard({required List<_SecurityItem> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.tone.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.tone, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.value,
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _rideHistoryCard(_RideHistoryEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.routeShortName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                entry.timeLabel,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.title,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _favoriteCard(FavoriteRoute favorite) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors
                  .busLineColors[favorite.colorIndex % AppColors.busLineColors.length]
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: AppColors
                  .busLineColors[favorite.colorIndex % AppColors.busLineColors.length],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite.name,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${favorite.fromStop} → ${favorite.toStop}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            favorite.routeShortName,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({required List<_SummaryItem> items}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _summaryCard(item.label, item.value);
      },
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<_RideHistoryEntry> _buildRideHistory(TransitState transitState) {
  final entries = <_RideHistoryEntry>[];

  for (final favorite in transitState.favorites.take(3)) {
    entries.add(
      _RideHistoryEntry(
        routeShortName: favorite.routeShortName,
        title: favorite.name,
        subtitle: '${favorite.fromStop} to ${favorite.toStop}',
        timeLabel: 'Saved commute',
      ),
    );
  }

  for (final alert in transitState.alerts.take(2)) {
    final routeLabel = transitState.routes
        .cast<TransitRoute?>()
        .firstWhere((route) => route?.id == alert.routeId, orElse: () => null)
        ?.shortName;
    entries.add(
      _RideHistoryEntry(
        routeShortName: routeLabel ?? 'LIVE',
        title: alert.title,
        subtitle: alert.message,
        timeLabel: _timeAgo(alert.timestamp),
      ),
    );
  }

  return entries.take(5).toList();
}

int _profileCompletionScore(AppUserProfile profile) {
  var score = 50;
  if (profile.name.trim().isNotEmpty) score += 20;
  if (profile.phone.trim().isNotEmpty) score += 15;
  if (profile.avatar.trim().isNotEmpty) score += 5;
  if (FirebaseAuth.instance.currentUser?.emailVerified == true) score += 10;
  return score.clamp(0, 100);
}

String _providerLabel(String providerId) {
  switch (providerId) {
    case 'google.com':
      return 'Google';
    case 'password':
      return 'Email';
    case 'phone':
      return 'Phone';
    default:
      return providerId;
  }
}

String _timeAgo(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _RideHistoryEntry {
  const _RideHistoryEntry({
    required this.routeShortName,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
  });

  final String routeShortName;
  final String title;
  final String subtitle;
  final String timeLabel;
}

class _SecurityItem {
  const _SecurityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
