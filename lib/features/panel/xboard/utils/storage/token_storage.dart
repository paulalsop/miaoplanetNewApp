import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
  if (kDebugMode) {
    print('Token stored: $token');
  }
}

Future<void> storeClientToken(String clientToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('client_token', clientToken);
  if (kDebugMode) {
    print('Client token stored: $clientToken');
  }
}

Future<String?> getClientToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('client_token');
}

Future<void> deleteClientToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('client_token');
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<void> deleteToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}
