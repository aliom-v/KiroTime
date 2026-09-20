import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 统一的设计系统（浅色 · 液态玻璃 / Liquid Glass 风格）。
///
/// 目标审美参考 Apple iOS 26 "液态玻璃"：通透的毛玻璃面板、柔和的高光描边、
/// 浅色低饱和背景，配合轻盈的阴影与圆角。所有颜色集中在这里，方便整体调性统一。
abstract final class KiroPalette {
  // 背景渐变（浅色、通透、带一点点冷调）
  static const List<Color> canvasGradient = <Color>[
    Color(0xFFEAF1FF),
    Color(0xFFF1EDFF),
    Color(0xFFE7FBF4),
  ];

  // 主色（青绿，保留品牌识别）
  static const Color primary = Color(0xFF0FA694);
  static const Color primaryDim = Color(0xFF8FE3D5);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // 文本
  static const Color textPrimary = Color(0xFF1B2A2E);
  static const Color textSecondary = Color(0xFF5C6B72);
  static const Color textTertiary = Color(0xFF8A969C);

  // 玻璃面板
  static const Color glassFillTop = Color(0xFFFFFFFF);
  static const Color glassFillBottom = Color(0xFFF4FBFF);
  static const Color glassBorder = Color(0x99FFFFFF);
  static const Color glassHighlight = Color(0x66FFFFFF);

  // 分隔线 / 虚线
  static const Color separator = Color(0x142C3B45);

  // 今日高亮
  static const Color todayAccent = Color(0xFFBFF3E8);

  // 软阴影
  static List<BoxShadow> get softShadow => <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF1E3A3F).withAlpha(18),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

ThemeData buildKiroTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: KiroPalette.primary,
        primary: KiroPalette.primary,
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFF6FBFD),
        onSurface: KiroPalette.textPrimary,
        outlineVariant: const Color(0x1F2C3B45),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFEAF1FF),
    splashFactory: InkSparkle.splashFactory,
    textTheme: _textTheme,
    iconTheme: const IconThemeData(color: KiroPalette.textPrimary),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: KiroPalette.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFEAF1FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    // 输入框：浅色玻璃感
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withAlpha(120),
      labelStyle: const TextStyle(color: KiroPalette.textSecondary),
      hintStyle: const TextStyle(color: KiroPalette.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KiroPalette.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KiroPalette.primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KiroPalette.primary,
        foregroundColor: KiroPalette.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KiroPalette.primary,
        side: const BorderSide(color: KiroPalette.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: KiroPalette.primary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KiroPalette.onPrimary
            : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KiroPalette.primary
            : const Color(0xFFCBD5D9),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white.withAlpha(235),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
  );
}

const TextTheme _textTheme = TextTheme(
  headlineSmall: TextStyle(
    color: KiroPalette.textPrimary,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  ),
  titleLarge: TextStyle(
    color: KiroPalette.textPrimary,
    fontWeight: FontWeight.w800,
  ),
  titleMedium: TextStyle(
    color: KiroPalette.textPrimary,
    fontWeight: FontWeight.w700,
  ),
  titleSmall: TextStyle(
    color: KiroPalette.textPrimary,
    fontWeight: FontWeight.w700,
  ),
  bodyLarge: TextStyle(color: KiroPalette.textPrimary),
  bodyMedium: TextStyle(color: KiroPalette.textPrimary),
  bodySmall: TextStyle(color: KiroPalette.textSecondary),
  labelLarge: TextStyle(
    color: KiroPalette.textPrimary,
    fontWeight: FontWeight.w600,
  ),
);
