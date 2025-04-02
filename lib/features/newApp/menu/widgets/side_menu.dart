import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_assets.dart';
import '../../auth/auth_routes.dart';
import '../../auth/screens/login_page.dart';
import '../../auth/services/auth_service.dart';
import '../../core/routes/app_routes.dart';
import '../../user/screens/referrer_info_page.dart';
import '../../user/screens/bsc_address_page.dart';
import '../../user/screens/reset_password_page.dart';
import '../../ticket/screens/ticket_list_page.dart';
import '../../../panel/xboard/services/http_service/user_service.dart';
import '../../../panel/xboard/models/user_info_model.dart';
import '../../../panel/xboard/services/http_service/invite_code_service.dart';

/// 侧边栏菜单项数据结构
class SideMenuItem {
  final String icon;
  final String title;
  final VoidCallback onTap;

  SideMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

/// 侧边栏组件
class SideMenu extends StatefulWidget {
  const SideMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.userId,
    this.onLogout,
  });

  /// 侧边栏是否打开
  final bool isOpen;

  /// 关闭侧边栏回调
  final VoidCallback onClose;

  /// 用户ID
  final String userId;

  /// 退出登录回调
  final VoidCallback? onLogout;

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // 菜单项列表
  late List<SideMenuItem> _menuItems;

  // 侧边栏宽度
  final double _sideMenuWidth = 300.0;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 侧边栏滑动动画
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // 初始化菜单项
    _initMenuItems();

    // 如果侧边栏打开，立即开始动画
    if (widget.isOpen) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  // 初始化菜单项
  void _initMenuItems() {
    _menuItems = [
      // 临时账号升级选项（仅当用户使用临时账号时显示）
      SideMenuItem(
        icon: NewAppAssets.menuInviteIcon,
        title: '升级账号',
        onTap: () {
          widget.onClose();
          if (context.mounted) {
            NewAppRoutes.navigateTo(context, NewAppRoutes.upgradeAccount);
          }
        },
      ),
      // 邀请链接（仅当用户绑定了推荐人时显示）
      SideMenuItem(
        icon: NewAppAssets.menuInviteIcon,
        title: '邀请链接',
        onTap: () {
          _handleMenuItemTap('邀请链接');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuUserIcon,
        title: '推荐人',
        onTap: () {
          _handleReferrerTap();
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuWalletIcon,
        title: 'BSC地址',
        onTap: () {
          _handleBscAddressTap();
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.orderListIcon,
        title: '订单列表',
        onTap: () {
          _handleMenuItemTap('订单列表');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuUserIcon,
        title: '用户协议',
        onTap: () {
          _handleMenuItemTap('用户协议');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuPrivacyIcon,
        title: '隐私协议',
        onTap: () {
          _handleMenuItemTap('隐私协议');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuServiceIcon,
        title: '客服咨询',
        onTap: () {
          _handleMenuItemTap('客服咨询');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuResetPasswordIcon,
        title: '重置密码',
        onTap: () {
          _handleMenuItemTap('重置密码');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuLogoutAccountIcon,
        title: '注销账号',
        onTap: () {
          _handleMenuItemTap('注销账号');
        },
      ),
    ];
  }

  // 处理菜单项点击
  void _handleMenuItemTap(String menuTitle) {
    // 首先关闭侧边栏
    widget.onClose();

    // 菜单项点击逻辑
    switch (menuTitle) {
      case '邀请链接':
        _showInvitationPage();
        break;
      case '订单列表':
        _navigateToOrderList();
        break;
      case 'BSC地址':
        _showBscAddressPage();
        break;
      case '用户协议':
        _showFeatureInDevelopment('用户协议');
        break;
      case '隐私协议':
        _showFeatureInDevelopment('隐私协议');
        break;
      case '客服咨询':
        _showTicketListPage();
        break;
      case '重置密码':
        _showResetPasswordPage();
        break;
      case '注销账号':
        _showFeatureInDevelopment('注销账号');
        break;
      default:
        // 显示功能开发中提示
        _showFeatureInDevelopment(menuTitle);
    }
  }

  // 显示推荐人信息页面
  void _showReferrerInfoPage() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭推荐人信息',
      barrierColor: Colors.black.withOpacity(0.75),
      pageBuilder: (context, animation1, animation2) =>
          const ReferrerInfoPage(),
      transitionBuilder: (context, animation1, animation2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation1,
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  // 处理推荐人点击
  void _handleReferrerTap() {
    // 首先关闭侧边栏
    widget.onClose();

    // 打开推荐人信息页面
    _showReferrerInfoPage();
  }

  // 显示邀请链接页面
  void _showInvitationPage() {
    if (context.mounted) {
      NewAppRoutes.navigateTo(context, NewAppRoutes.invitationCode);
    }
  }

  // 导航到订单列表
  void _navigateToOrderList() {
    if (context.mounted) {
      NewAppRoutes.navigateTo(context, NewAppRoutes.orderList);
    }
  }

  // 显示BSC地址页面
  void _showBscAddressPage() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭BSC地址',
      barrierColor: Colors.black.withOpacity(0.75),
      pageBuilder: (context, animation1, animation2) => const BscAddressPage(),
      transitionBuilder: (context, animation1, animation2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation1,
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  // 处理BSC地址点击
  void _handleBscAddressTap() {
    // 首先关闭侧边栏
    widget.onClose();

    // 打开BSC地址页面
    _showBscAddressPage();
  }

  // 显示重置密码页面
  void _showResetPasswordPage() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭重置密码',
      barrierColor: Colors.black.withOpacity(0.75),
      pageBuilder: (context, animation1, animation2) =>
          const ResetPasswordPage(),
      transitionBuilder: (context, animation1, animation2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation1,
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  // 显示功能开发中提示
  void _showFeatureInDevelopment(String featureName) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$featureName 功能开发中，敬请期待！'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 处理退出登录
  void _handleLogout() {
    debugPrint('【侧边栏】退出登录按钮被点击');

    // 先显示确认对话框
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退出登录'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('【侧边栏】取消退出登录');
              Navigator.pop(dialogContext);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              debugPrint('【侧边栏】确认退出登录，开始执行退出操作');

              try {
                // 1. 先执行退出登录操作
                debugPrint('【侧边栏】1. 开始清除token');
                await AuthService.instance.logout();
                debugPrint('【侧边栏】1. token清除完成');

                // 2. 调用外部回调（如果有）
                if (widget.onLogout != null) {
                  debugPrint('【侧边栏】2. 执行外部onLogout回调');
                  widget.onLogout!();
                }

                // 3. 关闭确认对话框
                debugPrint('【侧边栏】3. 关闭确认对话框');
                Navigator.pop(dialogContext);

                // 4. 关闭侧边栏
                debugPrint('【侧边栏】4. 关闭侧边栏');
                widget.onClose();

                // 5. 导航到登录页
                debugPrint('【侧边栏】5. 准备导航到登录页');
                if (context.mounted) {
                  NewAppRoutes.navigateAndRemoveUntil(
                      context, NewAppRoutes.login);
                  debugPrint('【侧边栏】5. 导航命令已发送');
                }
              } catch (e) {
                debugPrint('【侧边栏】退出登录过程中出错: $e');
                // 确保对话框被关闭
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 检查是否为临时账号
  Future<bool> _isTempAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_temp_account') ?? false;
  }

  // 显示工单列表页面
  void _showTicketListPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TicketListPage(),
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
    return WillPopScope(
      onWillPop: () async {
        if (widget.isOpen) {
          widget.onClose();
          return false;
        }
        return true;
      },
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 半透明背景蒙版 - 实现为两层
            // 第一层：纯色遮罩，保证点击效果
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onClose,
                    child: Container(
                      color: Colors.black.withOpacity(
                        _animationController.value * 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),

            // 第二层：UI装饰层，显示背景图案但不处理点击
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _animationController.value * 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    NewAppAssets.menuBgMask,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // 侧边栏内容
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  left: _slideAnimation.value * _sideMenuWidth,
                  top: 0,
                  bottom: 0,
                  width: _sideMenuWidth,
                  child: Material(
                    type: MaterialType.card,
                    color: Colors.transparent,
                    elevation: 16,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: _buildSideMenuContent(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 构建侧边栏内容
  Widget _buildSideMenuContent() {
    return Container(
      width: _sideMenuWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(NewAppAssets.menuSideMenuBg),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 头像和用户信息区域
            _buildUserInfoSection(),

            // 分割线
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Image.asset(
            //     NewAppAssets.menuSideLine,
            //     width: double.infinity,
            //     height: 1,
            //   ),
            // ),
            const SizedBox(height: 20),

            // 菜单项列表
            Expanded(
              child: SingleChildScrollView(
                child: _buildMenuItems(),
              ),
            ),

            // 退出登录按钮
            _buildLogoutButton(),

            // 底部安全区域填充
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 构建用户信息区域
  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          // 用户头像
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              NewAppAssets.menuAvatar,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),

          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名
                const Text(
                  'MIAO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // 用户ID
                Text(
                  '${widget.userId}',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建菜单项列表
  Widget _buildMenuItems() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserStatus(),
      builder: (context, snapshot) {
        List<Widget> menuWidgets = [];

        // 如果是临时账号，显示升级选项
        if (snapshot.hasData && snapshot.data?['isTemp'] == true) {
          menuWidgets.add(
            _buildMenuItem(
              icon: NewAppAssets.menuInviteIcon,
              title: '升级账号',
              isHighlighted: true,
              onTap: () {
                widget.onClose();
                if (context.mounted) {
                  NewAppRoutes.navigateTo(context, NewAppRoutes.upgradeAccount);
                }
              },
            ),
          );
        }

        // 只有当用户有推荐人时才显示邀请链接菜单项
        if (snapshot.hasData && snapshot.data?['hasInviter'] == true) {
          menuWidgets.add(
            _buildMenuItem(
              icon: NewAppAssets.menuInviteIcon,
              title: '邀请链接',
              onTap: () {
                _handleMenuItemTap('邀请链接');
              },
            ),
          );
        }

        // 添加其他固定菜单项
        menuWidgets.addAll([
          _buildMenuItem(
            icon: NewAppAssets.menuUserIcon,
            title: '推荐人',
            onTap: () {
              _handleReferrerTap();
            },
          ),
          _buildMenuItem(
            icon: NewAppAssets.menuWalletIcon,
            title: 'BSC地址',
            onTap: () {
              _handleBscAddressTap();
            },
          ),
          _buildMenuItem(
            icon: NewAppAssets.orderListIcon,
            title: '订单列表',
            onTap: () {
              _handleMenuItemTap('订单列表');
            },
          ),
          _buildMenuItem(
            icon: NewAppAssets.menuUserIcon,
            title: '用户协议',
            onTap: () {
              _handleMenuItemTap('用户协议');
            },
          ),
          _buildMenuItem(
            icon: NewAppAssets.menuPrivacyIcon,
            title: '隐私协议',
            onTap: () {
              _handleMenuItemTap('隐私协议');
            },
          ),
          _buildMenuItem(
            icon: NewAppAssets.menuServiceIcon,
            title: '客服咨询',
            onTap: () {
              _handleMenuItemTap('客服咨询');
            },
          ),
          _buildMenuItem(
            icon: NewAppAssets.menuResetPasswordIcon,
            title: '重置密码',
            onTap: () {
              _handleMenuItemTap('重置密码');
            },
          ),
          _buildMenuItem(
            icon: NewAppAssets.menuLogoutAccountIcon,
            title: '注销账号',
            onTap: () {
              _handleMenuItemTap('注销账号');
            },
          ),
        ]);

        return Column(children: menuWidgets);
      },
    );
  }

  // 获取用户状态（包括临时账号状态和推荐人状态）
  Future<Map<String, dynamic>> _getUserStatus() async {
    try {
      final token = AuthService.instance.token;
      if (token == null) {
        return {'hasInviter': false, 'isTemp': false};
      }

      // 获取用户信息（包含临时账号状态）
      final userInfo = await UserService().fetchUserInfo(token);
      // 获取推荐人状态
      final inviteStatus = await InviteCodeService().getInviteStatus(token);

      return {
        'isTemp': userInfo?.isTemp ?? false,
        'hasInviter': inviteStatus['hasInviter'] ?? false,
      };
    } catch (e) {
      debugPrint('获取用户状态失败: $e');
      return {'hasInviter': false, 'isTemp': false};
    }
  }

  // 构建单个菜单项
  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  icon,
                  color: isHighlighted ? Colors.orange : Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isHighlighted ? Colors.orange : Colors.white,
                    fontSize: 16,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建退出登录按钮
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: 80,
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.menuQuitButtonBg),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(22.5),
        ),
        alignment: Alignment.center,
        child: const Text(
          '退出登录',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
