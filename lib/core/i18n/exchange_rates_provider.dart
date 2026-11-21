import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/currency_converter.dart';
import 'package:hb_social/core/i18n/exchange_rate_repository.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) => ExchangeRateRepository(ref.watch(supabaseClientProvider)));
final exchangeRatesProvider = FutureProvider<List<ExchangeRate>>((ref) => ref.watch(exchangeRateRepositoryProvider).fetchLatest());
final currencyConverterProvider = FutureProvider<CurrencyConverter>((ref) async => CurrencyConverter(await ref.watch(exchangeRatesProvider.future)));