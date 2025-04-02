class OrderModel {
  final String orderId;
  final String productName;
  final double amount;
  final String type;
  final String traffic;
  final DateTime createTime;
  final DateTime expiryTime;
  final String currencySymbol;

  OrderModel({
    required this.orderId,
    required this.productName,
    required this.amount,
    required this.type,
    required this.traffic,
    required this.createTime,
    required this.expiryTime,
    this.currencySymbol = '¥',
  });
}
