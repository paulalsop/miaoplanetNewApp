/// 认证表单类型
enum AuthFormType {
  /// 登录表单
  login,

  /// 注册表单
  register,
}

/// 验证结果
class ValidationResult {
  /// 构造函数
  ValidationResult({
    this.isValid = true,
    this.errorMessage = '',
  });

  /// 是否验证通过
  final bool isValid;

  /// 错误信息
  final String errorMessage;

  /// 创建验证成功的结果
  static ValidationResult success() => ValidationResult();

  /// 创建验证失败的结果
  static ValidationResult error(String message) => ValidationResult(
        isValid: false,
        errorMessage: message,
      );
}

/// 表单验证工具类
class AuthValidator {
  /// 验证邮箱
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult.error('邮箱不能为空');
    }

    // 简单的邮箱格式验证
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.error('请输入有效的邮箱地址');
    }

    return ValidationResult.success();
  }

  /// 验证用户名
  static ValidationResult validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult.error('用户名不能为空');
    }

    if (username.length < 4) {
      return ValidationResult.error('用户名长度不能少于4个字符');
    }

    return ValidationResult.success();
  }

  /// 验证密码
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult.error('密码不能为空');
    }

    if (password.length < 8) {
      return ValidationResult.error('密码长度不能少于8个字符');
    }

    return ValidationResult.success();
  }

  /// 验证确认密码
  static ValidationResult validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return ValidationResult.error('确认密码不能为空');
    }

    if (password != confirmPassword) {
      return ValidationResult.error('两次输入的密码不一致');
    }

    return ValidationResult.success();
  }

  /// 验证邀请码
  static ValidationResult validateInviteCode(String inviteCode) {
    if (inviteCode.isEmpty) {
      return ValidationResult.error('邀请码不能为空');
    }

    return ValidationResult.success();
  }

  /// 验证验证码
  static ValidationResult validateVerificationCode(String code) {
    if (code.isEmpty) {
      return ValidationResult.error('验证码不能为空');
    }

    if (code.length < 4) {
      return ValidationResult.error('验证码长度不正确');
    }

    return ValidationResult.success();
  }
}
