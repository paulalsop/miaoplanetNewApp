import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// 服务器套餐卡片组件
class ServerBanner extends StatelessWidget {
  /// 构造函数
  const ServerBanner({
    super.key,
    this.onSubscribe,
  });

  /// 订阅回调
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.serverBanner),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 套餐图标
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Image.asset(
                  NewAppAssets.serverCrownIcon,
                  width: 35,
                  height: 35,
                ),
              ),
            ),

            // 套餐信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 标题
                    const Text(
                      'MIAO VPN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // 描述
                    const Text(
                      'Subcribe our premium membership to access all premium locations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
