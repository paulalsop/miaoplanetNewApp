// 工单模型类
class Ticket {
  final int id;
  final int level;
  final int replyStatus;
  final int status;
  final String subject;
  final int createdAt;
  final int updatedAt;
  final int userId;

  Ticket({
    required this.id,
    required this.level,
    required this.replyStatus,
    required this.status,
    required this.subject,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      level: json['level'] as int,
      replyStatus: json['reply_status'] as int,
      status: json['status'] as int,
      subject: json['subject'] as String? ?? '',
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
      userId: json['user_id'] as int,
    );
  }

  // 获取工单优先级文本
  String getLevelText() {
    switch (level) {
      case 0:
        return '低';
      case 1:
        return '中';
      case 2:
        return '高';
      default:
        return '未知';
    }
  }

  // 获取工单状态文本
  String getStatusText() {
    return status == 0 ? '待回复' : '已关闭';
  }

  // 获取创建时间格式化字符串
  String getFormattedCreatedAt() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
  }

  // 获取更新时间格式化字符串
  String getFormattedUpdatedAt() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000);
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
  }

  // 数字补零
  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }
}

// 工单消息模型类
class TicketMessage {
  final int id;
  final int ticketId;
  final bool isMe;
  final String message;
  final int createdAt;
  final int updatedAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.isMe,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int,
      ticketId: json['ticket_id'] as int,
      isMe: json['is_me'] as bool,
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
    );
  }

  // 获取创建时间格式化字符串
  String getFormattedCreatedAt() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
  }

  // 数字补零
  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }
}

// 工单详情模型类，包含工单基本信息和消息列表
class TicketDetail {
  final int id;
  final int level;
  final int replyStatus;
  final int status;
  final String subject;
  final List<TicketMessage> messages;
  final int createdAt;
  final int updatedAt;
  final int userId;

  TicketDetail({
    required this.id,
    required this.level,
    required this.replyStatus,
    required this.status,
    required this.subject,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    // 处理消息列表
    final List<TicketMessage> messagesList = [];
    if (json['message'] != null && json['message'] is List) {
      for (var messageJson in (json['message'] as List)) {
        messagesList
            .add(TicketMessage.fromJson(messageJson as Map<String, dynamic>));
      }
    }

    return TicketDetail(
      id: json['id'] as int,
      level: json['level'] as int,
      replyStatus: json['reply_status'] as int,
      status: json['status'] as int,
      subject: json['subject'] as String? ?? '',
      messages: messagesList,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
      userId: json['user_id'] as int,
    );
  }

  // 获取工单优先级文本
  String getLevelText() {
    switch (level) {
      case 0:
        return '低';
      case 1:
        return '中';
      case 2:
        return '高';
      default:
        return '未知';
    }
  }

  // 获取工单状态文本
  String getStatusText() {
    return status == 0 ? '待回复' : '已关闭';
  }

  // 获取创建时间格式化字符串
  String getFormattedCreatedAt() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
  }

  // 获取更新时间格式化字符串
  String getFormattedUpdatedAt() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000);
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
  }

  // 数字补零
  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }
}
