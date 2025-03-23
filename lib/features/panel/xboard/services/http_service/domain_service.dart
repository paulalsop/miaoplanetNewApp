// services/domain_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DomainService {
  static const String ossDomain =
      'https://s3.ap-southeast-1.amazonaws.com/808676.tigerskombat.com/config.json';
  
  // 备用域名列表，当OSS接口不可用时使用
  static const List<String> fallbackDomains = [
    'https://vp.boom314.com',         // 替换为实际的API域名
    'https://api2.tiger.net',        // 替换为实际的API域名
    'http://localhost:8009',         // 本地开发服务器（仅开发环境）
  ];

// 从返回的 JSON 中挑选一个可以正常访问的域名
  static Future<String> fetchValidDomain() async {
    try {
      // 首先尝试从OSS获取域名列表
      final response = await http
          .get(Uri.parse(ossDomain))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> websites =
            json.decode(response.body) as List<dynamic>;
        for (final website in websites) {
          final Map<String, dynamic> websiteMap =
              website as Map<String, dynamic>;
          final String domain = websiteMap['url'] as String;
          print("正在测试域名: $domain");
          if (await _checkDomainAccessibility(domain)) {
            if (kDebugMode) {
              print('有效域名: $domain');
            }
            return domain;
          }
        }
        // 如果没有找到可访问的域名，尝试使用备用域名
        return await _tryFallbackDomains();
      } else {
        print('OSS域名不可用，尝试备用域名');
        return await _tryFallbackDomains();
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取有效域名时出错: $ossDomain:  $e');
      }
      // 发生异常时也尝试备用域名
      return await _tryFallbackDomains();
    }
  }

  // 尝试使用备用域名
  static Future<String> _tryFallbackDomains() async {
    for (final domain in fallbackDomains) {
      print("正在测试备用域名: $domain");
      if (await _checkDomainAccessibility(domain)) {
        if (kDebugMode) {
          print('有效备用域名: $domain');
        }
        return domain;
      }
    }
    // 如果所有域名都不可用，抛出异常
    throw Exception('所有域名均不可访问');
  }

  static Future<bool> _checkDomainAccessibility(String domain) async {
    try {
      final response = await http
          .get(Uri.parse('$domain/api/v1/guest/comm/config'))
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('域名检查失败: $domain, 错误: $e');
      return false;
    }
  }
}
