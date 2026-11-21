import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/i18n/exchange_rates_provider.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';

/// Displays a free price, a converted estimate, and the original amount.
class HBPrice extends ConsumerWidget {
  final int amountMinor;
  final String currencyCode;

  const HBPrice({super.key, required this.amountMinor, required this.currencyCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (amountMinor == 0) return Text('events.free'.tr());
    final settings = ref.watch(userSettingsProvider);
    final original = MoneyFormatter.format(amountMinor: amountMinor, currencyCode: currencyCode, locale: context.locale);
    if (currencyCode == settings.currencyCode) return Text(original);
    final converter = ref.watch(currencyConverterProvider);
    return converter.when(
      loading: () => Text(original),
      error: (_, __) => Text(original),
      data: (value) {
        final amount = value.convert(amountMinor: amountMinor, fromCode: currencyCode, toCode: settings.currencyCode);
        return amount == null ? Text(original) : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('≈ ${MoneyFormatter.format(amountMinor: amount, currencyCode: settings.currencyCode, locale: context.locale)}'), Text(original, style: Theme.of(context).textTheme.bodySmall)]);
      },
    );
  }
}