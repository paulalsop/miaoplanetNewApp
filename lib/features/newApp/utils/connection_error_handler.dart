import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';

/// 连接错误处理工具类
class ConnectionErrorHandler {
  /// 私有构造函数
  ConnectionErrorHandler._();
  
  /// 公共方法：提供友好的错误消息
  static String getErrorMessage(Object error) {
    if (error is ProfileFailure) {
      return _getProfileErrorMessage(error);
    } else if (error is ConnectionFailure) {
      return _getConnectionErrorMessage(error);
    } else if (error is TimeoutException) {
      return '连接超时，请检查网络连接';
    } else {
      return '连接出错: $error';
    }
  }
  
  /// 处理配置相关错误
  static String _getProfileErrorMessage(ProfileFailure error) {
    return switch (error) {
      ProfileInvalidUrlFailure() => '订阅链接无效',
      ProfileInvalidConfigFailure(:final message) => '配置无效: ${message ?? "未知原因"}',
      ProfileNotFoundFailure() => '找不到配置文件',
      ProfileUnexpectedFailure(:final error) => '配置处理出错: $error',
    };
  }
  
  /// 处理连接相关错误
  static String _getConnectionErrorMessage(ConnectionFailure error) {
    return switch (error) {
      InvalidConfig(:final message) => '配置无效: ${message ?? "未知原因"}',
      MissingVpnPermission() => '缺少VPN权限，请授权后重试',
      MissingNotificationPermission() => '缺少通知权限，请授权后重试',
      MissingPrivilege() => '缺少特权模式权限，请授权后重试',
      MissingGeoAssets() => '缺少地理位置资源文件',
      InvalidConfigOption(:final message) => '配置选项无效: ${message ?? "未知原因"}',
      UnexpectedConnectionFailure(:final error) => '连接出错: $error',
    };
  }
  
  /// 公共方法：显示错误提示对话框
  static void showErrorDialog(BuildContext context, Object error) {
    final message = getErrorMessage(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 公共方法：显示错误提示Toast
  static void showErrorToast(BuildContext context, Object error) {
    final message = getErrorMessage(error);
    // 这里可以实现Toast显示，或者使用现有的Toast库
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
} 