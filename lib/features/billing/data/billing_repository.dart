import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/billing/domain/payment_method.dart';
import 'package:hb_social/features/orders/data/payments_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingRepository {
  final SupabaseClient _client;
  final PaymentsRepository _payments;
  const BillingRepository(this._client, this._payments);

  Future<List<BillingPaymentMethod>> myPaymentMethods() async {
    try {
      final rows = await _client.rpc('my_payment_methods');
      return [for (final row in rows as List) BillingPaymentMethod.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw _map(error); }
  }

  Future<Uri> setupCard(String returnUrl) async => Uri.parse((await _invoke('pm_setup', {'return_url': returnUrl}))['url'].toString());

  Future<List<BillingPaymentMethod>> syncCards() async {
    final data = await _invoke('pm_sync');
    final rows = data['payment_methods'] as List? ?? const [];
    return [for (final row in rows) BillingPaymentMethod.fromJson(Map<String, dynamic>.from(row as Map))];
  }

  Future<void> setDefault(String id) async => _invoke('pm_set_default', {'id': id});
  Future<void> remove(String id) async => _invoke('pm_remove', {'id': id});

  Future<Map<String, dynamic>> _invoke(String action, [Map<String, dynamic> body = const {}]) async {
    try { return await _payments.invoke(action, body); } catch (error) { throw _map(error); }
  }

  AppException _map(Object error) {
    if (error is AppException) {
      final key = error.messageKey.split('.').last;
      const billingKeys = {'payment_method_not_found', 'payment_method_permission_denied', 'payment_method_in_use', 'payment_method_invalid', 'payment_method_type_invalid', 'billing_permission_denied', 'not_authenticated'};
      if (billingKeys.contains(key)) return AppException('billing.errors.$key');
      return error;
    }
    final message = error.toString().toLowerCase();
    for (final key in const ['payment_method_not_found', 'payment_method_permission_denied', 'payment_method_in_use', 'payment_method_invalid', 'payment_method_type_invalid', 'billing_permission_denied', 'not_authenticated']) {
      if (message.contains(key)) return AppException('billing.errors.$key');
    }
    final mapped = ErrorMapper.fromSupabase(error);
    final key = mapped.messageKey.split('.').last;
    return AppException('billing.errors.$key');
  }
}