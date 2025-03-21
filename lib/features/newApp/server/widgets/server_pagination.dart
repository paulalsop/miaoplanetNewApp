import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// 服务器分页控件
class ServerPagination extends StatelessWidget {
  /// 构造函数
  const ServerPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  /// 当前页码
  final int currentPage;

  /// 总页数
  final int totalPages;

  /// 页码变化回调
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 40,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(NewAppAssets.serverPaginationBg),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 上一页按钮
          _buildPaginationButton(
            icon: NewAppAssets.serverPreviousPageIcon,
            onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),

          // 页码显示
          Text(
            '$currentPage / $totalPages',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          // 下一页按钮
          _buildPaginationButton(
            icon: NewAppAssets.serverNextPageIcon,
            onTap: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  /// 构建分页按钮
  Widget _buildPaginationButton({
    required String icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        icon,
        width: 24,
        height: 24,
        color: onTap == null ? Colors.white.withOpacity(0.5) : Colors.white,
      ),
    );
  }
}
