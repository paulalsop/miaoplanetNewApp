import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_assets.dart';
import '../models/order_model.dart';
import '../models/order_status.dart';
import '../widgets/order_product_info.dart';
import '../widgets/order_payment_method.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/payment_result_dialog.dart';
import '../../../panel/xboard/services/http_service/order_service.dart';
import '../../../panel/xboard/services/http_service/payment_service.dart';
import '../../../panel/xboard/utils/storage/token_storage.dart';
import '../../../panel/xboard/providers/config_provider.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.onClose,
    this.initialStatus = OrderDetailStatus.pending,
  });

  final String orderId;
  final VoidCallback? onClose;
  final OrderDetailStatus initialStatus;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  late OrderDetailStatus _status;
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _paymentMethods = [];
  final _orderService = OrderService();
  final _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _loadData();
  }

  String _getStatusTitle(int status) {
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

  String _getStatusDescription(int status) {
    switch (status) {
      case 0:
        return '交易将在23小时59分后关闭，请及时付款！';
      case 2:
        return '订单由于超时支付已被取消';
      case 3:
        return '订单已支付并开通';
      default:
        return '';
    }
  }

  Future<void> _loadData() async {
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

      // 并行加载订单详情和支付方式
      final results = await Future.wait([
        _orderService.getOrderDetails(widget.orderId, token),
        _paymentService.getPaymentMethods(token),
      ]);

      final orderResult = results[0] as Map<String, dynamic>;
      final paymentMethodsResult = results[1] as List<dynamic>;

      if (orderResult['status'] == 'success' &&
          paymentMethodsResult.isNotEmpty) {
        setState(() {
          _orderData = orderResult['data'] as Map<String, dynamic>;

          // 检查订单类型（会员订阅或股东订阅）
          final bool isShareholderOrder = _isShareholderOrder(_orderData!);

          // 根据订单类型过滤支付方式
          _paymentMethods =
              paymentMethodsResult.cast<Map<String, dynamic>>().where((method) {
            final int methodId = method['id'] as int;
            // 股东订阅只保留MIAO支付(ID=1)
            if (isShareholderOrder) {
              return methodId == 1; // MIAO支付
            }
            // 会员订阅只保留支付宝和微信支付(ID=3,4)
            else {
              return methodId == 3 || methodId == 4; // 支付宝或微信支付
            }
          }).toList();

          // 设置默认支付方式为第一个
          if (_paymentMethods.isNotEmpty) {
            final firstMethod = _paymentMethods[0];
            _selectedPaymentMethod = PaymentMethod(
              id: firstMethod['id'] as int,
              name: firstMethod['name'] as String,
              icon: firstMethod['icon'] as String,
            );
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = orderResult['message'] as String? ?? "获取数据失败";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "加载失败: $e";
        _isLoading = false;
      });
    }
  }

  // 判断是否为股东订阅
  bool _isShareholderOrder(Map<String, dynamic> orderData) {
    // 根据订单中的plan信息判断是否为股东订阅
    // 假设plan_id=2表示股东订阅，plan_id=1表示普通会员
    if (orderData.containsKey('plan') &&
        orderData['plan'] is Map<String, dynamic>) {
      final plan = orderData['plan'] as Map<String, dynamic>;
      return plan.containsKey('id') && plan['id'] == 2;
    }
    return false;
  }

  // 获取货币符号
  String _getCurrencySymbol() {
    if (_orderData == null) return '¥';
    return _isShareholderOrder(_orderData!) ? 'MIAO' : '¥';
  }

  void _handleCancelOrder() async {
    if (_orderData == null) return;

    try {
      // 显示确认对话框
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('确认取消'),
          content: const Text('确定要取消这个订单吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('再想想'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '确定取消',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      final token = await getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
        return;
      }

      final result = await _orderService.cancelOrder(
        _orderData!['trade_no'] as String,
        token,
      );

      if (!mounted) return;

      if (result['status'] == 'success') {
        // 刷新订单数据
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订单已取消')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] as String? ?? '取消失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('取消失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final orderStatus = _orderData?['status'] as int? ?? 0;

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
            '订单详情',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            if (widget.onClose != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.white)))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 状态和描述
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusTitle(orderStatus),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getStatusDescription(orderStatus),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 商品信息
                        if (_orderData != null)
                          OrderProductInfo(
                            order: OrderModel(
                              orderId: _orderData!['trade_no'] as String,
                              productName: (_orderData!['plan']
                                  as Map<String, dynamic>)['name'] as String,
                              amount: (_orderData!['balance_amount'] != null
                                      ? (_orderData!['balance_amount'] as num)
                                          .toDouble()
                                      : (_orderData!['total_amount'] as num)
                                          .toDouble()) /
                                  100,
                              type: _getPeriodName(
                                  _orderData!['period'] as String),
                              traffic:
                                  '${(_orderData!['plan'] as Map<String, dynamic>)['transfer_enable']}GB',
                              createTime: DateTime.fromMillisecondsSinceEpoch(
                                (_orderData!['created_at'] as int) * 1000,
                              ),
                              expiryTime: DateTime.now()
                                  .add(const Duration(hours: 23, minutes: 59)),
                              currencySymbol: _getCurrencySymbol(),
                            ),
                          ),

                        // 支付方式选择 - 只在待支付状态显示
                        if (orderStatus == 0 &&
                            _paymentMethods.isNotEmpty &&
                            _selectedPaymentMethod != null)
                          OrderPaymentMethod(
                            selectedMethod: _selectedPaymentMethod!,
                            onMethodChanged: (method) {
                              setState(() => _selectedPaymentMethod = method);
                            },
                            paymentMethods: _paymentMethods,
                          ),

                        // 支付和取消按钮区域
                        if (orderStatus == 0)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // 立即支付按钮
                                ElevatedButton(
                                  onPressed: _handleStartPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFA726),
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '立即支付',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // 取消订单按钮
                                TextButton(
                                  onPressed: _handleCancelOrder,
                                  style: TextButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '取消订单',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _getPeriodName(String period) {
    switch (period) {
      case 'month_price':
        return '月付';
      case 'quarter_price':
        return '季付';
      case 'half_year_price':
        return '半年付';
      case 'year_price':
        return '年付';
      case 'two_year_price':
        return '两年付';
      case 'three_year_price':
        return '三年付';
      case 'onetime_price':
        return '一次性';
      default:
        return period;
    }
  }

  void _handleStartPayment() async {
    if (_orderData == null || _selectedPaymentMethod == null) return;

    try {
      final token = await getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
        return;
      }

      // 使用选择的支付方式ID
      final result = await _paymentService.submitOrder(
        _orderData!['trade_no'] as String,
        _selectedPaymentMethod!.id.toString(),
        token,
      );

      if (result['status'] == 'success' && result['payment_url'] != null) {
        if (!mounted) return;

        // 检查URL是否已包含http/https协议前缀
        String urlStr = result['payment_url'] as String;
        final url =
            urlStr.startsWith('http://') || urlStr.startsWith('https://')
                ? Uri.parse(urlStr)
                : Uri.parse('https://$urlStr');

        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication, // 使用外部浏览器打开
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开支付页面')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] as String? ?? '支付失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('支付失败: $e')),
      );
    }
  }
}
