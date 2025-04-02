import 'package:flutter/material.dart';

/// 服务器状态
enum ServerStatus {
  /// 可用
  available,

  /// 不可用
  unavailable,

  /// 已连接
  connected,
}

/// 服务器模型
class ServerModel {
  /// 构造函数
  ServerModel({
    required this.id,
    required this.name,
    required this.ping,
    required this.status,
    this.isSelected = false,
  });

  /// 服务器ID
  final String id;

  /// 服务器名称
  final String name;

  /// 延迟值(毫秒)
  final int ping;

  /// 服务器状态
  final ServerStatus status;

  /// 是否被选中
  final bool isSelected;

  /// 创建一个此对象的副本，但更新了指定字段
  ServerModel copyWith({
    String? id,
    String? name,
    int? ping,
    ServerStatus? status,
    bool? isSelected,
  }) {
    return ServerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ping: ping ?? this.ping,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// 获取延迟显示文本
  String get pingText {
    if (ping == 0) {
      return "-"; // 未测试
    } else if (ping >= 65000) {
      return "×"; // 不可用，显示为"×"
    } else {
      return "${ping}ms"; // 显示具体延迟值
    }
  }

  /// 获取延迟的颜色
  Color getDelayColor(BuildContext context) {
    if (ping == 0) {
      return Colors.grey; // 未测试
    } else if (ping >= 65000) {
      return Colors.red; // 不可用
    } else if (ping < 800) {
      return const Color(0xFF13C23F); // 良好，使用绿色
    } else if (ping < 1500) {
      return Colors.orange; // 中等
    } else {
      return Colors.red; // 较差
    }
  }
}
