// services/user_service.dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class UserService {
  final HttpService _httpService = HttpService();

  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/info",
      headers: {'Authorization': accessToken},
    );
    if (result.containsKey("data")) {
      final data = result["data"];
      return UserInfo.fromJson(data as Map<String, dynamic>);
    }
    throw Exception("Failed to retrieve user info");
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {'Authorization': token},
      );
      return response['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<String?> convertTempAccount(
      String email, String password, String accessToken) async {
    final result = await _httpService.postRequest(
      "/api/v1/user/convertTempAccount",
      {'email': email, 'password': password},
      headers: {'Authorization': accessToken},
    );
    return result["data"] as String?;
  }

  Future<String?> getSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/getSubscribe",
      headers: {'Authorization': accessToken},
    );
    // ignore: avoid_dynamic_calls
    return result["data"]["subscribe_url"] as String?;
  }

  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/resetSecurity",
      headers: {'Authorization': accessToken},
    );
    return result["data"] as String?;
  }

  /// 绑定推荐人邀请码
  ///
  /// 将当前用户与推荐人关联
  /// 返回绑定结果
  Future<Map<String, dynamic>> bindInviteCode(
      String inviteCode, String accessToken) async {
    try {
      final result = await _httpService.postRequest(
        "/api/v1/user/bindInviteCode",
        {"invite_code": inviteCode},
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'data': result['data'],
      };
    } catch (e) {
      // 尝试从错误信息中提取message字段
      String errorMessage = '绑定失败';

      try {
        // 将错误转为字符串
        String errorString = e.toString();

        // 检查是否包含JSON响应
        if (errorString.contains('{"status":"fail"')) {
          // 查找message部分
          RegExp messageRegex = RegExp(r'"message":"([^"]+)"');
          final match = messageRegex.firstMatch(errorString);

          if (match != null && match.groupCount >= 1) {
            errorMessage = match.group(1) ?? errorMessage;
          }
        }
      } catch (_) {
        // 解析失败，使用默认错误信息
      }

      return {
        'success': false,
        'message': errorMessage,
        'data': null,
      };
    }
  }

  /// 获取用户BSC地址
  ///
  /// 返回用户绑定的BSC地址，如果未绑定则返回null
  Future<Map<String, dynamic>> getBscAddress(String accessToken) async {
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/getBscAddress",
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'bscAddress': result['data']?['bsc_address'],
      };
    } catch (e) {
      // 尝试从错误信息中提取message字段
      String errorMessage = '获取BSC地址失败';

      try {
        // 将错误转为字符串
        String errorString = e.toString();

        // 检查是否包含JSON响应
        if (errorString.contains('{"status":"fail"')) {
          // 查找message部分
          RegExp messageRegex = RegExp(r'"message":"([^"]+)"');
          final match = messageRegex.firstMatch(errorString);

          if (match != null && match.groupCount >= 1) {
            errorMessage = match.group(1) ?? errorMessage;
          }
        }
      } catch (_) {
        // 解析失败，使用默认错误信息
      }

      return {
        'success': false,
        'message': errorMessage,
        'bscAddress': null,
      };
    }
  }

  /// 更新用户BSC地址
  ///
  /// 设置用户的BSC地址
  Future<Map<String, dynamic>> updateBscAddress(
      String bscAddress, String accessToken) async {
    try {
      final result = await _httpService.postRequest(
        "/api/v1/user/updateBscAddress",
        {"bsc_address": bscAddress},
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'data': result['data'],
      };
    } catch (e) {
      // 尝试从错误信息中提取message字段
      String errorMessage = '更新BSC地址失败';

      try {
        // 将错误转为字符串
        String errorString = e.toString();

        // 检查是否包含JSON响应
        if (errorString.contains('{"status":"fail"')) {
          // 查找message部分
          RegExp messageRegex = RegExp(r'"message":"([^"]+)"');
          final match = messageRegex.firstMatch(errorString);

          if (match != null && match.groupCount >= 1) {
            errorMessage = match.group(1) ?? errorMessage;
          }
        }
      } catch (_) {
        // 解析失败，使用默认错误信息
      }

      return {
        'success': false,
        'message': errorMessage,
        'data': null,
      };
    }
  }

  /// 获取工单列表
  ///
  /// 返回用户的所有工单
  Future<Map<String, dynamic>> fetchTickets(String accessToken) async {
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/ticket/fetch",
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'tickets': result['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': '获取工单列表失败: $e',
        'tickets': [],
      };
    }
  }

  /// 获取单个工单详情
  ///
  /// 返回指定ID工单的详细信息和消息记录
  Future<Map<String, dynamic>> fetchTicketDetail(
      int ticketId, String accessToken) async {
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/ticket/fetch?id=$ticketId",
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'ticketDetail': result['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': '获取工单详情失败: $e',
        'ticketDetail': null,
      };
    }
  }

  /// 创建新工单
  ///
  /// 创建一个新的客服工单
  Future<Map<String, dynamic>> createTicket(
      String subject, int level, String message, String accessToken) async {
    try {
      final result = await _httpService.postRequest(
        "/api/v1/user/ticket/save",
        {
          "subject": subject,
          "level": level,
          "message": message,
        },
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'data': result['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': '创建工单失败: $e',
        'data': null,
      };
    }
  }

  /// 回复工单
  ///
  /// 向指定ID的工单发送回复消息
  Future<Map<String, dynamic>> replyTicket(
      int ticketId, String message, String accessToken) async {
    try {
      final result = await _httpService.postRequest(
        "/api/v1/user/ticket/reply",
        {
          "id": ticketId,
          "message": message,
        },
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'data': result['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': '回复工单失败: $e',
        'data': null,
      };
    }
  }
}
