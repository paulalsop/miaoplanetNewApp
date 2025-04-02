import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

// 修改为动态支付方式类型
class PaymentMethod {
  final int id;
  final String name;
  final String icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class OrderPaymentMethod extends StatelessWidget {
  const OrderPaymentMethod({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.paymentMethods,
  });

  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final List<Map<String, dynamic>> paymentMethods;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支付方式',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentMethods.map((method) {
            final paymentMethod = PaymentMethod(
              id: method['id'] as int,
              name: method['name'] as String,
              icon: method['icon'] as String,
            );

            return Column(
              children: [
                _buildPaymentOption(
                  method: paymentMethod,
                  isSelected: selectedMethod.id == paymentMethod.id,
                ),
                if (method != paymentMethods.last) const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onMethodChanged(method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Image.network(
              method.icon,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                // 如果网络图片加载失败，显示默认图标
                return const Icon(
                  Icons.payment,
                  color: Colors.white,
                  size: 24,
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              method.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Image.asset(
              isSelected
                  ? NewAppAssets.paySelectedIcon
                  : NewAppAssets.payUnselectedIcon,
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
