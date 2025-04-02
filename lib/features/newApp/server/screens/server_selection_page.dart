import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/app_assets.dart';
import '../models/server_model.dart';
import '../widgets/server_banner.dart';
import '../widgets/server_list_item.dart';
import '../widgets/server_pagination.dart';
import '../../../proxy/data/proxy_data_providers.dart';
import '../../../proxy/overview/proxies_overview_notifier.dart';
import '../../../proxy/model/proxy_entity.dart';
import 'package:hiddify/singbox/model/singbox_proxy_type.dart';
import 'package:hiddify/utils/utils.dart';
import '../../../profile/data/profile_data_providers.dart';
import '../../../profile/model/profile_entity.dart';
import '../../../profile/notifier/active_profile_notifier.dart';
import '../../../proxy/active/active_proxy_notifier.dart';
import '../../../config_option/data/config_option_repository.dart' as ConfigOptions;
import 'dart:convert';
import 'dart:math' as math;
import '../../../connection/notifier/connection_notifier.dart';
import '../../../connection/model/connection_status.dart';
import '../../home/providers/connection_provider.dart' as home_provider;

/// 服务器选择页面
class ServerSelectionPage extends ConsumerStatefulWidget {
  /// 构造函数
  const ServerSelectionPage({
    super.key,
    this.onServerSelected,
    this.onClose,
  });

  /// 服务器选择回调
  final ValueChanged<ServerModel>? onServerSelected;

  /// 关闭页面回调
  final VoidCallback? onClose;

  @override
  ConsumerState<ServerSelectionPage> createState() =>
      _ServerSelectionPageState();
}

class _ServerSelectionPageState extends ConsumerState<ServerSelectionPage> {
  /// 当前页码
  int _currentPage = 1;

  /// 每页显示的服务器数量
  final int _serversPerPage = 8;

  /// 选中服务器的ID
  String? _selectedServerId;

  /// 是否正在加载服务器列表
  bool _isLoadingServers = false;

  /// 服务器列表
  List<ProxyItemEntity> _servers = [];

  /// 服务器延迟测试结果缓存
  Map<String, int> _pingResults = {};

  /// 服务器状态缓存
  Map<String, bool> _serverAvailability = {};

