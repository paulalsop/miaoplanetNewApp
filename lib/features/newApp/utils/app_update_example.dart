import 'package:flutter/material.dart';
import 'app_update_service.dart';

/// 这是一个示例，展示如何在应用启动时检查更新
class AppUpdateExample extends StatefulWidget {
  final Widget child;

  const AppUpdateExample({super.key, required this.child});

  @override
  State<AppUpdateExample> createState() => _AppUpdateExampleState();
}

class _AppUpdateExampleState extends State<AppUpdateExample> {
  final AppUpdateService _updateService = AppUpdateService();

  @override
  void initState() {
    super.initState();
    // 延迟检查更新，确保应用已完全启动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final result = await _updateService.checkForUpdate();

      if (result.hasUpdate && mounted) {
        _updateService.showUpdateDialog(context, result);
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 使用示例:
/// 
/// ```dart
/// void main() {
///   runApp(
///     AppUpdateExample(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
/// 
/// 或者在特定页面:
/// 
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return AppUpdateExample(
///     child: Scaffold(
///       // ...
///     ),
///   );
/// }
/// ``` 