# 邀请码界面接口对接方案

## 1. 概述

本文档描述了邀请码界面与后端API的对接方案。邀请码功能涉及获取用户邀请码和邀请链接，以便用户可以邀请其他人注册使用本应用。

## 2. 当前实现状态

目前项目中存在两套实现方案：

1. **旧版实现**：位于 `lib/features/panel/xboard/services/http_service/invite_code_service.dart`，通过HTTP请求直接与后端API交互。
2. **新版模拟实现**：位于 `lib/features/newApp/invitation/services/invitation_service.dart`，目前仅使用SharedPreferences存储模拟数据。

## 3. 对接方案

### 3.1 整体架构

采用三层架构进行API对接：

1. **UI层**：`invitation_page.dart` - 负责展示界面和用户交互
2. **服务层**：`invitation_service.dart` - 负责业务逻辑和数据处理
3. **数据层**：需增加 `invitation_repository.dart` - 负责网络请求和数据持久化

### 3.2 数据模型定义

创建邀请码数据模型类：

```dart
// lib/features/newApp/invitation/models/invitation.dart
class Invitation {
  final String code;
  final String link;

  const Invitation({
    required this.code,
    required this.link,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      code: json['code'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'link': link,
    };
  }
}
```

### 3.3 Repository层实现

创建Repository类管理网络请求和本地存储：

```dart
// lib/features/newApp/invitation/repositories/invitation_repository.dart
import 'package:dio/dio.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invitation.dart';

class InvitationRepository {
  final DioHttpClient _httpClient;
  static const String _invitationCodeKey = 'invitation_code';
  static const String _invitationLinkKey = 'invitation_link';
  
  // 构造函数注入HTTP客户端
  InvitationRepository(this._httpClient);
  
  // 从API获取邀请码
  Future<Invitation> fetchInvitationFromApi(String token) async {
    try {
      // 获取邀请码列表
      final response = await _httpClient.get<Map<String, dynamic>>(
        '/api/v1/user/invite/fetch',
        headers: {'Authorization': token},
      );
      
      if (response.data != null && 
          response.data!.containsKey('data') && 
          response.data!['data'] is Map<String, dynamic>) {
        
        final data = response.data!['data'];
        final codes = data['codes'] as List<dynamic>;
        
        if (codes.isNotEmpty) {
          final code = codes.first['code'] as String;
          
          // 构建邀请链接
          final baseUrl = '${response.requestOptions.baseUrl}/#/register?code=';
          final link = '$baseUrl$code';
          
          // 保存到本地
          await _saveInvitationToLocal(code, link);
          
          return Invitation(code: code, link: link);
        }
      }
      
      // 如果无法获取，尝试本地缓存
      return await fetchInvitationFromLocal();
    } on DioException catch (e) {
      print('获取邀请码失败: ${e.message}');
      // 网络请求失败时，使用本地缓存数据
      return await fetchInvitationFromLocal();
    } catch (e) {
      print('获取邀请码异常: $e');
      return await fetchInvitationFromLocal();
    }
  }
  
  // 从本地存储获取邀请码
  Future<Invitation> fetchInvitationFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_invitationCodeKey) ?? '';
      final link = prefs.getString(_invitationLinkKey) ?? '';
      
      return Invitation(code: code, link: link);
    } catch (e) {
      print('从本地获取邀请码失败: $e');
      // 返回空数据
      return const Invitation(code: '', link: '');
    }
  }
  
  // 保存邀请码到本地
  Future<void> _saveInvitationToLocal(String code, String link) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_invitationCodeKey, code);
      await prefs.setString(_invitationLinkKey, link);
    } catch (e) {
      print('保存邀请码到本地失败: $e');
    }
  }
  
  // 生成新的邀请码
  Future<bool> generateInvitation(String token) async {
    try {
      await _httpClient.get<Map<String, dynamic>>(
        '/api/v1/user/invite/save',
        headers: {'Authorization': token},
      );
      return true;
    } catch (e) {
      print('生成邀请码失败: $e');
      return false;
    }
  }
}
```

### 3.4 Service层改造

修改现有的Service类连接Repository：

```dart
// lib/features/newApp/invitation/services/invitation_service.dart
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/features/newApp/auth/services/auth_service.dart';
import '../models/invitation.dart';
import '../repositories/invitation_repository.dart';

class InvitationService {
  static final InvitationService instance = InvitationService._internal();
  
  late final InvitationRepository _repository;
  
  // 私有构造函数
  InvitationService._internal() {
    // 获取DioHttpClient实例
    final httpClient = DioHttpClient(
      timeout: const Duration(seconds: 10),
      userAgent: 'Hiddify/App',
      debug: true,
    );
    
    _repository = InvitationRepository(httpClient);
  }
  
  // 获取邀请码和链接
  Future<Map<String, String>> refreshInvitationData() async {
    try {
      // 获取当前用户的token
      final token = AuthService.instance.token;
      
      if (token == null || token.isEmpty) {
        // 用户未登录，返回空数据
        return {'code': '', 'link': ''};
      }
      
      // 调用repository获取邀请数据
      final invitation = await _repository.fetchInvitationFromApi(token);
      
      return {
        'code': invitation.code,
        'link': invitation.link,
      };
    } catch (e) {
      print('刷新邀请数据失败: $e');
      
      // 发生异常时，尝试从本地获取
      final localData = await _repository.fetchInvitationFromLocal();
      return {
        'code': localData.code,
        'link': localData.link,
      };
    }
  }
  
  // 生成新的邀请码（如需在UI中添加刷新功能）
  Future<bool> generateNewInvitation() async {
    final token = AuthService.instance.token;
    
    if (token == null || token.isEmpty) {
      return false;
    }
    
    return await _repository.generateInvitation(token);
  }
}
```

## 4. UI层的实现变更

新的UI界面已经用`_loadInvitationData()`方法对接了`InvitationService.refreshInvitationData()`，无需更改。如果需要添加刷新功能，可以实现以下方法：

```dart
// 在 _InvitationPageState 类中添加
Future<void> _refreshInvitationCode() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    final success = await InvitationService.instance.generateNewInvitation();
    if (success) {
      await _loadInvitationData(); // 重新加载数据
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生成新邀请码失败')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    print('刷新邀请码失败: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('刷新邀请码时发生错误')),
    );
    setState(() {
      _isLoading = false;
    });
  }
}
```

## 5. 权限处理

确保用户已登录且具有适当权限后才能获取邀请码：

1. 在`InvitationService`中检查用户登录状态
2. 通过`AuthService`获取token，并在API请求中使用
3. 若用户未登录，提供适当的错误处理和反馈

## 6. 错误处理

实现了多级容错机制：

1. 首先尝试从API获取最新数据
2. API调用失败时，回退到本地缓存
3. 本地缓存不可用时，显示友好的错误信息

## 7. 测试方案

1. **单元测试**：测试Repository和Service层的逻辑
2. **Mock测试**：使用mock HTTP客户端测试网络请求
3. **UI测试**：测试界面在不同数据状态下的表现

## 8. 部署步骤

1. 创建数据模型类
2. 实现Repository层
3. 改造Service层
4. 验证UI层的集成
5. 添加错误处理和日志记录
6. 运行测试确保功能正常 