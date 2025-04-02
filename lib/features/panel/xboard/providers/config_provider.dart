import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/http_service/auth_service.dart';

class CurrencyConfig {
  final String currency;
  final String symbol;

  CurrencyConfig({
    required this.currency,
    required this.symbol,
  });

  factory CurrencyConfig.fromJson(Map<String, dynamic> json) {
    return CurrencyConfig(
      currency: json['currency'] as String? ?? 'MIAO',
      symbol: json['currency_symbol'] as String? ?? 'MIAO',
    );
  }
}

class ConfigNotifier extends StateNotifier<CurrencyConfig> {
  ConfigNotifier() : super(CurrencyConfig(currency: 'MIAO', symbol: 'MIAO'));

  final _authService = AuthService();

  Future<void> loadConfig() async {
    try {
      final result = await _authService.getUserConfig();
      if (result['status'] == 'success' && result['data'] != null) {
        state = CurrencyConfig.fromJson(result['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      print('Failed to load config: $e');
    }
  }
}

final configProvider =
    StateNotifierProvider<ConfigNotifier, CurrencyConfig>((ref) {
  return ConfigNotifier();
});
