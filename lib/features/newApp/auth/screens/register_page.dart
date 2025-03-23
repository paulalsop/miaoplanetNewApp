import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../core/constants/app_assets.dart';
import '../../core/routes/app_routes.dart';
import '../models/auth_model.dart';
import '../widgets/auth_input_field.dart';
import '../services/auth_service.dart';

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
    final emailCodeController = useTextEditingController();

    // 系统配置状态
    final isConfigLoading = useState(true);
    final isEmailVerifyEnabled = useState(false);
    final isInviteForceEnabled = useState(false);
    final isRecaptchaEnabled = useState(false);

    // 倒计时状态
    final countdownSeconds = useState(0);
    final canSendCode = useState(true);

    // 表单是否有效
    final isFormValid = useState(false);

    // 是否正在提交
    final isSubmitting = useState(false);

    // 初始化配置
    useEffect(() {
      // 加载系统配置
      Future<void> loadConfig() async {
        try {
          final config = await AuthService.instance.getSystemConfig();
          isEmailVerifyEnabled.value = config['is_email_verify'] == 1;
          isInviteForceEnabled.value = config['is_invite_force'] == 1;
          isRecaptchaEnabled.value = config['is_recaptcha'] == 1;
          debugPrint(
              '【RegisterPage】系统配置加载完成: 邮箱验证=${isEmailVerifyEnabled.value}, 强制邀请码=${isInviteForceEnabled.value}, 图形验证码=${isRecaptchaEnabled.value}');
        } catch (e) {
          debugPrint('【RegisterPage】加载系统配置失败: $e');
          // 默认设置
          isEmailVerifyEnabled.value = true;
          isInviteForceEnabled.value = false;
          isRecaptchaEnabled.value = false;
        } finally {
          isConfigLoading.value = false;
        }
      }

      loadConfig();
      return null;
    }, []);

    // 开始倒计时
    void startCountdown() {
      countdownSeconds.value = 60;
      canSendCode.value = false;

      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdownSeconds.value > 0) {
          countdownSeconds.value--;
        } else {
          canSendCode.value = true;
          timer.cancel();
        }
      });
    }

    // 发送验证码
    Future<void> sendVerificationCode() async {
      if (!canSendCode.value) return;

      final email = usernameController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先输入邮箱'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 邮箱格式验证
      final emailValidation = AuthValidator.validateEmail(email);
      if (!emailValidation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailValidation.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final success =
            await AuthService.instance.sendEmailVerificationCode(email);

        // 关闭加载指示器
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (success) {
          // 开始倒计时
          startCountdown();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('验证码已发送，请查收邮件')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('验证码发送失败，请稍后重试'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // 关闭加载指示器
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('验证码发送出错: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // 验证表单
    void validateForm() {
      final isUsernameValid =
          AuthValidator.validateEmail(usernameController.text).isValid;
      final isPasswordValid =
          AuthValidator.validatePassword(passwordController.text).isValid;
      final isConfirmPasswordValid = AuthValidator.validateConfirmPassword(
        passwordController.text,
        confirmPasswordController.text,
      ).isValid;

      // 邀请码检查：如果强制邀请码或者用户填写了邀请码，则验证
      final isInviteCodeValid = !isInviteForceEnabled.value ||
          AuthValidator.validateInviteCode(inviteCodeController.text).isValid;

      // 邮箱验证码检查：如果需要邮箱验证，则验证码不能为空
      final isEmailCodeValid = !isEmailVerifyEnabled.value ||
          AuthValidator.validateVerificationCode(emailCodeController.text)
              .isValid;

      isFormValid.value = isUsernameValid &&
          isPasswordValid &&
          isConfirmPasswordValid &&
          isInviteCodeValid &&
          isEmailCodeValid;
    }

    // 处理注册
    Future<void> handleRegister() async {
      if (isSubmitting.value) return;

      // 设置为提交状态
      isSubmitting.value = true;

      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // 调用AuthService进行注册
        final emailCode =
            isEmailVerifyEnabled.value ? emailCodeController.text.trim() : "";
        final inviteCode = isInviteForceEnabled.value
            ? inviteCodeController.text.trim()
            : inviteCodeController.text.trim(); // 非强制但用户填写了也要发送

        debugPrint('【RegisterPage】开始注册...');
        debugPrint('【RegisterPage】邮箱: ${usernameController.text.trim()}');
        debugPrint('【RegisterPage】密码: ${passwordController.text.trim()}');
        debugPrint('【RegisterPage】邀请码: $inviteCode');
        debugPrint('【RegisterPage】邮箱验证码: $emailCode');

        final success = await AuthService.instance.register(
          usernameController.text.trim(),
          passwordController.text.trim(),
          inviteCode,
          emailCode: emailCode,
        );

        // 关闭加载指示器
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (success) {
          // 注册成功，显示成功消息并返回登录页面
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('注册成功，请登录')),
            );
            Navigator.of(context).pop();
          }
        } else {
          // 注册失败
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('注册失败，请检查账号、邀请码或验证码是否正确'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // 关闭加载指示器
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // 显示错误提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('注册失败: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // 恢复状态
        isSubmitting.value = false;
      }
    }

    // 如果配置正在加载，显示加载界面
    if (isConfigLoading.value) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(NewAppAssets.registerBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
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

                      // 用户名输入框 (邮箱)
                      AuthInputField(
                        controller: usernameController,
                        hintText: '输入邮箱',
                        iconPath: NewAppAssets.registerAccountIcon,
                        validator: (value) {
                          validateForm();
                          return AuthValidator.validateEmail(value);
                        },
                        maxLength: 50,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 密码输入框
                      AuthInputField(
                        controller: passwordController,
                        hintText: '输入密码 (8-20位字符)',
                        iconPath: NewAppAssets.registerPasswordIcon,
                        obscureText: true,
                        eyeIconPath: NewAppAssets.loginPasswordVisibleIcon,
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
                        iconPath: NewAppAssets.registerPasswordIcon,
                        obscureText: true,
                        eyeIconPath: NewAppAssets.loginPasswordVisibleIcon,
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

                      // 邮箱验证码输入框 (如果需要邮箱验证)
                      if (isEmailVerifyEnabled.value)
                        Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: AuthInputField(
                                controller: emailCodeController,
                                hintText: '输入邮箱验证码',
                                iconPath: NewAppAssets.registerShieldIcon,
                                validator: (value) {
                                  validateForm();
                                  return AuthValidator.validateVerificationCode(
                                      value);
                                },
                                maxLength: 6,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: canSendCode.value
                                    ? sendVerificationCode
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B5FF5),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  canSendCode.value
                                      ? '发送验证码'
                                      : '${countdownSeconds.value}秒',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (isEmailVerifyEnabled.value)
                        const SizedBox(height: 16),

                      // 邀请码输入框（如果需要或强制）
                      AuthInputField(
                        controller: inviteCodeController,
                        hintText: isInviteForceEnabled.value
                            ? '输入邀请码（必填）'
                            : '输入邀请码（选填）',
                        iconPath: NewAppAssets.registerShieldIcon,
                        validator: (value) {
                          validateForm();
                          return isInviteForceEnabled.value
                              ? AuthValidator.validateInviteCode(value)
                              : ValidationResult.success(); // 非强制时总是有效
                        },
                        maxLength: 20,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) {
                          if (isFormValid.value && !isSubmitting.value) {
                            handleRegister();
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // 注册按钮
                      GestureDetector(
                        onTap: (isFormValid.value && !isSubmitting.value)
                            ? handleRegister
                            : null,
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
                            child: isSubmitting.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text(
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
