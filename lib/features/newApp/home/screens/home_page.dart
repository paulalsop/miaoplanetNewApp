import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_assets.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/size_utils.dart';
import '../providers/connection_provider.dart' as provider;
import '../widgets/connection_status.dart';
import '../widgets/space_cat_animation.dart';
import '../widgets/server_info_button.dart';
import '../../member/member_routes.dart';
import '../../shared/layouts/app_scaffold.dart';
import '../../menu/services/side_menu_service.dart';
import '../../server/server_routes.dart' as server_routes;
import '../../server/models/server_model.dart';
import '../../utils/app_update_service.dart';
import '../../auth/services/auth_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';

// 系统底层连接相关
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/model/connection_status.dart'
    as core_status;

/// 主页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  final AppUpdateService _updateService = AppUpdateService();
  final UserService _userService = UserService();

  // 用户信息相关
  String _userEmail = '';
  int _planId = 0; // 0表示未知, 1表示普通会员, 2表示股东会员
  DateTime? _expiryDate;
  bool _isSubscriptionExpired = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 按钮脉冲动画（缓慢变大变小）
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // 延迟检查更新，等待页面完全加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _fetchUserInfo();
    });
  }

  /// 获取用户信息
  Future<void> _fetchUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = AuthService.instance.token;
      if (token == null) {
        debugPrint('获取token失败，无法获取用户信息');
        return;
      }

      final userInfo = await _userService.fetchUserInfo(token);
      if (userInfo != null) {
        setState(() {
          _userEmail = userInfo.email ?? '';
          _planId = userInfo.planId ?? 1;

          if (userInfo.expiredAt != null) {
            _expiryDate =
                DateTime.fromMillisecondsSinceEpoch(userInfo.expiredAt! * 1000);

            // 检查是否过期
            final now = DateTime.now();
            _isSubscriptionExpired = now.isAfter(_expiryDate!);
          }

          _isLoading = false;
        });

        // 如果已过期，显示提示
        if (_isSubscriptionExpired && mounted) {
          _showSubscriptionExpiredDialog();
        }
      }
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示订阅已过期对话框
  void _showSubscriptionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('会员订阅已过期'),
        content: const Text('您的会员订阅已经过期，请续费以继续使用完整功能。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              MemberRoutes.openMembershipPage(context);
            },
            child: const Text('立即续费'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('稍后再说'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionData = ref.watch(provider.connectionProvider);
    final isConnected =
        connectionData.status == provider.ConnectionStatus.connected;

    // 添加调试日志以便于排错
    debugPrint('首页显示状态: ${connectionData.status}');

    // 状态监听 - 优化，避免不必要的状态更新 ,

    ref.listen<AsyncValue<core_status.ConnectionStatus>>(
        connectionNotifierProvider, (previous, next) {
      next.when(
        loading: () => debugPrint('系统连接状态加载中...'),
        error: (error, stack) {
          debugPrint('系统连接状态错误: $error');
          final uiNotifier = ref.read(provider.connectionProvider.notifier);
          uiNotifier.forceDisconnectUI();
        },
        data: (status) {
          final uiNotifier = ref.read(provider.connectionProvider.notifier);
          final currentUIStatus = ref.read(provider.connectionProvider).status;

          if (status is core_status.Connected &&
              currentUIStatus != provider.ConnectionStatus.connected) {
            uiNotifier.forceUpdateConnectedUI();
          } else if (status is core_status.Disconnected &&
              currentUIStatus != provider.ConnectionStatus.disconnected) {
            uiNotifier.forceDisconnectUI();
          }
        },
      );
    });

    final screenHeight = SizeUtils.screenHeight(context);

    // 使用AppScaffold作为根布局
    return AppScaffold(
      userId: _userEmail.isNotEmpty ? _userEmail : '加载中...',
      onLogout: () {
        // 处理退出登录逻辑
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已退出登录')),
        );
      },
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isConnected
                ? NewAppAssets.homeConnectedBackground
                : NewAppAssets.homeBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 主内容
              Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 24),

                  // 根据连接状态显示不同的标题
                  Text(
                    isConnected ? '链接时间' : '未链接',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 显示会员到期时间（只有普通会员且有到期时间时显示）
                  if (_planId == 1 && _expiryDate != null && !_isLoading) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '会员到期: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_expiryDate!)}',
                        style: TextStyle(
                          color: _isSubscriptionExpired
                              ? Colors.red
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // 连接时间（仅连接时显示）
                  if (isConnected) ...[
                    const SizedBox(height: 16),
                    Text(
                      connectionData.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 网速显示（仅连接后显示）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSpeedInfo(
                          icon: Icons.download_rounded,
                          label: 'Download',
                          value:
                              '${connectionData.downloadSpeed.toStringAsFixed(2)} KB/s',
                        ),
                        const SizedBox(width: 40),
                        _buildSpeedInfo(
                          icon: Icons.upload_rounded,
                          label: 'Upload',
                          value:
                              '${connectionData.uploadSpeed.toStringAsFixed(2)} KB/s',
                        ),
                      ],
                    ),
                  ],

                  // 服务器选择按钮
                  const SizedBox(height: 30),
                  // _buildServerSelectButton(connectionData.serverName),

                  // 未连接时给更多空间，连接后减少空间以放置太空猫
                  isConnected ? const Spacer() : const Spacer(flex: 2),

                  // 连接按钮或太空猫
                  isConnected
                      ? SpaceCatAnimation(
                          isVisible: isConnected, // 确保只在连接状态显示
                          onTap: () {
                            // 点击太空猫断开连接
                            _forceDisconnectVPN(context);
                          },
                        )
                      : _buildConnectButton(),

                  SizedBox(height: isConnected ? 24 : screenHeight * 0.05),

                  // 底部状态指示器
                  GestureDetector(
                    onTap: () {
                      // 点击状态指示器切换连接状态
                      if (isConnected) {
                        _forceDisconnectVPN(context);
                      } else {
                        _connectVPN(context);
                      }
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? const Color.fromARGB(255, 1, 253, 38)
                                  .withOpacity(0.7)
                              : Colors.grey.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isConnected
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected ? '已链接 (点击断开链接)' : '未链接 (点击链接)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建顶部应用栏
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧菜单按钮
          _buildIconButton(
            icon: NewAppAssets.homeMenuIcon,
            size: 36,
            onTap: () => SideMenuController.open(),
          ),

          // 中间标题
          const Text(
            'MIAO VPN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          // 右侧会员按钮 - 根据会员类型显示不同图标
          _buildIconButton(
            icon: _planId == 2
                ? NewAppAssets.shareholderMemberBadge
                : NewAppAssets.homeMemberIcon,
            size: 36,
            onTap: () {
              // 打开会员页面
              MemberRoutes.openMembershipPage(context);
            },
          ),
        ],
      ),
    );
  }

  // 构建通用图标按钮
  Widget _buildIconButton({
    required String icon,
    required double size,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Image.asset(
          icon,
          width: size,
          height: size,
        ),
      ),
    );
  }

  // 连接VPN
  Future<void> _connectVPN(BuildContext context) async {
    // 检查会员是否过期
    if (_isSubscriptionExpired) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('会员已过期'),
          content: const Text('您的会员已过期，无法使用VPN服务。请续费后再试。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                MemberRoutes.openMembershipPage(context);
              },
              child: const Text('立即续费'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        ),
      );
      return;
    }

    // 防止重复连接
    final connectionData = ref.read(provider.connectionProvider);
    if (connectionData.status != provider.ConnectionStatus.disconnected) {
      debugPrint('已经处于连接状态或正在连接中，忽略连接请求');
      return;
    }

    // 通知用户正在连接
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在连接VPN...')),
    );

    try {
      // 确保侧边栏关闭
      SideMenuController.close();

      // 尝试使用UI控制器连接，这样即使系统级出错也能更新界面
      final uiNotifier = ref.read(provider.connectionProvider.notifier);

      // 然后尝试系统级连接
      try {
        // 使用系统级连接器
        final connectionNotifier =
            ref.read(connectionNotifierProvider.notifier);

        // 安全地获取系统状态
        final systemStatusAsync = ref.read(connectionNotifierProvider);

        // 根据状态类型执行不同操作
        if (systemStatusAsync is AsyncData &&
            systemStatusAsync.value is core_status.Disconnected) {
          // 正常状态：系统已断开，执行连接
          debugPrint('检测到系统已断开，执行连接操作');
          await connectionNotifier.toggleConnection();
          debugPrint('已调用系统toggleConnection开始连接');
          return; // 操作成功，直接返回
        } else if (systemStatusAsync is AsyncError) {
          // 错误状态：使用备用方法
          debugPrint('系统状态错误: ${systemStatusAsync.error}，使用UI连接');
          // 继续执行UI连接
        } else {
          debugPrint('系统状态未确认或已连接: $systemStatusAsync，使用UI连接');
          // 继续执行UI连接
        }
      } catch (e) {
        debugPrint('系统连接尝试失败: $e');
        // 继续执行UI连接
      }

      // 无论系统级连接成功与否，确保UI状态更新为连接
      debugPrint('执行UI级连接');
      await uiNotifier.connect(context);
    } catch (e) {
      debugPrint('所有连接尝试均失败: $e');
      // 通知用户连接失败
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: $e')),
        );
      }
    }
  }

  // 构建连接按钮
  Widget _buildConnectButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _connectVPN(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 大圆底图（带脉冲动画）
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Image.asset(
                  NewAppAssets.homeStartButtonBig,
                  width: 160,
                  height: 160,
                ),
              );
            },
          ),

          // 小圆
          Image.asset(
            NewAppAssets.homeStartButtonSmall,
            width: 120,
            height: 120,
          ),

          // 电源图标
          Image.asset(
            NewAppAssets.homeStartButtonIcon,
            width: 36,
            height: 36,
          ),
        ],
      ),
    );
  }

  // 构建网速信息
  Widget _buildSpeedInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 构建服务器选择按钮
  Widget _buildServerSelectButton(String serverName) {
    // 获取最新的状态
    final connectionData = ref.watch(provider.connectionProvider);
    final isConnected =
        connectionData.status == provider.ConnectionStatus.connected;

    return ServerInfoButton(
      status: connectionData.status,
      serverName: serverName,
      pingValue: connectionData.pingValue,
      onTap: () async {
        // 打开服务器选择页面
        final server =
            await server_routes.ServerRoutes.openServerSelectionFullScreen(
                context);
        if (server != null && context.mounted) {
          // 处理选中的服务器
          final notifier = ref.read(provider.connectionProvider.notifier);
          notifier.setSelectedServer(
            name: server.name,
            pingValue: server.ping,
          );

          // 如果服务器状态为已连接，自动连接
          if (server.status == ServerStatus.connected && !isConnected) {
            _connectVPN(context);
          }
        }
      },
    );
  }

  // 强制断开VPN连接
  Future<void> _forceDisconnectVPN(BuildContext context) async {
    try {
      // 1. 先更新UI状态为断开
      final uiNotifier = ref.read(provider.connectionProvider.notifier);
      uiNotifier.forceDisconnectUI();

      // 2. 尝试直接调用connectionRepository断开
      try {
        final connectionRepo = ref.read(connectionRepositoryProvider);
        if (connectionRepo != null) {
          await connectionRepo.disconnect().run();
          debugPrint('已通过Repository断开连接');
        }
        // final connectionNotifier =
        // ref.read(connectionNotifierProvider.notifier);
        // await connectionNotifier.toggleConnection();
      } catch (e) {
        debugPrint('Repository断开失败: $e');

        // 3. 如果上面失败，尝试alternative方法
        try {
          final connectionNotifier =
              ref.read(connectionNotifierProvider.notifier);
          await connectionNotifier.abortConnection();
          // await connectionNotifier.toggleConnection();
          debugPrint('已通过abortConnection断开连接');
        } catch (e2) {
          debugPrint('所有断开方法均失败: $e2');
        }
      }
    } catch (e) {
      debugPrint('断开操作失败: $e');
    }
  }

  /// 检查应用更新
  Future<void> _checkForUpdates() async {
    try {
      final result = await _updateService.checkForUpdate();
      if (result.hasUpdate && mounted) {
        _updateService.showUpdateDialog(context, result);
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
  }
}
