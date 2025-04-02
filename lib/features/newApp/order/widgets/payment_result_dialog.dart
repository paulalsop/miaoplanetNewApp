import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

class PaymentResultDialog extends StatelessWidget {
  const PaymentResultDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onViewOrder,
    this.onBack,
  });

  final String title;
  final String message;
  final String icon;
  final VoidCallback? onViewOrder;
  final VoidCallback? onBack;

  static Future<void> showSuccess(
    BuildContext context, {
    VoidCallback? onViewOrder,
    VoidCallback? onBack,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentResultDialog(
        title: '已完成',
        message: '订单已支付并开通',
        icon: NewAppAssets.orderCompletedIcon,
        onViewOrder: onViewOrder,
        onBack: onBack,
      ),
    );
  }

  static Future<void> showCancelled(
    BuildContext context, {
    VoidCallback? onBack,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentResultDialog(
        title: '已取消',
        message: '订单由于超时支付已被取消',
        icon: NewAppAssets.orderCancelledIcon,
        onBack: onBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.orderPayDialogBg),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Image.asset(
              icon,
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      text: '返回',
                      onPressed: () {
                        Navigator.of(context).pop();
                        onBack?.call();
                      },
                      bgAsset: NewAppAssets.orderBackButton,
                    ),
                  ),
                  if (onViewOrder != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildButton(
                        text: '查看订单',
                        onPressed: () {
                          Navigator.of(context).pop();
                          onViewOrder?.call();
                        },
                        bgAsset: NewAppAssets.orderLookButton,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required String bgAsset,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgAsset),
          fit: BoxFit.cover,
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
