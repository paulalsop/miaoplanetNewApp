import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/membership_model.dart';
import '../widgets/membership_header.dart';
import '../widgets/membership_plan_item.dart';
import '../widgets/membership_type_tabs.dart';
import '../widgets/subscription_button.dart';

/// 会员页面
class MembershipPage extends StatefulWidget {
  /// 构造函数
  const MembershipPage({
    super.key,
    this.onClose,
    this.initialType = MembershipType.ordinary,
  });

  /// 关闭回调
  final VoidCallback? onClose;

  /// 初始会员类型
  final MembershipType initialType;

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  /// 当前选中的会员类型
  late MembershipType _selectedType;

  /// 普通会员选中的套餐ID
  String _selectedOrdinaryPlanId = ordinaryMembershipPlans.first.id;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  /// 获取当前会员类型对应的背景图片
  String get _backgroundImage => _selectedType == MembershipType.ordinary
      ? NewAppAssets.ordinaryMemberBackground
      : NewAppAssets.shareholderMemberBackground;

  /// 获取当前会员类型对应的关闭按钮图标
  String get _closeIcon => _selectedType == MembershipType.ordinary
      ? NewAppAssets.ordinaryMemberQuitIcon
      : NewAppAssets.shareholderMemberQuitIcon;

  /// 获取当前会员类型对应的套餐列表
  List<MembershipPlan> get _currentPlans =>
      _selectedType == MembershipType.ordinary
          ? ordinaryMembershipPlans
          : shareholderMembershipPlans;

  /// 处理会员类型变化
  void _handleTypeChanged(MembershipType type) {
    setState(() {
      _selectedType = type;
    });
  }

  /// 处理普通会员套餐选择
  void _handleOrdinaryPlanSelected(String planId) {
    setState(() {
      _selectedOrdinaryPlanId = planId;
    });
  }

  /// 处理订阅提交
  void _handleSubscribe() {
    // 获取选中的套餐
    final selectedPlan = _selectedType == MembershipType.ordinary
        ? ordinaryMembershipPlans
            .firstWhere((plan) => plan.id == _selectedOrdinaryPlanId)
        : shareholderMembershipPlans.first;

    // 显示订阅成功消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '成功订阅 ${_selectedType == MembershipType.ordinary ? "普通会员" : "股东会员"} - ${selectedPlan.name}'),
      ),
    );

    // 关闭页面
    if (widget.onClose != null) {
      widget.onClose!();
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

              // 套餐列表
              Expanded(
                child: _selectedType == MembershipType.ordinary
                    ? _buildOrdinaryPlansList() // 普通会员套餐列表
                    : _buildShareholderPlansList(), // 股东会员套餐列表
              ),

              // 订阅按钮
              SubscriptionButton(
                onTap: _handleSubscribe,
                membershipType: _selectedType,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建普通会员套餐列表
  Widget _buildOrdinaryPlansList() {
    return ListView.builder(
      itemCount: ordinaryMembershipPlans.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        final plan = ordinaryMembershipPlans[index];
        final isSelected = plan.id == _selectedOrdinaryPlanId;

        return MembershipPlanItem(
          plan: plan,
          isSelected: isSelected,
          membershipType: MembershipType.ordinary,
          onTap: () => _handleOrdinaryPlanSelected(plan.id),
        );
      },
    );
  }

  /// 构建股东会员套餐列表
  Widget _buildShareholderPlansList() {
    // 股东会员套餐展示时增加额外间隔，让布局更加合理
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        const SizedBox(height: 16),
        // 股东会员只有一个套餐，放在中央位置展示
        MembershipPlanItem(
          plan: shareholderMembershipPlans.first,
          isSelected: true,
          membershipType: MembershipType.shareholder,
          onTap: () {}, // 股东会员只有一个套餐，无需切换
        ),
      ],
    );
  }
}
