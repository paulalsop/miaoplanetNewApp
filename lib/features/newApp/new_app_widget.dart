import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/newApp/new_app.dart';

/// 新应用程序入口包装组件
///
/// 这个组件用于在现有应用程序中加载新的界面设计
/// 可以通过条件判断来决定是显示旧界面还是新界面
class NewAppWidget extends ConsumerWidget {
  const NewAppWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这里可以加入逻辑来决定是否显示新界面
    // 例如可以从设置中读取一个标志，或者使用Provider提供的状态

    return const NewApp();
  }
}
