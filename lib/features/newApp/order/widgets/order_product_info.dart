import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../../core/constants/app_assets.dart';

class OrderProductInfo extends StatelessWidget {
  const OrderProductInfo({
    super.key,
    required this.order,
  });

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(NewAppAssets.orderProductBg),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '商品信息',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('产品名称：', order.productName),
          const SizedBox(height: 8),
          _buildInfoRow('支付金额：', '${order.amount} ${order.currencySymbol}'),
          const SizedBox(height: 8),
          _buildInfoRow('类型/周期：', order.type),
          const SizedBox(height: 8),
          _buildInfoRow('产品流量：', order.traffic),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
