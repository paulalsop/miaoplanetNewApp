import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import '../core/routes/app_routes.dart';

/// 认证路由类
class AuthRoutes {
  /// 私有构造函数，防止实例化
  AuthRoutes._();

  /// 打开登录页面
  static Future<bool?> openLoginPage(BuildContext context) async {
    return await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const LoginPage(),
      ),
    );
  }

  /// 打开注册页面
  static Future<bool?> openRegisterPage(BuildContext context) async {
    return await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  /// 全局导航到登录页面
  ///
  /// 这个方法不需要context，可以在任何地方调用
  /// 它使用了全局导航方法，确保即使当前context已经被销毁也能导航到登录页面
  static void navigateToLoginPage() {
    try {
      // 使用一个延迟来确保当前的UI操作已经完成
      Future.delayed(const Duration(milliseconds: 300), () {
        // 直接创建一个新的页面实例，而不是依赖路由名称
        final navigatorState = NewAppRoutes.globalNavigatorKey.currentState;
        if (navigatorState != null) {
          debugPrint('找到了全局导航器，准备导航到登录页面');
          // 直接创建MaterialPageRoute，不使用路由名称
          navigatorState.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
              fullscreenDialog: true,
            ),
            (route) => false, // 清除所有路由
          );
        } else {
          debugPrint('全局导航器未初始化，尝试备用方案');
          // 备用方案：如果全局导航器未初始化，使用登录页面的静态方法打开
          _openLoginPageFallback();
        }
      });
    } catch (e) {
      debugPrint('导航到登录页面时出错: $e');
      // 发生错误时尝试备用方案
      _openLoginPageFallback();
    }
  }

  /// 打开登录页面的备用方案
  static void _openLoginPageFallback() {
    // 创建一个新的顶级导航器和一个登录页面
    runApp(MaterialApp(
      home: LoginPage(),
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
    ));
  }
}
