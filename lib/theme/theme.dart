import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class T {
  // Background layers (matches CSS variables)
  static const Color bg = Color(0xFF0D1117); // --bg
  static const Color surface = Color(0xFF161B22); // --surface
  static const Color surfaceEl = Color(0xFF1C2333); // elevated
  static const Color border = Color(0xFF30363D); // --border

  // Accent
  static const Color accent = Color(0xFF238636); // green (waiting action)
  static const Color accentBlue = Color(0xFF1F6FEB); // blue (active)
  static const Color purple = Color(0xFF8B5CF6);

  // Status colours
  static const Color waiting = Color(0xFFF0883E); // orange
  static const Color active = Color(0xFF3FB950); // green
  static const Color bot = Color(0xFF8B5CF6); // purple
  static const Color closed = Color(0xFF6E7681); // grey

  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // Message bubbles
  static const Color visitorBubble = Color(0xFF1C2333);
  static const Color adminBubble = Color(0xFF1F6FEB);
  static const Color botBubble = Color(0xFF2D1F5E);

  // Status pill
  static Color statusColor(String status) => switch (status) {
    'waiting' => waiting,
    'active' => active,
    'bot' => bot,
    'closed' => closed,
    _ => closed,
  };

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(primary: accentBlue, surface: surface),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceEl,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: accentBlue, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}
