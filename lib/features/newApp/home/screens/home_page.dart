import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/app_assets.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/size_utils.dart';
import '../providers/connection_provider.dart' as provider;
import '../widgets/connection_status.dart';
import '../widgets/space_cat_animation.dart';
import '../widgets/speed_display.dart';
import '../widgets/server_info_button.dart';
import '../../menu/services/side_menu_service.dart';
import '../../shared/layouts/app_scaffold.dart';
import '../../server/server_routes.dart';
import '../../server/models/server_model.dart';
import '../../member/member_routes.dart';
import '../../member/models/membership_model.dart';

/// 主页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionData = ref.watch(provider.connectionProvider);
    final isDisconnected = connectionData.status == provider.ConnectionStatus.disconnected;
    final isConnected = connectionData.status == provider.ConnectionStatus.connected;
    final screenHeight = SizeUtils.screenHeight(context);

    // 使用AppScaffold作为根布局
    return AppScaffold(
      userId: '123456789', // 这里应该从用户信息提供者中获取真实的用户ID
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
            image: AssetImage(isConnected ? NewAppAssets.homeConnectedBackground : NewAppAssets.homeBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 24),

              // 根据连接状态显示不同的标题
              Text(
                isDisconnected ? 'Not Connected' : 'Connecting Time',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // 连接时间（仅连接时显示）
              if (!isDisconnected) ...[
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
                SpeedDisplay(
                  downloadSpeed: connectionData.downloadSpeed,
                  uploadSpeed: connectionData.uploadSpeed,
                ),
              ],

              const SizedBox(height: 28),

              // 服务器选择/信息按钮
              ServerInfoButton(
                status: connectionData.status,
                serverName: connectionData.serverName,
                pingValue: connectionData.pingValue,
                onTap: () async {
                  // 打开服务器选择页面
                  final server = await ServerRoutes.openServerSelectionFullScreen(context);
                  if (server != null && context.mounted) {
                    // 处理选中的服务器
                    final notifier = ref.read(provider.connectionProvider.notifier);
                    notifier.setSelectedServer(
                      name: server.name,
                      pingValue: server.ping,
                    );

                    // 如果服务器状态为已连接，自动连接
                    if (server.status == ServerStatus.connected && !isConnected) {
                      notifier.connect();
                    }
                  }
                },
              ),

              // 未连接时给更多空间，连接后减少空间以放置太空猫
              isConnected ? const Spacer() : const Spacer(flex: 2),

              // 连接按钮或太空猫
              isConnected
                  ? SpaceCatAnimation(
                      isVisible: isConnected, // 确保只在连接状态显示
                      onTap: () {
                        // 点击太空猫断开连接
                        final notifier = ref.read(provider.connectionProvider.notifier);
                        notifier.disconnect();
                      },
                    )
                  : _buildConnectButton(),

              // 调整底部间距
              isConnected ? const SizedBox(height: 16) : const Spacer(),

              // 底部连接状态
              ConnectionStatus(status: connectionData.status),

              SizedBox(height: isConnected ? 24 : screenHeight * 0.05),
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

          // 右侧会员按钮
          _buildIconButton(
            icon: NewAppAssets.homeMemberIcon,
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

  // 构建连接按钮
  Widget _buildConnectButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 处理连接/断开连接逻辑
        final notifier = ref.read(provider.connectionProvider.notifier);
        final connectionData = ref.read(provider.connectionProvider);

        // 确保侧边栏关闭
        SideMenuController.close();

        if (connectionData.status == provider.ConnectionStatus.disconnected) {
          notifier.connect();
        } else {
          notifier.disconnect();
        }
      },
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
}
