import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../preferences/new_ui_preferences.dart';

/// 新界面切换开关组件
///
/// 这个组件可以添加到设置页面，用于切换新旧界面
class NewUIToggle extends ConsumerWidget {
  const NewUIToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useNewUI = ref.watch(useNewUIProvider);
    final notifier = ref.watch(useNewUIProvider.notifier);

    return SwitchListTile(
      title: const Text('使用新界面'),
      subtitle: const Text('切换到新设计的用户界面'),
      value: useNewUI,
      onChanged: (value) => notifier.set(value),
    );
  }
}
