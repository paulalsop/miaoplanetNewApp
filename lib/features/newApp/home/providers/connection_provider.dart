import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 连接状态枚举
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

/// 连接数据模型
class ConnectionData {
  final ConnectionStatus status;
  final Duration connectedDuration;
  final double downloadSpeed; // KB/s
  final double uploadSpeed; // KB/s
  final String serverName;
  final int pingValue; // ms

  const ConnectionData({
    this.status = ConnectionStatus.disconnected,
    this.connectedDuration = Duration.zero,
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.serverName = '',
    this.pingValue = 0,
  });

  ConnectionData copyWith({
    ConnectionStatus? status,
    Duration? connectedDuration,
    double? downloadSpeed,
    double? uploadSpeed,
    String? serverName,
    int? pingValue,
  }) {
    return ConnectionData(
      status: status ?? this.status,
      connectedDuration: connectedDuration ?? this.connectedDuration,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      serverName: serverName ?? this.serverName,
      pingValue: pingValue ?? this.pingValue,
    );
  }

  /// 获取连接时间的格式化字符串 (HH:MM:SS)
  String get formattedDuration {
    final hours = connectedDuration.inHours.toString().padLeft(2, '0');
    final minutes = (connectedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (connectedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// 连接状态提供者
class ConnectionNotifier extends StateNotifier<ConnectionData> {
  ConnectionNotifier() : super(const ConnectionData()) {
    _initializeTimers();
  }

  Timer? _durationTimer;
  Timer? _speedUpdateTimer;

  void _initializeTimers() {
    // 每秒更新一次连接时间
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == ConnectionStatus.connected) {
        state = state.copyWith(
          connectedDuration: state.connectedDuration + const Duration(seconds: 1),
        );
      }
    });

    // 每2秒更新一次网速（模拟）
    _speedUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state.status == ConnectionStatus.connected) {
        // 模拟网速波动
        final newDownloadSpeed = (100 + (150 * _generateRandomValue())).toDouble();
        final newUploadSpeed = (350 + (100 * _generateRandomValue())).toDouble();

        state = state.copyWith(
          downloadSpeed: newDownloadSpeed,
          uploadSpeed: newUploadSpeed,
        );
      }
    });
  }

  // 生成-1.0到1.0之间的随机值，用于模拟网速波动
  double _generateRandomValue() {
    return (DateTime.now().millisecondsSinceEpoch % 200) / 100 - 1.0;
  }

  /// 连接到服务器
  Future<void> connect() async {
    // 先设置为连接中状态
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      serverName: 'United Kingdom',
      pingValue: 225,
    );

    // 模拟连接延迟
    await Future.delayed(const Duration(seconds: 2));

    // 设置为已连接状态
    state = state.copyWith(
      status: ConnectionStatus.connected,
      connectedDuration: Duration.zero,
      downloadSpeed: 137.89,
      uploadSpeed: 368.8,
    );
  }

  /// 断开连接
  Future<void> disconnect() async {
    // 模拟断开延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 重置状态
    state = const ConnectionData();
  }

  /// 设置选中的服务器
  void setSelectedServer({required String name, required int pingValue}) {
    state = state.copyWith(
      serverName: name,
      pingValue: pingValue,
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _speedUpdateTimer?.cancel();
    super.dispose();
  }
}

/// 全局连接状态提供者
final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionData>((ref) {
  return ConnectionNotifier();
});
