import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart'
    as xboard_auth;

/// 重置密码页面
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verifyCodeController = TextEditingController();

  bool _isLoading = false;
  bool _sendingCode = false;
  String _errorMessage = '';
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // 验证码倒计时相关
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  final xboard_auth.AuthService _authService = xboard_auth.AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verifyCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    // 邮箱格式验证
    if (email.isEmpty) {
      setState(() {
        _errorMessage = '请输入邮箱地址';
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = '请输入有效的邮箱地址';
      });
      return;
    }

    try {
      setState(() {
        _sendingCode = true;
        _errorMessage = '';
      });

      final result = await _authService.sendVerificationCode(email);

      if (result['status'] == 'success') {
        // 开始倒计时
        setState(() {
          _countdownSeconds = 60;
          _sendingCode = false;
        });

        _startCountdown();

        // 显示发送成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('验证码已发送，请查收邮箱')),
          );
        }
      } else {
        setState(() {
          _sendingCode = false;
          _errorMessage = result['message'] as String? ?? '发送验证码失败';
        });
      }
    } catch (e) {
      setState(() {
        _sendingCode = false;
        _errorMessage = '发送验证码失败: $e';
      });
    }
  }

  // 开始倒计时
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  // 重置密码
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final verifyCode = _verifyCodeController.text.trim();

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result =
          await _authService.resetPassword(email, password, verifyCode);

      setState(() {
        _isLoading = false;
      });

      if (result['status'] == 'success') {
        // 重置密码成功
        if (mounted) {
          // 显示成功对话框
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('密码重置成功'),
              content: const Text('您的密码已成功重置，请使用新密码登录。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 关闭对话框
                    Navigator.pop(context); // 关闭重置密码页面
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] as String? ?? '重置密码失败';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '重置密码失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 标题和关闭按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '重置密码',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 错误信息显示
                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 邮箱输入框
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '邮箱',
                        hintText: '请输入您的账号邮箱',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // 验证码行
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 验证码输入框
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _verifyCodeController,
                            decoration: InputDecoration(
                              labelText: '验证码',
                              hintText: '请输入验证码',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.security),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入验证码';
                              }
                              if (value.length < 6) {
                                return '验证码为6位数字';
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 发送验证码按钮
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 56, // 匹配输入框高度
                            child: ElevatedButton(
                              onPressed: (_sendingCode ||
                                      _countdownSeconds > 0 ||
                                      _isLoading)
                                  ? null
                                  : _sendVerificationCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _sendingCode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _countdownSeconds > 0
                                          ? '${_countdownSeconds}s'
                                          : '发送',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 密码输入框
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: '新密码',
                        hintText: '请输入新密码',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入新密码';
                        }
                        if (value.length < 6) {
                          return '密码长度不能少于6位';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // 确认密码输入框
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: '确认密码',
                        hintText: '请再次输入新密码',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请确认新密码';
                        }
                        if (value != _passwordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),

                    // 重置密码按钮
                    SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22.5),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '重置密码',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
