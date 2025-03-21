import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/newApp/new_app_widget.dart';

/// 路由集成
///
/// 这个文件用于将新界面的路由集成到现有的路由系统中
class NewAppRouteIntegration {
  static const String newAppPath = '/new-ui';
  static const String newAppName = 'NewApp';

  /// 获取用于集成的路由
  static RouteBase getRoute() {
    return GoRoute(
      path: newAppPath,
      name: newAppName,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        name: newAppName,
        child: NewAppWidget(),
      ),
    );
  }

  /// 导航到新界面
  static void navigateToNewApp(BuildContext context) {
    GoRouter.of(context).pushNamed(newAppName);
  }

  /// 创建一个按钮，用于导航到新界面
  static Widget buildNavigationButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => navigateToNewApp(context),
      child: const Text('使用新界面'),
    );
  }
}
