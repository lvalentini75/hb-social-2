import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/billing/data/billing_repository.dart';
import 'package:hb_social/features/billing/domain/payment_method.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) => BillingRepository(ref.watch(supabaseClientProvider), ref.watch(paymentsRepositoryProvider)));
final paymentMethodsProvider = FutureProvider.autoDispose<List<BillingPaymentMethod>>((ref) => ref.watch(billingRepositoryProvider).myPaymentMethods());