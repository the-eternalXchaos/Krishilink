// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AppTheme {
//   static final lightTheme = ThemeData(
//     brightness: Brightness.light,
//     colorScheme: ColorScheme.light(
//       primary: Colors.green.shade700,
//       primaryContainer: Colors.green.shade100,
//       onPrimaryContainer: Colors.green.shade900,
//       secondary: Colors.green.shade300,
//       surface: Colors.green.shade100,
//       onPrimary: Colors.white,
//       onSurface: Colors.black,
//     ),
//     scaffoldBackgroundColor: Colors.green.shade100,
//     textTheme: GoogleFonts.poppinsTextTheme().copyWith(
//       headlineLarge: const TextStyle(
//         fontSize: 26,
//         fontWeight: FontWeight.bold,
//         color: Colors.black87,
//       ),
//       headlineMedium: const TextStyle(
//         fontSize: 22,
//         fontWeight: FontWeight.w600,
//         color: Colors.black87,
//       ),
//       titleLarge: const TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//         color: Colors.black87,
//       ),
//       titleMedium: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//         color: Colors.black87,
//       ),
//       bodyLarge: const TextStyle(fontSize: 16, color: Colors.black87),
//       bodyMedium: const TextStyle(fontSize: 14, color: Colors.black87),
//       labelLarge: const TextStyle(
//         fontSize: 14,
//         fontWeight: FontWeight.w500,
//         color: Colors.black87,
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green.shade700,
//         foregroundColor: Colors.white,
//         textStyle: const TextStyle(fontWeight: FontWeight.bold),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 2,
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: Colors.green.shade50,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       hintStyle: TextStyle(color: Colors.white70),
//     ),
//     tabBarTheme: TabBarThemeData(
//       labelColor: Colors.green.shade800,
//       unselectedLabelColor: Colors.grey.shade700,
//       indicator: UnderlineTabIndicator(
//         borderSide: BorderSide(width: 3, color: Colors.green.shade800),
//       ),
//     ),
//     snackBarTheme: SnackBarThemeData(
//       backgroundColor: Colors.green.shade500,
//       contentTextStyle: const TextStyle(color: Colors.white),
//     ),
//     visualDensity: VisualDensity.adaptivePlatformDensity,
//     pageTransitionsTheme: const PageTransitionsTheme(
//       builders: {
//         TargetPlatform.android: ZoomPageTransitionsBuilder(),
//         TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
//       },
//     ),
//   );

//   static final darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     colorScheme: ColorScheme.dark(
//       primary: Colors.green.shade600,
//       primaryContainer: Colors.green.shade900,
//       onPrimaryContainer: Colors.white70,
//       secondary: Colors.teal.shade700,
//       surface: Colors.grey.shade800,
//       onPrimary: Colors.white,
//       onSurface: Colors.grey.shade100,
//     ),
//     scaffoldBackgroundColor: Colors.grey.shade900,
//     appBarTheme: AppBarTheme(
//       backgroundColor: Colors.grey.shade800,
//       titleTextStyle: GoogleFonts.poppins(
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       ),
//       iconTheme: const IconThemeData(color: Colors.white),
//       elevation: 3,
//     ),

