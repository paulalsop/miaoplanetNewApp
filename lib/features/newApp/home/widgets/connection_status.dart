import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../providers/connection_provider.dart' as provider;

/// 连接状态底部组件
class ConnectionStatus extends StatelessWidget {
  final provider.ConnectionStatus status;

  const ConnectionStatus({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 未连接状态显示"Tap to Connect"
    if (status == provider.ConnectionStatus.disconnected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            NewAppAssets.homeTapIcon,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Tap to Connect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // 已连接状态显示"Connected"（绿色文字）
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(NewAppAssets.homeConnectedStatusBg),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            NewAppAssets.homeConnectedStatusIcon,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Connected',
            style: TextStyle(
              color: Color(0xFF00FF85), // 绿色文字
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
