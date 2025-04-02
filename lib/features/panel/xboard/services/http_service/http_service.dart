// services/http_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:http/http.dart' as http;

class HttpService {
  static String baseUrl = ''; // 基础URL
  static bool isInitialized = false; // 跟踪初始化状态

  // 初始化服务并设置动态域名
  static Future<void> initialize() async {
    if (isInitialized) return; // 如果已初始化，则直接返回

    try {
      // baseUrl = await DomainService.fetchValidDomain();
      baseUrl = 'https://miaovpn.org'; // 本地开发服务器
      print("成功初始化HttpService，使用域名: $baseUrl");
      isInitialized = true;
    } catch (e) {
      print("HttpService初始化失败: $e");

      // 使用开发模式下的本地服务器作为最后的备用方案
      if (kDebugMode) {
        print("使用本地开发服务器作为备用");
        baseUrl = 'http://localhost:8009'; // 本地开发服务器
        isInitialized = true;
        return;
      }

      // 如果没有可用域名且不在开发模式，重新抛出异常
      throw Exception("无法连接到任何可用服务器");
    }
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    // 确保HttpService已初始化
    if (!isInitialized) {
      try {
        await initialize();
      } catch (e) {
        throw Exception("服务未初始化，无法执行请求: $e");
      }
    }

    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print("GET $baseUrl$endpoint response: ${response.body}");
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            "GET request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during GET request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }

  // 统一的 POST 请求方法

  // 统一的 POST 请求方法，增加 requiresHeaders 开关
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresHeaders = true,
  }) async {
    // 确保HttpService已初始化
    if (!isInitialized) {
      try {
        await initialize();
      } catch (e) {
        throw Exception("服务未初始化，无法执行请求: $e");
      }
    }

    final url = Uri.parse('$baseUrl$endpoint');

    try {
      // 添加调试信息，打印请求体
      if (kDebugMode) {
        print("POST请求到 $baseUrl$endpoint");
        print("请求体: ${json.encode(body)}");
        print("请求头: $headers");
      }

      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http
          .post(
            url,
            headers: requiresHeaders
                ? {...defaultHeaders, ...?headers}
                : defaultHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        print("POST $baseUrl$endpoint response: ${response.body}");
      }

      final decodedResponse =
          json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return decodedResponse;
      } else {
        throw Exception(
            "POST request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during POST request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }

  // POST 请求方法，不包含 headers
  Future<Map<String, dynamic>> postRequestWithoutHeaders(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .post(
            url,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print(
            "POST $baseUrl$endpoint without headers response: ${response.body}");
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            "POST request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error during POST request without headers to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }
}
