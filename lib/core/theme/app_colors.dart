import 'package:flutter/material.dart';

/// Velocity Transit Design System — Solid Light Colors
class AppColors {
  AppColors._();

  // ── Background layers ──
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundElevated = Color(0xFFF1F5F9);
  static const Color backgroundSheet = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color backgroundDarkTitle = Color(0xFF050914);

  // ── Primary palette ──
  static const Color primary = Color(0xFF4338CA);        // Bold Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryMuted = Color(0xFFE0E7FF);
  static const Color primarySurface = Color(0xFFEEF2FF);

  // ── Accent palette ──
  static const Color accent = Color(0xFFEC4899);          // Vibrant Pink
  static const Color accentLight = Color(0xFFF472B6);
  static const Color accentMuted = Color(0xFFFCE7F3);

  // ── Signal colors ──
  static const Color warning = Color(0xFFF59E0B);         // Bright Amber
  static const Color error = Color(0xFFEF4444);           // Red
  static const Color success = Color(0xFF10B981);         // Emerald Green
  static const Color info = Color(0xFF3B82F6);            // Blue

  // ── Occupancy states ──
  static const Color occupancyLow = Color(0xFF10B981);
  static const Color occupancyMedium = Color(0xFFF59E0B);
  static const Color occupancyHigh = Color(0xFFEF4444);

  // ── Heatmap blocks ──
  static const Color heatmapLow = Color(0xFFE2E8F0);
  static const Color heatmapMedium = Color(0xFF93C5FD);
  static const Color heatmapHigh = Color(0xFFF87171);
  static const Color heatmapCritical = Color(0xFFEF4444);

  // ── Text hierarchy ──
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & Dividers ──
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // ── Route line colors ──
  static const Color routePrimary = Color(0xFF4338CA);
  static const Color routeSecondary = Color(0xFFEC4899);
  static const Color routeAlt = Color(0xFF3B82F6);
  static const Color routeInactive = Color(0xFFCBD5E1);

  // ── Bus line badge colors ──
  static const List<Color> busLineColors = [
    Color(0xFF4338CA), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF43F5E), // Rose
    Color(0xFF0EA5E9), // Sky
  ];
}
