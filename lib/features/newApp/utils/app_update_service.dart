import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../panel/xboard/services/http_service/auth_service.dart';
import '../core/constants/app_environment.dart';

/// 应用更新服务
///
/// 负责检查应用版本并处理更新流程
class AppUpdateService {
  final AuthService _authService = AuthService();

  /// 检查应用是否有新版本
  ///
  /// 返回检查结果，如果有更新则返回下载链接
  Future<AppUpdateCheckResult> checkForUpdate() async {
    try {
      // 确认当前是新版应用
      if (!AppEnvironment.isNewUIMode) {
        return AppUpdateCheckResult(hasUpdate: false);
      }

      // 获取当前应用版本信息
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);
      debugPrint('当前版本号: $currentVersionCode');

      // 获取服务器上的版本信息
      final response = await _authService.getAppVersion();
      debugPrint('服务器响应: $response');

      if (response['status'] != 'success') {
        return AppUpdateCheckResult(
          hasUpdate: false,
          errorMessage: response['message']?.toString() ?? '检查更新失败',
        );
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        return AppUpdateCheckResult(hasUpdate: false);
      }

      // 检查安卓版本
      final androidVersion = data['android_version']?.toString();
      final androidDownloadUrl = data['android_download_url']?.toString();

      if (androidVersion == null || androidDownloadUrl == null) {
        return AppUpdateCheckResult(hasUpdate: false);
      }

      // 解析服务器版本号
      final serverVersionCode = int.parse(androidVersion);
      debugPrint('服务器版本号: $serverVersionCode');

      // 比较版本号
      final hasUpdate = serverVersionCode > currentVersionCode;
      debugPrint('是否有更新: $hasUpdate');

      // 将服务器版本号转换为可读格式
      String formattedVersion = _formatVersionNumber(androidVersion);

      return AppUpdateCheckResult(
        hasUpdate: hasUpdate,
        downloadUrl: androidDownloadUrl,
        latestVersion: formattedVersion,
        currentVersion: _formatVersionNumber(packageInfo.buildNumber),
      );
    } catch (e) {
      debugPrint('检查更新时发生错误: $e');
      return AppUpdateCheckResult(
        hasUpdate: false,
        errorMessage: '检查更新时发生错误: $e',
      );
    }
  }

  /// 将数字版本号格式化为语义化版本号
  ///
  /// 例如：将 20507 转换为 2.5.7
  String _formatVersionNumber(String versionCode) {
    try {
      if (versionCode.length >= 5) {
        final major = versionCode.substring(0, 1);
        final minor =
            versionCode.substring(1, 3).replaceFirst(RegExp('^0+'), '');
        final patch =
            versionCode.substring(3, 5).replaceFirst(RegExp('^0+'), '');
        return '$major.$minor.$patch';
      }
      return versionCode;
    } catch (e) {
      return versionCode;
    }
  }

  /// 显示更新对话框
  void showUpdateDialog(BuildContext context, AppUpdateCheckResult result) {
    if (!result.hasUpdate) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.system_update, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Text('发现新版本'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('当前版本: ',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(result.currentVersion ?? '未知',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('最新版本: ',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(result.latestVersion ?? '未知',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '新版本带来更好的体验和功能，建议立即更新。',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl(result.downloadUrl!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 16),
                SizedBox(width: 6),
                Text('立即更新'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 打开下载链接
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 应用更新检查结果
class AppUpdateCheckResult {
  /// 是否有更新可用
  final bool hasUpdate;

  /// 下载链接
  final String? downloadUrl;

  /// 最新版本号
  final String? latestVersion;

  /// 当前版本号
  final String? currentVersion;

  /// 错误信息
  final String? errorMessage;

  AppUpdateCheckResult({
    required this.hasUpdate,
    this.downloadUrl,
    this.latestVersion,
    this.currentVersion,
    this.errorMessage,
  });
}
