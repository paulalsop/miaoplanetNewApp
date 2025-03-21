import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/theme_provider.dart';
import 'auth/startup_page.dart';
import 'menu/services/side_menu_service.dart';
import 'shared/layouts/app_scaffold.dart';

/// 新版应用入口
class NewApp extends ConsumerWidget {
  const NewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前主题
    final themeMode = ref.watch(themeProviderNotifier);
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: '新版Hiddify',
      theme: theme,
      darkTheme: theme, // 这里应该使用暗色主题，暂时使用相同主题
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      navigatorKey: NewAppRoutes.globalNavigatorKey, // 设置全局导航键
      initialRoute: NewAppRoutes.startup,
      routes: NewAppRoutes.routes,
      onGenerateRoute: (settings) {
        // 处理未定义的路由
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('页面未找到'),
            ),
          ),
        );
      },
    );
  }
}
