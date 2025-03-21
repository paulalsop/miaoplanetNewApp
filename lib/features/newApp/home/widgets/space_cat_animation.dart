import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// 太空猫动画组件
class SpaceCatAnimation extends StatefulWidget {
  const SpaceCatAnimation({
    super.key,
    required this.isVisible,
    this.onTap,
  });

  final bool isVisible;
  final VoidCallback? onTap;

  @override
  State<SpaceCatAnimation> createState() => _SpaceCatAnimationState();
}

class _SpaceCatAnimationState extends State<SpaceCatAnimation> with TickerProviderStateMixin {
  late AnimationController _flyInController;
  late AnimationController _floatController;

  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 飞入动画控制器
    _flyInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 漂浮/晃动动画控制器
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    // 飞入位置动画
    _positionAnimation = Tween<Offset>(
      begin: const Offset(-1.8, 1.2), // 从左下角开始
      end: Offset.zero, // 结束于中心点
    ).animate(CurvedAnimation(
      parent: _flyInController,
      curve: Curves.easeOutCubic,
    ));

    // 旋转动画
    _rotationAnimation = Tween<double>(
      begin: -0.08,
      end: 0.08,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // 缩放动画
    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _flyInController.forward();
    }
  }

  @override
  void didUpdateWidget(SpaceCatAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _flyInController.forward();
      } else {
        _flyInController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flyInController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_flyInController, _floatController]),
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.translate(
            offset: _positionAnimation.value * 100,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Image.asset(
                  NewAppAssets.homeSpaceCat,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
