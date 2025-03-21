# Hiddify VPN连接过程详细文档

## 1. 概述

本文档详细描述了Hiddify应用中VPN连接的完整过程，包括用户界面交互、连接状态管理、底层服务调用以及系统集成。这些内容可帮助开发者理解应用的核心功能实现方式。

## 2. 架构设计

Hiddify应用采用了分层架构设计，连接过程涉及以下几个主要层级：

1. **UI层**：用户界面组件，包括连接按钮和状态显示
2. **状态管理层**：使用Riverpod管理连接状态
3. **业务逻辑层**：包含Repository和Service实现
4. **平台集成层**：连接到系统VPN服务和Singbox核心

### 2.1 核心组件

- **ConnectionButton**：主界面上的连接/断开按钮
- **ConnectionNotifier**：管理连接状态的Riverpod提供者
- **ConnectionRepository**：处理连接业务逻辑
- **SingboxService**：与Singbox核心进行交互的服务
- **ConnectionStatus**：表示连接状态的枚举（已连接、连接中、已断开等）

## 3. 连接状态流程

Hiddify使用状态机管理VPN连接过程，主要状态包括：

- **Disconnected**：已断开连接（可能包含失败原因）
- **Connecting**：正在连接
- **Connected**：已连接
- **Disconnecting**：正在断开连接

状态转换由用户交互和系统事件触发，通过`ConnectionNotifier`进行管理和分发。

## 4. 详细连接流程

### 4.1 初始化过程

1. 应用启动时：
   - 初始化`SingboxService`
   - 加载配置选项
   - 设置目录结构
   - 检查系统权限

2. 主界面加载：
   - 显示连接按钮
   - 注册连接状态监听器
   - 加载当前活跃配置文件

### 4.2 连接触发过程

当用户点击连接按钮时：

1. **UI交互**：
   ```dart
   // ConnectionButton.dart
   onTap: switch (connectionStatus) {
     AsyncData(value: Disconnected()) || AsyncError() => () async {
         if (await showExperimentalNotice()) {
           return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
         }
       },
     // 其他状态...
   }
   ```

2. **状态管理**：
   ```dart
   // ConnectionNotifier.dart
   Future<void> toggleConnection() async {
     // 处理连接/断开连接逻辑
     switch (value) {
       case Disconnected():
         await haptic.lightImpact();
         await ref.read(Preferences.startedByUser.notifier).update(true);
         await _connect();
       // 其他状态...
     }
   }
   ```

3. **连接实现**：
   ```dart
   // ConnectionNotifier.dart
   Future<void> _connect() async {
     final activeProfile = await ref.read(activeProfileProvider.future);
     if (activeProfile == null) {
       loggy.info("no active profile, not connecting");
       return;
     }
     await _connectionRepo.connect(
       activeProfile.id,
       activeProfile.name,
       ref.read(Preferences.disableMemoryLimit),
       activeProfile.testUrl,
     ).mapLeft((err) async {
       // 错误处理...
     }).run();
   }
   ```

4. **底层服务调用**：
   ```dart
   // ConnectionRepository.dart
   TaskEither<ConnectionFailure, Unit> connect(
     String fileName,
     String profileName,
     bool disableMemoryLimit,
     String? testUrl,
   ) {
     return TaskEither<ConnectionFailure, Unit>.Do(
       ($) async {
         var options = await $(getConfigOption());
         // 检查权限
         // 设置配置项
         // 启动Singbox服务
         return await $(
           singbox.start(
             profilePathResolver.file(fileName).path,
             profileName,
             disableMemoryLimit,
           ).mapLeft(UnexpectedConnectionFailure.new),
         );
       },
     );
   }
   ```

5. **平台集成**：
   - Android/iOS: 通过`PlatformSingboxService`与原生代码交互
   - Windows/macOS/Linux: 通过`FFISingboxService`与Singbox库进行FFI集成

### 4.3 VPN服务启动

1. **配置准备**：
   - 加载用户选择的配置文件
   - 应用全局设置（如DNS、路由规则等）
   - 验证配置有效性

2. **权限检查**：
   - 检查VPN权限
   - 检查通知权限（如需要）
   - 检查特权模式（TUN模式需要）

3. **服务启动**：
   - 创建VPN服务
   - 配置路由表
   - 建立DNS解析器
   - 初始化代理组件

4. **状态监听**：
   - 通过Stream接收服务状态更新
   - 将状态变化转发到UI层

