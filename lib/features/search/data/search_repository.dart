import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/home/data/feed_repository.dart';
import 'package:hb_social/features/polls/domain/poll.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/search/domain/search_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchRepository {
  static const pageSize = 20;
  static const _recentKey = 'search.recent_queries';
  final SupabaseClient _client;
  late final FeedRepository _feedRepository = FeedRepository(_client);

  SearchRepository(this._client);

  Future<SearchOverview> searchAll(String query, {int limit = 3}) async {
    final term = query.trim();
    if (term.length < 2) return const SearchOverview({});
    try {
      final rows = await _client.rpc('search_all', params: {'p_q': term, 'p_limit': limit});
      final sections = <SearchCategory, List<SearchPreview>>{};
      for (final raw in rows as List) {
        final preview = _previewWithMedia(SearchPreview.fromJson(Map<String, dynamic>.from(raw as Map)));
        sections.putIfAbsent(preview.category, () => []).add(preview);
      }
      return SearchOverview(sections);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<SearchPageResult> searchType({required String query, required SearchCategory category, int offset = 0}) async {
    final term = query.trim();
    if (term.length < 2 || category == SearchCategory.all) return const SearchPageResult(items: [], hasMore: false);
    try {
      final params = {'p_q': term, 'p_limit': pageSize, 'p_offset': offset};
      final List<Object> items = switch (category) {
        SearchCategory.people => await _profiles(params),
        SearchCategory.posts => await _posts(params),
        SearchCategory.hashtags => await _hashtags(params),
        SearchCategory.groups => await _communities('search_groups', params, category),
        SearchCategory.pages => await _communities('search_pages', params, category),
        SearchCategory.listings => await _listings(params),
        SearchCategory.events => await _events(params),
        SearchCategory.forum => await _threads(params),
        SearchCategory.all => const [],
      };
      return SearchPageResult(items: items, hasMore: items.length == pageSize);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<UserProfile>> _profiles(Map<String, Object> params) async {
    final rows = await _client.rpc('search_profiles', params: params).select('id,username,display_name,avatar_url,verification_level,follower_count,bio');
    return (rows as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
      return UserProfile.fromJson(json);
    }).toList();
  }

  Future<List<SearchPostResult>> _posts(Map<String, Object> params) async {
    final rows = await _client.rpc('search_posts', params: params).select('${FeedRepository.postSelect},poll:polls(*,options:poll_options(*))');
    final rawRows = (rows as List).map((raw) => Map<String, dynamic>.from(raw as Map)).toList();
    final posts = await _feedRepository.parsePosts(rawRows);
    return List.generate(posts.length, (index) {
      final rawPoll = rawRows[index]['poll'];
      final pollJson = rawPoll is List ? rawPoll.firstOrNull : rawPoll;
      return SearchPostResult(post: posts[index], poll: pollJson is Map ? Poll.fromJson(Map<String, dynamic>.from(pollJson)) : null);
    });
  }

  Future<List<SearchHashtag>> _hashtags(Map<String, Object> params) async {
    final offset = params['p_offset'] as int;
    final rows = await _client.rpc('search_hashtags', params: {'p_q': params['p_q'], 'p_limit': offset + pageSize});
    return (rows as List).skip(offset).map((raw) => SearchHashtag.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
  }

  Future<List<SearchCommunityResult>> _communities(String function, Map<String, Object> params, SearchCategory category) async {
    final rows = await _client.rpc(function, params: params);
    final bucket = category == SearchCategory.groups ? 'group-media' : 'page-media';
    return (rows as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      return SearchCommunityResult(
        category: category, id: json['id'] as String, title: json['name'] as String? ?? '', subtitle: json['description'] as String?,
        imageUrl: storagePublicUrl(_client, bucket, json['avatar_url'] as String?), slug: json['slug'] as String?,
        count: (json[category == SearchCategory.groups ? 'member_count' : 'follower_count'] as num?)?.toInt(),
      );
    }).toList();
  }

  Future<List<SearchCommunityResult>> _listings(Map<String, Object> params) async {
    final rows = await _client.rpc('search_listings', params: params).select('*,media:listing_media(path,sort_order)');
    return (rows as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      final media = ((json['media'] as List?) ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList()..sort((a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0).compareTo((b['sort_order'] as num?)?.toInt() ?? 0));
      return SearchCommunityResult(
        category: SearchCategory.listings, id: json['id'] as String, title: json['title'] as String? ?? '', subtitle: json['description'] as String?,
        imageUrl: media.isEmpty ? null : storagePublicUrl(_client, 'listing-media', media.first['path'] as String?),
        priceMinor: (json['price_minor'] as num?)?.toInt(), currencyCode: json['currency_code'] as String?, date: _date(json['created_at']), isMediated: json['is_mediated'] == true,
      );
    }).toList();
  }

  Future<List<SearchCommunityResult>> _events(Map<String, Object> params) async {
    final rows = await _client.rpc('search_events', params: params);
    return (rows as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      return SearchCommunityResult(
        category: SearchCategory.events, id: json['id'] as String, title: json['title'] as String? ?? '', subtitle: json['location_name'] as String? ?? json['description'] as String?,
        imageUrl: storagePublicUrl(_client, 'event-media', json['cover_url'] as String?), date: _date(json['starts_at']),
      );
    }).toList();
  }

  Future<List<SearchCommunityResult>> _threads(Map<String, Object> params) async {
    final rows = await _client.rpc('search_forum_threads', params: params).select('*,forum:forums(slug,name)');
    return (rows as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      final forum = json['forum'] is Map ? Map<String, dynamic>.from(json['forum'] as Map) : const <String, dynamic>{};
      return SearchCommunityResult(
        category: SearchCategory.forum, id: json['id'] as String, title: json['title'] as String? ?? '', subtitle: forum['name'] as String?,
        count: (json['reply_count'] as num?)?.toInt(), date: _date(json['created_at']), forumSlug: forum['slug'] as String?,
      );
    }).toList();
  }

  Future<List<SearchHashtag>> trendingHashtags() async {
    try {
      final rows = await _client.from('hashtags').select('id,tag,post_count').gt('post_count', 0).order('post_count', ascending: false).limit(5);
      return (rows as List).map((raw) => SearchHashtag.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<String>> recentQueries() async => (await SharedPreferences.getInstance()).getStringList(_recentKey) ?? const [];

  Future<List<String>> saveRecent(String query) async {
    final value = query.trim();
    if (value.length < 2) return recentQueries();
    final preferences = await SharedPreferences.getInstance();
    final items = await recentQueries();
    final updated = [value, ...items.where((item) => item.toLowerCase() != value.toLowerCase())].take(10).toList();
    await preferences.setStringList(_recentKey, updated);
    return updated;
  }

  Future<List<String>> removeRecent(String query) async {
    final preferences = await SharedPreferences.getInstance();
    final updated = (await recentQueries()).where((item) => item != query).toList();
    await preferences.setStringList(_recentKey, updated);
    return updated;
  }

  Future<void> clearRecent() async => (await SharedPreferences.getInstance()).remove(_recentKey);

  SearchPreview _previewWithMedia(SearchPreview item) {
    final bucket = switch (item.category) {
      SearchCategory.people || SearchCategory.posts || SearchCategory.forum => 'avatars',
      SearchCategory.groups => 'group-media',
      SearchCategory.pages => 'page-media',
      SearchCategory.listings => 'listing-media',
      SearchCategory.events => 'event-media',
      _ => '',
    };
    if (bucket.isEmpty || item.imageUrl == null) return item;
    return SearchPreview(category: item.category, total: item.total, id: item.id, title: item.title, subtitle: item.subtitle, imageUrl: storagePublicUrl(_client, bucket, item.imageUrl), slug: item.slug, extra: item.extra);
  }
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toUtc() : null;