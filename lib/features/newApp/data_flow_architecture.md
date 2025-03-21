# Hiddify应用数据流与存储架构文档

## 1. 概述

本文档详细描述了Hiddify应用中数据的获取、存储和使用的完整流程，帮助开发者理解应用的数据架构，为新UI界面的开发提供依据。应用采用了分层架构，遵循MVVM（Model-View-ViewModel）设计模式，并结合Riverpod状态管理。

## 2. 数据架构分层

Hiddify应用的数据架构采用了清晰的分层结构：

```
UI层 (Views) ↔ 状态管理层 (ViewModels/Providers) ↔ 服务层 (Services) ↔ 数据源层 (Repositories) ↔ 网络/本地存储层 (API/Storage)
```

### 2.1 各层职责

1. **UI层**：负责展示数据和接收用户输入
2. **状态管理层**：管理UI状态，协调数据流动
3. **服务层**：提供业务逻辑和数据处理
4. **数据源层**：抽象数据获取方式
5. **网络/本地存储层**：处理实际的API请求和本地存储操作

## 3. 数据模型（Models）

应用使用明确定义的数据模型类来表示各种实体：

**源文件目录：** `lib/features/panel/xboard/models/`

### 3.1 主要数据模型

- **UserInfo** (`user_info_model.dart`)：用户信息模型
- **Plan** (`plan_model.dart`)：套餐信息模型
- **Order** (`order_model.dart`)：订单信息模型
- **InviteCode** (`invite_code_model.dart`)：邀请码模型

### 3.2 数据模型示例

```dart
// user_info_model.dart
class UserInfo {
  final String email;
  final double transferEnable;
  final int? lastLoginAt;
  final int createdAt;
  // ... 其他属性
  
  // 从JSON构造函数
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      email: json['email'] as String? ?? '',
      // ... 其他属性映射
    );
  }
}
```

## 4. API数据获取流程

### 4.1 HTTP服务层

**源文件：** `lib/features/panel/xboard/services/http_service/http_service.dart`

HTTP服务封装了与API交互的基本方法：

```dart
class HttpService {
  static String baseUrl = '';
  
  // 初始化并设置基础URL
  static Future<void> initialize() async {
    baseUrl = await DomainService.fetchValidDomain();
  }
  
  // 执行GET请求
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    // 实现GET请求逻辑
  }
  
  // 执行POST请求
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresHeaders = true,
  }) async {
    // 实现POST请求逻辑
  }
}
```

### 4.2 Service层实现

**源文件目录：** `lib/features/panel/xboard/services/http_service/`

各个服务类封装了特定领域的API调用：

```dart
// auth_service.dart 示例
class AuthService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/login",
      {"email": email, "password": password},
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  // 其他身份验证方法...
}
```

## 5. 数据存储机制

### 5.1 Token存储

**源文件：** `lib/features/panel/xboard/utils/storage/token_storage.dart`

应用使用SharedPreferences存储认证令牌：

```dart
// 存储令牌
Future<void> storeToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

// 获取令牌
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

// 删除令牌
Future<void> deleteToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}
```

### 5.2 状态管理与缓存

应用使用Riverpod作为状态管理解决方案，包含以下Provider类型：

1. **StateProvider**：用于简单状态
2. **FutureProvider**：处理异步数据
3. **ChangeNotifierProvider**：管理复杂状态和通知

## 6. ViewModel层实现

**源文件目录：** `lib/features/panel/xboard/viewmodels/`

ViewModels负责处理业务逻辑和状态管理：

```dart
// user_info_viewmodel.dart 示例
class UserInfoViewModel extends ChangeNotifier {
  final UserService _userService;
  UserInfo? _userInfo;
  UserInfo? get userInfo => _userInfo;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserInfoViewModel({required UserService userService})
      : _userService = userService;

  Future<void> fetchUserInfo() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await getToken();
      if (token != null) {
        _userInfo = await _userService.fetchUserInfo(token);
      }
    } catch (e) {
      _userInfo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// 注册Provider
final userInfoViewModelProvider = ChangeNotifierProvider((ref) {
  return UserInfoViewModel(userService: UserService());
});
```

## 7. 完整数据流示例

以用户登录和信息获取为例，展示完整的数据流程：

1. **用户在UI层输入登录信息**
   ```dart
   ElevatedButton(
     onPressed: () => viewModel.login(context),
     child: Text('登录'),
   )
   ```

2. **ViewModel处理登录逻辑**
   ```dart
   Future<void> login(BuildContext context) async {
     try {
       final response = await _authService.login(emailController.text, passwordController.text);
       if (response['status'] == 'success') {
         final token = response['data']['token'];
         await storeToken(token);
         ref.read(authProvider.notifier).state = true;
       }
     } catch (e) {
       // 错误处理
     }
   }
   ```

3. **服务层调用API**
   ```dart
   Future<Map<String, dynamic>> login(String email, String password) async {
     return await _httpService.postRequest(
       "/api/v1/passport/auth/login",
       {"email": email, "password": password},
     );
   }
   ```

4. **存储认证Token**
   ```dart
   await storeToken(token);
   ```

5. **更新认证状态**
   ```dart
   ref.read(authProvider.notifier).state = true;
   ```

6. **获取用户信息**
   ```dart
   await userInfoViewModel.fetchUserInfo();
   ```

7. **UI层消费用户信息**
   ```dart
   final userInfo = ref.watch(userInfoProvider.value);
   Text('欢迎, ${userInfo?.email}');
   ```

## 8. 新UI开发注意事项

### 8.1 数据模型复用

新UI可以复用现有的数据模型类：

```dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
```

### 8.2 服务层集成

新UI也可以直接使用现有的服务类：

```dart
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';

final authService = AuthService();
final result = await authService.login(email, password);
```

### 8.3 状态管理选择

新UI可以选择继续使用Riverpod，或者采用其他状态管理方案：

```dart
// 使用 Riverpod
final userInfoProvider = FutureProvider<UserInfo?>((ref) async {
  final token = await getToken();
  if (token != null) {
    return await UserService().fetchUserInfo(token);
  }
  return null;
});
```

## 9. 数据流程图

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│             │      │             │      │             │      │             │
│     UI      │◄────►│  ViewModel  │◄────►│   Service   │◄────►│     API     │
│             │      │             │      │             │      │             │
└─────────────┘      └──────┬──────┘      └─────────────┘      └─────────────┘
                            │                                         ▲
                            │                                         │
                            ▼                                         │
                     ┌─────────────┐                           ┌─────────────┐
                     │             │                           │             │
                     │   Storage   │◄─────────────────────────►│    Model    │
                     │             │                           │             │
                     └─────────────┘                           └─────────────┘
```

## 10. 总结

Hiddify应用采用了分层架构和MVVM设计模式，通过明确的职责分离，使得数据获取、存储和使用流程清晰可维护。新UI界面可以在理解现有架构的基础上，选择复用或重构部分组件，确保与现有系统的兼容性。 