import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/environment.dart';

/// 环境提供者包装器
/// 
/// 用于确保environmentProvider在整个应用中被正确覆盖
class EnvironmentProviderWrapper extends StatelessWidget {
  final Widget child;
  final Environment environment;

  const EnvironmentProviderWrapper({
    Key? key,
    required this.child,
    required this.environment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        environmentProvider.overrideWithValue(environment),
      ],
      child: child,
    );
  }
} 