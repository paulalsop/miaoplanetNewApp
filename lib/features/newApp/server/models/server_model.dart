/// 服务器信息模型类
class ServerModel {
  /// 服务器ID
  final String id;

  /// 服务器名称
  final String name;

  /// 服务器延迟(毫秒)
  final int ping;

  /// 服务器状态
  final ServerStatus status;

  /// 是否为当前选中的服务器
  final bool isSelected;

  /// 构造函数
  ServerModel({
    required this.id,
    required this.name,
    required this.ping,
    this.status = ServerStatus.available,
    this.isSelected = false,
  });

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
}

/// 服务器状态枚举
enum ServerStatus {
  /// 可用
  available,

  /// 已连接
  connected,

  /// 不可用
  unavailable,
}
