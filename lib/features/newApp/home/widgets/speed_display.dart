import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// 网速显示组件
class SpeedDisplay extends StatelessWidget {
  final double downloadSpeed;
  final double uploadSpeed;

  const SpeedDisplay({
    Key? key,
    required this.downloadSpeed,
    required this.uploadSpeed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 下载速度
          _buildSpeedItem(
            icon: NewAppAssets.homeDownloadIcon,
            label: 'Download',
            speed: downloadSpeed,
          ),

          // 分隔线
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withOpacity(0.2),
          ),

          // 上传速度
          _buildSpeedItem(
            icon: NewAppAssets.homeUploadIcon,
            label: 'Upload',
            speed: uploadSpeed,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedItem({
    required String icon,
    required String label,
    required double speed,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset(
              icon,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${speed.toStringAsFixed(2)} KB/s',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
