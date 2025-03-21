import 'package:flutter/foundation.dart';
import '../core/constants/app_environment.dart';

/// 应用版本工具类
///
/// 提供版本信息和功能检测相关的方法
class AppVersionUtils {
  // 私有构造函数，防止实例化
  AppVersionUtils._();

  /// 检查当前是否运行在新界面模式
  static bool get isNewUIMode => AppEnvironment.isNewUIMode;

  /// 获取应用版本标识
  static String get versionSuffix => AppEnvironment.versionSuffix;

  /// 检查当前是否为调试模式
  static bool get isDebugMode => kDebugMode;

  /// 获取完整的应用版本
  static String getFullVersion(String baseVersion) {
    if (isNewUIMode) {
      return '$baseVersion-${AppEnvironment.versionSuffix}';
    }
    return baseVersion;
  }

  /// 获取应用数据存储键
  ///
  /// 根据界面模式自动添加前缀，避免数据冲突
  static String getStorageKey(String key) {
    if (isNewUIMode) {
      return '${AppEnvironment.storagePrefix}$key';
    }
    return key;
  }
}
