/// 应用环境变量
class AppEnvironment {
  // 私有构造函数，防止实例化
  AppEnvironment._();

  /// 表示当前是否运行在新界面模式
  static const bool isNewUIMode = true;

  /// 应用版本标识
  static const String versionSuffix = 'New-UI';

  /// 应用数据存储前缀
  ///
  /// 用于区分新旧界面的数据存储，避免冲突
  static const String storagePrefix = 'new_ui_';
}
