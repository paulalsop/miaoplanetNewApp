# 新版界面API对接开发计划

## 1. 现有代码分析与理解

### 1.1 项目架构

Hiddify应用采用了清晰的分层架构，遵循MVVM（Model-View-ViewModel）设计模式，并结合Riverpod状态管理。项目分为以下几个层次：

```
UI层 (Views) ↔ 状态管理层 (ViewModels/Providers) ↔ 服务层 (Services) ↔ 数据源层 (Repositories) ↔ 网络/本地存储层 (API/Storage)
```

### 1.2 现有API服务实现

现有的API实现位于`/lib/features/panel/xboard/`目录下，主要包含以下几个核心组件：

#### HTTP基础服务
- **HttpService**：封装基础HTTP GET/POST请求，处理请求头和错误情况
- **DomainService**：负责动态获取有效的服务器域名，确保应用可以连接到可用服务器

#### 认证相关服务
- **AuthService**：处理登录、注册、验证码发送等认证流程
- **Token存储**：使用SharedPreferences存储和管理认证令牌
- **AuthProvider**：提供全局认证状态管理

#### 用户信息服务
- **UserService**：获取用户资料、订阅链接等用户相关信息
- **UserInfo模型**：定义用户数据结构和JSON解析

#### 其他业务服务
- **InviteCodeService**：处理邀请码生成和获取
- **PlanService**：处理套餐相关API
- **SubscriptionService**：管理用户订阅信息

#### ViewModel层
- **LoginViewModel**：管理登录状态和逻辑
- **UserInfoViewModel**：管理用户信息的获取和状态

### 1.3 现有API调用流程

1. 用户触发操作（如登录）
2. ViewModel调用对应Service
3. Service通过HttpService发送网络请求
4. 解析响应并更新状态
5. 通知UI层更新

### 1.4 VPN连接实现逻辑

Hiddify应用的核心功能是VPN连接，其实现采用了多层架构：

#### 1.4.1 连接架构

1. **用户界面层**：
   - `ConnectionButton` 组件提供了连接/断开按钮
   - 根据连接状态显示不同的视觉反馈（按钮颜色、文本等）
   - 监听用户点击，触发连接状态切换

2. **状态管理层**：
   - `ConnectionNotifier`（Riverpod状态提供者）管理整个连接状态
   - 使用状态机模型处理不同状态（已连接、连接中、已断开等）
   - 处理连接切换逻辑，如启动连接、断开连接、重新连接等

3. **业务逻辑层**：
   - `ConnectionRepository` 处理连接业务逻辑
   - 负责加载配置、启动服务、管理连接状态
   - 处理错误情况并进行适当的转换

4. **服务层**：
   - `SingboxService` 是底层VPN服务的抽象接口
   - 根据不同平台使用不同实现：
     - `PlatformSingboxService`：移动平台（Android/iOS）
     - `FFISingboxService`：桌面平台（Windows/macOS/Linux）

#### 1.4.2 连接流程

1. **初始化**：应用启动时初始化SingboxService、设置目录结构
2. **连接触发**：用户点击连接按钮，调用ConnectionNotifier.toggleConnection()
3. **配置加载**：加载当前活跃的配置文件
4. **服务启动**：
   - 调用SingboxService.start()启动VPN服务
   - 传递配置文件路径、名称和内存限制选项
5. **状态监听**：持续监听连接状态变化，更新UI
6. **断开连接**：用户点击已连接状态下的按钮，触发disconnnect()方法
7. **错误处理**：处理各种连接错误，并向用户提供反馈

### 1.5 订阅节点解析实现

订阅节点功能允许用户通过URL导入和管理代理配置：

#### 1.5.1 订阅流程

1. **获取订阅链接**：
   - 通过`SubscriptionService.getSubscriptionLink()`获取用户的订阅URL
   - 使用HTTP API `/api/v1/user/getSubscribe`从服务器获取订阅链接
   - 支持重置订阅链接（`resetSubscriptionLink`方法）

2. **订阅处理流程**：
   - `Subscription`类负责处理订阅相关逻辑
   - 获取订阅链接后，删除旧的配置文件
   - 添加新的订阅链接，生成新的配置文件
   - 将新配置设置为活动配置

3. **配置解析**：
   - `ProfileParser`负责解析订阅配置
   - 处理不同的订阅格式（base64编码、文本等）
   - 解析订阅信息，如流量限制、过期时间等

