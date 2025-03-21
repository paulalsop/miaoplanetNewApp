/// 会员类型枚举
enum MembershipType {
  /// 普通会员
  ordinary,

  /// 股东会员
  shareholder,
}

/// 会员套餐期限枚举
enum MembershipPeriod {
  /// 一个月
  oneMonth,

  /// 三个月
  threeMonths,

  /// 六个月
  sixMonths,

  /// 一年
  oneYear,

  /// 终身会员（仅股东会员可用）
  lifetime,
}

/// 会员套餐模型
class MembershipPlan {
  /// 套餐ID
  final String id;

  /// 套餐名称
  final String name;

  /// 套餐价格
  final int price;

  /// 套餐币种
  final String currency;

  /// 套餐期限
  final MembershipPeriod period;

  /// 构造函数
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'Miao',
    required this.period,
  });

  /// 获取每月价格
  String get monthlyPrice {
    if (period == MembershipPeriod.lifetime) {
      return '$price$currency/Life member';
    }

    return '$price$currency/per month';
  }
}

/// 普通会员套餐
final List<MembershipPlan> ordinaryMembershipPlans = [
  const MembershipPlan(
    id: 'ordinary_1m',
    name: '1 Month',
    price: 2000,
    period: MembershipPeriod.oneMonth,
  ),
  const MembershipPlan(
    id: 'ordinary_3m',
    name: '3 Month',
    price: 6000,
    period: MembershipPeriod.threeMonths,
  ),
  const MembershipPlan(
    id: 'ordinary_6m',
    name: '6 Month',
    price: 12000,
    period: MembershipPeriod.sixMonths,
  ),
  const MembershipPlan(
    id: 'ordinary_1y',
    name: '1 Year',
    price: 24000,
    period: MembershipPeriod.oneYear,
  ),
];

/// 股东会员套餐
final List<MembershipPlan> shareholderMembershipPlans = [
  const MembershipPlan(
    id: 'shareholder_lifetime',
    name: 'Life member',
    price: 30000,
    period: MembershipPeriod.lifetime,
  ),
];
