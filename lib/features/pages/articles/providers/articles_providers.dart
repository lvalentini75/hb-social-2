import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/pages/articles/data/articles_repository.dart';
import 'package:hb_social/features/pages/articles/domain/article.dart';

final articlesRepositoryProvider = Provider<ArticlesRepository>((ref) => ArticlesRepository(ref.watch(supabaseClientProvider)));
typedef ArticlesRequest = ({String pageId, String status});
final articlesByPageProvider = FutureProvider.autoDispose.family<List<PageArticle>, ArticlesRequest>((ref, request) => ref.watch(articlesRepositoryProvider).byPage(request.pageId, status: request.status));
typedef ArticlePath = ({String pageSlug, String slug});
final articleByPathProvider = FutureProvider.autoDispose.family<PageArticle?, ArticlePath>((ref, path) => ref.watch(articlesRepositoryProvider).detail(pageSlug: path.pageSlug, slug: path.slug));
final articleByIdProvider = FutureProvider.autoDispose.family<PageArticle?, String>((ref, id) => ref.watch(articlesRepositoryProvider).detail(id: id));