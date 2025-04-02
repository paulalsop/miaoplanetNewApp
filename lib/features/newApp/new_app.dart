import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/theme_provider.dart';
import 'auth/startup_page.dart';
import 'menu/services/side_menu_service.dart';
import 'shared/layouts/app_scaffold.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/environment.dart';

/// 新版应用入口
class NewApp extends ConsumerWidget {
  const NewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前主题
    final themeMode = ref.watch(themeProviderNotifier);
    final theme = ref.watch(themeProvider);

    // 确保环境提供者已被覆盖
    try {
      final env = ref.read(environmentProvider);
      debugPrint("当前环境: ${env.name}");
    } catch (e) {
      debugPrint("环境提供者错误: $e");
      // 当环境提供者未被覆盖时，显示错误界面
      return MaterialApp(
        title: 'Miao Planet - 错误',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '应用初始化失败',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('错误详情: $e', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Miao Planet',
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
