# 侧边栏组件使用说明

本文档介绍了侧边栏组件的使用方法和注意事项。

## 组件结构

侧边栏组件包含以下文件：

- `widgets/side_menu.dart`: 侧边栏UI组件
- `services/side_menu_service.dart`: 侧边栏状态管理服务
- `screens/menu_demo_page.dart`: 侧边栏演示页面
- `../shared/layouts/app_scaffold.dart`: 集成侧边栏的应用脚手架

## 使用方法

### 1. 将页面包装在 AppScaffold 中

```dart
import 'package:flutter/material.dart';
import '../../shared/layouts/app_scaffold.dart';

class YourPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('页面标题'),
      ),
      userId: '用户ID', // 从用户服务中获取
      onLogout: () {
        // 处理退出登录逻辑
      },
      body: YourPageContent(),
    );
  }
}
```

### 2. 添加菜单按钮

在AppBar中添加菜单按钮：

```dart
AppBar(
  title: const Text('页面标题'),
  actions: [
    IconButton(
      icon: const Icon(Icons.menu),
      onPressed: SideMenuController.open, // 打开侧边栏
    ),
  ],
)
```

### 3. 控制侧边栏

可以在代码中使用以下方法控制侧边栏：

```dart
// 打开侧边栏
SideMenuController.open();

// 关闭侧边栏
SideMenuController.close();

// 切换侧边栏状态
SideMenuController.toggle();

// 获取侧边栏状态
bool isOpen = SideMenuController.isOpen;
```

## 自定义菜单项

如果需要自定义菜单项，可以修改 `side_menu.dart` 文件中的 `_initMenuItems` 方法。每个菜单项包含图标、标题和点击回调：

```dart
SideMenuItem(
  icon: NewAppAssets.menuInviteIcon, // 图标资源路径
  title: '菜单项标题',
  onTap: () {
    // 处理点击事件
    _handleMenuItemTap('菜单项标题');
  },
)
```

## 菜单项处理

当点击菜单项时，当前实现会先关闭侧边栏，然后执行点击回调。如需修改此行为，可以调整 `_handleMenuItemTap` 方法。

## 注意事项

1. 使用前需确保已在项目中添加了所有必要的图片资源。
2. 如果需要支持国际化，请修改菜单项的标题和其他文本内容。
3. 侧边栏的样式是基于设计规范实现的，如需修改，请调整对应的样式代码。
4. 侧边栏状态是全局管理的，无需在每个页面单独维护状态。

## 演示

要查看侧边栏的演示效果，可以导航到 `MenuDemoPage`：

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const MenuDemoPage()),
);
``` 