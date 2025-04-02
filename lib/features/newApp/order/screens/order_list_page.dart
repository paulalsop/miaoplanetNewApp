import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/app_assets.dart';
import 'order_detail_page.dart';
import '../models/order_status.dart';
import '../../../panel/xboard/services/http_service/order_service.dart';
import '../../../panel/xboard/utils/storage/token_storage.dart';
import '../../../panel/xboard/models/order_model.dart';
import '../../../panel/xboard/providers/config_provider.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await ref.read(configProvider.notifier).loadConfig();
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);

      final token = await getToken();
      if (token == null) {
        setState(() {
          _error = "请先登录";
          _isLoading = false;
        });
        return;
      }

      final orders = await _orderService.fetchUserOrders(token);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "加载失败: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '待支付';
      case 2:
        return '已取消';
      case 3:
        return '已完成';
      default:
        return '未知状态';
    }
  }

  OrderDetailStatus _getOrderDetailStatus(int status) {
    switch (status) {
      case 0:
        return OrderDetailStatus.pending;
      case 2:
        return OrderDetailStatus.cancelled;
      case 3:
        return OrderDetailStatus.completed;
      default:
        return OrderDetailStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(NewAppAssets.orderListPrefix + 'bg_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '订单列表',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            tabs: const [
              Tab(text: '全部'),
              Tab(text: '待支付'),
              Tab(text: '已完成'),
              Tab(text: '已取消'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.white)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(),
                      _buildOrderList(status: 0),
                      _buildOrderList(status: 3),
                      _buildOrderList(status: 2),
                    ],
                  ),
      ),
    );
  }

  Widget _buildOrderList({int? status}) {
    final filteredOrders = status == null
        ? _orders
        : _orders.where((order) => order.status == status).toList();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) => _buildOrderItem(filteredOrders[index]),
      ),
    );
  }

  Widget _buildOrderItem(Order order) {
    final config = ref.watch(configProvider);
    final status = _getStatusText(order.status ?? 0);
    final statusColor = status == '已完成'
        ? const Color(0xFF4CAF50)
        : status == '已取消'
            ? const Color(0xFFFF5252)
            : const Color(0xFFFFA726);
    final orderId = order.tradeNo ?? '';
    final amount =
        ((order.balanceAmount ?? order.totalAmount) ?? 0).toDouble() / 100;
    final createTime = DateTime.fromMillisecondsSinceEpoch(
      (order.createdAt ?? 0) * 1000,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(NewAppAssets.orderListPrefix + 'bg_Order_bg.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(
                orderId: orderId,
                initialStatus: _getOrderDetailStatus(order.status ?? 0),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '订单号：$orderId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '创建时间：${createTime.year}-${createTime.month.toString().padLeft(2, '0')}-${createTime.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '查看详情',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '状态：$status',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(1)} ${config.symbol}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
