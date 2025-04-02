import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/invite_code_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/panel/xboard/models/invite_code_model.dart';

/// 邀请码服务类
class InvitationService {
  // 单例模式
  static final InvitationService _instance = InvitationService._internal();
  static InvitationService get instance => _instance;
  InvitationService._internal();

  // 模拟的邀请码和邀请链接
  // 在实际应用中，这些应该从服务器获取
  static const String _defaultInvitationCode = '';
  static const String _defaultInvitationLink = '';

  // SharedPreferences键名
  static const String _invitationCodeKey = 'invitation_code';
  static const String _invitationLinkKey = 'invitation_link';

  // 底层服务
  final _inviteCodeService = InviteCodeService();

  /// 获取邀请码
  Future<String> getInvitationCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_invitationCodeKey) ?? _defaultInvitationCode;
    } catch (e) {
      print('获取邀请码失败: $e');
      return _defaultInvitationCode;
    }
  }

  /// 获取邀请链接
  Future<String> getInvitationLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_invitationLinkKey) ?? _defaultInvitationLink;
    } catch (e) {
      print('获取邀请链接失败: $e');
      return _defaultInvitationLink;
    }
  }

  /// 设置邀请码（仅用于测试或开发）
  Future<void> setInvitationCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_invitationCodeKey, code);
    } catch (e) {
      print('设置邀请码失败: $e');
    }
  }

  /// 设置邀请链接（仅用于测试或开发）
  Future<void> setInvitationLink(String link) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_invitationLinkKey, link);
    } catch (e) {
      print('设置邀请链接失败: $e');
    }
  }

  /// 刷新邀请数据，获取最新的邀请码和链接
  ///
  /// 如果用户没有邀请码，会自动创建一个
  Future<Map<String, String>> refreshInvitationData() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('用户未登录，无法获取邀请码');
    }

    // 获取现有邀请码
    List<InviteCode> codes = [];
    try {
      codes = await _inviteCodeService.fetchInviteCodes(token);
    } catch (e) {
      print('获取邀请码失败: $e');
    }

    // 如果没有邀请码，创建一个
    if (codes.isEmpty) {
      try {
        await _inviteCodeService.generateInviteCode(token);
        // 创建后重新获取
        codes = await _inviteCodeService.fetchInviteCodes(token);
      } catch (e) {
        throw Exception('创建邀请码失败: $e');
      }
    }

    // 如果仍然没有邀请码，抛出异常
    if (codes.isEmpty) {
      throw Exception('无法获取或创建邀请码');
    }

    // 使用第一个邀请码
    final inviteCode = codes.first;
    final inviteLink = _inviteCodeService.getInviteLink(inviteCode.code);

    return {
      'code': inviteCode.code,
      'link': inviteLink,
    };
  }
}
