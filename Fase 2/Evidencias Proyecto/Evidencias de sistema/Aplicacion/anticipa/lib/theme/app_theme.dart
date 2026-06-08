import 'package:flutter/material.dart';

class ThemeColors {
  final Color background;
  final Color appBar;
  final Color card;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  const ThemeColors({
    required this.background,
    required this.appBar,
    required this.card,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  Map<String, dynamic> toJson() => {
    'background': background.toARGB32(),
    'appBar': appBar.toARGB32(),
    'card': card.toARGB32(),
    'primary': primary.toARGB32(),
    'textPrimary': textPrimary.toARGB32(),
    'textSecondary': textSecondary.toARGB32(),
  };

  factory ThemeColors.fromJson(Map<String, dynamic> json) => ThemeColors(
    background: Color(json['background'] as int),
    appBar: Color(json['appBar'] as int),
    card: Color(json['card'] as int),
    primary: Color(json['primary'] as int),
    textPrimary: Color(json['textPrimary'] as int),
    textSecondary: Color(json['textSecondary'] as int),
  );
}

class PredefinedTheme {
  final int id;
  final String name;
  final String emoji;
  final bool isDark;
  final ThemeColors colors;

  const PredefinedTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isDark,
    required this.colors,
  });
}

class ThemeConfig {
  final int temaId;
  final ThemeColors colors;
  final bool usandoTemaPredefinido;

  const ThemeConfig({
    required this.temaId,
    required this.colors,
    required this.usandoTemaPredefinido,
  });

  factory ThemeConfig.defaultTheme() => const ThemeConfig(
    temaId: 0,
    colors: ThemeColors(
      background: Color(0xFFF5F7FF),
      appBar: Color(0xFF061A40),
      card: Color(0xFFFFFFFF),
      primary: Color(0xFF4F46E5),
      textPrimary: Color(0xFF061A40),
      textSecondary: Color(0xFF6B7280),
    ),
    usandoTemaPredefinido: true,
  );

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    if (json['usandoTemaPredefinido'] == true && json['temaId'] != null) {
      final predef = predefinedThemes.firstWhere(
        (t) => t.id == json['temaId'],
        orElse: () => predefinedThemes.first,
      );
      return ThemeConfig(temaId: predef.id, colors: predef.colors, usandoTemaPredefinido: true);
    }
    return ThemeConfig(
      temaId: -1,
      colors: ThemeColors.fromJson(json['colors'] as Map<String, dynamic>),
      usandoTemaPredefinido: false,
    );
  }

  Map<String, dynamic> toJson() {
    if (usandoTemaPredefinido) {
      return {'temaId': temaId, 'usandoTemaPredefinido': true};
    }
    return {
      'usandoTemaPredefinido': false,
      'colors': colors.toJson(),
    };
  }

  ThemeConfig copyWith({int? temaId, ThemeColors? colors, bool? usandoTemaPredefinido}) {
    return ThemeConfig(
      temaId: temaId ?? this.temaId,
      colors: colors ?? this.colors,
      usandoTemaPredefinido: usandoTemaPredefinido ?? this.usandoTemaPredefinido,
    );
  }

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: colors.background.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light,
        surface: colors.background,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.primary.withValues(alpha: 0.7),
        surfaceContainerHighest: colors.card,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.appBar,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textPrimary),
        bodySmall: TextStyle(color: colors.textSecondary),
        labelLarge: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      dividerColor: colors.textSecondary.withValues(alpha: 0.2),
    );
  }
}

const List<PredefinedTheme> predefinedThemes = [
  PredefinedTheme(
    id: 0,
    name: 'Por defecto',
    emoji: '🔵',
    isDark: false,
    colors: ThemeColors(
      background: Color(0xFFF5F7FF),
      appBar: Color(0xFF061A40),
      card: Color(0xFFFFFFFF),
      primary: Color(0xFF4F46E5),
      textPrimary: Color(0xFF061A40),
      textSecondary: Color(0xFF6B7280),
    ),
  ),
  PredefinedTheme(
    id: 1,
    name: 'Azul calmado',
    emoji: '🌊',
    isDark: false,
    colors: ThemeColors(
      background: Color(0xFFEEF6FF),
      appBar: Color(0xFF1565C0),
      card: Color(0xFFE3F2FD),
      primary: Color(0xFF1976D2),
      textPrimary: Color(0xFF0D47A1),
      textSecondary: Color(0xFF546E7A),
    ),
  ),
  PredefinedTheme(
    id: 2,
    name: 'Verde naturaleza',
    emoji: '🌿',
    isDark: false,
    colors: ThemeColors(
      background: Color(0xFFF0FFF4),
      appBar: Color(0xFF2E7D32),
      card: Color(0xFFE8F5E9),
      primary: Color(0xFF388E3C),
      textPrimary: Color(0xFF1B5E20),
      textSecondary: Color(0xFF558B2F),
    ),
  ),
  PredefinedTheme(
    id: 3,
    name: 'Amarillo alegre',
    emoji: '☀️',
    isDark: false,
    colors: ThemeColors(
      background: Color(0xFFFFFDE7),
      appBar: Color(0xFFF57F17),
      card: Color(0xFFFFF9C4),
      primary: Color(0xFFF9A825),
      textPrimary: Color(0xFFE65100),
      textSecondary: Color(0xFF8D6E63),
    ),
  ),
  PredefinedTheme(
    id: 4,
    name: 'Púrpura suave',
    emoji: '💜',
    isDark: false,
    colors: ThemeColors(
      background: Color(0xFFF3E5F5),
      appBar: Color(0xFF7B1FA2),
      card: Color(0xFFE1BEE7),
      primary: Color(0xFF8E24AA),
      textPrimary: Color(0xFF4A148C),
      textSecondary: Color(0xFF7B1FA2),
    ),
  ),
  PredefinedTheme(
    id: 5,
    name: 'Modo oscuro',
    emoji: '🌙',
    isDark: true,
    colors: ThemeColors(
      background: Color(0xFF121212),
      appBar: Color(0xFF1E1E1E),
      card: Color(0xFF2C2C2C),
      primary: Color(0xFFBB86FC),
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFF9E9E9E),
    ),
  ),
];