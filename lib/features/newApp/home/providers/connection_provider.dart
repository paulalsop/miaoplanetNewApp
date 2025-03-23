import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../panel/xboard/utils/storage/token_storage.dart';
import '../../../panel/xboard/services/http_service/user_service.dart';
import '../../../panel/xboard/services/http_service/http_service.dart';
import '../../../panel/xboard/services/subscription.dart';
import '../../../connection/data/connection_data_providers.dart';
import '../../../connection/notifier/connection_notifier.dart';
import '../../../connection/model/connection_status.dart';
import '../../../profile/notifier/active_profile_notifier.dart';
import '../../../profile/data/profile_data_providers.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/notifier/profile_notifier.dart';
import '../../utils/connection_error_handler.dart';

/// 连接状态枚举
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

/// 连接数据模型
class ConnectionData {
  final ConnectionStatus status;
  final Duration connectedDuration;
  final double downloadSpeed; // KB/s
  final double uploadSpeed; // KB/s
  final String serverName;
  final int pingValue; // ms

  const ConnectionData({
    this.status = ConnectionStatus.disconnected,
    this.connectedDuration = Duration.zero,
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.serverName = '',
    this.pingValue = 0,
  });

  ConnectionData copyWith({
    ConnectionStatus? status,
    Duration? connectedDuration,
    double? downloadSpeed,
    double? uploadSpeed,
    String? serverName,
    int? pingValue,
  }) {
    return ConnectionData(
      status: status ?? this.status,
      connectedDuration: connectedDuration ?? this.connectedDuration,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      serverName: serverName ?? this.serverName,
      pingValue: pingValue ?? this.pingValue,
    );
  }

  /// 获取连接时间的格式化字符串 (HH:MM:SS)
  String get formattedDuration {
    final hours = connectedDuration.inHours.toString().padLeft(2, '0');
    final minutes =
        (connectedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
        (connectedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// 连接状态提供者
class ConnectionNotifier extends StateNotifier<ConnectionData> {
  ConnectionNotifier(this.ref) : super(const ConnectionData()) {
    _initializeConnection();
  }

  final Ref ref;
  Timer? _durationTimer;
  Timer? _speedUpdateTimer;
  bool _initialSetupDone = false;
  bool _isFirstConnect = true;

  // 初始化连接，包括获取当前连接状态和设置计时器
  Future<void> _initializeConnection() async {
    // 监听现有的ConnectionNotifier中的连接状态
    ref.listen(connectionNotifierProvider, (previous, next) {
      if (next is AsyncData) {
        // 转换连接状态
        ConnectionStatus newStatus;
        if (next.value is Connected) {
          debugPrint('检测到已连接状态，更新UI...');
          newStatus = ConnectionStatus.connected;

          // 更新状态并启动计时器
          state = state.copyWith(
            status: newStatus,
            connectedDuration: Duration.zero,
          );

          // 确保计时器已启动
          _setupTimers();

          debugPrint('状态已更新为Connected: ${state.status}');
        } else if (next.value is Connecting) {
          debugPrint('检测到Connecting状态，更新UI...');
          newStatus = ConnectionStatus.connecting;
          state = state.copyWith(status: newStatus);
        } else {
          debugPrint('检测到Disconnected状态，更新UI...');
          newStatus = ConnectionStatus.disconnected;
          state = state.copyWith(
            status: newStatus,
            connectedDuration: Duration.zero,
            downloadSpeed: 0,
            uploadSpeed: 0,
          );

          // 断开时取消计时器
          _durationTimer?.cancel();
          _speedUpdateTimer?.cancel();
        }
      }
    });

    // 获取保存的配置信息（服务器名称等）
    _loadSavedSettings();

    // 检查初始连接状态
    try {
      final currentStatus = await ref.read(connectionNotifierProvider.future);
      debugPrint('初始化时检查到连接状态: ${currentStatus.runtimeType}');

      if (currentStatus is Connected) {
        debugPrint('应用启动时已连接，更新UI状态...');
        state = state.copyWith(status: ConnectionStatus.connected);
        _setupTimers();
      }
    } catch (e) {
      debugPrint('检查初始连接状态失败: $e');
    }

    // 如果是第一次启动应用，自动获取订阅链接和配置
    if (!_initialSetupDone) {
      _initialSetupDone = true;
      _setupInitialConfig();
    }
  }

  // 加载保存的设置
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverName = prefs.getString('selected_server_name') ?? 'Auto';
      final pingValue = prefs.getInt('selected_server_ping') ?? 100;

      state = state.copyWith(
        serverName: serverName,
        pingValue: pingValue,
      );
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  // 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_server_name', state.serverName);
      await prefs.setInt('selected_server_ping', state.pingValue);
    } catch (e) {
      debugPrint('保存设置失败: $e');
    }
  }

  // 初始化计时器
  void _setupTimers() {
    // 取消可能已经存在的计时器
    _durationTimer?.cancel();
    _speedUpdateTimer?.cancel();

    // 创建新的计时器
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == ConnectionStatus.connected) {
        state = state.copyWith(
          connectedDuration:
              state.connectedDuration + const Duration(seconds: 1),
        );
      }
    });

