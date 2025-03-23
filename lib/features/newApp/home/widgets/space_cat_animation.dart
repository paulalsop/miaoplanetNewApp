import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// 太空猫动画组件 - 显示在用户连接VPN后的有趣动画
class SpaceCatAnimation extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onTap;

  const SpaceCatAnimation({
    Key? key,
    required this.isVisible,
    required this.onTap,
  }) : super(key: key);

  @override
  State<SpaceCatAnimation> createState() => _SpaceCatAnimationState();
}

class _SpaceCatAnimationState extends State<SpaceCatAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Column(
      children: [
        // 动画部分
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    NewAppAssets.homeSpaceCat,
                    width: 150,
                    height: 150,
                  ),
                ),
              );
            },
          ),
        ),
        
        // 提示文字
        const SizedBox(height: 10),
        Text(
          'Tap cat to disconnect',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
