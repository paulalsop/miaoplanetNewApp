import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 控制是否启用新界面的首选项提供者
final useNewUIProvider = StateNotifierProvider<UseNewUINotifier, bool>((ref) {
  return UseNewUINotifier(ref);
});

/// 新界面启用状态管理
class UseNewUINotifier extends StateNotifier<bool> {
  static const _useNewUIKey = 'use_new_ui';
  final Ref _ref;

  UseNewUINotifier(this._ref) : super(false) {
    _loadFromPrefs();
  }

  /// 切换新界面设置
  Future<void> toggle() async {
    state = !state;
    await _saveToPrefs(state);
  }

  /// 设置是否使用新界面
  Future<void> set(bool value) async {
    state = value;
    await _saveToPrefs(value);
  }

  /// 从首选项中加载设置
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_useNewUIKey) ?? false;
    } catch (e) {
      state = false;
    }
  }

  /// 保存设置到首选项
  Future<void> _saveToPrefs(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useNewUIKey, value);
    } catch (e) {
      // 处理错误
    }
  }
}
