import 'package:flutter/material.dart';

class AppTokens {
  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 22.0;
  static const double radiusPill = 40.0;

  // Paddings
  static const double padSm = 8.0;
  static const double padMd = 16.0;
  static const double padLg = 24.0;

  // Glassmorphism Blur
  static const double blurSigma = 18.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get glowShadowGold => [
        BoxShadow(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
}
