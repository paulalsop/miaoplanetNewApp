import 'package:flutter/material.dart';
import '../../auth/screens/login_page.dart';
import '../../home/screens/home_page.dart';

class NewAppRoutes {
  // 路由名称
  static const String home = '/home';
  static const String login = '/login';

  // 导航方法
  static void navigateTo(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  static void navigateAndRemoveUntil(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false, arguments: arguments);
  }

  // 路由表
  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    login: (context) => const LoginPage(),
  };
}
