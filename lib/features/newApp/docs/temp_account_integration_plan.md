# 临时账号功能设计与实现计划

## 1. 功能概述

临时账号功能用于用户首次打开应用时**静默创建**一个临时账号，无需用户手动注册，即可使用应用的基本功能。该功能能够降低新用户的使用门槛，提高用户留存率。

### 1.1 功能流程

1. 应用启动时，**首先使用DomainService检查服务器连接性**，获取可用域名
2. 如果连接成功，在现有启动页动画播放过程中，**静默触发**临时账号创建
3. 应用生成设备唯一标识符作为参数（使用UUID随机生成）
4. 调用API创建临时账号
5. 获取并保存返回的账号信息（token、邮箱、密码等）
6. 使用临时账号token自动登录
7. 导航到主界面（不展示任何账号创建或登录提示）

### 1.2 API响应示例

```json
{
  "success": true,
  "data": {
    "auth_data": {
      "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
      "expires_at": 1679308800
    },
    "email": "temp_abc123@temp.local",
    "password": "randompassword",
    "expired_at": 1679308800,
    "is_new": true
  }
}
```

## 2. 实现架构设计

### 2.1 复用现有服务

**关键原则**：所有API交互功能应直接使用`/lib/features/panel/xboard/`目录下已实现的服务，不重复开发。

#### 2.1.1 DomainService复用

**文件路径**：`/lib/features/panel/xboard/services/http_service/domain_service.dart`

在应用启动流程中，首先使用DomainService检查服务器连接并获取可用域名：

```dart
// 在StartupPage的初始化阶段调用
Future<bool> _initializeServices() async {
  try {
    // 初始化HttpService和DomainService
    await HttpService.initialize();
    debugPrint('【启动页】成功初始化HttpService，可用域名: ${HttpService.baseUrl}');
    
    // 已成功获取可用域名，可以继续后续流程
    return true;
  } catch (e) {
    debugPrint('【启动页】初始化HttpService失败: $e');
    // 服务器连接失败，但允许继续流程尝试本地操作
    return false;
  }
}
```

#### 2.1.2 AuthService复用

**文件路径**：`/lib/features/panel/xboard/services/http_service/auth_service.dart`

复用现有AuthService，添加创建临时账号的方法调用：

```dart
// 通过DI或单例访问现有AuthService实例
final AuthService _authService = AuthService();

// 调用现有AuthService中的临时账号创建API
Future<Map<String, dynamic>> createTempAccount(String deviceId) async {
  return await _authService.tempAccountCreate(deviceId);
}
```

#### 2.1.3 UserService复用

**文件路径**：`/lib/features/panel/xboard/services/http_service/user_service.dart`

复用现有UserService进行账号升级操作：

```dart
// 通过DI或单例访问现有UserService实例
final UserService _userService = UserService();

// 账号升级时调用现有方法
Future<String?> upgradeTempAccount(String email, String password, String token) async {
  return await _userService.convertTempAccount(email, password, token);
}
```

### 2.2 数据模型集成

如需添加新的数据模型，应添加到 `/lib/features/panel/xboard/models/` 目录下，保持整体架构一致性。

**示例**：如果需要添加临时账号相关模型，应放在以下位置：

**文件路径**：`/lib/features/panel/xboard/models/temp_account_model.dart`

```dart
// 如果现有模型不能满足需求，可添加新模型类
class TempAccountData {
  final String email;
  final String password;
  final int expiredAt;
  final bool isNew;
  final dynamic authData;
  
  const TempAccountData({
    required this.email,
    required this.password,
    required this.expiredAt,
    required this.isNew,
    required this.authData,
  });
  
  factory TempAccountData.fromJson(Map<String, dynamic> json) {
    return TempAccountData(
      email: json['email'] as String,
      password: json['password'] as String,
      expiredAt: json['expired_at'] as int,
      isNew: json['is_new'] as bool? ?? false,
      authData: json['auth_data'],
    );
  }
}
```

### 2.3 设备ID生成服务

**文件路径**：`/lib/features/newApp/utils/device_id_service.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static Future<String> getDeviceId() async {
    // 获取持久化存储中的设备ID
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    // 如果不存在，则生成新的随机UUID作为设备ID
    if (deviceId == null) {
      deviceId = const Uuid().v4(); // 生成标准UUID，长度为36字符（含连字符）
      
      // UUID格式：8-4-4-4-12，例如：123e4567-e89b-12d3-a456-426614174000
      // 数据库长度限制为64字符，UUID长度为36字符，完全满足要求
      
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }
}
```