    // 创建网速更新计时器
    _speedUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == ConnectionStatus.connected) {
        // 这里需要从实际流量数据中获取，这里只是模拟
        final downloadSpeed =
            (state.downloadSpeed + _getRandomSpeed()).clamp(0.0, 500.0);
        final uploadSpeed =
            (state.uploadSpeed + _getRandomSpeed()).clamp(0.0, 200.0);

        state = state.copyWith(
          downloadSpeed: downloadSpeed,
          uploadSpeed: uploadSpeed,
        );
      }
    });

    debugPrint('计时器已设置');
  }

  // 生成随机网速变化（模拟）
  double _getRandomSpeed() {
    final random = DateTime.now().millisecondsSinceEpoch % 100 - 50;
    return random / 10;
  }

  // 初始化配置，包括获取订阅链接
  Future<void> _setupInitialConfig() async {
    try {
      // 尝试直接获取订阅链接，不依赖于 profileRepository
      await _setupSubscription();

      // 成功获取并添加订阅后，尝试查看是否有活跃配置文件
      try {
        debugPrint('尝试检查活跃配置文件...');
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        debugPrint('ProfileRepository加载完成');

        final profiles = await profileRepo.watchAll().first;
        final activeProfiles = profiles
            .getOrElse(
              (failure) {
                debugPrint('获取配置文件列表失败: $failure');
                return [];
              },
            )
            .where((profile) => profile.active)
            .toList();

        final activeProfile =
            activeProfiles.isNotEmpty ? activeProfiles.first : null;
        if (activeProfile != null) {
          debugPrint('已存在活跃配置文件: ${activeProfile.name}');
          // 更新服务器名称
          state = state.copyWith(serverName: activeProfile.name);
        } else {
          debugPrint('没有活跃的配置文件');
        }
      } catch (e) {
        debugPrint('检查活跃配置文件失败: $e');
        // 即使检查失败，在前面已经尝试获取过订阅链接了
      }
    } catch (e, stackTrace) {
      debugPrint('初始化配置失败: $e');
      debugPrint('错误堆栈: $stackTrace');
    }
  }

  // 单独提取订阅设置方法，以便于错误处理和重试
  Future<void> _setupSubscription() async {
    // 确保HttpService已初始化
    try {
      if (!HttpService.isInitialized) {
        debugPrint('正在初始化HTTP服务...');
        await HttpService.initialize();
        debugPrint('HTTP服务初始化成功');
      }
    } catch (e) {
      debugPrint('HTTP服务初始化失败: $e');
      // 即使HTTP服务初始化失败，仍然尝试获取token和订阅链接
    }

    final token = await getToken();
    if (token == null) {
      debugPrint('未找到token，无法获取订阅链接');
      return;
    }

    try {
      // 获取订阅链接
      final userService = UserService();
      String? subscribeUrl;

      // 尝试多次获取订阅链接
      for (int i = 0; i < 3; i++) {
        try {
          subscribeUrl = await userService.getSubscriptionLink(token);
          if (subscribeUrl != null) break;
        } catch (e) {
          debugPrint('第${i + 1}次获取订阅链接失败: $e');
          if (i < 2) await Future.delayed(Duration(seconds: 2)); // 延迟2秒后重试
        }
      }

      if (subscribeUrl != null) {
        debugPrint('成功获取订阅链接: $subscribeUrl');
        try {
          // 添加配置文件
          final addProfileNotifier = ref.read(addProfileProvider.notifier);
          await addProfileNotifier.add(subscribeUrl);
          debugPrint('成功添加订阅链接到配置文件');
        } catch (e) {
          debugPrint('添加订阅链接到配置文件失败: $e');
        }
      } else {
        debugPrint('获取订阅链接失败，请检查网络连接');
      }
    } catch (e) {
      debugPrint('获取订阅链接失败: $e');
    }
  }

  /// 连接到服务器
  Future<void> connect(BuildContext? context) async {
    if (state.status != ConnectionStatus.disconnected) return;

    // 设置为连接中状态
    state = state.copyWith(status: ConnectionStatus.connecting);

    try {
      // 确保有订阅链接
      await _setupSubscription();

      // 直接使用现有的连接服务，不依赖profileRepository
      final connectionNotifier = ref.read(connectionNotifierProvider.notifier);

      // 重试连接，最多3次
      Exception? lastError;
      for (int i = 0; i < 3; i++) {
        try {
          debugPrint('尝试连接 (尝试 ${i + 1}/3)...');
          await connectionNotifier.toggleConnection();
          debugPrint('连接成功');

          // 手动更新状态为已连接
          state = state.copyWith(
              status: ConnectionStatus.connected,
              connectedDuration: Duration.zero);

          // 确保定时器运行
          _setupTimers();

          debugPrint('连接后UI状态已更新: ${state.status}');
          return; // 连接成功，直接返回
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          debugPrint('第${i + 1}次连接尝试失败: $e');
          if (i < 2) await Future.delayed(Duration(seconds: 1)); // 延迟后重试
        }
      }

      // 如果所有尝试均失败
      throw lastError ?? Exception("连接失败，原因未知");
    } catch (e, stackTrace) {
      debugPrint('连接出错: $e');
      debugPrint('连接错误堆栈: $stackTrace');
      // 恢复为断开状态
      state = state.copyWith(status: ConnectionStatus.disconnected);

      // 如果提供了上下文，显示错误提示
      if (context != null) {
        ConnectionErrorHandler.showErrorToast(context, e);
      }
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (state.status == ConnectionStatus.disconnected) return;

    try {
      debugPrint('正在尝试断开VPN连接...');

      // 直接使用_disconnect方法而不是toggleConnection
      final connectionNotifier = ref.read(connectionNotifierProvider.notifier);

      // 使用toggleConnection方法断开连接
      await connectionNotifier.toggleConnection();

      // 手动更新UI状态为断开连接
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
        connectedDuration: Duration.zero,
        downloadSpeed: 0,
        uploadSpeed: 0,
      );

      // 停止计时器
      _durationTimer?.cancel();
      _speedUpdateTimer?.cancel();

      debugPrint('断开连接命令已发送，UI状态已更新: ${state.status}');
    } catch (e) {
      debugPrint('断开连接出错: $e');

      // 尝试备用方法
      try {
        debugPrint('尝试使用备用方法断开连接...');
        final connectionRepo = ref.read(connectionRepositoryProvider);
        if (connectionRepo != null) {
          await connectionRepo.disconnect().run();
          debugPrint('备用方法断开连接成功');

          // 更新UI状态
          state = state.copyWith(
            status: ConnectionStatus.disconnected,
            connectedDuration: Duration.zero,
            downloadSpeed: 0,
            uploadSpeed: 0,
          );
        }
      } catch (e2) {
        debugPrint('所有断开连接尝试均失败: $e2');
      }
    }
  }

  /// 强制更新UI状态为断开（不进行实际VPN断开操作）
  void forceDisconnectUI() {
    debugPrint('强制将UI状态更新为已断开');

    // 手动更新UI状态为断开连接
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      connectedDuration: Duration.zero,
      downloadSpeed: 0,
      uploadSpeed: 0,
    );

    // 停止计时器
    _durationTimer?.cancel();
    _speedUpdateTimer?.cancel();

    debugPrint('UI状态已更新为已断开');
  }

  /// 强制更新UI状态为已连接（不进行实际VPN连接操作）
  void forceUpdateConnectedUI() {
    debugPrint('强制将UI状态更新为已连接');

    // 手动更新UI状态为已连接
    state = state.copyWith(
      status: ConnectionStatus.connected,
    );

    // 确保计时器已启动
    _setupTimers();

    debugPrint('UI状态已更新为已连接');
  }

  /// 设置选中的服务器
  void setSelectedServer({required String name, required int pingValue}) {
    state = state.copyWith(
      serverName: name,
      pingValue: pingValue,
    );
    _saveSettings();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _speedUpdateTimer?.cancel();
    super.dispose();
  }
}

/// 全局连接状态提供者
final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionData>((ref) {
  return ConnectionNotifier(ref);
});
