import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../providers/connection_provider.dart' as provider;

/// 服务器信息按钮
class ServerInfoButton extends StatelessWidget {
  final provider.ConnectionStatus status;
  final String serverName;
  final int pingValue;
  final VoidCallback onTap;

  const ServerInfoButton({
    Key? key,
    required this.status,
    required this.serverName,
    required this.pingValue,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据连接状态选择不同的背景和内容
    final bool isConnected = status == provider.ConnectionStatus.connected;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isConnected ? NewAppAssets.homeConnectedServerButtonBg : NewAppAssets.homeServerButtonBg),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Image.asset(
              isConnected ? NewAppAssets.homeConnectedServerPlanetIcon : NewAppAssets.homeServerPlanetIcon,
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isConnected
                  ? _buildConnectedContent()
                  : const Text(
                      'Select Server',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            Image.asset(
              isConnected ? NewAppAssets.homeConnectedServerMoreIcon : NewAppAssets.homeServerMoreIcon,
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  // 已连接状态下的内容
  Widget _buildConnectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          serverName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$pingValue ms',
          style: const TextStyle(
            color: Color(0xFF00FF85), // 绿色
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
