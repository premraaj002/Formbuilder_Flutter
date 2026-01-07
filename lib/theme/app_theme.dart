import 'package:flutter/material.dart';

class AppTheme {
  // Colors based on FormBuilderScreen's elegant design
  static const Color _primaryColor = Color(0xFF1A73E8);
  static const Color _primaryColorDark = Color(0xFF8AB4F8);
  static const Color _surfaceColor = Color(0xFFFAFBFF);
  static const Color _surfaceColorDark = Color(0xFF121212);
  static const Color _cardColor = Colors.white;
  static const Color _cardColorDark = Color(0xFF1E1E1E);
  static const Color _scaffoldBackgroundColor = Color(0xFFF8F9FA);
  static const Color _scaffoldBackgroundColorDark = Color(0xFF0F0F0F);

  // Enhanced light theme matching FormBuilderScreen style
  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: Color(0xFF6B73FF),
      onSecondary: Colors.white,
      tertiary: Color(0xFF7C4DFF),
      onTertiary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: _surfaceColor,
      onSurface: Color(0xFF1C1B1F),
      onSurfaceVariant: Color(0xFF49454F),
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFCAC4D0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF313033),
      onInverseSurface: Color(0xFFF4EFF4),
      inversePrimary: Color(0xFF8AB4F8),
      primaryContainer: Color(0xFFD8E2FF),
      onPrimaryContainer: Color(0xFF001D36),
      secondaryContainer: Color(0xFFE0E0FF),
      onSecondaryContainer: Color(0xFF1B1B2F),
      tertiaryContainer: Color(0xFFEADDFF),
      onTertiaryContainer: Color(0xFF21005D),
      surfaceContainerHighest: Color(0xFFE6E1E5),
      surfaceContainerHigh: Color(0xFFECE6EA),
      surfaceContainer: Color(0xFFF2ECF0),
      surfaceContainerLow: Color(0xFFF7F2FA),
      surfaceContainerLowest: Colors.white,
      surfaceVariant: Color(0xFFE7E0EC),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _scaffoldBackgroundColor,
      
      // AppBar theme matching FormBuilderScreen
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceColor,
        foregroundColor: Color(0xFF1C1B1F),
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF49454F),
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Color(0xFF49454F),
          size: 24,
        ),
      ),

      // Card theme with enhanced shadows and borders
      cardTheme: CardThemeData(
        color: _cardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Enhanced input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: Color(0xFF79747E),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF79747E),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _primaryColor.withOpacity(0.3),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // IconButton theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF49454F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // FloatingActionButton theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return const Color(0xFF79747E);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor.withOpacity(0.5);
          }
          return const Color(0xFFE6E1E5);
        }),
      ),

      // Chip theme
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFFE6E1E5),
        selectedColor: Color(0xFFD8E2FF),
        secondarySelectedColor: Color(0xFFD8E2FF),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE6E1E5),
        thickness: 1,
        space: 1,
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        backgroundColor: _surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 6,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF313033),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF4EFF4),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ListTile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  // Enhanced dark theme
  static ThemeData get dark {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryColorDark,
      onPrimary: Color(0xFF1A1A1A),
      secondary: Color(0xFF8B8BF7),
      onSecondary: Color(0xFF1A1A1A),
      tertiary: Color(0xFFB19AFF),
      onTertiary: Color(0xFF1A1A1A),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: _surfaceColorDark,
      onSurface: Color(0xFFE6E1E5),
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E1E5),
      onInverseSurface: Color(0xFF313033),
      inversePrimary: _primaryColor,
      primaryContainer: Color(0xFF004A77),
      onPrimaryContainer: Color(0xFFD8E2FF),
      secondaryContainer: Color(0xFF3A3A60),
      onSecondaryContainer: Color(0xFFE0E0FF),
      tertiaryContainer: Color(0xFF3B2370),
      onTertiaryContainer: Color(0xFFEADDFF),
      surfaceContainerHighest: Color(0xFF36343B),
      surfaceContainerHigh: Color(0xFF2B2930),
      surfaceContainer: Color(0xFF211F26),
      surfaceContainerLow: Color(0xFF1D1B20),
      surfaceContainerLowest: Color(0xFF0F0D13),
      surfaceVariant: Color(0xFF49454F),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _scaffoldBackgroundColorDark,
      
      // AppBar theme for dark mode
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceColorDark,
        foregroundColor: Color(0xFFE6E1E5),
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E1E5),
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFCAC4D0),
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Color(0xFFCAC4D0),
          size: 24,
        ),
      ),

      // Card theme for dark mode
      cardTheme: CardThemeData(
        color: _cardColorDark,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input decoration theme for dark mode
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColorDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: Color(0xFF938F99),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF938F99),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Button themes for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColorDark,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.5),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColorDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColorDark,
          side: const BorderSide(color: _primaryColorDark, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // IconButton theme for dark mode
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFCAC4D0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // FloatingActionButton theme for dark mode
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColorDark,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Switch theme for dark mode
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColorDark;
          }
          return const Color(0xFF938F99);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColorDark.withOpacity(0.5);
          }
          return const Color(0xFF49454F);
        }),
      ),

      // Chip theme for dark mode
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF49454F),
        selectedColor: Color(0xFF004A77),
        secondarySelectedColor: Color(0xFF004A77),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Divider theme for dark mode
      dividerTheme: const DividerThemeData(
        color: Color(0xFF49454F),
        thickness: 1,
        space: 1,
      ),

      // Bottom sheet theme for dark mode
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceColorDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Dialog theme for dark mode
      dialogTheme: const DialogThemeData(
        backgroundColor: _surfaceColorDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 6,
      ),

      // Snackbar theme for dark mode
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF313033),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF4EFF4),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ListTile theme for dark mode
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}
