// services/order_service.dart
import 'package:hiddify/features/panel/xboard/models/order_model.dart';

import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class OrderService {
  final HttpService _httpService = HttpService();

  Future<List<Order>> fetchUserOrders(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/order/fetch",
      headers: {'Authorization': accessToken},
    );

    if (result["status"] == "success" && result["data"] != null) {
      final ordersJson = result["data"] as List;
      return ordersJson
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(result["message"] ?? "Failed to fetch user orders");
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(
      String tradeNo, String accessToken) async {
    return await _httpService.getRequest(
      "/api/v1/user/order/detail?trade_no=$tradeNo",
      headers: {'Authorization': accessToken},
    );
  }

  Future<Map<String, dynamic>> cancelOrder(
      String tradeNo, String accessToken) async {
    return await _httpService.postRequest(
      "/api/v1/user/order/cancel",
      {"trade_no": tradeNo},
      headers: {'Authorization': accessToken},
    );
  }

  Future<Map<String, dynamic>> createOrder(
      String accessToken, int planId, String period) async {
    print('OrderService createOrder - planId: $planId, period: $period');
    print('OrderService createOrder - accessToken: $accessToken');

    final response = await _httpService.postRequest(
      "/api/v1/user/order/save",
      {"plan_id": planId, "period": period},
      headers: {
        'Authorization': accessToken,
        'Content-Type': 'application/json',
      },
    );

    print('OrderService createOrder - response: $response');
    return response;
  }
}
