import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app_theme.dart';
import '../constants/app_constants.dart';

/// 主题模式状态提供者
final themeProviderNotifier = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

/// 主题模式状态管理类
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    // 初始化时从本地存储加载主题模式
    _loadThemeMode();
  }

  /// 切换主题模式
  Future<void> toggleThemeMode() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode(newMode);
    state = newMode;
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    await _saveThemeMode(mode);
    state = mode;
  }

  /// 加载主题模式
  Future<void> _loadThemeMode() async {
    // 这里应该从本地存储加载主题设置
    // 暂时使用系统默认模式
    state = ThemeMode.system;
  }

  /// 保存主题模式
  Future<void> _saveThemeMode(ThemeMode mode) async {
    // 这里应该将主题模式保存到本地存储
  }
}

/// 主题数据提供者
final themeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProviderNotifier);

  switch (themeMode) {
    case ThemeMode.light:
      return NewAppTheme.lightTheme();
    case ThemeMode.dark:
      return NewAppTheme.darkTheme();
    case ThemeMode.system:
      // 使用系统设置，但我们需要在运行时确定当前系统是否为暗色模式
      return NewAppTheme.lightTheme(); // 默认使用亮色主题
  }
});
