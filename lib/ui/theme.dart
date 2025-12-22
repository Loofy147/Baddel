import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// This file centralizes the application's design system, including colors,
// typography, and spacing, to ensure a consistent and high-quality UI.

class AppTheme {
  // --- BRAND COLORS (Cyberpunk/Neon Palette) ---
  // Primary colors that define the Baddel brand identity.
  static const Color neonGreen = Color(0xFF00E676); // Primary Action/Success
  static const Color neonPurple = Color(0xFF6200EA); // Secondary Branding/Premium
  static const Color vividRed = Color(0xFFFF1744); // Accent/Danger/Pass

  // --- UI COLORS ---
  // Standard colors for UI elements like backgrounds, text, and borders.
  static const Color deepObsidian = Color(0xFF0A0A0A); // Primary Background
  static const Color darkSurface = Color(0xFF1A1A1A); // Dark Card/Container Background
  static const Color glassSurface = Color(0xCC1A1A1A); // Frosted Glass Surface (80% opacity)

  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFBDBDBD); // Lighter grey for subtitles.
  static const Color accentColor = neonGreen;
  static const Color errorColor = vividRed;
  static const Color borderColor = Color(0xFF212121); // Subtle border color.

  // --- TEXT STYLES ---
  // A consistent typography scale using Google Fonts for a modern, tech-inspired look.
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.bold, color: primaryText),
    headlineMedium: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: primaryText),
    titleLarge: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w700, color: primaryText),
    bodyLarge: GoogleFonts.roboto(fontSize: 16, color: primaryText),
    bodyMedium: GoogleFonts.roboto(fontSize: 14, color: secondaryText),
    labelLarge: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
  );

  // --- SPACING ---
  // Standardized padding and margin values to create a consistent layout rhythm.
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  // --- BORDERS & RADII ---
  // Consistent border radius values for cards, buttons, and other rounded elements.
  static final BorderRadius borderRadius = BorderRadius.circular(16.0); // Slightly larger radius for premium feel
  static final Border border = Border.all(color: borderColor, width: 1.5);

  // --- THEME DATA ---
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepObsidian,
      primaryColor: neonGreen,
      colorScheme: ColorScheme.dark(
        primary: neonGreen,
        secondary: neonPurple,
        surface: darkSurface,
        background: deepObsidian,
        error: vividRed,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepObsidian,
        elevation: 0,
        centerTitle: true,
      ),
      // Customizing the BottomNavigationBar to match the dark theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: deepObsidian,
        selectedItemColor: neonGreen,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
      ),
      // Customizing buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }
}
