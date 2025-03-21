import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/membership_model.dart';

/// 会员套餐选择项组件
class MembershipPlanItem extends StatelessWidget {
  /// 构造函数
  const MembershipPlanItem({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
    required this.membershipType,
  });

  /// 套餐数据
  final MembershipPlan plan;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback onTap;

  /// 会员类型
  final MembershipType membershipType;

  @override
  Widget build(BuildContext context) {
    // 根据会员类型和选中状态确定背景和图标
    final String backgroundImage;
    final String selectionIcon;

    // 根据会员类型和选中状态确定文字颜色
    final Color textColor;

    if (membershipType == MembershipType.ordinary) {
      backgroundImage = isSelected ? NewAppAssets.ordinaryMemberButtonGreen : NewAppAssets.ordinaryMemberButtonWhite;
      selectionIcon = isSelected ? NewAppAssets.ordinaryMemberSelectIcon : NewAppAssets.ordinaryMemberNormalIcon;
      textColor = isSelected ? Colors.white : Colors.black87;
    } else {
      // 股东会员使用蓝色按钮
      backgroundImage = NewAppAssets.shareholderMemberButtonGreen;
      selectionIcon = NewAppAssets.shareholderMemberSelectIcon;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        height: membershipType == MembershipType.shareholder ? 90 : 80,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 套餐名称
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                plan.name,
                style: TextStyle(
                  color: textColor,
                  fontSize: membershipType == MembershipType.shareholder ? 22 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),

            // 套餐价格
            if (membershipType == MembershipType.shareholder)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${plan.price}${plan.currency}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "/Life member",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  plan.monthlyPrice,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ),

            // 选择指示器
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Image.asset(
                selectionIcon,
                width: 24,
                height: 24,
                color: membershipType == MembershipType.shareholder || isSelected ? null : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
