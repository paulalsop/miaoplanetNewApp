import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/routes/app_routes.dart';
import '../services/auth_service.dart';

/// 登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 处理登录逻辑
  Future<void> _handleLogin() async {
    // 隐藏键盘
    FocusScope.of(context).unfocus();

    // 获取输入
    final email = _accountController.text.trim();
    final password = _passwordController.text.trim();

    // 输入验证
    if (email.isEmpty) {
      _showError('请输入账号');
      return;
    }

    if (password.isEmpty) {
      _showError('请输入密码');
      return;
    }

    // 设置加载状态
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用登录方法
      final success = await AuthService.instance.login(email, password);

      // 处理登录结果
      if (success) {
        // 登录成功，导航到主页
        if (mounted) {
          NewAppRoutes.navigateAndRemoveUntil(context, NewAppRoutes.home);
        }
      } else {
        // 登录失败
        if (mounted) {
          _showError('账号或密码错误，请重试');
        }
      }
    } catch (e) {
      // 发生异常
      if (mounted) {
        _showError('登录失败: $e');
      }
    } finally {
      // 恢复状态
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时页面溢出
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.loginBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 关闭按钮
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    // 导航到首页并清除所有其他页面
                    NewAppRoutes.navigateAndRemoveUntil(context, NewAppRoutes.home);
                  },
                  child: Image.asset(
                    NewAppAssets.loginCloseIcon,
                    width: 32,
                    height: 32,
                  ),
                ),
              ),

              // 主要内容
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 欢迎文本
                    const Text(
                      'Welcome\nBack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 账号输入框
                    _buildInputField(
                      controller: _accountController,
                      hintText: '输入账号（8-20位字符）',
                      icon: NewAppAssets.loginAccountIcon,
                    ),
                    const SizedBox(height: 16),

                    // 密码输入框
                    _buildInputField(
                      controller: _passwordController,
                      hintText: '输入密码（8-20位字符）',
                      icon: NewAppAssets.loginPasswordIcon,
                      isPassword: true,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            NewAppAssets.loginEyeIcon,
                            width: 24,
                            height: 24,
                            color: _isPasswordVisible ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 底部按钮区域
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: 处理忘记密码
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // 导航到注册页面
                            NewAppRoutes.navigateTo(context, NewAppRoutes.register);
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // 登录按钮
                    Container(
                      width: double.infinity,
                      height: 50,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B5FF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Text(
                              '登录',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required String icon,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(NewAppAssets.loginInputBackground),
          fit: BoxFit.fill,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              icon,
              width: 24,
              height: 24,
            ),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
