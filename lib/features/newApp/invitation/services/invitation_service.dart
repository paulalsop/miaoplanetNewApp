import 'package:shared_preferences/shared_preferences.dart';

/// 邀请码服务类
class InvitationService {
  // 单例模式
  static final InvitationService instance = InvitationService._internal();
  InvitationService._internal();

  // 模拟的邀请码和邀请链接
  // 在实际应用中，这些应该从服务器获取
  static const String _defaultInvitationCode = 'HIDDIFY2024';
  static const String _defaultInvitationLink = 'https://hiddify.com/invite/HIDDIFY2024';

  // SharedPreferences键名
  static const String _invitationCodeKey = 'invitation_code';
  static const String _invitationLinkKey = 'invitation_link';

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

  /// 刷新邀请码和邀请链接（在实际应用中，应该从服务器获取）
  Future<Map<String, String>> refreshInvitationData() async {
    // TODO: 从服务器获取最新的邀请码和邀请链接
    // 这里模拟从服务器获取数据
    await Future.delayed(const Duration(milliseconds: 500));

    final code = await getInvitationCode();
    final link = await getInvitationLink();

    return {
      'code': code,
      'link': link,
    };
  }
}
