import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/membership_type.dart';

/// 订阅提交按钮组件
class SubscriptionButton extends StatelessWidget {
  /// 构造函数
  const SubscriptionButton({
    super.key,
    required this.onTap,
    required this.membershipType,
  });

  /// 点击回调
  final VoidCallback? onTap;

  /// 会员类型
  final MembershipType membershipType;

  @override
  Widget build(BuildContext context) {
    final backgroundImage = membershipType == MembershipType.ordinary
        ? NewAppAssets.ordinaryMemberStartButton
        : NewAppAssets.shareholderMemberStartButton;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              '立即开通',
              style: TextStyle(
                color: membershipType == MembershipType.ordinary
                    ? Colors.white
                    : Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