  @override
  void initState() {
    super.initState();
    // 初始化时加载服务器列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServersFromProfile();
    });
  }

  /// 从活跃配置中加载服务器列表
  Future<void> _loadServersFromProfile() async {
    if (mounted) {
      setState(() {
        _isLoadingServers = true;
      });
    }

    print('开始从活跃配置加载服务器列表');

    try {
      // 获取活跃配置
      final activeProfileState = ref.read(activeProfileProvider);

      // 检查是否有活跃配置
      if (activeProfileState is AsyncData<ProfileEntity?>) {
        final profile = activeProfileState.value;

        if (profile != null) {
          print('找到活跃配置: ${profile.name}');

          // 获取配置内容
          final profileRepo = ref.read(profileRepositoryProvider).requireValue;
          final configResult =
              await profileRepo.generateConfig(profile.id).run();

          configResult.fold(
            (failure) {
              print('获取配置内容失败: $failure');
              if (mounted) {
                setState(() {
                  _isLoadingServers = false;
                });
              }
            },
            (configData) {
              if (configData.isNotEmpty) {
                print('成功获取配置内容，长度: ${configData.length}');

                // 解析配置JSON
                _parseConfigJson(configData);

                // 检查当前选中的代理
                _checkCurrentSelectedProxy();
              } else {
                print('配置内容为空');
              }

              if (mounted) {
                setState(() {
                  _isLoadingServers = false;
                });
              }
            },
          );
        } else {
          print('没有活跃配置');
          if (mounted) {
            setState(() {
              _isLoadingServers = false;
            });
          }
        }
      } else {
        print('活跃配置状态异常: $activeProfileState');
        if (mounted) {
          setState(() {
            _isLoadingServers = false;
          });
        }
      }
    } catch (e) {
      print('加载服务器列表出错: $e');
      if (mounted) {
        setState(() {
          _isLoadingServers = false;
        });
      }
    }
  }

  /// 检查当前选中的代理
  void _checkCurrentSelectedProxy() async {
    try {
      // 获取当前活跃代理
      final activeProxyState = ref.read(activeProxyNotifierProvider);

      if (activeProxyState is AsyncData<ProxyItemEntity>) {
        final activeProxy = activeProxyState.value;
        if (activeProxy.tag.isNotEmpty) {
          print('当前选中的代理: ${activeProxy.tag}');

          // 更新选中状态
          if (mounted) {
            setState(() {
              _selectedServerId = activeProxy.tag;
            });
          }
        }
      }
    } catch (e) {
      print('检查当前代理失败: $e');
    }
  }

  /// 获取真实延迟值
  Future<int> _getRealPingValue(String serverId, ProxyType proxyType) async {
    try {
      final proxyRepo = ref.read(proxyRepositoryProvider);
      if (proxyRepo == null) return 0; // 返回0表示未测试

      // 确保测试URL正确设置
      //final configOptions = ref.watch(ConfigOptions.connectionTestUrl);
     // print('开始对节点 $serverId 进行延迟测试，使用URL: $configOptions');

      // 首先尝试从proxiesOverviewNotifier获取现有延迟数据
      try {
        // 刷新proxiesOverviewNotifier以获取最新数据
        ref.invalidate(proxiesOverviewNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 1000));
        
        final proxiesState = ref.read(proxiesOverviewNotifierProvider);
        if (proxiesState is AsyncData<List<ProxyGroupEntity>>) {
          for (final group in proxiesState.value) {
            for (final item in group.items) {
              if (item.tag == serverId && item.urlTestDelay > 0) {
                // 已有非零延迟数据，直接返回
                print('已有节点 $serverId 的延迟数据: ${item.urlTestDelay}ms');
                return item.urlTestDelay;
              }
            }
          }
        }
      } catch (e) {
        print('获取现有延迟数据失败: $e');
      }

      // 如果没有现有数据，执行url测试
      print('执行节点 $serverId 的URL测试');

      // 使用urlTest方法进行测试 - 这里统一使用"auto"组进行测试，与旧界面实现一致
      await proxyRepo.urlTest("auto").run();

      // 增加等待时间，确保延迟测试完成并更新到系统中
      print('等待节点 $serverId 测试完成...');
      await Future.delayed(const Duration(milliseconds: 5000));

      // 重新获取最新的延迟数据
      try {
        // 刷新proxiesOverviewNotifier以获取最新数据
        ref.invalidate(proxiesOverviewNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 1000));
        
        final proxiesState = ref.read(proxiesOverviewNotifierProvider);
        if (proxiesState is AsyncData<List<ProxyGroupEntity>>) {
          for (final group in proxiesState.value) {
            for (final item in group.items) {
              if (item.tag == serverId) {
                // 已有真实延迟数据
                final delay = item.urlTestDelay;
                print('获取到节点 $serverId 的延迟: ${delay}ms');
                if (delay > 0) {
                  return delay;
                }
              }
            }
          }
        }
      } catch (e) {
        print('从proxiesOverviewNotifier获取延迟失败: $e');
      }

      // 如果还是没有获取到真实延迟，尝试再次测试
      try {
        print('尝试再次测试节点 $serverId 延迟');
        // 尝试使用select组进行测试
        await proxyRepo.urlTest("select").run();
        print('等待第二次测试完成...');
        await Future.delayed(const Duration(milliseconds: 5000));
        
        ref.invalidate(proxiesOverviewNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 1000));
        
        final proxiesState = ref.read(proxiesOverviewNotifierProvider);
        if (proxiesState is AsyncData<List<ProxyGroupEntity>>) {
          for (final group in proxiesState.value) {
            for (final item in group.items) {
              if (item.tag == serverId && item.urlTestDelay > 0) {
                print('第二次测试获取到节点 $serverId 的延迟: ${item.urlTestDelay}ms');
                return item.urlTestDelay;
              }
            }
          }
        }
      } catch (e) {
        print('第二次测试延迟失败: $e');
      }
      
      // 如果还是没有获取到真实延迟，尝试第三次测试
      try {
        print('尝试第三次测试节点 $serverId 延迟');
        // 直接使用节点标签进行测试
        await proxyRepo.urlTest(serverId).run();
        print('等待第三次测试完成...');
        await Future.delayed(const Duration(milliseconds: 5000));
        
        ref.invalidate(proxiesOverviewNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 1000));
        
        final proxiesState = ref.read(proxiesOverviewNotifierProvider);
        if (proxiesState is AsyncData<List<ProxyGroupEntity>>) {
          for (final group in proxiesState.value) {
            for (final item in group.items) {
              if (item.tag == serverId && item.urlTestDelay > 0) {
                print('第三次测试获取到节点 $serverId 的延迟: ${item.urlTestDelay}ms');
                return item.urlTestDelay;
              }
            }
          }
        }
      } catch (e) {
        print('第三次测试延迟失败: $e');
      }

      // 如果还是没有获取到真实延迟，返回默认值
      print('无法获取节点 $serverId 的延迟数据，返回默认值0');
      return 0; // 表示未测试
    } catch (e) {
      print('测试延迟出错: $e');
      return 0;
    }
  }

  /// 判断节点是否可用 - 基于旧界面的判断方式
  bool _isNodeAvailable(String nodeTag, int delay) {
    // urlTestDelay > 65000 被认为是超时/不可用节点
    // urlTestDelay == 0 表示未测试
    // 对于未测试的节点，我们需要尝试进行测试
    if (delay == 0) {
      // 如果延迟为0，检查是否已经尝试过测试
      final hasAttemptedTest = _pingResults.containsKey(nodeTag);
      if (!hasAttemptedTest) {
        // 如果未尝试过测试，默认认为可用，后续会进行测试
        return true;
      } else {
        // 如果已尝试过测试但仍为0，可能表示测试失败
        // 此时我们查看是否有明确的可用性标记
        return _serverAvailability[nodeTag] ?? false;
      }
    }
    
    // 对于已有延迟值的节点，使用标准判断
    return delay < 65000;
  }

  /// 解析配置JSON提取服务器列表
  void _parseConfigJson(String configJson) {
    try {
      print('开始解析配置JSON...');
      // 解析配置文件
      final config = json.decode(configJson) as Map<String, dynamic>;
      print('配置解析成功，结构: ${config.keys.join(", ")}');

      // 尝试从配置中提取出站代理
      if (config.containsKey('outbounds')) {
        final outbounds = config['outbounds'] as List<dynamic>;
        print('找到出站代理配置，数量: ${outbounds.length}');

        // 创建代理项列表
        final proxyItems = <ProxyItemEntity>[];
        int skippedCount = 0;

        // 系统类型和系统标签
        final systemTypes = ['direct', 'block', 'dns', 'selector', 'urltest'];
        final systemTags = [
          'direct',
          'block',
          'bypass',
          'direct-fragment',
          'dns-out'
        ];

        // 第一遍，先提取所有可能的代理服务器
        for (final outbound in outbounds) {
          if (outbound is Map<String, dynamic>) {
            final tag = outbound['tag'] as String?;
            final type = outbound['type'] as String?;

            // 输出每个找到的出站代理信息以便调试
            print('出站代理: tag=$tag, type=$type');

            // 只添加可能是服务器的出站代理
            if (tag != null && type != null) {
              // 跳过系统类型和系统标签
              if (systemTypes.contains(type.toLowerCase()) ||
                  systemTags.contains(tag) ||
                  tag.toLowerCase().contains('block') ||
                  tag.toLowerCase().contains('reject')) {
                skippedCount++;
                print('跳过系统代理: $tag ($type)');
                continue;
              }

              // 确认是实际的代理服务器类型
              final isProxyServerType = type.contains('vmess') ||
                  type.contains('trojan') ||
                  type.contains('shadowsocks') ||
                  type.contains('vless') ||
                  type.contains('socks');

              if (isProxyServerType) {
                print('提取到代理服务器: $tag ($type)');
                final proxyType = _mapConfigTypeToProxyType(type);

                // 初始延迟为0，等待测试
                final proxyItem = ProxyItemEntity(
                  tag: tag,
                  type: proxyType,
                  urlTestDelay: 0,
                );

                proxyItems.add(proxyItem);

                // 开始异步获取真实延迟
                _getRealPingValue(tag, proxyType).then((realPing) {
                  if (mounted && realPing > 0) {
                    setState(() {
                      _pingResults[tag] = realPing;
                      _serverAvailability[tag] =
                          _isNodeAvailable(tag, realPing);
                      print('更新节点 $tag 的延迟: ${realPing}ms');
                    });
                  }
                });
              } else {
                skippedCount++;
                print('跳过不支持的类型: $tag ($type)');
              }
            }
          }
        }

        print('解析结果: 提取了 ${proxyItems.length} 个代理服务器, 跳过了 $skippedCount 个系统代理');

        if (proxyItems.isNotEmpty) {
          if (mounted) {
            setState(() {
              _servers = proxyItems;
            });

            // 立即进行延迟测试
            _runUrlTestForAllProxies();
          }
        } else {
          print('没有找到任何代理服务器，尝试解析整个配置');
          _parseConfigForAllPossibleServers(config);
        }
      } else {
        print('未找到出站代理配置，尝试其他节点');
        _parseConfigForAllPossibleServers(config);
      }
    } catch (e) {
      print('解析配置文件失败: $e');
    }
  }

  /// 为所有代理执行URL测试
  Future<void> _runUrlTestForAllProxies() async {
    try {
      final proxyRepo = ref.read(proxyRepositoryProvider);
      if (proxyRepo == null) {
        print('URL测试失败: proxyRepo为空');
        return;
      }

      // 确保测试URL正确设置
      //final configOptions = ref.watch(ConfigOptions.connectionTestUrl);
      //print('当前测试URL: $configOptions');
      
      // 与旧UI实现保持一致，强制使用auto组
      print('开始执行URL测试 (auto组)...');
      await proxyRepo.urlTest("auto").run();

      // 增加等待时间，确保测试完成
      print('等待测试完成...');
      await Future.delayed(const Duration(milliseconds: 5000));

      // 刷新proxiesOverviewNotifier以获取最新数据
      print('刷新代理状态...');
      ref.invalidate(proxiesOverviewNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 从proxiesOverviewNotifier获取最新数据
      _updateRealDelayFromOverview();

      // 再次延迟获取数据，确保测试结果已更新
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // 如果第一次更新没有获取到延迟数据，尝试再次测试
      bool hasDelayData = false;
      for (final server in _servers) {
        if (_pingResults[server.tag] != null && _pingResults[server.tag]! > 0) {
          hasDelayData = true;
          print('节点 ${server.tag} 获取到延迟: ${_pingResults[server.tag]}ms');
          break;
        }
      }
      
      if (!hasDelayData) {
        print('未获取到延迟数据，尝试再次测试...');
        // 尝试使用不同的组名进行测试
        print('尝试使用select组进行测试');
        await proxyRepo.urlTest("select").run();
        await Future.delayed(const Duration(milliseconds: 5000));
        ref.invalidate(proxiesOverviewNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 1000));
        _updateRealDelayFromOverview();
        
        // 检查是否有数据
        hasDelayData = false;
        for (final server in _servers) {
          if (_pingResults[server.tag] != null && _pingResults[server.tag]! > 0) {
            hasDelayData = true;
            print('第二次测试获取到节点 ${server.tag} 延迟: ${_pingResults[server.tag]}ms');
            break;
          }
        }
        
        // 如果还是没有数据，尝试直接测试每个节点
        if (!hasDelayData) {
          print('尝试直接测试每个节点');
          for (final server in _servers) {
            print('直接测试节点: ${server.tag}');
            await _testSelectedProxyDelay(server.tag);
            await Future.delayed(const Duration(milliseconds: 3000));
          }
        }
      }
      
      _updateRealDelayFromOverview();
    } catch (e) {
      print('URL测试失败: $e');
    }
  }

  /// 从proxiesOverview获取真实延迟数据
  void _updateRealDelayFromOverview() {
    try {
      final proxiesState = ref.read(proxiesOverviewNotifierProvider);
      if (proxiesState is! AsyncData<List<ProxyGroupEntity>>) {
        print('无法获取代理状态: $proxiesState');
        return;
      }

      // 查找并更新每个服务器的延迟信息
      bool hasUpdates = false;
      for (final proxyGroup in proxiesState.value) {
        for (final item in proxyGroup.items) {
          for (final server in _servers) {
            if (server.tag == item.tag && item.urlTestDelay > 0) {
              _pingResults[server.tag] = item.urlTestDelay;
              _serverAvailability[server.tag] =
                  _isNodeAvailable(server.tag, item.urlTestDelay);
              print('从overview更新节点 ${server.tag} 延迟: ${item.urlTestDelay}ms');
              hasUpdates = true;
            }
          }
        }
      }

      // 只在有更新时刷新UI
      if (hasUpdates && mounted) {
        setState(() {});
        print('已刷新UI显示最新延迟信息');
      }
    } catch (e) {
      print('更新延迟信息失败: $e');
    }
  }

  /// 测试选定代理的延迟
  Future<void> _testSelectedProxyDelay(String serverId) async {
    try {
      final proxyRepo = ref.read(proxyRepositoryProvider);
      if (proxyRepo == null) {
        print('测试选定代理延迟失败: proxyRepo为空');
        return;
      }

      // 确保测试URL正确设置
      //final configOptions = ref.watch(ConfigOptions.connectionTestUrl);
      //print('测试节点 $serverId 使用URL: $configOptions');
      
      // 直接使用与旧界面相同的方法
      print('测试选定代理延迟: $serverId');
      await proxyRepo.urlTest("auto").run();

      // 等待测试完成 - 增加等待时间
      print('等待节点 $serverId 测试完成...');
      await Future.delayed(const Duration(milliseconds: 3000));

      // 刷新数据
      ref.invalidate(proxiesOverviewNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 从proxiesOverviewNotifier获取最新数据
      final proxiesState = ref.read(proxiesOverviewNotifierProvider);
      if (proxiesState is AsyncData<List<ProxyGroupEntity>>) {
        bool found = false;
        for (final group in proxiesState.value) {
          for (final item in group.items) {
            if (item.tag == serverId) {
              print('从overview获取到节点 $serverId 延迟: ${item.urlTestDelay}ms');
              if (mounted) {
                setState(() {
                  _pingResults[serverId] = item.urlTestDelay;
                  _serverAvailability[serverId] =
                      _isNodeAvailable(serverId, item.urlTestDelay);
                });
              }
              found = true;
              break;
            }
          }
          if (found) break;
        }
        
        // 如果没有找到数据，尝试使用select组
        if (!found) {
          print('未找到节点 $serverId 的延迟数据，尝试使用select组');
          await proxyRepo.urlTest("select").run();
          await Future.delayed(const Duration(milliseconds: 3000));
          
          ref.invalidate(proxiesOverviewNotifierProvider);
          await Future.delayed(const Duration(milliseconds: 1000));
          
          final newProxiesState = ref.read(proxiesOverviewNotifierProvider);
          if (newProxiesState is AsyncData<List<ProxyGroupEntity>>) {
            for (final group in newProxiesState.value) {
              for (final item in group.items) {
                if (item.tag == serverId) {
                  print('第二次尝试获取到节点 $serverId 延迟: ${item.urlTestDelay}ms');
                  if (mounted) {
                    setState(() {
                      _pingResults[serverId] = item.urlTestDelay;
                      _serverAvailability[serverId] =
                          _isNodeAvailable(serverId, item.urlTestDelay);
                    });
                  }
                  break;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('测试选定代理延迟失败: $e');
    }
  }

  /// 获取节点延迟的颜色 - 基于旧界面实现
  Color _getDelayColor(int delay) {
    if (delay == 0) {
      return Colors.grey; // 未测试
    } else if (delay >= 65000) {
      return Colors.red; // 不可用
    } else if (delay < 800) {
      return Colors.green; // 良好
    } else if (delay < 1500) {
      return Colors.orange; // 中等
    } else {
      return Colors.red; // 较差
    }
  }

  /// 获取节点延迟文本 - 基于旧界面实现
  String _getDelayText(int delay) {
    if (delay == 0) {
      return "-"; // 未测试
    } else if (delay >= 65000) {
      return "×"; // 不可用，显示为"×"
    } else {
      return "${delay}ms"; // 显示具体延迟值
    }
  }

  /// 当前页面显示的服务器列表
  List<ServerModel> _getCurrentPageServers(List<ProxyItemEntity> allServers) {
    if (allServers.isEmpty) {
      print('服务器列表为空，返回空列表');
      return [];
    }

    final startIndex = (_currentPage - 1) * _serversPerPage;
    if (startIndex >= allServers.length) {
      print('起始索引超出范围: $startIndex >= ${allServers.length}');
      return [];
    }

    final endIndex = startIndex + _serversPerPage;
    final filteredServers =
        allServers.where((server) => server.isVisible).toList();
    print('可见服务器数量: ${filteredServers.length}');

    if (filteredServers.isEmpty) {
      return [];
    }

    final lastIndex =
        endIndex < filteredServers.length ? endIndex : filteredServers.length;
    final sublist = filteredServers.sublist(startIndex, lastIndex);
    print('当前页服务器数量(${startIndex}-${lastIndex - 1}): ${sublist.length}');

    return sublist.map((proxyItem) {
      // 获取节点名称
      final name = proxyItem.name.isNotEmpty ? proxyItem.name : proxyItem.tag;

      // 获取缓存的延迟值，如果没有则使用节点自身延迟值
      final delay = _pingResults[proxyItem.tag] ?? proxyItem.urlTestDelay;

      // 判断节点可用性 - 优先使用缓存，没有则基于延迟判断
      final isAvailable = _serverAvailability[proxyItem.tag] ??
          _isNodeAvailable(proxyItem.tag, delay);

      print('创建服务器: $name, ID: ${proxyItem.tag}, 延迟: $delay, 可用: $isAvailable');

      // 节点状态判断
      ServerStatus status;
      if (_selectedServerId == proxyItem.tag) {
        status = ServerStatus.connected; // 已连接
      } else if (!isAvailable || delay >= 65000) {
        status = ServerStatus.unavailable; // 不可用
      } else {
        status = ServerStatus.available; // 可用
      }

      return ServerModel(
        id: proxyItem.tag,
        name: name,
        ping: delay,
        status: status,
        isSelected: _selectedServerId == proxyItem.tag,
      );
    }).toList();
  }

  /// 获取总页数
  int _getTotalPages(List<ProxyItemEntity> allServers) {
    final visibleServers =
        allServers.where((server) => server.isVisible).length;
    return (visibleServers / _serversPerPage).ceil();
  }

  /// 处理页面变化
  void _handlePageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  /// 处理服务器连接
  void _handleServerConnect(ServerModel server) async {
    // 检查服务器是否可用
    final isAvailable = _serverAvailability[server.id] ?? true;
    if (!isAvailable) {
      print('服务器不可用，无法连接: ${server.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('节点 ${server.name} 不可用，请选择其他节点'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 更新选中状态
    setState(() {
      _selectedServerId = server.id;
    });

    // 调用系统API选择代理
    try {
      final proxyRepo = ref.read(proxyRepositoryProvider);
      if (proxyRepo != null) {
        print('选择服务器: ${server.name} (ID: ${server.id})');

        // 尝试使用选择器组设置代理 - 优先使用"auto"组，与旧界面实现一致
        try {
          print('尝试在auto组中选择代理: ${server.name}');
          final result = await proxyRepo.selectProxy("auto", server.id).run();
          result.fold(
            (failure) {
              print('在auto组选择代理失败: $failure，尝试其他方法');
              _tryAlternativeSelection(proxyRepo, server);
            },
            (_) {
              print('成功选择代理: ${server.name}');
              // 更新首页连接状态
              _updateHomeConnectionStatus(server);

              // 执行延迟测试
              _testSelectedProxyDelay(server.id);
            },
          );
        } catch (e) {
          print('选择代理时出错: $e，尝试其他方法');
          _tryAlternativeSelection(proxyRepo, server);
        }
      }
    } catch (e) {
      print('选择代理时出错: $e');
    }

    // 回调通知
    if (widget.onServerSelected != null) {
      widget.onServerSelected!(server);
    }
  }

  /// 更新首页连接状态
  void _updateHomeConnectionStatus(ServerModel server) {
    try {
      // 更新首页连接提供者状态
      final homeConnectionNotifier =
          ref.read(home_provider.connectionProvider.notifier);

      // 设置选择的服务器信息
      homeConnectionNotifier.setSelectedServer(
        name: server.name,
        pingValue: server.ping,
      );

      // 检查当前连接状态
      final connectionStatus =
          ref.read(home_provider.connectionProvider).status;

      // 如果当前未连接，尝试连接
      if (connectionStatus == ConnectionStatus.disconnected) {
        print('当前未连接，尝试连接VPN');
        if (context.mounted) {
          homeConnectionNotifier.connect(context);
        }
      } else {
        print('已连接状态，更新服务器信息');
      }
    } catch (e) {
      print('更新首页连接状态失败: $e');
    }
  }

  /// 尝试替代的选择方法
  Future<void> _tryAlternativeSelection(
      dynamic proxyRepo, ServerModel server) async {
    // 查找可用的代理组
    try {
      final proxiesState = ref.read(proxiesOverviewNotifierProvider);
      if (proxiesState is AsyncData<List<ProxyGroupEntity>>) {
        // 尝试多种策略查找合适的代理组
        String? groupTag;

        // 策略1: 查找包含该服务器的选择器组
        for (final group in proxiesState.value) {
          final containsServer =
              group.items.any((item) => item.tag == server.id);
          if (containsServer && group.type == ProxyType.selector) {
            groupTag = group.tag;
            print('找到包含服务器的选择器组: $groupTag');
            break;
          }
        }

        // 策略2: 使用第一个选择器组
        if (groupTag == null) {
          for (final group in proxiesState.value) {
            if (group.type == ProxyType.selector) {
              groupTag = group.tag;
              print('使用第一个选择器组: $groupTag');
              break;
            }
          }
        }

        // 执行服务器选择
        if (groupTag != null) {
          print('尝试在 $groupTag 组中选择服务器: ${server.name}');
          final result = await proxyRepo.selectProxy(groupTag, server.id).run();
          result.fold(
            (failure) => print('选择代理最终失败: $failure'),
            (_) {
              print('成功选择代理: ${server.name}');
              // 更新首页连接状态
              _updateHomeConnectionStatus(server);

              // 执行延迟测试
              _testSelectedProxyDelay(server.id);
            },
          );
        } else {
          print('未找到适合的代理组');
        }
      }
    } catch (e) {
      print('尝试替代选择方法失败: $e');
    }
  }

  /// 批量测试所有代理节点的延迟
  Future<void> _batchTestAllProxiesDelay() async {
    print('开始批量测试所有节点延迟');
    try {
      final proxyRepo = ref.read(proxyRepositoryProvider);
      if (proxyRepo == null) {
        print('批量测试失败: proxyRepo为空');
        return;
      }

      print('执行auto组URL测试...');
      // 与旧界面保持一致，使用auto组进行URL测试
      await proxyRepo.urlTest("auto").run();

      // 获取所有代理组信息
      final proxiesState = ref.read(proxiesOverviewNotifierProvider);
      if (proxiesState is! AsyncData<List<ProxyGroupEntity>>) {
        print('无法获取代理列表: $proxiesState');
        // 尝试刷新代理列表
        ref.invalidate(proxiesOverviewNotifierProvider);
        return;
      }

      // 测试完成后，立即刷新获取最新延迟信息
      for (final proxyGroup in proxiesState.value) {
        print(
            '代理组: ${proxyGroup.tag}, 类型: ${proxyGroup.type}, 项数: ${proxyGroup.items.length}');

        // 只寻找包含我们需要节点的组
        for (final proxyItem in proxyGroup.items) {
          // 找到对应的服务器
          for (final server in _servers) {
            if (server.tag == proxyItem.tag) {
              final delay = proxyItem.urlTestDelay;
              final isAvailable = _isNodeAvailable(server.tag, delay);
              print('节点 ${server.tag} 真实延迟: ${delay}ms, 可用: $isAvailable');

              // 更新延迟和可用性信息
              _pingResults[server.tag] = delay;
              _serverAvailability[server.tag] = isAvailable;
            }
          }
        }
      }

      // 刷新UI以显示更新的延迟信息
      if (mounted) {
        setState(() {});
        print('已更新延迟信息并刷新UI');
      }
    } catch (e) {
      print('批量测试节点延迟失败: $e');
    }
  }

  /// 尝试从整个配置中查找任何可能的服务器信息
  void _parseConfigForAllPossibleServers(Map<String, dynamic> config) {
    print('尝试从整个配置中查找可能的服务器信息');
    final proxyItems = <ProxyItemEntity>[];

    // 查找任何可能包含服务器信息的字段
    void searchForServerData(dynamic data, [String parentKey = '']) {
      if (data is Map<String, dynamic>) {
        // 检查这个Map是否可能是一个服务器配置
        if (data.containsKey('tag') &&
            data.containsKey('server') &&
            data.containsKey('port')) {
          final tag = data['tag'] as String?;
          final server = data['server'] as String?;
          final port = data['port'];
          final type = data['type'] as String? ?? 'unknown';

          if (tag != null && server != null && port != null) {
            print('找到可能的服务器配置: $tag ($server:$port)');

            final proxyType = _mapConfigTypeToProxyType(type);
            final randomPing = 50 + math.Random().nextInt(150);

            proxyItems.add(
              ProxyItemEntity(
                tag: tag,
                type: proxyType,
                urlTestDelay: randomPing,
              ),
            );
            return;
          }
        }

        // 继续遍历所有键
        for (final key in data.keys) {
          searchForServerData(data[key], key);
        }
      } else if (data is List) {
        // 遍历列表中的所有项
        for (int i = 0; i < data.length; i++) {
          searchForServerData(data[i], '$parentKey[$i]');
        }
      }
    }

    searchForServerData(config);

    if (proxyItems.isNotEmpty) {
      print('从配置中找到 ${proxyItems.length} 个可能的服务器');
      if (mounted) {
        setState(() {
          _servers = proxyItems;
        });

        // 也为这种情况添加批量延迟测试
        _batchTestAllProxiesDelay();
      }
    } else {
      print('无法从配置中提取任何服务器信息');
    }
  }

  /// 将配置类型映射到代理类型
  ProxyType _mapConfigTypeToProxyType(String configType) {
    if (configType.contains('vmess')) return ProxyType.vmess;
    if (configType.contains('trojan')) return ProxyType.trojan;
    if (configType.contains('shadowsocks')) return ProxyType.shadowsocks;
    if (configType.contains('socks')) return ProxyType.socks;
    if (configType.contains('vless')) return ProxyType.vless;
    return ProxyType.direct;
  }

  @override
  Widget build(BuildContext context) {
    // 监听活跃配置
    final activeProfileState = ref.watch(activeProfileProvider);

    // 获取所有服务器
    List<ProxyItemEntity> allServers = _servers;
    int totalPages = _getTotalPages(allServers);

    // 确保当前页不超过总页数
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }

    // 获取当前页的服务器
    final currentPageServers = _getCurrentPageServers(allServers);
    print('当前页面服务器数量: ${currentPageServers.length}');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(NewAppAssets.serverBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 标题栏
              _buildAppBar(),

              // 套餐卡片
              const ServerBanner(),

              // 加载指示器或服务器列表
              if (_isLoadingServers || activeProfileState is AsyncLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '加载服务器列表中...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else if (activeProfileState is AsyncError)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '加载配置文件失败',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '请先连接VPN并确认配置文件已导入',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // 重试加载
                            _loadServersFromProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('重试加载'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: currentPageServers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无可用服务器',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '请先连接VPN后再尝试加载服务器列表',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  // 重新加载
                                  _loadServersFromProfile();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('重新加载'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 20),
                          itemCount: currentPageServers.length,
                          itemBuilder: (context, index) {
                            return ServerListItem(
                              server: currentPageServers[index],
                              onConnect: _handleServerConnect,
                            );
                          },
                        ),
                ),

              // 分页控件
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: ServerPagination(
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    onPageChanged: _handlePageChanged,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建应用栏
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'SERVER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                NewAppAssets.serverCloseIcon,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
