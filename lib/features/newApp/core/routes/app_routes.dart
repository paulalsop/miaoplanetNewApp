import 'package:flutter/material.dart';
import '../../auth/startup_page.dart';
import '../../home/screens/home_page.dart';
import '../../auth/screens/login_page.dart';
import '../../auth/screens/register_page.dart';
import '../../auth/screens/account_upgrade_page.dart';
import '../../invitation/screens/invitation_page.dart';

/// 新版应用的路由定义
class NewAppRoutes {
  // 私有构造函数，防止实例化
  NewAppRoutes._();

  /// 全局导航键，用于在任何地方进行导航
  static final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

  // 定义路由路径
  static const String startup = '/newApp/startup';
  static const String login = '/newApp/login';
  static const String register = '/newApp/register';
  static const String home = '/newApp/home';
  static const String menu = '/newApp/menu';
  static const String ordinaryMember = '/newApp/member/ordinary';
  static const String shareholderMember = '/newApp/member/shareholder';
  static const String selectNode = '/newApp/node/select';
  static const String nodeDetails = '/newApp/node/details';
  static const String invitationCode = '/newApp/invitation/code';
  static const String upgradeAccount = '/newApp/auth/upgrade';

  /// 注册所有路由
  static Map<String, WidgetBuilder> routes = {
    startup: (context) => const StartupPage(),
    home: (context) => const HomePage(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    invitationCode: (context) => const InvitationPage(),
    upgradeAccount: (context) => const AccountUpgradePage(),
    // 其他路由将在实现相应页面后添加
  };

  /// 路由配置
  static RouteSettings settings(String name, {Map<String, dynamic>? arguments}) {
    return RouteSettings(name: name, arguments: arguments);
  }

  /// 生成通用页面路由
  static Route<dynamic> _buildRoute(
    Widget page, {
    bool fullScreenDialog = false,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(
      builder: (context) => page,
      fullscreenDialog: fullScreenDialog,
      settings: settings,
    );
  }

  /// 生成带有淡入淡出动画的路由
  static Route<dynamic> _buildFadeRoute(
    Widget page, {
    bool fullScreenDialog = false,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var opacityAnimation = animation.drive(tween);

        return FadeTransition(opacity: opacityAnimation, child: child);
      },
      fullscreenDialog: fullScreenDialog,
      settings: settings,
    );
  }

  /// 生成带有滑动动画的路由
  static Route<dynamic> _buildSlideRoute(
    Widget page, {
    bool fullScreenDialog = false,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      fullscreenDialog: fullScreenDialog,
      settings: settings,
    );
  }

  /// 导航到指定页面
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Map<String, dynamic>? arguments}) {
    return Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// 替换当前页面
  static Future<T?> navigateReplace<T>(BuildContext context, String routeName, {Map<String, dynamic>? arguments}) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// 清除所有页面并导航到指定页面
  static Future<T?> navigateAndRemoveUntil<T>(BuildContext context, String routeName, {Map<String, dynamic>? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// 返回到前一个页面
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  /// 检查是否可以返回
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }

  /// 获取路由参数
  static T? getArguments<T>(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as T?;
  }
}
