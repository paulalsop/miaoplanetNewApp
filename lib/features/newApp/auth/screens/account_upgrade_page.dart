import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../panel/xboard/services/http_service/user_service.dart';
import '../services/auth_service.dart';
import '../../core/routes/app_routes.dart';

class AccountUpgradePage extends StatefulWidget {
  const AccountUpgradePage({Key? key}) : super(key: key);

  @override
  _AccountUpgradePageState createState() => _AccountUpgradePageState();
}

class _AccountUpgradePageState extends State<AccountUpgradePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final UserService _userService = UserService(); // 使用xboard中的UserService

  @override
  void initState() {
    super.initState();
    _loadTempAccountInfo();
  }

  Future<void> _loadTempAccountInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final tempEmail = prefs.getString('temp_email');

    if (tempEmail != null) {
      setState(() {
        _emailController.text = tempEmail;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _upgradeAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = AuthService.instance.token;
      if (token == null) {
        _showError('未找到有效的登录信息');
        return;
      }

      // 使用xboard中的UserService进行账号升级
      final result = await _userService.convertTempAccount(
        _emailController.text,
        _passwordController.text,
        token,
      );

      if (result != null) {
        // 更新token
        await AuthService.instance.setToken(result);

        // 清除临时账号标记
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('temp_email');
        await prefs.remove('temp_password');
        await prefs.remove('temp_expired_at');
        await prefs.setBool('is_temp_account', false);

        if (mounted) {
          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('账号升级成功，您现在可以使用新的邮箱和密码登录'),
              duration: Duration(seconds: 3),
            ),
          );
          // 返回主页
          NewAppRoutes.navigateAndRemoveUntil(context, NewAppRoutes.home);
        }
      } else {
        _showError('账号升级失败，请稍后再试');
      }
    } catch (e) {
      // 尝试从错误信息中提取有用的信息
      String errorMessage = '账号升级失败，请稍后再试';

      try {
        String errorString = e.toString();

        // 检查是否包含JSON格式的错误信息
        if (errorString.contains('"status":"fail"')) {
          // 使用正则表达式提取message字段
          RegExp messageRegex = RegExp(r'"message":"([^"]+)"');
          final match = messageRegex.firstMatch(errorString);
          if (match != null && match.groupCount >= 1) {
            String extractedMessage = match.group(1) ?? '';
            if (extractedMessage.isNotEmpty) {
              errorMessage = extractedMessage;
            }
          }
        }

        // 针对服务器返回的具体错误进行处理
        if (errorString.contains('user does not exist') ||
            errorString.contains('The user does not exist')) {
          errorMessage = '用户不存在';
        } else if (errorString.contains('当前账号不是临时账号')) {
          errorMessage = '当前账号不是临时账号，无需转换';
        } else if (errorString.contains('请使用真实的邮箱地址')) {
          errorMessage = '请使用真实的邮箱地址';
        } else if (errorString.contains('账号更新失败')) {
          errorMessage = '账号更新失败，请稍后重试';
        } else if (errorString.contains('该邮箱已被使用') ||
            errorString.contains('email already exists')) {
          errorMessage = '该邮箱已被注册，您可以直接使用该邮箱登录系统';
        } else if (errorString.contains('密码格式不正确')) {
          errorMessage = '密码格式不正确，请至少包含8个字符';
        }

        // 检查是否为HTTP状态码错误
        if (errorString.contains('failed: 400')) {
          // 这里保留提取出的errorMessage，因为前面已经尝试解析了
        } else if (errorString.contains('failed: 500')) {
          errorMessage = '服务器内部错误，请稍后重试';
        } else if (errorString.contains('failed: 401')) {
          errorMessage = '授权已过期，请重新登录';
        } else if (errorString.contains('failed: 403')) {
          errorMessage = '没有权限执行此操作';
        }
      } catch (_) {
        // 如果解析失败，使用默认错误信息
      }

      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('升级为正式账号'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '临时账号升级',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '设置您的电子邮箱和密码，将临时账号升级为正式账号，享受更多功能和更长的使用期限。',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '电子邮箱',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入您的电子邮箱';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return '请输入有效的电子邮箱地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码长度至少为6位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _upgradeAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('升级账号'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
