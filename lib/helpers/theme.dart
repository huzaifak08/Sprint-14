import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF4285F4),
    primary: const Color(0xFF4285F4),
    onPrimary: Colors.white,
    surface: Colors.white,
    tertiary: Color(0xFFFF9800),
    onSecondary: Colors.black,
  ),
  scaffoldBackgroundColor: Colors.grey[100],

  // DATE PICKER LIGHT
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Colors.white,
    headerBackgroundColor: const Color(0xFF4285F4),
    headerForegroundColor: Colors.white,
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF4285F4);
      return null;
    }),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return Colors.black;
    }),
    todayBorder: const BorderSide(color: Color(0xFF4285F4)),
    confirmButtonStyle: TextButton.styleFrom(
      foregroundColor: const Color(0xFF4285F4),
    ),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
  ),

  // TIME PICKER LIGHT
  timePickerTheme: TimePickerThemeData(
    backgroundColor: Colors.white,
    dialHandColor: const Color(0xFF4285F4),
    dialBackgroundColor: Colors.grey[200],
    hourMinuteTextColor: Colors.black,
    hourMinuteColor: Colors.grey[100],
    entryModeIconColor: const Color(0xFF4285F4),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.grey,
    brightness: Brightness.dark,
    primary: const Color(0xFFD4AF37), // Golden accent
    onPrimary: Colors.black,
    surface: const Color(0xFF1A1A1A),
    tertiary: Color(0xFFFF9800),
    onSecondary: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F0F),

  // DATE PICKER DARK
  datePickerTheme: DatePickerThemeData(
    backgroundColor: const Color(0xFF1A1A1A),
    headerBackgroundColor: const Color(0xFF1A1A1A),
    headerForegroundColor: const Color(0xFFD4AF37),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFD4AF37);
      return null;
    }),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.black;
      return Colors.white;
    }),
    todayBorder: const BorderSide(color: Color(0xFFD4AF37)),
    confirmButtonStyle: TextButton.styleFrom(
      foregroundColor: const Color(0xFFD4AF37),
    ),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white70),
  ),

  // TIME PICKER DARK
  timePickerTheme: TimePickerThemeData(
    backgroundColor: const Color(0xFF1A1A1A),
    dialHandColor: const Color(0xFFD4AF37),
    dialTextColor: Colors.white,
    dialBackgroundColor: Colors.black,
    hourMinuteTextColor: const Color(0xFFD4AF37),
    hourMinuteColor: Colors.black,
    dayPeriodTextColor: const Color(0xFFD4AF37),
    entryModeIconColor: const Color(0xFFD4AF37),
  ),
);
