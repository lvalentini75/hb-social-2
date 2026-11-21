import 'package:hb_social/core/i18n/currency_converter.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the latest available rate for every currency pair.
class ExchangeRateRepository {
  final SupabaseClient _client;

  const ExchangeRateRepository(this._client);

  Future<List<ExchangeRate>> fetchLatest() async {
    try {
      final rows = await _client.from('exchange_rates').select('base_code,quote_code,rate,valid_on').order('valid_on', ascending: false);
      final latest = <String, ExchangeRate>{};
      for (final row in rows as List) {
        final rate = ExchangeRate.fromJson(Map<String, dynamic>.from(row as Map));
        latest.putIfAbsent('${rate.baseCode}:${rate.quoteCode}', () => rate);
      }
      return latest.values.toList(growable: false);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}