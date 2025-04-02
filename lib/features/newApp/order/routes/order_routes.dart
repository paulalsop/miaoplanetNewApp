import 'package:flutter/material.dart';
import '../screens/order_detail_page.dart';

class OrderRoutes {
  static const String orderDetail = '/order/detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case orderDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final orderId = args?['orderId'] as String?;

        // 如果orderId为空，返回错误页面
        if (orderId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('订单ID不能为空'),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => OrderDetailPage(
            orderId: orderId,
            onClose: args?['onClose'] as VoidCallback?,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('未找到页面'),
            ),
          ),
        );
    }
  }

  static Future<void> navigateToOrderDetail(
    BuildContext context, {
    required String orderId,
    VoidCallback? onClose,
  }) async {
    await Navigator.pushNamed(
      context,
      orderDetail,
      arguments: {
        'orderId': orderId,
        'onClose': onClose,
      },
    );
  }
}
