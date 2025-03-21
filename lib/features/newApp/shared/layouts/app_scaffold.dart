import 'package:flutter/material.dart';
import '../../menu/widgets/side_menu.dart';
import '../../menu/services/side_menu_service.dart';
import '../../auth/auth_routes.dart';

/// 应用脚手架，集成侧边栏功能
class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.userId = '',
    this.onLogout,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
  });

  /// 主体内容
  final Widget body;

  /// 应用栏
  final PreferredSizeWidget? appBar;

  /// 用户ID，用于侧边栏显示
  final String userId;

  /// 退出登录回调
  final VoidCallback? onLogout;

  /// 背景颜色
  final Color? backgroundColor;

  /// 是否调整大小以避免底部插入
  final bool resizeToAvoidBottomInset;

  /// 是否将主体内容扩展到应用栏后面
  final bool extendBodyBehindAppBar;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  /// 侧边栏是否打开
  bool _isSideMenuOpen = false;

  @override
  void initState() {
    super.initState();

    // 初始状态
    _isSideMenuOpen = SideMenuService.instance.isOpen;

    // 添加状态监听
    SideMenuService.instance.addListener(_handleSideMenuStateChanged);
  }

  @override
  void dispose() {
    // 移除状态监听
    SideMenuService.instance.removeListener(_handleSideMenuStateChanged);
    super.dispose();
  }

  /// 处理侧边栏状态变化
  void _handleSideMenuStateChanged(bool isOpen) {
    setState(() {
      _isSideMenuOpen = isOpen;
    });
  }

  /// 关闭侧边栏
  void _closeSideMenu() {
    SideMenuService.instance.closeSideMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      backgroundColor: widget.backgroundColor,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      body: Stack(
        children: [
          // 主体内容
          widget.body,

          // 侧边栏 - 仅当打开时才添加到组件树
          if (_isSideMenuOpen)
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: SideMenu(
                isOpen: true, // 固定为true，因为我们只在打开时才添加组件
                onClose: _closeSideMenu,
                userId: widget.userId,
                onLogout: widget.onLogout ?? _defaultLogout, // 使用提供的回调或默认回调
              ),
            ),
        ],
      ),
    );
  }

  /// 默认的退出登录处理
  void _defaultLogout() {
    // 使用AuthRoutes中的全局导航方法，不依赖于当前context
    AuthRoutes.navigateToLoginPage();
  }
}
