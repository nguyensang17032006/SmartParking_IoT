import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double height = 1.4,
  }) {
    return GoogleFonts.beVietnamPro(
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  // DISPLAY
  static final displayLarge = _base(
    size: 32,
    weight: FontWeight.w700,
    height: 1.2,
  );

  // HEADINGS
  static final headingLarge = _base(
    size: 28,
    weight: FontWeight.w700,
    height: 1.25,
  );

  static final headingMedium = _base(
    size: 24,
    weight: FontWeight.w700,
    height: 1.3,
  );

  static final headingSmall = _base(
    size: 20,
    weight: FontWeight.w600,
    height: 1.3,
  );

  // TITLES
  static final titleLarge = _base(size: 18, weight: FontWeight.w600);

  static final titleMedium = _base(size: 16, weight: FontWeight.w600);

  // BODY
  static final bodyLarge = _base(size: 16, weight: FontWeight.w400);

  static final bodyMedium = _base(size: 14, weight: FontWeight.w400);

  static final bodySmall = _base(size: 12, weight: FontWeight.w400);

  // BUTTONS
  static final buttonLarge = _base(
    size: 16,
    weight: FontWeight.w600,
    height: 1.2,
  );

  static final buttonMedium = _base(
    size: 14,
    weight: FontWeight.w600,
    height: 1.2,
  );

  // CAPTION
  static final caption = _base(size: 12, weight: FontWeight.w400);
}
