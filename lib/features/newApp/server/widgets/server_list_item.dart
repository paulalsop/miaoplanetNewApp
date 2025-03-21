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
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${server.ping}ms',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
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

  /// 构建连接按钮
  Widget _buildConnectButton() {
    return GestureDetector(
      onTap: () => onConnect(server),
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          color: server.status == ServerStatus.connected ? const Color(0xFF13C23F) : Colors.black,
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
