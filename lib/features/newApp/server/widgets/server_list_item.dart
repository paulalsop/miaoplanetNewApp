import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/server_model.dart';

/// 服务器列表项组件
class ServerListItem extends StatelessWidget {
  /// 构造函数
  const ServerListItem({
    super.key,
    required this.server,
    required this.onConnect,
  });

  /// 服务器数据
  final ServerModel server;

  /// 连接回调
  final ValueChanged<ServerModel> onConnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.serverCard),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // 服务器名称
              Expanded(
                child: Text(
                  server.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // 服务器延迟信息
              Row(
                children: [
                  Image.asset(
                    NewAppAssets.serverSignalIcon,
                    width: 20,
                    height: 20,
                    color: _getSignalIconColor(),
                  ),
                  const SizedBox(width: 4),
                  _buildDelayText(context),
                ],
              ),

              const SizedBox(width: 20),

              // 连接按钮
              _buildConnectButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建延迟文本组件
  Widget _buildDelayText(BuildContext context) {
    // 不可用或未测试时显示特殊文本
    if (server.ping >= 65000) {
      return const Text(
        "×", // 不可用，显示为"×"
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (server.ping == 0) {
      return const Text(
        "-", // 未测试
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      );
    } else {
      // 正常显示延迟数值
      return Text(
        "${server.ping}ms",
        style: TextStyle(
          color: server.getDelayColor(context),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  /// 获取信号图标的颜色
  Color _getSignalIconColor() {
    // 优先根据服务器状态判断
    if (server.status == ServerStatus.unavailable) {
      return Colors.red; // 不可用
    } else if (server.status == ServerStatus.connected) {
      return const Color(0xFF13C23F); // 已连接，使用绿色
    }

    // 其次根据延迟值判断
    if (server.ping >= 65000) {
      return Colors.red; // 超时
    } else if (server.ping == 0) {
      return Colors.white.withOpacity(0.6); // 未测试，使用半透明白色
    } else if (server.ping < 800) {
      return const Color(0xFF13C23F); // 良好，使用绿色
    } else if (server.ping < 1500) {
      return Colors.orange; // 中等
    } else {
      return Colors.red; // 较差
    }
  }

  /// 构建连接按钮
  Widget _buildConnectButton() {
    return GestureDetector(
      onTap: () => onConnect(server),
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          color: server.status == ServerStatus.connected
              ? const Color(0xFF13C23F)
              : Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          server.status == ServerStatus.connected ? 'Success' : 'Connect',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
