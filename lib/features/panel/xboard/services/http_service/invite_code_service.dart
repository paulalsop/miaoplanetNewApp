// services/invite_service.dart
import 'package:hiddify/features/panel/xboard/models/invite_code_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class InviteCodeService {
  final HttpService _httpService = HttpService();

  /// 生成邀请码的方法
  ///
  /// 返回一个Map，包含：
  /// - success: 是否成功
  /// - message: 提示消息
  /// - needBindInviter: 是否需要先绑定推荐人
  Future<Map<String, dynamic>> generateInviteCode(String accessToken) async {
    try {
      // 先检查推荐人状态
      final inviteStatus = await getInviteStatus(accessToken);

      // 如果没有推荐人，返回错误提示
      if (inviteStatus['hasInviter'] == false) {
        return {
          'success': false,
          'message': '请先绑定推荐人后再生成邀请码',
          'needBindInviter': true,
        };
      }

      // 如果有推荐人，继续生成邀请码
      await _httpService.getRequest(
        "/api/v1/user/invite/save",
        headers: {'Authorization': accessToken},
      );

      return {
        'success': true,
        'message': '邀请码生成成功',
        'needBindInviter': false,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '生成邀请码失败: $e',
        'needBindInviter': false,
      };
    }
  }

  // 获取邀请码数据的方法
  Future<List<InviteCode>> fetchInviteCodes(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/invite/fetch",
      headers: {'Authorization': accessToken},
    );

    if (result.containsKey("data") && result["data"] is Map<String, dynamic>) {
      final data = result["data"];
      // ignore: avoid_dynamic_calls
      final codes = data["codes"] as List;
      return codes
          .cast<Map<String, dynamic>>()
          .map((json) => InviteCode.fromJson(json))
          .toList();
    } else {
      throw Exception("Failed to retrieve invite codes");
    }
  }

  // 获取完整邀请码链接的方法
  String getInviteLink(String code) {
    final inviteLinkBase = "${HttpService.baseUrl}/#/register?code=";
    if (HttpService.baseUrl.isEmpty) {
      throw Exception('Base URL is not set.');
    }
    return '$inviteLinkBase$code';
  }

  /// 获取推荐人状态信息
  ///
  /// 返回用户的推荐人状态，包括是否有推荐人、推荐人信息、邀请码状态等
  Future<Map<String, dynamic>> getInviteStatus(String accessToken) async {
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/invite/status",
        headers: {'Authorization': accessToken},
      );

      return {
        'success': result['status'] == 'success',
        'message': result['message'] ?? '',
        'data': result['data'],
        'hasInviter': result['data']?['has_inviter'] == true,
        'inviterInfo': result['data']?['inviter_info'],
        'hasInviteCode': result['data']?['has_invite_code'] == true,
        'canGenerateCode': result['data']?['can_generate_code'] == true,
        'activeInviteCodeCount':
            result['data']?['active_invite_code_count'] ?? 0,
        'maxInviteCodeLimit': result['data']?['max_invite_code_limit'] ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '获取推荐人状态失败',
        'data': null,
        'hasInviter': false,
        'inviterInfo': null,
        'hasInviteCode': false,
        'canGenerateCode': false,
        'activeInviteCodeCount': 0,
        'maxInviteCodeLimit': 0,
      };
    }
  }
}
