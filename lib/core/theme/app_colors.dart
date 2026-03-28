import 'package:flutter/material.dart';

/// Velocity Transit Design System — Refined (High Contrast + Controlled Pastels)
class AppColors {
  AppColors._();

  // ── Background layers ──
  static const Color backgroundLight = Color(0xFFF4F6FA);   // cleaner neutral
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundElevated = Color(0xFFE9EDF5);
  static const Color backgroundSheet = Color(0xFFF8FAFC);

  // Dark surfaces (true usable dark mode, not blue-heavy)
  static const Color backgroundDark = Color(0xFF0B0F1A);
  static const Color backgroundDarkTitle = Color(0xFF020617);

  // ── Primary palette (more authority, less pastel fade) ──
  static const Color primary = Color(0xFF4F6EDB);          // stronger blue
  static const Color primaryLight = Color(0xFF7C93F0);
  static const Color primaryMuted = Color(0xFFE3E9FF);     // controlled tint
  static const Color primarySurface = Color(0xFFF0F3FF);

  // ── Accent palette (less dusty, more defined) ──
  static const Color accent = Color(0xFFE88C6B);           // sharpened coral
  static const Color accentLight = Color(0xFFF2B29B);
  static const Color accentMuted = Color(0xFFFDEAE4);

  // ── Signal colors (clear readability priority) ──
  static const Color warning = Color(0xFFF59E0B);          // amber
  static const Color error = Color(0xFFEF4444);            // red
  static const Color success = Color(0xFF22C55E);          // green
  static const Color info = Color(0xFF3B82F6);             // blue

  // ── Occupancy states (must be instantly scannable) ──
  static const Color occupancyLow = Color(0xFF22C55E);
  static const Color occupancyMedium = Color(0xFFF59E0B);
  static const Color occupancyHigh = Color(0xFFEF4444);

  // ── Heatmap blocks (remove muddy tones, increase separation) ──
  static const Color heatmapLow = Color(0xFFDCEFE3);
  static const Color heatmapMedium = Color(0xFF93C5FD);
  static const Color heatmapHigh = Color(0xFFFCA5A5);
  static const Color heatmapCritical = Color(0xFFDC2626);

  // ── Text hierarchy (higher contrast for accessibility) ──
  static const Color textPrimary = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & Dividers (less beige, more neutral UI feel) ──
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // ── Route line colors (distinct, non-conflicting hues) ──
  static const Color routePrimary = Color(0xFF4F6EDB);
  static const Color routeSecondary = Color(0xFFE88C6B);
  static const Color routeAlt = Color(0xFF06B6D4);
  static const Color routeInactive = Color(0xFFCBD5E1);

  // ── Bus line badge colors (high differentiation set) ──
  static const List<Color> busLineColors = [
    Color(0xFF4F6EDB), // blue
    Color(0xFFE88C6B), // coral
    Color(0xFF06B6D4), // cyan
    Color(0xFFF59E0B), // amber
    Color(0xFF22C55E), // green
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
  ];
}