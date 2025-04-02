import 'package:flutter/material.dart';
import 'screens/membership_page.dart';
import 'models/membership_type.dart';

/// 会员页面路由类
class MemberRoutes {
  /// 私有构造函数，防止实例化
  MemberRoutes._();

  /// 打开会员页面
  static Future<void> openMembershipPage(
    BuildContext context, {
    MembershipType initialType = MembershipType.ordinary,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MembershipPage(
          initialType: initialType,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
