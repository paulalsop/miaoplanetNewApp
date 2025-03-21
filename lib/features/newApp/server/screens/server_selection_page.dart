import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/server_model.dart';
import '../widgets/server_banner.dart';
import '../widgets/server_list_item.dart';
import '../widgets/server_pagination.dart';

/// 服务器选择页面
class ServerSelectionPage extends StatefulWidget {
  /// 构造函数
  const ServerSelectionPage({
    super.key,
    this.onServerSelected,
    this.onClose,
  });

  /// 服务器选择回调
  final ValueChanged<ServerModel>? onServerSelected;

  /// 关闭页面回调
  final VoidCallback? onClose;

  @override
  State<ServerSelectionPage> createState() => _ServerSelectionPageState();
}

class _ServerSelectionPageState extends State<ServerSelectionPage> {
  /// 当前页码
  int _currentPage = 1;

  /// 总页数
  final int _totalPages = 5;

  /// 每页显示的服务器数量
  final int _serversPerPage = 8;

  /// 模拟的服务器列表
  final List<ServerModel> _allServers = List.generate(
    40,
    (index) => ServerModel(
      id: 'server_$index',
      name: 'United States',
      ping: 167,
      status: index == 0 ? ServerStatus.connected : ServerStatus.available,
    ),
  );

  /// 当前页面显示的服务器列表
  List<ServerModel> get _currentPageServers {
    final startIndex = (_currentPage - 1) * _serversPerPage;
    final endIndex = startIndex + _serversPerPage;
    return _allServers.sublist(
      startIndex,
      endIndex < _allServers.length ? endIndex : _allServers.length,
    );
  }

  /// 处理页面变化
  void _handlePageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  /// 处理服务器连接
  void _handleServerConnect(ServerModel server) {
    // 更新服务器状态
    setState(() {
      for (int i = 0; i < _allServers.length; i++) {
        if (_allServers[i].id == server.id) {
          _allServers[i] = _allServers[i].copyWith(
            status: ServerStatus.connected,
          );
        } else if (_allServers[i].status == ServerStatus.connected) {
          _allServers[i] = _allServers[i].copyWith(
            status: ServerStatus.available,
          );
        }
      }
    });

    // 回调通知
    if (widget.onServerSelected != null) {
      widget.onServerSelected!(server);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.serverBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 标题栏
              _buildAppBar(),

              // 套餐卡片
              const ServerBanner(),

              // 服务器列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: _currentPageServers.length,
                  itemBuilder: (context, index) {
                    return ServerListItem(
                      server: _currentPageServers[index],
                      onConnect: _handleServerConnect,
                    );
                  },
                ),
              ),

              // 分页控件
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: ServerPagination(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageChanged: _handlePageChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建应用栏
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'SERVER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                NewAppAssets.serverCloseIcon,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
