import 'package:flutter/material.dart';

/// 新版应用的主题配置
class NewAppTheme {
  // 私有构造函数，防止实例化
  NewAppTheme._();

  // 主要颜色
  static const Color primaryColor = Color(0xFF3B82F6); // 蓝色
  static const Color secondaryColor = Color(0xFF10B981); // 绿色
  static const Color accentColor = Color(0xFFF59E0B); // 橙色

  // 背景颜色
  static const Color backgroundColor = Color(0xFFFFFFFF); // 白色
  static const Color surfaceColor = Color(0xFFF3F4F6); // 浅灰色

  // 文本颜色
  static const Color textPrimaryColor = Color(0xFF1F2937); // 深灰色
  static const Color textSecondaryColor = Color(0xFF6B7280); // 中灰色
  static const Color textTertiaryColor = Color(0xFF9CA3AF); // 浅灰色

  // 状态颜色
  static const Color successColor = Color(0xFF10B981); // 绿色
  static const Color warningColor = Color(0xFFF59E0B); // 橙色
  static const Color errorColor = Color(0xFFEF4444); // 红色
  static const Color infoColor = Color(0xFF3B82F6); // 蓝色

  // 连接状态颜色
  static const Color connectedColor = Color(0xFF10B981); // 绿色
  static const Color disconnectedColor = Color(0xFFEF4444); // 红色
  static const Color connectingColor = Color(0xFFF59E0B); // 橙色

  // 阴影
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // 圆角
  static const double borderRadius = 12.0;
  static BorderRadius defaultBorderRadius = BorderRadius.circular(borderRadius);

  // 间距
  static const double spacing = 8.0;
  static const double spacingSmall = 4.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;

  // 创建亮色主题
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      textTheme: _buildTextTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      appBarTheme: _buildAppBarTheme(),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }

  // 创建暗色主题
  static ThemeData darkTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: errorColor,
      ),
      textTheme: _buildTextTheme(isDark: true),
      elevatedButtonTheme: _buildElevatedButtonTheme(isDark: true),
      outlinedButtonTheme: _buildOutlinedButtonTheme(isDark: true),
      inputDecorationTheme: _buildInputDecorationTheme(isDark: true),
      cardTheme: _buildCardTheme(isDark: true),
      appBarTheme: _buildAppBarTheme(isDark: true),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }

  // 文本主题
  static TextTheme _buildTextTheme({bool isDark = false}) {
    final Color textColor = isDark ? Colors.white : textPrimaryColor;
    final Color textSecondary = isDark ? Colors.white70 : textSecondaryColor;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: textColor),
      titleLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontSize: 16.0, color: textColor),
      bodyMedium: TextStyle(fontSize: 14.0, color: textColor),
      bodySmall: TextStyle(fontSize: 12.0, color: textSecondary),
      labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600, color: textColor),
      labelSmall: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w600, color: textSecondary),
    );
  }

  // 按钮主题
  static ElevatedButtonThemeData _buildElevatedButtonTheme({bool isDark = false}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // 轮廓按钮主题
  static OutlinedButtonThemeData _buildOutlinedButtonTheme({bool isDark = false}) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // 输入框主题
  static InputDecorationTheme _buildInputDecorationTheme({bool isDark = false}) {
    final Color borderColor = isDark ? Colors.white24 : Colors.black12;

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // 卡片主题
  static CardTheme _buildCardTheme({bool isDark = false}) {
    return CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      margin: const EdgeInsets.all(0),
    );
  }

  // 应用栏主题
  static AppBarTheme _buildAppBarTheme({bool isDark = false}) {
    return AppBarTheme(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      foregroundColor: isDark ? Colors.white : textPrimaryColor,
      centerTitle: true,
    );
  }
}
