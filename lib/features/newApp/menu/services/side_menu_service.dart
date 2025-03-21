import 'package:flutter/material.dart';

/// 侧边栏状态监听器
typedef SideMenuStateListener = void Function(bool isOpen);

/// 侧边栏服务，用于管理侧边栏的状态
class SideMenuService {
  // 私有构造函数
  SideMenuService._();

  // 单例实例
  static final SideMenuService _instance = SideMenuService._();

  // 获取单例实例
  static SideMenuService get instance => _instance;

  // 侧边栏状态
  bool _isOpen = false;

  // 状态监听器列表
  final List<SideMenuStateListener> _listeners = [];

  // 获取侧边栏状态
  bool get isOpen => _isOpen;

  // 打开侧边栏
  void openSideMenu() {
    if (!_isOpen) {
      _isOpen = true;
      _notifyListeners();
    }
  }

  // 关闭侧边栏
  void closeSideMenu() {
    if (_isOpen) {
      _isOpen = false;
      _notifyListeners();

      // 确保UI在下一帧更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 这里不需要额外操作，因为AppScaffold会根据_isOpen值
        // 自动从组件树中移除SideMenu组件
      });
    }
  }

  // 切换侧边栏状态
  void toggleSideMenu() {
    _isOpen = !_isOpen;
    _notifyListeners();
  }

  // 添加状态监听器
  void addListener(SideMenuStateListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  // 移除状态监听器
  void removeListener(SideMenuStateListener listener) {
    _listeners.remove(listener);
  }

  // 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_isOpen);
    }
  }
}

/// 侧边栏控制器，用于在UI中控制侧边栏
class SideMenuController {
  // 打开侧边栏
  static void open() {
    SideMenuService.instance.openSideMenu();
  }

  // 关闭侧边栏
  static void close() {
    SideMenuService.instance.closeSideMenu();
  }

  // 切换侧边栏状态
  static void toggle() {
    SideMenuService.instance.toggleSideMenu();
  }

  // 获取侧边栏状态
  static bool get isOpen => SideMenuService.instance.isOpen;
}
