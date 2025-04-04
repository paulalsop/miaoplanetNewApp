import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/newApp/new_app.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/environment.dart';

/// 新界面的主入口函数
void main() async {
  // 确保Flutter的Widgets绑定已初始化
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 设置系统UI样式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // 运行新版应用，直接在根ProviderScope中覆盖environmentProvider
  runApp(
    ProviderScope(
      overrides: [
        environmentProvider.overrideWithValue(Environment.dev),
      ],
      child: const NewApp(),
    ),
  );
}