//     textTheme: GoogleFonts.poppinsTextTheme().copyWith(
//       headlineSmall: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: const Color.fromARGB(255, 253, 250, 250),
//       ),
//       headlineLarge: TextStyle(
//         fontSize: 26,
//         fontWeight: FontWeight.bold,
//         color: Colors.grey.shade100,
//       ),
//       headlineMedium: TextStyle(
//         fontSize: 22,
//         fontWeight: FontWeight.w600,
//         color: Colors.grey.shade100,
//       ),
//       titleLarge: TextStyle(
//         fontSize: 22,
//         fontWeight: FontWeight.w600,
//         color: Colors.grey.shade100,
//       ),
//       titleMedium: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//         color: Colors.grey.shade100,
//       ),
//       bodyLarge: TextStyle(fontSize: 16, color: Colors.grey.shade200),
//       bodyMedium: TextStyle(fontSize: 14, color: Colors.grey.shade300),
//       labelLarge: const TextStyle(
//         fontSize: 14,
//         fontWeight: FontWeight.w500,
//         color: Colors.white,
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green.shade600,
//         foregroundColor: Colors.white,
//         textStyle: const TextStyle(fontWeight: FontWeight.bold),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 2,
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: Colors.grey.shade800,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       hintStyle: TextStyle(color: Colors.grey.shade500),
//     ),
//     tabBarTheme: TabBarThemeData(
//       labelColor: Colors.green.shade600,
//       unselectedLabelColor: Colors.grey.shade500,
//       indicator: UnderlineTabIndicator(
//         borderSide: BorderSide(width: 3, color: Colors.green.shade600),
//       ),
//     ),
//     snackBarTheme: SnackBarThemeData(
//       backgroundColor: Colors.green.shade600,
//       contentTextStyle: const TextStyle(color: Colors.white),
//     ),
//     visualDensity: VisualDensity.adaptivePlatformDensity,
//     pageTransitionsTheme: const PageTransitionsTheme(
//       builders: {
//         TargetPlatform.android: ZoomPageTransitionsBuilder(),
//         TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
//       },
//     ),
//   );
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Base text theme with Google Fonts
  static final _baseTextTheme = GoogleFonts.poppinsTextTheme();

  // Shared ElevatedButton style base
  static final _baseButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );

  // Reusable input decoration
  static InputDecorationTheme _inputTheme(Color fillColor, Color hintColor) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: hintColor),
      );

  // Reusable tab bar theme
  static TabBarThemeData _tabBarTheme(Color activeColor, Color inactiveColor) =>
      TabBarThemeData(
        labelColor: activeColor,
        unselectedLabelColor: inactiveColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: activeColor),
        ),
      );

  // Reusable snackbar theme
  static SnackBarThemeData _snackBarTheme(Color bg, Color textColor) =>
      SnackBarThemeData(
        backgroundColor: bg,
        contentTextStyle: TextStyle(color: textColor),
      );

  // 🌞 Light Theme
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Colors.green.shade700,
      primaryContainer: Colors.green.shade100,
      onPrimaryContainer: Colors.green.shade900,
      secondary: Colors.green.shade300,
      surface: Colors.green.shade100,
      onPrimary: Colors.white,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.green.shade100,
    textTheme: _baseTextTheme.copyWith(
      headlineLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      headlineMedium: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16),
      bodyMedium: const TextStyle(fontSize: 14),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _baseButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.green.shade700),
      ),
    ),
    inputDecorationTheme: _inputTheme(
      Colors.green.shade50,
      Colors.black.withAlpha(128),
    ),
    tabBarTheme: _tabBarTheme(Colors.green.shade800, Colors.grey.shade700),
    snackBarTheme: _snackBarTheme(Colors.green.shade500, Colors.white),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // 🌙 Dark Theme
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.green.shade600,
      primaryContainer: Colors.green.shade900,
      onPrimaryContainer: Colors.white70,
      secondary: Colors.teal.shade700,
      surface: Colors.grey.shade800,
      onPrimary: Colors.white,
      onSurface: Colors.grey.shade100,
    ),
    scaffoldBackgroundColor: Colors.grey.shade900,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade800,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 3,
    ),
    textTheme: _baseTextTheme.copyWith(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade100,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade100,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade100,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade100,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade100,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.grey.shade200),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.grey.shade300),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _baseButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.green.shade600),
      ),
    ),
    inputDecorationTheme: _inputTheme(
      Colors.grey.shade800,
      Colors.grey.shade500,
    ),
    tabBarTheme: _tabBarTheme(Colors.green.shade600, Colors.grey.shade500),
    snackBarTheme: _snackBarTheme(Colors.green.shade600, Colors.white),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
