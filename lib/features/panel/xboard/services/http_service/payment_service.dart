// services/payment_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class PaymentService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo, String method, String accessToken) async {
    final response = await _httpService.postRequest(
      "/api/v1/user/order/checkout",
      {"trade_no": tradeNo, "method": method},
      headers: {'Authorization': accessToken},
    );

    // 构建完整的支付URL
    if (response['type'] == 1 && response['data'] is String) {
      final url = response['data'] as String;
      final paymentUrl = url.startsWith('http://') || url.startsWith('https://')
          ? url
          : HttpService.baseUrl + url;
      return {
        'status': 'success',
        'payment_url': paymentUrl,
      };
    }

    return response;
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    final response = await _httpService.getRequest(
      "/api/v1/user/order/getPaymentMethod",
      headers: {'Authorization': accessToken},
    );
    return (response['data'] as List).cast<dynamic>();
  }
}
