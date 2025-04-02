import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/ticket_model.dart';

/// 工单详情页面
class TicketDetailPage extends StatefulWidget {
  final int ticketId;

  const TicketDetailPage({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isWaitingForReply = false;
  String _errorMessage = '';
  TicketDetail? _ticketDetail;

  // 定时器用于轮询获取最新消息
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();

    // 启动轮询
    _startPolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // 清除轮询定时器
    _pollingTimer?.cancel();

    super.dispose();
  }

  // 启动轮询
  void _startPolling() {
    // 每10秒轮询一次最新消息
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchTicketDetail(isPolling: true);
      }
    });
  }

  // 获取工单详情
  Future<void> _fetchTicketDetail({bool isPolling = false}) async {
    try {
      if (!isPolling) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final token = AuthService.instance.token;
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '获取授权令牌失败，请重新登录';
        });
        return;
      }

      final result =
          await _userService.fetchTicketDetail(widget.ticketId, token);

      if (result['success'] == true) {
        final ticketDetailData =
            result['ticketDetail'] as Map<String, dynamic>?;

        if (ticketDetailData != null) {
          setState(() {
            _ticketDetail = TicketDetail.fromJson(ticketDetailData);
            _isLoading = false;
            // 检查是否在等待管理员回复
            _isWaitingForReply = _ticketDetail!.replyStatus == 1;
          });

          // 如果不是首次加载，检查是否有新消息，如果有则滚动到底部
          if (!isPolling ||
              (_ticketDetail != null && _ticketDetail!.messages.isNotEmpty)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = '工单数据格式错误';
          });
        }
      } else {
        if (!isPolling) {
          setState(() {
            _isLoading = false;
            _errorMessage = result['message'] as String? ?? '获取工单详情失败';
          });
        }
      }
    } catch (e) {
      if (!isPolling) {
        setState(() {
          _isLoading = false;
          _errorMessage = '获取工单详情出错: $e';
        });
      }
    }
  }

  // 发送回复消息
  Future<void> _sendReply() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入回复内容'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSending = true;
      });

      final token = AuthService.instance.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('获取授权令牌失败，请重新登录'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _isSending = false;
        });
        return;
      }

      final result = await _userService.replyTicket(
        widget.ticketId,
        message,
        token,
      );

      setState(() {
        _isSending = false;
      });

      if (result['success'] == true) {
        // 清空输入框
        _messageController.clear();

        // 刷新工单详情
        await _fetchTicketDetail();

        // 用户回复后，工单状态应该更新为等待回复
        setState(() {
          _isWaitingForReply = true;
        });
      } else {
        if (context.mounted) {
          String errorMsg = result['message'] as String? ?? '发送回复失败';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMsg)),
                ],
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('发送回复出错: $e')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticketDetail?.subject ?? '工单详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _fetchTicketDetail(),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // 构建页面主体
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchTicketDetail(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_ticketDetail == null) {
      return const Center(
        child: Text('未找到工单信息'),
      );
    }

    return Column(
      children: [
        // 工单信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '工单号: #${_ticketDetail!.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(_ticketDetail!.level),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _ticketDetail!.getLevelText(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '创建: ${_ticketDetail!.getFormattedCreatedAt()}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.update, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '更新: ${_ticketDetail!.getFormattedUpdatedAt()}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _ticketDetail!.status == 0
                            ? Colors.blue
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _ticketDetail!.getStatusText(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _isWaitingForReply ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isWaitingForReply ? '等待回复' : '可以回复',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 消息列表
        Expanded(
          child: _ticketDetail!.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        '暂无消息记录',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _ticketDetail!.messages.length,
                  itemBuilder: (context, index) {
                    final message = _ticketDetail!.messages[index];
                    return _buildMessageItem(message);
                  },
                ),
        ),

        // 等待管理员回复的提示条
        if (_isWaitingForReply && _ticketDetail!.status == 0)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.hourglass_empty,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '等待客服回复，请耐心等待...',
                    style:
                        TextStyle(color: Colors.orange.shade800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

        // 输入区域
        if (_ticketDetail!.status == 0) // 只有未关闭的工单才能回复
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText:
                            _isWaitingForReply ? '等待客服回复中...' : '输入内容回复工单',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        hintStyle: TextStyle(
                          color: _isWaitingForReply
                              ? Colors.orange.shade300
                              : Colors.grey,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      enabled: !_isSending && !_isWaitingForReply,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed:
                        (_isSending || _isWaitingForReply) ? null : _sendReply,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: _isWaitingForReply
                          ? Colors.orange.shade200
                          : Colors.grey.shade300,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isWaitingForReply
                                ? Icons.hourglass_empty
                                : Icons.send,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 构建消息项
  Widget _buildMessageItem(TicketMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 16,
                child: Icon(Icons.support_agent, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isMe
                        ? Colors.blue.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: message.isMe
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.blue.shade800
                          : Colors.grey.shade800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    message.getFormattedCreatedAt(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.green,
                radius: 16,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 根据工单级别获取颜色
  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
