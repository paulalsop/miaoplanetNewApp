import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../models/auth_model.dart';

/// 通用的认证输入框组件
class AuthInputField extends StatefulWidget {
  /// 构造函数
  const AuthInputField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.iconPath,
    this.obscureText = false,
    this.eyeIconPath,
    this.validator,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  }) : super(key: key);

  /// 文本控制器
  final TextEditingController controller;

  /// 提示文本
  final String hintText;

  /// 图标路径
  final String iconPath;

  /// 是否是密码输入框
  final bool obscureText;

  /// 眼睛图标路径（用于切换密码显示/隐藏）
  final String? eyeIconPath;

  /// 验证器
  final ValidationResult? Function(String)? validator;

  /// 最大长度
  final int? maxLength;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 输入操作
  final TextInputAction? textInputAction;

  /// 提交回调
  final Function(String)? onSubmitted;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _isPasswordVisible = false;
  ValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    if (widget.validator != null) {
      setState(() {
        _validationResult = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(NewAppAssets.loginInputBackground),
              fit: BoxFit.fill,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureText && !_isPasswordVisible,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              counterText: '',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  widget.iconPath,
                  width: 20,
                  height: 20,
                ),
              ),
              suffixIcon: widget.obscureText && widget.eyeIconPath != null
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          widget.eyeIconPath!,
                          width: 20,
                          height: 20,
                          color: _isPasswordVisible ? Colors.blue : Colors.grey,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (_validationResult != null && !_validationResult!.isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              _validationResult!.errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
