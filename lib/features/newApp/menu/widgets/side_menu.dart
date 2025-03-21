import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../auth/auth_routes.dart';
import '../../auth/screens/login_page.dart';
import '../../auth/services/auth_service.dart';
import '../../core/routes/app_routes.dart';

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

class _SideMenuState extends State<SideMenu> with SingleTickerProviderStateMixin {
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
      SideMenuItem(
        icon: NewAppAssets.menuInviteIcon,
        title: '邀请链接',
        onTap: () {
          // 处理邀请链接点击
          _handleMenuItemTap('邀请链接');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuUserIcon,
        title: '用户协议',
        onTap: () {
          // 处理用户协议点击
          _handleMenuItemTap('用户协议');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuPrivacyIcon,
        title: '隐私协议',
        onTap: () {
          // 处理隐私协议点击
          _handleMenuItemTap('隐私协议');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuServiceIcon,
        title: '客服咨询',
        onTap: () {
          // 处理客服咨询点击
          _handleMenuItemTap('客服咨询');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuResetPasswordIcon,
        title: '重置密码',
        onTap: () {
          // 处理重置密码点击
          _handleMenuItemTap('重置密码');
        },
      ),
      SideMenuItem(
        icon: NewAppAssets.menuLogoutAccountIcon,
        title: '注销账号',
        onTap: () {
          // 处理注销账号点击
          _handleMenuItemTap('注销账号');
        },
      ),
    ];
  }

  // 处理菜单项点击
  void _handleMenuItemTap(String itemName) {
    // 关闭菜单后执行操作
    widget.onClose();
    // 这里可以根据实际需求添加具体的跳转逻辑
    debugPrint('点击了菜单项: $itemName');

    // 处理邀请链接点击
    if (itemName == '邀请链接' && context.mounted) {
      NewAppRoutes.navigateTo(context, NewAppRoutes.invitationCode);
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
                  NewAppRoutes.navigateAndRemoveUntil(context, NewAppRoutes.login);
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Image.asset(
                NewAppAssets.menuSideLine,
                width: double.infinity,
                height: 1,
              ),
            ),
            const SizedBox(height: 20),

            // 菜单项列表
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
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
                  'ID: ${widget.userId}',
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
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return _buildMenuItem(item);
      },
    );
  }

  // 构建单个菜单项
  Widget _buildMenuItem(SideMenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // 图标
            Image.asset(
              item.icon,
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 16),

            // 标题
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建退出登录按钮
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
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