## 3. 集成到应用流程

### 3.1 启动页面集成

**文件路径**：`/lib/features/newApp/auth/startup_page.dart`

在现有的StartupPage实现中，修改初始化流程，添加服务器连接检查和临时账号创建逻辑：

```dart
@override
void initState() {
  super.initState();
  
  // 初始化动画控制器（保留现有代码）
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  
  // 初始化动画（保留现有代码）
  // ...
  
  // 启动动画
  _animationController.forward();
  
  // 在动画播放的同时，初始化服务并准备导航
  _initializeServicesAndPrepareNavigation();
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
  try {
    // 使用xboard中的DomainService初始化HttpService
    await HttpService.initialize();
    debugPrint('【启动页】成功初始化HttpService，可用域名: ${HttpService.baseUrl}');
    return true;
  } catch (e) {
    debugPrint('【启动页】初始化HttpService失败: $e');
    return false;
  }
}

/// 检查认证状态并导航到相应页面
Future<void> _checkAuthAndNavigate(bool serviceInitialized) async {
  debugPrint('【启动页】开始检查认证状态');

  // 初始化认证服务
  await AuthService.instance.init();
  debugPrint('【启动页】认证服务初始化完成，当前登录状态: ${AuthService.instance.isLoggedIn}');

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
        final tempResult = await AuthService().tempAccountCreate(deviceId);
        
        if (tempResult['success'] == true && tempResult.containsKey('data')) {
          // 从响应中提取并存储信息
          final data = tempResult['data'] as Map<String, dynamic>;
          final authData = data['auth_data'] as Map<String, dynamic>;
          final token = authData['token'] as String;
          
          // 存储token
          await AuthService.instance.setToken(token);
          
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
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('temp_email', data['email'] as String);
  await prefs.setString('temp_password', data['password'] as String);
  await prefs.setInt('temp_expired_at', data['expired_at'] as int);
  await prefs.setBool('is_temp_account', true);
}
```

### 3.2 侧边栏集成

**文件路径**：`/lib/features/newApp/menu/widgets/side_menu.dart`

在侧边栏菜单中添加"升级账号"选项（仅当用户使用临时账号时显示），使用xboard中的验证逻辑：

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/lib/features/newApp/core/routes/app_routes.dart';

