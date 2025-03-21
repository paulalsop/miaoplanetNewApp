import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/membership_model.dart';

/// 订阅提交按钮组件
class SubscriptionButton extends StatelessWidget {
  /// 构造函数
  const SubscriptionButton({
    super.key,
    required this.onTap,
    required this.membershipType,
  });

  /// 点击回调
  final VoidCallback onTap;

  /// 会员类型
  final MembershipType membershipType;

  @override
  Widget build(BuildContext context) {
    final String backgroundImage = membershipType == MembershipType.ordinary ? NewAppAssets.ordinaryMemberStartButton : NewAppAssets.shareholderMemberStartButton;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Start Subscriptions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
