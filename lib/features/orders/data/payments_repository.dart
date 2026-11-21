import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/orders/domain/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentsRepository {
  final SupabaseClient _client;
  const PaymentsRepository(this._client);

  Future<Map<String, dynamic>> invoke(String action, [Map<String, dynamic> body = const {}]) async {
    if (_client.auth.currentSession == null) throw const AppException('payments.errors.not_authenticated');
    try {
      final response = await _client.functions.invoke('payments', body: {'action': action, ...body}, headers: {'Authorization': 'Bearer ${_client.auth.currentSession!.accessToken}'});
      final data = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
      if (data['error'] != null) throw AppException('payments.errors.${data['error']}');
      return data;
    } catch (error) { if (error is AppException) rethrow; throw ErrorMapper.fromSupabase(error); }
  }

  Future<Uri> connectOnboard({required String returnUrl, required String refreshUrl}) async => Uri.parse((await invoke('connect_onboard', {'return_url': returnUrl, 'refresh_url': refreshUrl}))['url'].toString());
  Future<SellerAccountStatus> connectStatus() async => SellerAccountStatus.fromJson(await invoke('connect_status'));
  Future<Uri> connectLogin() async => Uri.parse((await invoke('connect_login'))['url'].toString());
  Future<CheckoutResult> checkout({required String listingId, required String deliveryMethod, Map<String, dynamic>? shippingAddress, String? buyerNote, required String successUrl, required String cancelUrl}) async => CheckoutResult.fromJson(await invoke('checkout', {'listing_id': listingId, 'delivery_method': deliveryMethod, 'shipping_address': shippingAddress, 'buyer_note': buyerNote, 'success_url': successUrl, 'cancel_url': cancelUrl}));
  Future<CheckoutResult> eventCheckout({required String eventId, required String successUrl, required String cancelUrl}) async => CheckoutResult.fromJson(await invoke('checkout', {'event_id': eventId, 'success_url': successUrl, 'cancel_url': cancelUrl}));
  Future<void> refund(String orderId) async => invoke('refund', {'order_id': orderId});
}