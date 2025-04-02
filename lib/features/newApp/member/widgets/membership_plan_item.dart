import 'package:flutter/material.dart';
import '../../../panel/xboard/models/plan_model.dart';
import '../models/membership_type.dart';

class PlanPeriod {
  final String name;
  final String period;
  final double? price;

  PlanPeriod({
    required this.name,
    required this.period,
    required this.price,
  });
}

/// 会员套餐选择项组件
class MembershipPlanItem extends StatelessWidget {
  /// 构造函数
  const MembershipPlanItem({
    Key? key,
    required this.plan,
    required this.selectedPeriod,
    required this.membershipType,
    required this.onPeriodSelected,
  }) : super(key: key);

  /// 套餐数据
  final Plan plan;

  /// 选中的周期
  final String? selectedPeriod;

  /// 会员类型
  final MembershipType membershipType;

  /// 周期选择回调
  final Function(String period) onPeriodSelected;

  List<PlanPeriod> get _periods => [
        if (plan.monthPrice != null)
          PlanPeriod(
            name: '1 月',
            period: 'month_price',
            price: plan.monthPrice,
          ),
        if (plan.quarterPrice != null)
          PlanPeriod(
            name: '3 月',
            period: 'quarter_price',
            price: plan.quarterPrice,
          ),
        if (plan.halfYearPrice != null)
          PlanPeriod(
            name: '6 月',
            period: 'half_year_price',
            price: plan.halfYearPrice,
          ),
        if (plan.yearPrice != null)
          PlanPeriod(
            name: '1 年',
            period: 'year_price',
            price: plan.yearPrice,
          ),
        if (plan.twoYearPrice != null)
          PlanPeriod(
            name: '2 年',
            period: 'two_year_price',
            price: plan.twoYearPrice,
          ),
        if (plan.threeYearPrice != null)
          PlanPeriod(
            name: '3 年',
            period: 'three_year_price',
            price: plan.threeYearPrice,
          ),
        if (plan.onetimePrice != null)
          PlanPeriod(
            name: '终生',
            period: 'onetime_price',
            price: plan.onetimePrice,
          ),
      ];

  // 获取货币符号
  String get _currencySymbol =>
      membershipType == MembershipType.ordinary ? '¥' : 'MIAO';

  // 获取价格显示文本
  String _getPriceText(double? price) {
    if (price == null) return '0 $_currencySymbol';

    // 如果是普通会员，显示小数点后两位；如果是股东，显示整数
    if (membershipType == MembershipType.ordinary) {
      return '${price.toStringAsFixed(2)} $_currencySymbol';
    } else {
      return '${price.toInt()} $_currencySymbol';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _periods.length,
      itemBuilder: (context, index) {
        final period = _periods[index];
        final isSelected = selectedPeriod == period.period;

        return GestureDetector(
          onTap: () => onPeriodSelected(period.period),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C4BF6) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPriceText(period.price),
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF6C4BF6),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