4. **配置管理**：
   - `ProfileRepository`管理所有配置文件
   - 支持远程配置（RemoteProfileEntity）和本地配置（LocalProfileEntity）
   - 监听配置变化，自动更新状态

#### 1.5.2 关键组件

1. **ProfileEntity**：定义配置文件的数据结构，包含远程和本地类型
2. **SubscriptionInfo**：存储订阅的元数据，包含流量使用信息
3. **ProfileParser**：解析订阅URL和响应头，提取配置信息
4. **ActiveProfileNotifier**：管理当前激活的配置文件

#### 1.5.3 VPN与订阅集成

VPN连接和订阅节点功能紧密集成：
- 当活跃配置变更时，自动重新连接VPN
- 订阅更新后会更新当前配置并重新应用
- 连接状态和订阅信息在UI上同步显示

## 2. 新版界面API对接计划

### 2.1 对接策略

我们将采用以下几种策略对新界面进行API对接：

1. **服务层复用**：尽可能复用现有的服务层代码，确保API调用一致性
2. **模型层适配**：使用相同的数据模型或进行适当调整
3. **状态管理重构**：使用Riverpod重新设计状态管理逻辑，适应新UI
4. **增量开发**：按功能模块逐步实现API对接，确保每个部分稳定后再进行下一步

### 2.2 实施步骤

#### 第一阶段：基础设施搭建

1. **HTTP基础服务移植**
   - 将HttpService和DomainService移植到新界面服务层
   - 确保请求/响应处理和错误处理机制正常
   - 增加请求状态和日志记录功能

2. **数据模型移植**
   - 复用UserInfo、Plan、InviteCode等数据模型
   - 根据新UI需求调整或扩展模型

3. **认证服务实现**
   - 完善AuthService实现真实登录/注册API调用
   - 实现Token管理机制
   - 设计全局认证状态Provider

#### 第二阶段：核心功能API对接

1. **登录/注册功能**
   - 实现登录页面与API对接
   - 实现注册页面与API对接
   - 完善表单验证和错误处理

2. **用户信息功能**
   - 实现用户信息获取和展示
   - 设计用户信息缓存机制
   - 实现资料更新功能

3. **连接功能**
   - 复用现有`ConnectionNotifier`和`ConnectionRepository`
   - 设计新的连接按钮UI组件，保持原有状态流
   - 确保与Singbox服务的正确交互
   - 实现连接状态的新UI反馈

4. **订阅功能**
   - 复用`SubscriptionService`和订阅处理逻辑
   - 设计新的订阅管理界面
   - 保持与配置解析系统的兼容性
   - 优化订阅信息展示（流量使用、过期时间等）

#### 第三阶段：扩展功能API对接

1. **会员功能**
   - 实现套餐信息获取和展示
   - 对接套餐购买API
   - 实现会员状态管理

2. **节点选择功能**
   - 实现节点列表获取和展示
   - 对接节点切换API
   - 实现节点测速功能

3. **邀请码功能**
   - 实现邀请码生成和管理
   - 对接邀请码API
   - 实现邀请记录跟踪

#### 第四阶段：优化与完善

1. **错误处理优化**
   - 完善网络错误处理机制
   - 实现友好的错误提示
   - 增加自动重试机制

2. **性能优化**
   - 实现数据缓存策略
   - 优化请求频率和批量处理
   - 减少不必要的API调用

3. **测试与验证**
   - 编写单元测试和集成测试
   - 进行端到端测试
   - 修复发现的问题

## 3. 技术要点与注意事项

### 3.1 技术要点

1. **状态管理**
   - 使用Riverpod进行状态管理
   - 设计清晰的Provider结构
   - 合理处理异步状态

2. **错误处理**
   - 统一的错误处理机制
   - 优雅降级策略
   - 用户友好的错误提示

3. **缓存策略**
   - 合理使用内存缓存
   - 持久化关键数据
   - 缓存失效机制

4. **安全考虑**
   - 安全存储敏感信息
   - 防止过度请求
   - 数据传输加密

5. **VPN连接管理**
   - 保持与Singbox核心的兼容性
   - 确保平台特定实现的正确性
   - 优化连接状态变更的响应速度
   - 增强错误处理和恢复机制

6. **订阅配置管理**
   - 优化订阅解析效率
   - 提升配置文件管理体验
   - 增强订阅信息的可视化展示

### 3.2 注意事项

1. **兼容性**
   - 确保新旧界面可以共存
   - 避免状态冲突
   - 共享关键数据

2. **用户体验**
   - 减少加载等待时间
   - 提供明确的操作反馈
   - 保持界面响应流畅

