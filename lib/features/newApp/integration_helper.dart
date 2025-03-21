import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/newApp/core/preferences/new_ui_preferences.dart';
import 'package:hiddify/features/newApp/new_app.dart';
import 'package:hiddify/features/newApp/new_app_widget.dart';

/// 新界面集成辅助类
///
/// 提供方法和工具，帮助将新界面集成到现有应用中
class NewUIIntegrationHelper {
  /// 根据设置决定使用哪个应用界面
  ///
  /// 这个方法应该在应用启动时调用，根据用户设置决定使用新界面还是旧界面
  static Widget chooseAppWidget(Widget originalApp, WidgetRef ref) {
    final useNewUI = ref.watch(useNewUIProvider);

    if (useNewUI) {
      return const NewAppWidget();
    }

    return originalApp;
  }

  /// 创建一个新界面预览按钮
  ///
  /// 这个按钮可以添加到设置页面，用于快速预览新界面
  static Widget buildPreviewButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NewAppWidget(),
            fullscreenDialog: true,
          ),
        );
      },
      child: const Text('预览新界面'),
    );
  }

  /// 在应用初始化时调用的方法
  ///
  /// 用于初始化与新界面相关的设置和服务
  static Future<void> initialize() async {
    // 在这里可以添加新界面需要的初始化代码
    // 例如预加载资源、初始化服务等
  }
}
