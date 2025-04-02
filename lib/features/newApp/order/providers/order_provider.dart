import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/order_model.dart';

final orderProvider = StateNotifierProvider<OrderNotifier, OrderModel?>((ref) {
  return OrderNotifier();
});

class OrderNotifier extends StateNotifier<OrderModel?> {
  OrderNotifier() : super(null);

  void setOrder(OrderModel order) {
    state = order;
  }

  void clearOrder() {
    state = null;
  }
}
