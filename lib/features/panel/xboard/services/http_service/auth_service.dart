// services/auth_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('AuthService.login 方法被调用 - 邮箱: [$email], 密码: [$password]');
    
    // 创建请求参数字典
    final Map<String, dynamic> requestBody = {
      "email": email,
      "password": password,
    };
    
    print('准备发送请求体: $requestBody');
    
    return await _httpService.postRequest(
      "/api/v1/passport/auth/login",
      requestBody,
      requiresHeaders: true,
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Map<String, dynamic>> register(String email, String password,
      String inviteCode, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/register",
      {
        "email": email,
        "password": password,
        "invite_code": inviteCode,
        "email_code": emailCode,
      },
    );
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return await _httpService.postRequest(
      "/api/v1/passport/comm/sendEmailVerify",
      {'email': email},
    );
  }

  Future<Map<String, dynamic>> tempAccountCreate(String deviceId) async {
    return await _httpService.postRequest(
      "/api/v1/guest/temp-account/create",
      {'device_id': deviceId},
    );
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }

  Future<Map<String, dynamic>> getSystemConfig() async {
    return await _httpService.getRequest(
      "/api/v1/guest/comm/config",
    );
  }
}
