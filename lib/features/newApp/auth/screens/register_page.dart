import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../core/constants/app_assets.dart';
import '../../core/routes/app_routes.dart';
import '../models/auth_model.dart';
import '../widgets/auth_input_field.dart';

/// 注册页面
class RegisterPage extends HookWidget {
  /// 构造函数
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 控制器
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final inviteCodeController = useTextEditingController();

    // 表单是否有效
    final isFormValid = useState(false);

    // 是否需要邀请码
    final needsInviteCode = useState(true);

    // 验证表单
    void validateForm() {
      final isUsernameValid = AuthValidator.validateUsername(usernameController.text).isValid;
      final isPasswordValid = AuthValidator.validatePassword(passwordController.text).isValid;
      final isConfirmPasswordValid = AuthValidator.validateConfirmPassword(
        passwordController.text,
        confirmPasswordController.text,
      ).isValid;

      final isInviteCodeValid = !needsInviteCode.value || AuthValidator.validateInviteCode(inviteCodeController.text).isValid;

      isFormValid.value = isUsernameValid && isPasswordValid && isConfirmPasswordValid && isInviteCodeValid;
    }

    // 处理注册
    Future<void> handleRegister() async {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // 模拟网络请求延迟
        await Future.delayed(const Duration(seconds: 2));

        // 关闭加载指示器
        Navigator.of(context).pop();

        // 注册成功，显示成功消息并返回登录页面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功，请登录')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        // 关闭加载指示器
        Navigator.of(context).pop();

        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注册失败: ${e.toString()}')),
        );
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时页面整体上移
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.registerBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 主要内容
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      const Text(
                        'Create\nAccount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 用户名输入框
                      AuthInputField(
                        controller: usernameController,
                        hintText: '输入账号 (8-20位字符)',
                        iconPath: NewAppAssets.registerAccountIcon,
                        validator: (value) {
                          validateForm();
                          return AuthValidator.validateUsername(value);
                        },
                        maxLength: 20,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 密码输入框
                      AuthInputField(
                        controller: passwordController,
                        hintText: '输入密码 (8-20位字符)',
                        iconPath: NewAppAssets.registerLockIcon,
                        obscureText: true,
                        eyeIconPath: NewAppAssets.loginEyeIcon,
                        validator: (value) {
                          validateForm();
                          return AuthValidator.validatePassword(value);
                        },
                        maxLength: 20,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 确认密码输入框
                      AuthInputField(
                        controller: confirmPasswordController,
                        hintText: '确认密码',
                        iconPath: NewAppAssets.registerLockIcon,
                        obscureText: true,
                        eyeIconPath: NewAppAssets.loginEyeIcon,
                        validator: (value) {
                          validateForm();
                          return AuthValidator.validateConfirmPassword(
                            passwordController.text,
                            value,
                          );
                        },
                        maxLength: 20,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 邀请码输入框（如果需要）
                      if (needsInviteCode.value)
                        AuthInputField(
                          controller: inviteCodeController,
                          hintText: '输入邀请码',
                          iconPath: NewAppAssets.registerShieldIcon,
                          validator: (value) {
                            validateForm();
                            return AuthValidator.validateInviteCode(value);
                          },
                          maxLength: 20,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (value) {
                            if (isFormValid.value) {
                              handleRegister();
                            }
                          },
                        ),

                      const SizedBox(height: 24),

                      // 注册按钮
                      GestureDetector(
                        onTap: isFormValid.value ? handleRegister : null,
                        child: Opacity(
                          opacity: isFormValid.value ? 1.0 : 0.7,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(NewAppAssets.registerButton),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '注册',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
