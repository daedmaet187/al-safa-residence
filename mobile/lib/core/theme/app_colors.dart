import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B3A6B);
  static const Color primaryLight = Color(0xFFEEF2F8);
  static const Color secondary = Color(0xFF2D5EA8);
  static const Color accent = Color(0xFFC9A96E);
  static const Color accentLight = Color(0xFFF5ECD9);
  static const Color accentDark = Color(0xFFB8924A);

  // ── Light Mode Surfaces ────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color sidebar = Color(0xFF0F1F3D);
  static const Color border = Color(0x0F000000);
  static const Color divider = Color(0x0F000000);

  // ── Light Mode Text ────────────────────────────────────────────────────────
  static const Color text = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Dark Mode Surfaces ─────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B0D10);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceRaised = Color(0xFF1F2937);
  static const Color darkSidebar = Color(0xFF060810);
  static const Color darkBorder = Color(0x14FFFFFF);
  static const Color darkDivider = Color(0x14FFFFFF);

  // ── Dark Mode Text ─────────────────────────────────────────────────────────
  static const Color darkText = Color(0xFFF9FAFB);
  static const Color darkTextMuted = Color(0xFF9CA3AF);
  static const Color darkTextSubtle = Color(0xFF6B7280);

  // ── Dark Mode Brand ────────────────────────────────────────────────────────
  static const Color darkPrimary = Color(0xFF3B6CC9);
  static const Color darkPrimaryLight = Color(0xFF1A2B4A);
  static const Color darkSecondary = Color(0xFF4A80D4);
  static const Color darkAccent = Color(0xFFD4AF7A);
  static const Color darkAccentLight = Color(0xFF2A1F0A);

  // ── Status Colors (Light) ──────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // ── Status Colors (Dark) ───────────────────────────────────────────────────
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkSuccessLight = Color(0xFF052E16);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkWarningLight = Color(0xFF2D1D06);
  static const Color darkDanger = Color(0xFFF87171);
  static const Color darkDangerLight = Color(0xFF2D0707);

  // ── Gate / Security Status ─────────────────────────────────────────────────
  static const Color gateApproved = Color(0xFF16A34A);
  static const Color gateGuest = Color(0xFF1D4ED8);
  static const Color gateDenied = Color(0xFFDC2626);
  static const Color gateBlacklist = Color(0xFF7F1D1D);
  static const Color gateWaiting = Color(0xFFD97706);

  // ── Dark Gate / Security Status ────────────────────────────────────────────
  static const Color darkGateApproved = Color(0xFF22C55E);
  static const Color darkGateGuest = Color(0xFF60A5FA);
  static const Color darkGateDenied = Color(0xFFF87171);
  static const Color darkGateBlacklist = Color(0xFFFCA5A5);
  static const Color darkGateWaiting = Color(0xFFFBBF24);

  // ── Gold Gradient Stops ────────────────────────────────────────────────────
  static const Color goldGradientStart = Color(0xFFD4AF7A);
  static const Color goldGradientMid = Color(0xFFC9A96E);
  static const Color goldGradientEnd = Color(0xFFB8924A);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldGradientStart, goldGradientMid, goldGradientEnd],
  );
}
