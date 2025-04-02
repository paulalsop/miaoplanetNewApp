import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/ticket_model.dart';
import 'ticket_detail_page.dart';

/// 工单列表页面
class TicketListPage extends StatefulWidget {
  const TicketListPage({Key? key}) : super(key: key);

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  String _errorMessage = '';
  List<Ticket> _tickets = [];

  // 创建工单相关变量
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  int _selectedLevel = 1; // 默认中等级别
  bool _isCreatingTicket = false;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 获取工单列表
  Future<void> _fetchTickets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final token = AuthService.instance.token;
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '获取授权令牌失败，请重新登录';
        });
        return;
      }

      final result = await _userService.fetchTickets(token);

      if (result['success'] == true) {
        final ticketsData = result['tickets'] as List<dynamic>?;

        setState(() {
          _tickets = ticketsData != null
              ? ticketsData
                  .map((item) => Ticket.fromJson(item as Map<String, dynamic>))
                  .toList()
              : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] as String? ?? '获取工单列表失败';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '获取工单列表出错: $e';
      });
    }
  }

  // 创建新工单
  Future<void> _createTicket() async {
    // 表单验证
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入工单主题'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入问题描述'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isCreatingTicket = true;
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
          _isCreatingTicket = false;
        });
        return;
      }

      final result = await _userService.createTicket(
        _subjectController.text.trim(),
        _selectedLevel,
        _messageController.text.trim(),
        token,
      );

      setState(() {
        _isCreatingTicket = false;
      });

      if (result['success'] == true) {
        // 关闭新建工单对话框
        if (context.mounted) {
          Navigator.pop(context);

          // 显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('工单创建成功'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );

          // 刷新工单列表
          _fetchTickets();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(result['message'] as String? ?? '创建工单失败')),
                ],
              ),
              backgroundColor: Colors.redAccent,
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
                Expanded(child: Text('创建工单出错: $e')),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

      setState(() {
        _isCreatingTicket = false;
      });
    }
  }

  // 显示工单详情页面
  void _showTicketDetail(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailPage(ticketId: ticket.id),
      ),
    ).then((_) {
      // 返回后刷新工单列表
      _fetchTickets();
    });
  }

  // 显示创建工单对话框
  void _showCreateTicketDialog() {
    // 重置控制器和选择状态
    _subjectController.clear();
    _messageController.clear();
    _selectedLevel = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.support_agent, size: 24, color: Colors.blue),
              SizedBox(width: 8),
              Text('新的工单'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主题输入
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: '主题',
                    hintText: '请输入工单主题',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  maxLength: 100,
                  enabled: !_isCreatingTicket,
                ),
                const SizedBox(height: 16),

                // 工单级别选择
                const Text('工单级别'),
                DropdownButtonFormField<int>(
                  value: _selectedLevel,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text('低'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text('中'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text('高'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: _isCreatingTicket
                      ? null
                      : (value) {
                          if (value != null) {
                            setDialogState(() {
                              _selectedLevel = value;
                            });
                          }
                        },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),

                // 消息内容
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: '问题描述',
                    hintText: '请详细描述您遇到的问题',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                  enabled: !_isCreatingTicket,
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed:
                  _isCreatingTicket ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('取消'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
            ElevatedButton.icon(
              onPressed: _isCreatingTicket ? null : _createTicket,
              icon: _isCreatingTicket
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('确认'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工单历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchTickets,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTicketDialog,
        backgroundColor: Colors.blue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: '新的工单',
      ),
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
              onPressed: _fetchTickets,
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

    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '暂无工单记录',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮创建新工单',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateTicketDialog,
              icon: const Icon(Icons.add),
              label: const Text('创建工单'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.separated(
        itemCount: _tickets.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showTicketDetail(ticket),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                _getLevelColor(ticket.level).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.support_agent,
                              color: _getLevelColor(ticket.level),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.subject,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '工单 #${ticket.id} • ${ticket.getFormattedCreatedAt()}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getLevelColor(ticket.level),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ticket.getLevelText(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ticket.status == 0
                                    ? Colors.blue
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ticket.getStatusText(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (ticket.replyStatus == 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.hourglass_empty,
                                      color: Colors.orange.shade800, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '等待回复',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
