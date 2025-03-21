import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../models/membership_model.dart';

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
    final String title = membershipType == MembershipType.ordinary ? 'Unlock\nexclusive\nprivileges:' : '30,000\nMiao Coin\nshareholders:';

    final List<String> privileges = membershipType == MembershipType.ordinary
        ? [
            '高速专属服务器：访问专属VPN节点，速度提升高达10倍！',
            '优先稳定连接：即使高峰期也畅通无阻',
          ]
        : [
            '终身免费使用Miao星球VPN，畅享全球高速网络加速服务',
            '持续加权分红利益，股东收益稳步提升',
            '享受Miao币生态发展带来的长期分红回报',
            '优先参与Miao星球后续项目、社区治理及生态建设',
          ];

    final String badgeImage = membershipType == MembershipType.ordinary ? NewAppAssets.ordinaryMemberBadge : NewAppAssets.shareholderMemberBadge;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, membershipType == MembershipType.shareholder ? 10 : 20, 24, membershipType == MembershipType.shareholder ? 20 : 30),
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
                    fontSize: membershipType == MembershipType.shareholder ? 40 : 36,
                    fontWeight: FontWeight.bold,
                    height: membershipType == MembershipType.shareholder ? 1.0 : 1.1,
                    letterSpacing: membershipType == MembershipType.shareholder ? -0.5 : 0,
                  ),
                ),
                SizedBox(height: membershipType == MembershipType.shareholder ? 18 : 24),

                // 特权描述列表
                ...privileges.map((privilege) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        privilege,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: membershipType == MembershipType.shareholder ? 1.3 : 1.2,
                        ),
                      ),
                    )),
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
