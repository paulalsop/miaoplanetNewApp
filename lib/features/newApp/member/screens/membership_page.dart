import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/app_assets.dart';
import '../models/membership_type.dart';
import '../widgets/membership_header.dart';
import '../widgets/membership_plan_item.dart';
import '../widgets/membership_type_tabs.dart';
import '../widgets/subscription_button.dart';
import '../../../panel/xboard/models/plan_model.dart';
import '../../../panel/xboard/services/http_service/plan_service.dart';
import '../../../panel/xboard/services/http_service/order_service.dart';
import '../../../panel/xboard/utils/storage/token_storage.dart';
import '../../order/screens/order_detail_page.dart';
import '../../order/models/order_status.dart';
import '../../order/screens/order_list_page.dart';

/// 会员页面
class MembershipPage extends ConsumerStatefulWidget {
  /// 构造函数
  const MembershipPage({
    super.key,
    required this.initialType,
    required this.onClose,
  });

  /// 初始会员类型
  final MembershipType initialType;

  /// 关闭回调
  final VoidCallback onClose;

  @override
  ConsumerState<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends ConsumerState<MembershipPage> {
  late MembershipType _selectedType;
  List<Plan>? _plans;
  Plan? _selectedPlan;
  String? _selectedPeriod;
  bool _isLoading = true;
  String? _error;

  final _planService = PlanService();
  final _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedPlan = _getDefaultPlan();
    _selectedPeriod = 'month_price'; // 默认选择月付
    _loadPlans();
  }

  Future<void> _loadPlans() async {
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

      final plans = await _planService.fetchPlanData(token);
      setState(() {
        _plans = plans;
        _selectedPlan = _getDefaultPlan();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "获取套餐失败: $e";
        _isLoading = false;
      });
    }
  }

  Plan? _getDefaultPlan() {
    if (_plans == null || _plans!.isEmpty) return null;
    return _plans!.firstWhere(
      (plan) => _selectedType == MembershipType.ordinary
          ? plan.id == 1
          : plan.id == 2,
      orElse: () => _plans!.first,
    );
  }

  /// 获取当前会员类型对应的背景图片
  String get _backgroundImage => _selectedType == MembershipType.ordinary
      ? NewAppAssets.ordinaryMemberBackground
      : NewAppAssets.shareholderMemberBackground;

  /// 获取当前会员类型对应的关闭按钮图标
  String get _closeIcon => _selectedType == MembershipType.ordinary
      ? NewAppAssets.ordinaryMemberQuitIcon
      : NewAppAssets.shareholderMemberQuitIcon;

  /// 获取当前会员类型对应的货币符号
  String get _currencySymbol =>
      _selectedType == MembershipType.ordinary ? '¥' : 'MIAO';

  /// 获取当前会员类型对应的套餐列表
  List<Plan> get _currentPlans =>
      _plans
          ?.where((plan) => _selectedType == MembershipType.ordinary
              ? plan.id == 1
              : plan.id == 2)
          .toList() ??
      [];

  /// 处理会员类型变化
  void _handleTypeChanged(MembershipType type) {
    setState(() {
      _selectedType = type;
      _selectedPlan = _getDefaultPlan();
    });
  }

  /// 处理普通会员套餐选择
  void _handlePlanSelected(Plan plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  /// 处理周期选择
  void _handlePeriodSelected(String period) {
    setState(() {
      _selectedPeriod = period;
    });
  }

  /// 处理订阅提交
  void _handleSubscribe() {
    _handleSubscribeAsync();
  }

  Future<void> _handleSubscribeAsync() async {
    if (_selectedPlan == null || _selectedPeriod == null) return;

    try {
      final token = await getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
        return;
      }

      // 发送请求
      final result = await _orderService.createOrder(
        token,
        _selectedPlan!.id,
        _selectedPeriod!,
      );

      if (!mounted) return;

      if (result['status'] == 'success') {
        final orderId = result['data'] as String;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(
              orderId: orderId,
              initialStatus: OrderDetailStatus.pending,
              onClose: () => Navigator.pop(context),
            ),
          ),
        );
      } else {
        String errorMessage = result['message'] as String? ?? '创建订单失败';

        // 检查是否是未支付订单的错误
        if (errorMessage.contains('您有未付款') ||
            errorMessage.contains('未付款') ||
            errorMessage.contains('未支付') ||
            errorMessage.contains('开通中') ||
            errorMessage.contains('未付费')) {
          // 显示提示对话框
          final shouldGoToOrders = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('提示'),
              content: const Text('您有未支付的订单，是否查看订单列表？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('查看订单'),
                ),
              ],
            ),
          );

          if (shouldGoToOrders == true) {
            if (!mounted) return;
            // 使用 MaterialPageRoute 导航到 OrderListPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderListPage(),
              ),
            );
          }
        } else {
          // 其他错误直接显示错误信息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final shouldGoToOrders = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('您有未支付的订单，是否查看订单列表？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('查看订单'),
            ),
          ],
        ),
      );

      if (shouldGoToOrders == true) {
        if (!mounted) return;
        // 使用 MaterialPageRoute 导航到 OrderListPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderListPage(),
          ),
        );
      }
    }
  }

  /// 格式化价格显示
  String _formatPrice(double? price) {
    if (price == null) return '0 $_currencySymbol';

    // 如果是普通会员，显示小数点后两位；如果是股东，显示整数
    if (_selectedType == MembershipType.ordinary) {
      return '${price.toStringAsFixed(2)} $_currencySymbol';
    } else {
      return '${price.toInt()} $_currencySymbol';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部栏：会员类型切换和关闭按钮
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 会员类型切换标签
                    Expanded(
                      child: MembershipTypeTabs(
                        selectedType: _selectedType,
                        onTypeChanged: _handleTypeChanged,
                      ),
                    ),

                    // 关闭按钮
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3C3C3C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          _closeIcon,
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 会员信息头部
              MembershipHeader(membershipType: _selectedType),

              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.white))),
                )
              else
                Expanded(
                  child: _buildPlansList(),
                ),

              // 订阅按钮
              SubscriptionButton(
                onTap: _selectedPlan != null ? _handleSubscribe : null,
                membershipType: _selectedType,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建普通会员套餐列表
  Widget _buildPlansList() {
    final plans = _currentPlans;
    if (plans.isEmpty) {
      return const Center(
        child: Text('暂无可用套餐', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: plans.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        final plan = plans[index];
        return MembershipPlanItem(
          plan: plan,
          selectedPeriod: _selectedPeriod,
          membershipType: _selectedType,
          onPeriodSelected: _handlePeriodSelected,
        );
      },
    );
  }
}
