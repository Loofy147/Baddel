import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// This file centralizes the application's design system, including colors,
// typography, and spacing, to ensure a consistent and high-quality UI.

class AppTheme {
  // --- BRAND COLORS ---
  // Primary colors that define the Baddel brand identity.
  static const Color electricBlue = Color(0xFF00E676); // A vibrant, attention-grabbing green for primary actions.
  static const Color neonPurple = Color(0xFF6200EA); // A deep purple for secondary branding elements.
  static const Color emeraldGreen = Color(0xFF00C853); // A slightly darker green for success states.

  // --- UI COLORS ---
  // Standard colors for UI elements like backgrounds, text, and borders.
  static const Color primaryBackground = Colors.black;
  static const Color cardBackground = Color(0xFF1A1A1A); // A very dark grey for card widgets.
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFBDBDBD); // A lighter grey for subtitles and less important text.
  static const Color accentColor = electricBlue;
  static const Color errorColor = Color(0xFFD32F2F); // A standard red for error messages.
  static const Color borderColor = Color(0xFF212121); // A subtle border color for cards and containers.

  // --- TEXT STYLES ---
  // A consistent typography scale using Google Fonts for a modern look.
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: primaryText),
    headlineMedium: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: primaryText),
    titleLarge: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w700, color: primaryText),
    bodyLarge: GoogleFonts.roboto(fontSize: 16, color: primaryText),
    bodyMedium: GoogleFonts.roboto(fontSize: 14, color: secondaryText),
    labelLarge: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
  );

  // --- SPACING ---
  // Standardized padding and margin values to create a consistent layout rhythm.
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  // --- BORDERS & RADII ---
  // Consistent border radius values for cards, buttons, and other rounded elements.
  static final BorderRadius borderRadius = BorderRadius.circular(12.0);
  static final Border border = Border.all(color: borderColor, width: 1.5);
}
