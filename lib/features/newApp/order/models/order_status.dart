enum OrderDetailStatus {
  pending, // 待支付
  completed, // 已完成
  cancelled, // 已取消
}

extension OrderDetailStatusExtension on OrderDetailStatus {
  String get title {
    switch (this) {
      case OrderDetailStatus.pending:
        return '待支付';
      case OrderDetailStatus.completed:
        return '已完成';
      case OrderDetailStatus.cancelled:
        return '已取消';
    }
  }

  String get description {
    switch (this) {
      case OrderDetailStatus.pending:
        return '交易将在23小时59分后关闭，请及时付款！';
      case OrderDetailStatus.completed:
        return '订单已支付并开通';
      case OrderDetailStatus.cancelled:
        return '订单由于超时支付已被取消';
    }
  }
}