3. **代码质量**
   - 保持代码一致性
   - 编写清晰的注释
   - 避免代码重复

4. **VPN特定考虑**
   - 处理不同平台的权限问题
   - 解决电池优化和后台运行限制
   - 确保稳定的VPN连接维护

## 4. 具体实现细节

### 4.1 复用API服务示例

```dart
// 新版认证服务 - 复用现有API逻辑但适应新UI
class NewAuthService {
  final HttpService _httpService;
  
  NewAuthService({HttpService? httpService}) 
      : _httpService = httpService ?? HttpService();
  
  Future<LoginResult> login(String email, String password) async {
    try {
      final result = await _httpService.postRequest(
        "/api/v1/passport/auth/login",
        {"email": email, "password": password},
        headers: {'Content-Type': 'application/json'},
      );
      
      // 处理响应并返回结构化结果
      return LoginResult.fromJson(result);
    } catch (e) {
      // 统一错误处理
      return LoginResult.error(e.toString());
    }
  }
  
  // 其他认证方法...
}
```

### 4.2 状态管理示例

```dart
// 用户认证状态Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// 认证状态通知器
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthService _authService;
  
  AuthNotifier(this._ref) 
    : _authService = _ref.read(authServiceProvider),
      super(const AuthState.initial());
  
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    
    try {
      final result = await _authService.login(email, password);
      if (result.success && result.token != null) {
        await TokenStorage.saveToken(result.token!);
        state = AuthState.authenticated(result.user);
      } else {
        state = AuthState.error(result.message ?? "登录失败");
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  // 其他认证方法...
}
```

### 4.3 VPN连接组件示例

```dart
// 简化的连接按钮示例
class NewConnectionButton extends ConsumerWidget {
  const NewConnectionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionNotifierProvider);
    
    return GestureDetector(
      onTap: () {
        if (!connectionStatus.isLoading) {
          ref.read(connectionNotifierProvider.notifier).toggleConnection();
        }
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getButtonColor(connectionStatus),
        ),
        child: Center(
          child: Text(
            _getButtonText(connectionStatus),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
  
  Color _getButtonColor(AsyncValue<ConnectionStatus> status) {
    return status.when(
      data: (status) => status.isConnected ? Colors.green : Colors.red,
      loading: () => Colors.grey,
      error: (_, __) => Colors.orange,
    );
  }
  
  String _getButtonText(AsyncValue<ConnectionStatus> status) {
    return status.when(
      data: (status) => status.isConnected ? "已连接" : "未连接",
      loading: () => "连接中...",
      error: (_, __) => "连接错误",
    );
  }
}
```

### 4.4 订阅管理示例

```dart
// 订阅更新处理示例
Future<void> updateSubscription(BuildContext context, WidgetRef ref) async {
  final authState = ref.read(authStateProvider);
  if (!authState.isAuthenticated) {
    // 显示错误：用户未登录
    return;
  }
  
  try {
    // 显示加载状态
    ref.read(subscriptionStateProvider.notifier).setLoading();
    
    // 获取订阅链接
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final token = await TokenStorage.getToken();
    final subscriptionUrl = await subscriptionService.getSubscriptionLink(token!);
    
    if (subscriptionUrl != null) {
      // 更新配置文件
      await ref.read(profileManagerProvider).updateFromUrl(subscriptionUrl);
      
      // 更新状态为成功
      ref.read(subscriptionStateProvider.notifier).setSuccess();
      
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("订阅更新成功")),
      );
    }
  } catch (e) {
    // 更新状态为错误
    ref.read(subscriptionStateProvider.notifier).setError(e.toString());
    
    // 显示错误提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("订阅更新失败: $e")),
    );
  }
}
```

## 5. 开发时间规划

|阶段|功能|预计时间|
|---|---|---|
|第一阶段|基础设施搭建|3天|
|第二阶段|核心功能API对接|7天|
|第三阶段|扩展功能API对接|5天|
|第四阶段|优化与完善|4天|
|测试与调整|全面测试|3天|

总计开发时间：约22天

## 6. 后续升级与维护

1. **持续优化**
   - 根据用户反馈调整API调用逻辑
   - 优化性能和内存使用
   - 完善VPN连接稳定性

2. **功能扩展**
   - 对接更多API接口
   - 增加新的数据模型和服务
   - 支持更多订阅格式和协议

3. **文档维护**
   - 保持API文档更新
   - 记录重要设计决策
   - 维护VPN连接和订阅逻辑文档 