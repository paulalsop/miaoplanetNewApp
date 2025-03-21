import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 认证服务 - 管理登录状态和token
class AuthService {
  /// 私有构造函数，防止外部实例化
  AuthService._();

  /// 单例实例
  static final AuthService instance = AuthService._();

  /// token存储的键
  static const String _tokenKey = 'auth_token';

  /// 默认测试token值
  static const String _defaultToken = 'test_token_123456';

  /// 是否已初始化
  bool _initialized = false;

  /// 当前token
  String? _token;

  /// 获取当前token
  String? get token => _token;

  /// 判断用户是否已登录
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 初始化服务
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _initialized = true;
      debugPrint('认证服务初始化完成，当前登录状态：${isLoggedIn ? '已登录' : '未登录'}');
    } catch (e) {
      debugPrint('认证服务初始化失败: $e');
      _initialized = true; // 即使失败也标记为已初始化，避免重复尝试
    }
  }

  /// 设置默认测试token (仅用于开发测试)
  Future<void> setDefaultToken() async {
    await setToken(_defaultToken);
    debugPrint('已设置默认测试token: $_defaultToken');
  }

  /// 设置token
  Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      _token = token;
      debugPrint('token已设置');
    } catch (e) {
      debugPrint('设置token失败: $e');
    }
  }

  /// 清除token (用于退出登录)
  Future<void> clearToken() async {
    try {
      debugPrint('【AuthService】开始清除token...');

      final prefs = await SharedPreferences.getInstance();
      final tokenBeforeClear = prefs.getString(_tokenKey);
      debugPrint('【AuthService】清除前的token: $tokenBeforeClear');

      await prefs.remove(_tokenKey);
      final tokenAfterClear = prefs.getString(_tokenKey);

      _token = null;
      debugPrint('【AuthService】token已从SharedPreferences清除，清除后的token: $tokenAfterClear');
      debugPrint('【AuthService】内存中的_token已设为null，用户已登出');
    } catch (e) {
      debugPrint('【AuthService】清除token失败: $e');
      // 即使SharedPreferences操作失败，也要确保内存中的token被清除
      _token = null;
      debugPrint('【AuthService】尽管出错，内存中的_token已设为null');
    }
  }

  /// 验证token (模拟验证过程)
  ///
  /// 返回true表示token有效，false表示token无效
  Future<bool> validateToken() async {
    debugPrint('【AuthService】开始验证token: $_token');
    if (!isLoggedIn) {
      debugPrint('【AuthService】未登录状态，token无效');
      return false;
    }

    // 这里应该是实际的token验证逻辑，例如调用后端API
    // 目前仅简单模拟，假设任何非空token都有效
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
    debugPrint('【AuthService】token验证完成，结果: 有效');
    return true;
  }

  /// 登录 (设置token并返回成功标志)
  Future<bool> login(String username, String password) async {
    // 这里应该是实际的登录逻辑，例如调用后端API获取token
    // 目前仅简单模拟，假设任何非空用户名和密码都能登录成功
    if (username.isEmpty || password.isEmpty) return false;

    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟

    // 生成一个简单的token (实际应用中应该由后端生成)
    final token = 'user_${username}_${DateTime.now().millisecondsSinceEpoch}';
    await setToken(token);
    return true;
  }

  /// 退出登录
  Future<void> logout() async {
    debugPrint('【AuthService】logout方法被调用');
    await clearToken();
    debugPrint('【AuthService】logout完成，token已清除');
  }
}
