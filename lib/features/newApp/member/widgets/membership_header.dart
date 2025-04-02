import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/membership_type.dart';

/// 会员信息头部组件
class MembershipHeader extends StatelessWidget {
  /// 构造函数
  const MembershipHeader({
    super.key,
    required this.membershipType,
  });

  /// 会员类型
  final MembershipType membershipType;

  @override
  Widget build(BuildContext context) {
    // 获取对应会员类型的标题、特权描述和徽章图片
    final String title =
        membershipType == MembershipType.ordinary ? '会员特权' : '股东特权';

    final List<String> privileges = membershipType == MembershipType.ordinary
        ? ['不限速', '多设备同时在线']
        : ['无限流量', '不限速', '多设备同时在线', '推荐高额返现', '专属客服'];

    final String badgeImage = membershipType == MembershipType.ordinary
        ? NewAppAssets.ordinaryMemberBadge
        : NewAppAssets.shareholderMemberBadge;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24,
          membershipType == MembershipType.shareholder ? 10 : 20,
          24,
          membershipType == MembershipType.shareholder ? 20 : 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和特权描述
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        membershipType == MembershipType.shareholder ? 40 : 36,
                    fontWeight: FontWeight.bold,
                    height: membershipType == MembershipType.shareholder
                        ? 1.0
                        : 1.1,
                    letterSpacing:
                        membershipType == MembershipType.shareholder ? -0.5 : 0,
                  ),
                ),
                SizedBox(
                    height:
                        membershipType == MembershipType.shareholder ? 18 : 24),

                // 特权描述列表
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: privileges
                      .map((privilege) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              privilege,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                height:
                                    membershipType == MembershipType.shareholder
                                        ? 1.3
                                        : 1.2,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // 会员徽章
          Image.asset(
            badgeImage,
            width: membershipType == MembershipType.shareholder ? 110 : 100,
            height: membershipType == MembershipType.shareholder ? 110 : 100,
          ),
        ],
      ),
    );
  }
}
