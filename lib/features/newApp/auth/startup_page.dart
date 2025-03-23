import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_assets.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/size_utils.dart';
import '../utils/device_id_service.dart';
import 'services/auth_service.dart';
import '../../panel/xboard/services/http_service/http_service.dart';
import '../../panel/xboard/services/http_service/auth_service.dart' as xboard_auth;

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
  
  // 添加网络初始化状态变量
  String _initStatus = '正在连接服务器...';
  double _initProgress = 0.0;
  bool _isInitializing = true;

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

    // 在动画播放的同时，初始化服务并准备导航
    _initializeServicesAndPrepareNavigation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServicesAndPrepareNavigation() async {
    // 首先初始化服务和域名检查
    final bool serviceInitialized = await _initializeServices();
    
    // 无论服务初始化是否成功，都设置定时器进行导航，确保不影响用户体验
    Timer(const Duration(milliseconds: 3000), () {
      _checkAuthAndNavigate(serviceInitialized);
    });
  }

  /// 初始化服务，包括域名检查
  Future<bool> _initializeServices() async {
    // 更新初始化状态
    setState(() {
      _initStatus = '正在连接服务器...';
      _initProgress = 0.3;
    });
    
    try {
      // 使用xboard中的DomainService初始化HttpService
      await HttpService.initialize();
      debugPrint('【启动页】成功初始化HttpService，可用域名: ${HttpService.baseUrl}');
      
      // 更新初始化状态
      setState(() {
        _initStatus = '服务器连接成功';
        _initProgress = 0.6;
      });
      
      return true;
    } catch (e) {
      debugPrint('【启动页】初始化HttpService失败: $e');
      
      // 更新初始化状态为失败
      setState(() {
        _initStatus = '服务器连接失败，正在尝试本地模式...';
        _initProgress = 0.4;
      });
      
      return false;
    }
  }

  /// 检查认证状态并导航到相应页面
  Future<void> _checkAuthAndNavigate(bool serviceInitialized) async {
    debugPrint('【启动页】开始检查认证状态');
    
    // 更新初始化状态
    setState(() {
      _initStatus = '正在验证登录状态...';
      _initProgress = serviceInitialized ? 0.7 : 0.5;
    });

    // 初始化认证服务
    await AuthService.instance.init();
    debugPrint('【启动页】认证服务初始化完成，当前登录状态: ${AuthService.instance.isLoggedIn}');
    
    // 更新初始化状态
    setState(() {
      _initStatus = '正在配置应用...';
      _initProgress = 0.8;
    });

    // 如果没有登录状态，并且服务器连接已初始化成功，判断是否是首次启动
    if (!AuthService.instance.isLoggedIn && serviceInitialized) {
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstLaunch = !(prefs.getBool('app_launched_before') ?? false);
      
      if (isFirstLaunch) {
        // 首次启动，静默创建临时账号
        debugPrint('【启动页】首次启动应用，创建临时账号...');
        try {
          // 获取设备ID
          final deviceId = await DeviceIdService.getDeviceId();
          
          // 调用xboard中的AuthService创建临时账号
          final xboardAuthService = xboard_auth.AuthService();
          final tempResult = await xboardAuthService.tempAccountCreate(deviceId);
          
          if (tempResult['status'] == 'success' && tempResult.containsKey('data')) {
            // 从响应中提取并存储信息
            final data = tempResult['data'] as Map<String, dynamic>;
            final authData = data['auth_data'] as Map<String, dynamic>;
            // final token = authData['token'] as String;
            final auth_data2 = authData['auth_data'] as String;
            
            // 存储token
            await AuthService.instance.setToken(auth_data2);
            
            // 存储临时账号信息
            await _storeTempAccountInfo(data);
            
            debugPrint('【启动页】临时账号创建成功');
          } else {
            debugPrint('【启动页】临时账号创建失败: ${tempResult['message']}');
            // 失败时，也不弹出任何提示，继续下一步流程
          }
        } catch (e) {
          debugPrint('【启动页】临时账号创建出错: $e');
          // 出错时，不弹出任何提示，继续下一步流程
        }
        
        // 标记为非首次启动
        await prefs.setBool('app_launched_before', true);
      }
    }

    // 验证token
    debugPrint('【启动页】开始验证token');
    final bool isTokenValid = await AuthService.instance.validateToken();
    debugPrint('【启动页】token验证结果: ${isTokenValid ? '有效' : '无效'}');
    
    // 更新初始化状态为完成
    setState(() {
      _initStatus = '初始化完成，即将进入...';
      _initProgress = 1.0;
      _isInitializing = false;
    });

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

  // 存储临时账号信息
  Future<void> _storeTempAccountInfo(Map<String, dynamic> data) async {
    try {
      debugPrint('【启动页】开始存储临时账号信息...');
      debugPrint('【启动页】临时账号数据: $data');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_email', data['email'] as String);
      debugPrint('【启动页】存储临时邮箱: ${data['email']}');
      
      await prefs.setString('temp_password', data['password'] as String);
      debugPrint('【启动页】存储临时密码: ${data['password']}');
      
      await prefs.setInt('temp_expired_at', data['expired_at'] as int);
      debugPrint('【启动页】存储过期时间: ${data['expired_at']}');
      
      await prefs.setBool('is_temp_account', true);
      debugPrint('【启动页】标记为临时账号完成');
    } catch (e) {
      debugPrint('【启动页】存储临时账号信息出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = SizeUtils.screenWidth(context);
    final screenHeight = SizeUtils.screenHeight(context);

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
                    top: screenHeight * 0.15,
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
                  
                  // 底部进度条
                  Positioned(
                    bottom: 50,
                    left: 30,
                    right: 30,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          // 进度条
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _initProgress,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.9),
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 状态文字
                          Text(
                            _initStatus,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
