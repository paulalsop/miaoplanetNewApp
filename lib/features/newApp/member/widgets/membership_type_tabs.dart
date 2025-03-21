import 'package:flutter/material.dart';
import '../models/membership_model.dart';

/// 会员类型切换标签组件
class MembershipTypeTabs extends StatelessWidget {
  /// 构造函数
  const MembershipTypeTabs({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  /// 当前选中的会员类型
  final MembershipType selectedType;

  /// 类型变化回调
  final ValueChanged<MembershipType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 85),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 普通会员标签
          _buildTab(
            context,
            '会员',
            selectedType == MembershipType.ordinary,
            () => onTypeChanged(MembershipType.ordinary),
          ),

          const SizedBox(width: 10),

          // 中间分隔点
          const Text(
            '·',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 10),

          // 股东会员标签
          _buildTab(
            context,
            '股东',
            selectedType == MembershipType.shareholder,
            () => onTypeChanged(MembershipType.shareholder),
          ),
        ],
      ),
    );
  }

  /// 构建标签
  Widget _buildTab(
    BuildContext context,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          decoration: isSelected ? TextDecoration.underline : TextDecoration.none,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
