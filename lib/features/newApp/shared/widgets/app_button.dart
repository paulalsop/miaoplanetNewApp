import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 应用按钮类型
enum AppButtonType {
  primary,
  secondary,
  outline,
  text,
}

/// 应用按钮大小
enum AppButtonSize {
  small,
  medium,
  large,
}

/// 自定义应用按钮
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool iconLeading;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AppButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconLeading = true,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根据按钮类型确定颜色
    final (Color bgColor, Color textColor) = _getColorsByType(theme);

    // 根据按钮大小确定尺寸和内边距
    final (double height, EdgeInsetsGeometry padding) = _getSizeProps();

    // 构建按钮内容
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buildButtonContent(textColor),
    );

    // 如果是全宽按钮，调整样式
    if (isFullWidth) {
      buttonContent = SizedBox(
        width: double.infinity,
        child: Center(child: buttonContent),
      );
    }

    // 根据按钮类型创建不同样式的按钮
    Widget button;
    switch (type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            minimumSize: Size(width ?? 0, this.height ?? height),
            padding: this.padding ?? padding,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(NewAppTheme.borderRadius),
            ),
            elevation: 0,
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            minimumSize: Size(width ?? 0, this.height ?? height),
            padding: this.padding ?? padding,
            side: BorderSide(color: bgColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(NewAppTheme.borderRadius),
            ),
          ),
          child: buttonContent,
        );
        break;
      case AppButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: bgColor,
            minimumSize: Size(width ?? 0, this.height ?? height),
            padding: this.padding ?? padding,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(NewAppTheme.borderRadius),
            ),
          ),
          child: buttonContent,
        );
        break;
    }

    return button;
  }

  // 根据按钮类型获取颜色
  (Color, Color) _getColorsByType(ThemeData theme) {
    switch (type) {
      case AppButtonType.primary:
        return (NewAppTheme.primaryColor, Colors.white);
      case AppButtonType.secondary:
        return (NewAppTheme.secondaryColor, Colors.white);
      case AppButtonType.outline:
      case AppButtonType.text:
        return (NewAppTheme.primaryColor, NewAppTheme.primaryColor);
    }
  }

  // 根据按钮大小获取尺寸和内边距
  (double, EdgeInsetsGeometry) _getSizeProps() {
    switch (size) {
      case AppButtonSize.small:
        return (36, const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
      case AppButtonSize.medium:
        return (44, const EdgeInsets.symmetric(horizontal: 16, vertical: 10));
      case AppButtonSize.large:
        return (52, const EdgeInsets.symmetric(horizontal: 24, vertical: 12));
    }
  }

  // 构建按钮内容（图标、文本和加载指示器）
  List<Widget> _buildButtonContent(Color textColor) {
    // 如果正在加载，只显示加载指示器
    if (isLoading) {
      return [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        ),
      ];
    }

    // 构建正常按钮内容
    final List<Widget> content = [];

    // 如果有图标且图标在前
    if (icon != null && iconLeading) {
      content.add(Icon(icon, size: 18));
      content.add(const SizedBox(width: 8));
    }

    // 添加文本标签
    content.add(Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w500),
    ));

    // 如果有图标且图标在后
    if (icon != null && !iconLeading) {
      content.add(const SizedBox(width: 8));
      content.add(Icon(icon, size: 18));
    }

    return content;
  }
}
