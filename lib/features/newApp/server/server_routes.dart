import 'package:flutter/material.dart';
import 'screens/server_selection_page.dart';
import 'models/server_model.dart';

/// 服务器路由类，提供与服务器相关的导航方法
class ServerRoutes {
  /// 私有构造函数，防止实例化
  ServerRoutes._();

  /// 打开服务器选择页面
  static Future<ServerModel?> openServerSelection(BuildContext context) async {
    return await showModalBottomSheet<ServerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const ServerSelectionPage(),
    );
  }

  /// 打开服务器选择页面（全屏模式）
  static Future<ServerModel?> openServerSelectionFullScreen(BuildContext context) async {
    return await Navigator.of(context).push<ServerModel>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ServerSelectionPage(
          onClose: () => Navigator.of(context).pop(),
          onServerSelected: (server) => Navigator.of(context).pop(server),
        ),
      ),
    );
  }
}
