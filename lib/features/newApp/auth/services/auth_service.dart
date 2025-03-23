import 'package:flutter/material.dart';
import '../../../panel/xboard/utils/storage/token_storage.dart' as token_storage;
import '../../../panel/xboard/services/http_service/user_service.dart';
import '../../../panel/xboard/services/http_service/auth_service.dart' as xboard_auth;
import '../../../panel/xboard/services/http_service/http_service.dart';

/// 认证服务 - 管理登录状态和token
class AuthService {
  /// 私有构造函数，防止外部实例化
  AuthService._();

  /// 单例实例
  static final AuthService instance = AuthService._();

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
      // 从token_storage获取token
      _token = await token_storage.getToken();
      _initialized = true;
      debugPrint('认证服务初始化完成，当前登录状态：${isLoggedIn ? '已登录' : '未登录'}');
    } catch (e) {
      debugPrint('认证服务初始化失败: $e');
      _initialized = true; // 即使失败也标记为已初始化，避免重复尝试
    }
  }

  /// 设置token
  Future<void> setToken(String token) async {
    try {
      // 使用token_storage存储token
      await token_storage.storeToken(token);
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

      // 使用token_storage删除token
      await token_storage.deleteToken();
      _token = null;
      debugPrint('【AuthService】token已清除，用户已登出');
    } catch (e) {
      debugPrint('【AuthService】清除token失败: $e');
      // 即使删除操作失败，也要确保内存中的token被清除
      _token = null;
      debugPrint('【AuthService】尽管出错，内存中的_token已设为null');
    }
  }

  /// 验证token
  ///
  /// 返回true表示token有效，false表示token无效
  Future<bool> validateToken() async {
    debugPrint('【AuthService】开始验证token: $_token');
    if (!isLoggedIn) {
      debugPrint('【AuthService】未登录状态，token无效');
      return false;
    }

    try {
      // 使用UserService验证token
      final userService = UserService();
      final isValid = await userService.validateToken(_token!);
      
      debugPrint('【AuthService】token验证完成，结果: ${isValid ? '有效' : '无效'}');
      return isValid;
    } catch (e) {
      debugPrint('【AuthService】token验证出错: $e');
      return false;
    }
  }

  /// 登录 (设置token并返回成功标志)
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return false;
    
    try {
      debugPrint('【AuthService】开始登录流程');
      
      // 使用xboard的AuthService进行登录
      final authService = xboard_auth.AuthService();
      final result = await authService.login(email, password);
      
      if (result['status'] == 'success' && result.containsKey('data')) {
        // 从响应中提取auth_data
        final data = result['data'] as Map<String, dynamic>;
        
        // 获取auth_data作为认证令牌
        final authData = data['auth_data'] as String;
        
        // 存储auth_data作为token
        await setToken(authData);
        debugPrint('【AuthService】登录成功，auth_data已保存');
        return true;
      } else {
        debugPrint('【AuthService】登录失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('【AuthService】登录出错: $e');
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    debugPrint('【AuthService】logout方法被调用');
    await clearToken();
    debugPrint('【AuthService】logout完成，token已清除');
  }

  /// 获取系统配置
  Future<Map<String, dynamic>> getSystemConfig() async {
    try {
      // 使用xboard的AuthService获取系统配置
      final authService = xboard_auth.AuthService();
      final result = await authService.getSystemConfig();
      
      if (result['status'] == 'success' && result.containsKey('data')) {
        return result['data'] as Map<String, dynamic>;
      } else {
        debugPrint('【AuthService】获取系统配置失败: ${result['message']}');
        return {};
      }
    } catch (e) {
      debugPrint('【AuthService】获取系统配置出错: $e');
      return {};
    }
  }

  /// 发送邮箱验证码
  Future<bool> sendEmailVerificationCode(String email) async {
    if (email.isEmpty) return false;
    
    try {
      debugPrint('【AuthService】开始发送邮箱验证码');
      
      final authService = xboard_auth.AuthService();
      final result = await authService.sendVerificationCode(email);
      
      if (result['status'] == 'success') {
        debugPrint('【AuthService】邮箱验证码发送成功');
        return true;
      } else {
        debugPrint('【AuthService】邮箱验证码发送失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('【AuthService】邮箱验证码发送出错: $e');
      return false;
    }
  }

  /// 注册新用户 (增加邮箱验证码参数)
  Future<bool> register(String username, String password, String inviteCode, {String emailCode = ""}) async {
    if (username.isEmpty || password.isEmpty) return false;
    
    try {
      debugPrint('【AuthService】开始注册流程');
      
      // 使用xboard的AuthService进行注册
      final authService = xboard_auth.AuthService();
      
      final result = await authService.register(
        username, // 用作email
        password,
        inviteCode,
        emailCode,
      );
      
      if (result['status'] == 'success') {
        debugPrint('【AuthService】注册成功');
        
        // 如果注册后返回了token信息，可以直接登录
        if (result.containsKey('data') && 
            result['data'] is Map<String, dynamic> && 
            (result['data'] as Map<String, dynamic>).containsKey('auth_data')) {
          final data = result['data'] as Map<String, dynamic>;
          final authData = data['auth_data'] as String;
          
          // 存储auth_data作为token
          await setToken(authData);
          debugPrint('【AuthService】注册后自动登录成功');
        }
        
        return true;
      } else {
        debugPrint('【AuthService】注册失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('【AuthService】注册出错: $e');
      return false;
    }
  }
}
