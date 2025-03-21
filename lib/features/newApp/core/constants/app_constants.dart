/// 新版应用的常量定义
class NewAppConstants {
  // 私有构造函数，防止实例化
  NewAppConstants._();

  // 应用信息
  static const String appName = 'Hiddify';
  static const String appVersion = '2.0.0';

  // 动画时长
  static const Duration animationDurationShort = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // 图片资源路径
  static const String startupBgImage = 'assets/images/newPageMaterials/startupPage/bg_activate_bg.png';
  static const String startupWordImage = 'assets/images/newPageMaterials/startupPage/word_activate_word.png';

  // 登录相关
  static const int verificationCodeLength = 6;
  static const Duration resendCodeDuration = Duration(seconds: 60);

  // 连接状态
  static const Duration statusUpdateInterval = Duration(seconds: 2);

  // 缓存键
  static const String tokenCacheKey = 'new_app_auth_token';
  static const String userInfoCacheKey = 'new_app_user_info';
  static const String themeModeCacheKey = 'new_app_theme_mode';

  // API相关
  static const String apiBaseUrl = 'https://api.example.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // 正则表达式
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

  // 分页
  static const int defaultPageSize = 20;

  // 网络状态
  static const Duration networkRetryInterval = Duration(seconds: 5);
  static const int maxNetworkRetries = 3;
}