class SideMenu extends ConsumerWidget {
  const SideMenu({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          // 保留现有抽屉头部
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Center(
              child: Text(
                'Hiddify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          
          // 保留现有菜单项
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('主页'),
            onTap: () {
              Navigator.pop(context);
              NewAppRoutes.navigateTo(context, NewAppRoutes.home);
            },
          ),
          
          // 其他现有菜单项...
          
          // 临时账号升级选项（仅当用户使用临时账号时显示）
          FutureBuilder<bool>(
            future: _isTempAccount(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return ListTile(
                  leading: const Icon(Icons.upgrade, color: Colors.orange),
                  title: const Text(
                    '升级账号',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, NewAppRoutes.upgradeAccount);
                  },
                );
              }
              return const SizedBox.shrink(); // 非临时账号不显示此选项
            },
          ),
        ],
      ),
    );
  }
  
  // 使用SharedPreferences检查是否为临时账号
  Future<bool> _isTempAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_temp_account') ?? false;
  }
}
```

### 3.3 账号升级页面

**文件路径**：`/lib/features/newApp/auth/screens/account_upgrade_page.dart`

账号升级页面需要使用xboard中的UserService来进行账号升级：

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/lib/features/panel/xboard/services/http_service/user_service.dart';
import '/lib/features/newApp/auth/services/auth_service.dart';
import '/lib/features/newApp/core/routes/app_routes.dart';

class AccountUpgradePage extends StatefulWidget {
  const AccountUpgradePage({Key? key}) : super(key: key);

  @override
  _AccountUpgradePageState createState() => _AccountUpgradePageState();
}

class _AccountUpgradePageState extends State<AccountUpgradePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final UserService _userService = UserService(); // 使用xboard中的UserService

  @override
  void initState() {
    super.initState();
    _loadTempAccountInfo();
  }

  Future<void> _loadTempAccountInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final tempEmail = prefs.getString('temp_email');
    
    if (tempEmail != null) {
      setState(() {
        _emailController.text = tempEmail;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _upgradeAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = AuthService.instance.token;
      if (token == null) {
        _showError('未找到有效的登录信息');
        return;
      }

      // 使用xboard中的UserService进行账号升级
      final result = await _userService.convertTempAccount(
        _emailController.text,
        _passwordController.text,
        token,
      );

      if (result != null) {
        // 更新token
        await AuthService.instance.setToken(result);
        
        // 清除临时账号标记
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('temp_email');
        await prefs.remove('temp_password');
        await prefs.remove('temp_expired_at');
        await prefs.setBool('is_temp_account', false);
        
        if (mounted) {
          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('账号升级成功')),
          );
          // 返回主页
          NewAppRoutes.navigateAndRemoveUntil(context, NewAppRoutes.home);
        }
      } else {
        _showError('账号升级失败，请稍后再试');
      }
    } catch (e) {
      _showError('升级过程中发生错误: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 保留原始UI实现
    return Scaffold(
      appBar: AppBar(
        title: const Text('升级为正式账号'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '临时账号升级',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '设置您的电子邮箱和密码，将临时账号升级为正式账号，享受更多功能和更长的使用期限。',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '电子邮箱',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入您的电子邮箱';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return '请输入有效的电子邮箱地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码长度至少为6位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _upgradeAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('升级账号'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 4. 实施计划

### 4.1 开发步骤

1. **基础设施准备（0.5天）**
   - 创建简单的设备ID生成服务 `/lib/features/newApp/utils/device_id_service.dart`
   - **直接复用** xboard 下的数据模型和服务

2. **启动页面集成（1天）**
   - 修改启动页面初始化流程，添加DomainService域名检查
   - 实现临时账号创建和信息存储逻辑
   - 确保整个过程静默执行，不影响用户体验

3. **侧边栏集成（0.5天）**
   - 在侧边栏中添加"升级账号"选项（仅临时账号显示）
   - 确保不影响现有UI样式和结构

4. **账号升级功能（1天）**
   - 实现账号升级页面，使用xboard的UserService
   - 更新路由配置
   - 集成测试与修复

### 4.2 测试计划

1. **单元测试**
   - 测试设备ID生成逻辑
   - 测试临时账号相关功能整合

2. **集成测试**
   - 测试域名检查和服务初始化
   - 测试临时账号静默创建流程
   - 测试账号升级流程
   - 测试侧边栏"升级账号"选项显示逻辑

3. **手动测试**
   - 首次启动应用时自动创建临时账号（验证是否静默）
   - 应用重启后使用已有临时账号（验证token保存）
   - 从侧边栏进入账号升级页面
   - 账号升级全流程测试

### 4.3 注意事项

1. **复用现有服务**
   - 始终优先使用xboard目录下已实现的服务和工具
   - 不重复开发已存在的功能
   - 如必须添加新功能，遵循现有架构

2. **保持现有UI不变**
   - 严格按照现有UI样式实现功能
   - 不修改现有布局和组件样式
   - 只添加功能性代码，不影响视觉表现

3. **静默处理**
   - 临时账号创建过程完全静默，不显示任何加载提示或弹窗
   - 域名检查失败时的静默降级
   - 即使创建失败也不打断用户体验，继续常规流程

4. **边缘情况处理**
   - 网络不可用时的降级处理
   - 服务器错误时的静默降级
   - 设备ID获取失败的备选方案

## 5. 后续优化方向

1. **账号管理优化**
   - 临时账号有效期监控
   - 临时账号自动升级提示（在侧边栏或用户中心）
   - 临时账号到期前预警

2. **用户体验优化**
   - 适当时机引导用户升级账号（不打扰正常使用）
   - 侧边栏中的提示优化
   - 临时账号状态指示的优化

## 6. 依赖库

需要添加或确保已添加以下依赖库：

```yaml
# pubspec.yaml 依赖配置
dependencies:
  # 工具库
  uuid: ^3.0.6
  
  # 现有项目中已有的依赖
  shared_preferences: ^2.0.15
  http: ^0.13.5
``` 