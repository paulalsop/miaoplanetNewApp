import 'package:flutter/material.dart';
import 'app_update_service.dart';
import '../core/constants/app_environment.dart';

/// 应用初始化辅助类
///
/// 提供应用启动时需要执行的初始化操作
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  final AppUpdateService _updateService = AppUpdateService();

  /// 在应用启动时初始化各项服务
  Future<void> initializeApp() async {
    // 可以在这里添加其他初始化操作
    // 例如：初始化日志、初始化数据库等
  }

  /// 检查应用更新
  ///
  /// 在合适的时机调用此方法
  Future<void> checkForUpdate(BuildContext context) async {
    // 只有新版界面模式才检查更新
    if (!AppEnvironment.isNewUIMode) return;

    try {
      final result = await _updateService.checkForUpdate();

      if (result.hasUpdate && context.mounted) {
        _updateService.showUpdateDialog(context, result);
      }
    } catch (e) {
      debugPrint('应用更新检查失败: $e');
    }
  }

  /// 在应用启动后适当延迟检查更新
  void scheduleUpdateCheck(BuildContext context) {
    // 使用Future.delayed直接延迟检查，不依赖于Frame回调
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        checkForUpdate(context);
      }
    });
  }

  /// 创建包装组件，方便在任何页面使用
  static Widget wrapWithUpdateChecker({required Widget child}) {
    return _AppUpdateWrapper(child: child);
  }
}

/// 应用更新检查包装组件
class _AppUpdateWrapper extends StatefulWidget {
  final Widget child;

  const _AppUpdateWrapper({required this.child});

  @override
  State<_AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends State<_AppUpdateWrapper> {
  @override
  void initState() {
    super.initState();
    // 在initState中直接调用scheduleUpdateCheck
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInitializer().scheduleUpdateCheck(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
