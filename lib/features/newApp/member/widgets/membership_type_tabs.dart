import 'package:flutter/material.dart';
import '../models/membership_type.dart';

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
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTab(
            '会员',
            selectedType == MembershipType.ordinary,
            () => onTypeChanged(MembershipType.ordinary),
          ),
          _buildTab(
            '股东',
            selectedType == MembershipType.shareholder,
            () => onTypeChanged(MembershipType.shareholder),
          ),
        ],
      ),
    );
  }

  /// 构建标签
  Widget _buildTab(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(isSelected ? 1 : 0.5),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
