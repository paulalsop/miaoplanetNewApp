import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_constants.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/size_utils.dart';
import 'services/auth_service.dart';

/// 启动页面
class StartupPage extends ConsumerStatefulWidget {
  const StartupPage({Key? key}) : super(key: key);

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundScaleAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 初始化淡入和文字缩放动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    // 背景轻微缩放动画，增加视觉效果
    _backgroundScaleAnimation = Tween<double>(begin: 1.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuad),
      ),
    );

    // 启动动画
    _animationController.forward();

    // 设置定时器，在一段时间后导航到下一个页面
    _setupNavigation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 设置延迟导航
  void _setupNavigation() {
    Timer(const Duration(milliseconds: 3000), () {
      _checkAuthAndNavigate();
    });
  }

  /// 检查认证状态并导航到相应页面
  Future<void> _checkAuthAndNavigate() async {
    debugPrint('【启动页】开始检查认证状态');

    // 初始化认证服务
    await AuthService.instance.init();
    debugPrint('【启动页】认证服务初始化完成，当前登录状态: ${AuthService.instance.isLoggedIn}');

    // 测试用：如果没有token，设置一个默认token
    // 注意：实际应用中，正式环境应当去掉这一行
    if (!AuthService.instance.isLoggedIn) {
      debugPrint('【启动页】当前无token，设置默认测试token...');
      await AuthService.instance.setDefaultToken();
      debugPrint('【启动页】默认测试token设置完成');
    } else {
      debugPrint('【启动页】已存在token: ${AuthService.instance.token}');
    }

    // 验证token
    debugPrint('【启动页】开始验证token');
    final bool isTokenValid = await AuthService.instance.validateToken();
    debugPrint('【启动页】token验证结果: ${isTokenValid ? '有效' : '无效'}');

    if (mounted) {
      if (isTokenValid) {
        // token有效，跳转到主页
        debugPrint('【启动页】token有效，准备导航到主页');
        NewAppRoutes.navigateAndRemoveUntil(context, NewAppRoutes.home);
        debugPrint('【启动页】导航到主页命令已发送');
      } else {
        // token无效，跳转到登录页
        debugPrint('【启动页】token无效，准备导航到登录页');
        NewAppRoutes.navigateAndRemoveUntil(context, NewAppRoutes.login);
        debugPrint('【启动页】导航到登录页命令已发送');
      }
    } else {
      debugPrint('【启动页】context已不再挂载，无法导航');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = SizeUtils.screenWidth(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            // 为背景添加轻微缩放动画
            child: Transform.scale(
              scale: _backgroundScaleAnimation.value,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图（包含火箭）
                  Image.asset(
                    NewAppAssets.startupBg,
                    fit: BoxFit.cover,
                  ),

                  // 文字层叠在背景上方
                  Positioned(
                    top: SizeUtils.screenHeight(context) * 0.15,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Center(
                          child: Image.asset(
                            NewAppAssets.startupWord,
                            width: screenWidth * 0.85,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