### 4.4 断开连接过程

1. **用户触发**：
   - 点击已连接状态下的按钮
   - 通过系统通知关闭

2. **状态转换**：
   - 将状态更新为`Disconnecting`
   - 触发断开连接操作

3. **服务关闭**：
   ```dart
   // ConnectionRepository.dart
   TaskEither<ConnectionFailure, Unit> disconnect() {
     return TaskEither<ConnectionFailure, Unit>.Do(
       ($) async {
         // 检查权限和配置
         return await $(
           singbox.stop().mapLeft(UnexpectedConnectionFailure.new),
         );
       },
     );
   }
   ```

4. **资源清理**：
   - 关闭VPN隧道
   - 恢复系统网络设置
   - 更新UI状态为`Disconnected`

## 5. 特殊场景处理

### 5.1 配置切换

当用户切换活跃的配置文件时：

```dart
// ConnectionNotifier.dart
ref.listen(
  activeProfileProvider.select((value) => value.asData?.value),
  (previous, next) async {
    if (previous == null) return;
    final shouldReconnect = next == null || previous.id != next.id;
    if (shouldReconnect) {
      await reconnect(next);
    }
  },
);
```

系统会自动断开当前连接，并使用新的配置文件重新连接。

### 5.2 错误处理

连接过程中的常见错误：

1. **配置无效**：显示错误消息，保持断开状态
2. **缺少权限**：提示用户授予VPN权限
3. **连接超时**：自动重试或提示用户检查网络
4. **系统限制**：提供解决方案（如电池优化设置）

错误处理流程：

```dart
// ConnectionNotifier.dart
ref.listen(
  connectionNotifierProvider,
  (_, next) {
    if (next case AsyncError(:final error)) {
      CustomAlertDialog.fromErr(t.presentError(error)).show(context);
    }
    if (next case AsyncData(value: Disconnected(:final connectionFailure?))) {
      CustomAlertDialog.fromErr(t.presentError(connectionFailure)).show(context);
    }
  },
);
```

### 5.3 后台运行

Hiddify支持在后台保持VPN连接：

1. **通知栏**：显示持久通知，提供快速操作
2. **服务保活**：使用前台服务确保VPN连接不被系统终止
3. **电池优化**：提示用户关闭电池优化以获得更稳定的连接

## 6. 技术实现细节

### 6.1 系统集成

- **Android**：使用VpnService API
- **iOS**：使用NetworkExtension框架
- **桌面平台**：通过Singbox的TUN模式或系统代理

### 6.2 Singbox核心

Singbox是Hiddify的核心组件，负责：

1. **协议支持**：处理多种代理协议（Shadowsocks、VMess、Trojan等）
2. **路由规则**：根据规则集转发流量
3. **DNS解析**：提供本地DNS服务
4. **流量统计**：监控上传/下载流量

### 6.3 性能考虑

- **内存限制**：移动平台可选择禁用内存限制提高性能
- **电池优化**：处理系统休眠和后台运行
- **连接测试**：自动进行延迟测试选择最佳节点

## 7. 用户体验优化

### 7.1 视觉反馈

- **按钮状态**：根据连接状态改变颜色和图标
- **动画过渡**：连接状态变化时提供平滑动画
- **触觉反馈**：连接/断开时提供触觉反馈

### 7.2 辅助功能

- **语义标签**：为连接按钮提供辅助功能标签
- **状态朗读**：连接状态变化时提供语音反馈

## 8. 连接过程流程图

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│             │     │             │     │             │     │             │
│  已断开连接  │──→──│   连接中    │──→──│   已连接    │──→──│  断开连接中  │
│             │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       ↑                                                           │
       │                                                           │
       └───────────────────────────────────────────────────────────┘
```

## 9. 调试与故障排除

1. **日志记录**：
   - 连接过程详细日志
   - Singbox核心日志
   - 错误堆栈跟踪

2. **常见问题**：
   - VPN权限问题
   - 配置格式错误
   - 系统限制（如电池优化、后台限制）
   - 代理服务器连接失败

3. **解决方案**：
   - 检查配置有效性
   - 验证网络连接
   - 重启应用或设备
   - 重置VPN设置

## 10. 总结

Hiddify应用的VPN连接过程是一个复杂但结构清晰的流程，从用户界面到底层系统集成，采用了分层设计和响应式状态管理。通过Singbox核心提供强大的代理功能，同时优化用户体验和系统集成，确保稳定可靠的VPN服务。 