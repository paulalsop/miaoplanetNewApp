import 'package:flutter/material.dart';
import '../../shared/layouts/app_scaffold.dart';
import '../services/side_menu_service.dart';

/// 菜单演示页面
class MenuDemoPage extends StatefulWidget {
  const MenuDemoPage({super.key});

  @override
  State<MenuDemoPage> createState() => _MenuDemoPageState();
}

class _MenuDemoPageState extends State<MenuDemoPage> {
  // 模拟的用户ID
  final String _userId = "123456789";

  // 退出登录
  void _handleLogout() {
    // 实际应用中，这里应该处理退出登录的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出登录')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('菜单演示'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: SideMenuController.toggle,
          ),
        ],
      ),
      userId: _userId,
      onLogout: _handleLogout,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '菜单演示页面',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: SideMenuController.open,
              child: const Text('打开侧边栏'),
            ),
          ],
        ),
      ),
    );
  }
}
