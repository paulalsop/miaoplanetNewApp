import 'package:flutter/material.dart';

/// 屏幕尺寸工具类，用于响应式布局
class SizeUtils {
  // 私有构造函数，防止实例化
  SizeUtils._();

  /// 获取屏幕宽度
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 获取状态栏高度
  static double statusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// 获取底部安全区域高度
  static double bottomSafeAreaHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 获取可用高度（屏幕高度减去状态栏和底部安全区域）
  static double availableHeight(BuildContext context) {
    return screenHeight(context) - statusBarHeight(context) - bottomSafeAreaHeight(context);
  }

  /// 获取设备方向
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// 检查是否为横屏
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }

  /// 检查是否为竖屏
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }

  /// 检查是否为手机屏幕（小屏幕）
  static bool isMobileScreen(BuildContext context) {
    return screenWidth(context) < 600;
  }

  /// 检查是否为平板屏幕（中等屏幕）
  static bool isTabletScreen(BuildContext context) {
    return screenWidth(context) >= 600 && screenWidth(context) < 1200;
  }

  /// 检查是否为桌面屏幕（大屏幕）
  static bool isDesktopScreen(BuildContext context) {
    return screenWidth(context) >= 1200;
  }

  /// 根据屏幕宽度获取响应式值
  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktopScreen(context) && desktop != null) {
      return desktop;
    } else if (isTabletScreen(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// 根据设计图尺寸计算实际尺寸（以宽度为基准）
  static double scaleWidth(BuildContext context, double size, {double designWidth = 375}) {
    return size * screenWidth(context) / designWidth;
  }

  /// 根据设计图尺寸计算实际尺寸（以高度为基准）
  static double scaleHeight(BuildContext context, double size, {double designHeight = 812}) {
    return size * availableHeight(context) / designHeight;
  }

  /// 根据设计图尺寸计算字体大小
  static double scaleFontSize(BuildContext context, double size, {double designWidth = 375}) {
    final scale = screenWidth(context) / designWidth;
    // 限制字体缩放范围，避免在大屏上字体过大
    return size * (scale > 1.5 ? 1.5 : (scale < 0.8 ? 0.8 : scale));
  }
}
