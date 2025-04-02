// services/auth_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

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

  Future<Map<String, dynamic>> getUserConfig() async {
    return await _httpService.getRequest(
      "/api/v1/user/comm/config",
    );
  }

  /// 获取应用版本信息
  ///
  /// 返回各平台的版本号和下载链接，不需要登录即可调用
  Future<Map<String, dynamic>> getAppVersion() async {
    final clientToken = await getClientToken();
    // 即使没有token也尝试获取版本信息
    final tokenParam = clientToken != null ? "?token=$clientToken" : "";

    return await _httpService.getRequest(
      "/api/v1/client/app/getVersion$tokenParam",
    );
  }
}
