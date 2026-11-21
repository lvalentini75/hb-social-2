import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/billing/domain/payment_method.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserFilters {
  final String? id;
  final String? status;
  final String? countryCode;
  final String? verificationLevel;
  final String? regionId;
  final String search;
  final bool expiringSoon;

  const AdminUserFilters({this.id, this.status, this.countryCode, this.verificationLevel, this.regionId, this.search = '', this.expiringSoon = false});
  @override bool operator ==(Object other) => other is AdminUserFilters && id == other.id && status == other.status && countryCode == other.countryCode && verificationLevel == other.verificationLevel && regionId == other.regionId && search == other.search && expiringSoon == other.expiringSoon;
  @override int get hashCode => Object.hash(id, status, countryCode, verificationLevel, regionId, search, expiringSoon);
}

class AdminReportFilters {
  final String? id;
  final List<String>? statuses;
  final String? priority;
  final String? targetType;
  final String? reason;
  final String? countryCode;

  const AdminReportFilters({this.id, this.statuses, this.priority, this.targetType, this.reason, this.countryCode});
  @override bool operator ==(Object other) => other is AdminReportFilters && id == other.id && _sameList(statuses, other.statuses) && priority == other.priority && targetType == other.targetType && reason == other.reason && countryCode == other.countryCode;
  @override int get hashCode => Object.hash(id, Object.hashAll(statuses ?? const []), priority, targetType, reason, countryCode);
}

class AdminApprovalFilters {
  final String? id;
  final String? status;
  final String? badgeType;

  const AdminApprovalFilters({this.id, this.status = 'pending', this.badgeType});
  @override bool operator ==(Object other) => other is AdminApprovalFilters && id == other.id && status == other.status && badgeType == other.badgeType;
  @override int get hashCode => Object.hash(id, status, badgeType);
}

class AdminListingFilters {
  final String? id;
  final String? status;
  final String? categoryId;
  final bool? isMediated;
  final String? countryCode;
  final String? regionId;
  final String search;

  const AdminListingFilters({this.id, this.status, this.categoryId, this.isMediated, this.countryCode, this.regionId, this.search = ''});
  @override bool operator ==(Object other) => other is AdminListingFilters && id == other.id && status == other.status && categoryId == other.categoryId && isMediated == other.isMediated && countryCode == other.countryCode && regionId == other.regionId && search == other.search;
  @override int get hashCode => Object.hash(id, status, categoryId, isMediated, countryCode, regionId, search);
}

class AdminCalendarFilters {
  final String? status;
  final String? countryCode;
  final String? regionId;
  final String? seasonLabel;
  final String? speciesCategory;
  final String search;

  const AdminCalendarFilters({this.status, this.countryCode, this.regionId, this.seasonLabel, this.speciesCategory, this.search = ''});
  @override bool operator ==(Object other) => other is AdminCalendarFilters && status == other.status && countryCode == other.countryCode && regionId == other.regionId && seasonLabel == other.seasonLabel && speciesCategory == other.speciesCategory && search == other.search;
  @override int get hashCode => Object.hash(status, countryCode, regionId, seasonLabel, speciesCategory, search);
}

class AdminAuditFilters {
  final String? action;
  final String? resourceType;
  final String? adminId;
  final DateTime? since;
  final String search;

  const AdminAuditFilters({this.action, this.resourceType, this.adminId, this.since, this.search = ''});
  @override bool operator ==(Object other) => other is AdminAuditFilters && action == other.action && resourceType == other.resourceType && adminId == other.adminId && since == other.since && search == other.search;
  @override int get hashCode => Object.hash(action, resourceType, adminId, since, search);
}

class AdminContentFilters {
  final String? id;
  final String? status;
  final String? kind;
  final String? visibility;
  final bool? isSensitive;
  final String? countryCode;
  final String search;
  const AdminContentFilters({this.id, this.status, this.kind, this.visibility, this.isSensitive, this.countryCode, this.search = ''});
  @override bool operator ==(Object other) => other is AdminContentFilters && id == other.id && status == other.status && kind == other.kind && visibility == other.visibility && isSensitive == other.isSensitive && countryCode == other.countryCode && search == other.search;
  @override int get hashCode => Object.hash(id, status, kind, visibility, isSensitive, countryCode, search);
}

class AdminCommunityFilters {
  final String? id;
  final String kind;
  final String? status;
  final String? visibility;
  final String? joinPolicy;
  final String? category;
  final String? verificationStatus;
  final String? countryCode;
  final String? regionId;
  final String period;
  final String search;
  const AdminCommunityFilters({this.id, required this.kind, this.status, this.visibility, this.joinPolicy, this.category, this.verificationStatus, this.countryCode, this.regionId, this.period = 'all', this.search = ''});
  @override bool operator ==(Object other) => other is AdminCommunityFilters && id == other.id && kind == other.kind && status == other.status && visibility == other.visibility && joinPolicy == other.joinPolicy && category == other.category && verificationStatus == other.verificationStatus && countryCode == other.countryCode && regionId == other.regionId && period == other.period && search == other.search;
  @override int get hashCode => Object.hash(id, kind, status, visibility, joinPolicy, category, verificationStatus, countryCode, regionId, period, search);
}

bool _sameList(List<String>? left, List<String>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) { if (left[index] != right[index]) return false; }
  return true;
}

class AdminListRepository {
  static const pageSize = 20;
  static const _personFields = 'id,username,display_name,avatar_url,verification_level,country_code';
  final SupabaseClient _client;

  const AdminListRepository(this._client);

  Future<AdminPageResult<AdminUserRecord>> fetchUsers({required AdminUserFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('user_profiles').select();
      query = _userFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final row in rows as List) AdminUserRecord.fromJson(_profileWithAvatar(row as Map))];
      return AdminPageResult(page: _page(items, (item) => item.profile.createdAt, (item) => item.profile.id), count: await countUsers(filters));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<int> countUsers(AdminUserFilters filters) async {
    dynamic query = _client.from('user_profiles').count(CountOption.exact);
    query = _userFilters(query, filters);
    return await query as int;
  }

  Future<AdminUserDetail> fetchUserDetail(String userId) async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('admin_users').select('role:admin_roles!admin_users_role_id_fkey(name)').eq('user_id', userId).maybeSingle(),
        _client.from('reports').count(CountOption.exact).eq('target_author_id', userId),
        _client.from('reports').select('*,reporter:user_profiles!reports_reporter_id_fkey($_personFields),target_author:user_profiles!reports_target_author_id_fkey($_personFields),assignee:user_profiles!reports_assigned_to_fkey($_personFields)').eq('target_author_id', userId).order('created_at', ascending: false).limit(3),
        _client.from('verification_requests').select('*,user:user_profiles!verification_requests_user_id_fkey($_personFields),reviewer:user_profiles!verification_requests_reviewed_by_fkey($_personFields),page:pages!verification_requests_page_id_fkey(id,slug,name,category)').eq('user_id', userId).order('created_at', ascending: false),
        _client.from('payment_methods').select('id,brand,last4,exp_month,exp_year,country_code,is_default,status,last_failure_code,created_at').eq('user_id', userId).neq('status', 'removed').order('created_at', ascending: false),
      ]);
      final admin = results[0] as Map<String, dynamic>?;
      return AdminUserDetail(
        adminRole: (admin?['role'] as Map?)?['name'] as String?,
        reportCount: results[1] as int,
        reports: [for (final row in results[2] as List) AdminReportRecord.fromJson(_reportWithAvatars(row as Map))],
        requests: [for (final row in results[3] as List) AdminVerificationRequest.fromJson(_verificationWithAvatars(row as Map))],
        paymentMethods: [for (final row in results[4] as List) BillingPaymentMethod.fromJson(Map<String, dynamic>.from(row as Map))],
      );
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminReportRecord>> fetchReports({required AdminReportFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('reports').select('*,reporter:user_profiles!reports_reporter_id_fkey($_personFields),target_author:user_profiles!reports_target_author_id_fkey($_personFields),assignee:user_profiles!reports_assigned_to_fkey($_personFields)');
      query = _reportFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final row in rows as List) AdminReportRecord.fromJson(_reportWithAvatars(row as Map))];
      return AdminPageResult(page: _page(items, (item) => item.createdAt, (item) => item.id), count: await countReports(filters));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<int> countReports(AdminReportFilters filters) async {
    dynamic query = _client.from('reports').count(CountOption.exact);
    query = _reportFilters(query, filters);
    return await query as int;
  }

  Future<AdminReportPreview> fetchReportPreview(AdminReportRecord report) async {
    try {
      if (report.targetType == 'ad') {
        final row = await _client.from('ads').select('id,creative:ad_creatives(*),ad_set:ad_sets(campaign:ad_campaigns(name,account:ad_accounts(id,name)))').eq('id', report.targetId).maybeSingle();
        if (row == null || row['creative'] is! Map) return const AdminReportPreview(title: 'admin.p05b.contentRemoved', removed: true);
        final creative = AdCreative.fromJson(Map<String, dynamic>.from(row['creative'] as Map));
        final campaign = (row['ad_set'] as Map?)?['campaign'] as Map?;
        final account = campaign?['account'] as Map?;
        return AdminReportPreview(title: creative.headline, text: creative.body, adCreative: creative, advertiserName: account?['name']?.toString(), adAccountId: account?['id']?.toString(), campaignName: campaign?['name']?.toString());
      }
      final config = switch (report.targetType) {
        'post' => ('posts', 'content,status,media:post_media(path,sort_order)'),
        'comment' => ('comments', 'content,status'),
        'reply' => ('forum_replies', 'content,status'),
        'listing' => ('listings', 'title,price_minor,currency_code,status'),
        'profile' => ('user_profiles', 'display_name,username,bio,status'),
        'thread' => ('forum_threads', 'title,content,status'),
        'group' => ('groups', 'name,description,status'),
        'page' => ('pages', 'name,description,status'),
        'event' => ('events', 'title,description,status'),
        _ => null,
      };
      if (config == null) return const AdminReportPreview(title: 'admin.p05b.previewUnavailable');
      final row = await _client.from(config.$1).select(config.$2).eq('id', report.targetId).maybeSingle();
      if (row == null) return const AdminReportPreview(title: 'admin.p05b.contentRemoved', removed: true);
      final title = (row['title'] ?? row['name'] ?? row['display_name'] ?? row['content'] ?? 'admin.p05b.previewUnavailable').toString();
      final text = (row['description'] ?? row['bio'] ?? (row['title'] == null ? null : row['content']))?.toString();
      String? mediaUrl;
      final media = row['media'] as List?;
      if (media != null && media.isNotEmpty) mediaUrl = storagePublicUrl(_client, 'post-media', (media.first as Map)['path'] as String?);
      final subtitle = row['price_minor'] == null ? row['status']?.toString() : '${row['price_minor']}|${row['currency_code']}';
      return AdminReportPreview(title: title, text: text, mediaUrl: mediaUrl, subtitle: subtitle);
    } catch (_) { return const AdminReportPreview(title: 'admin.p05b.contentRemoved', removed: true); }
  }

  Future<AdminPageResult<AdminVerificationRequest>> fetchApprovals({required AdminApprovalFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('verification_requests').select('*,user:user_profiles!verification_requests_user_id_fkey($_personFields),reviewer:user_profiles!verification_requests_reviewed_by_fkey($_personFields),page:pages!verification_requests_page_id_fkey(id,slug,name,category)');
      if (filters.status != null) query = query.eq('status', filters.status!);
      if (filters.id != null) query = query.eq('id', filters.id!);
      if (filters.badgeType != null) query = query.eq('badge_type', filters.badgeType);
      if (cursor != null) query = filters.status == 'pending' ? query.or('created_at.gt.${cursor.createdAt.toIso8601String()},and(created_at.eq.${cursor.createdAt.toIso8601String()},id.gt.${cursor.id})') : applyCursor(query, cursor);
      final ascending = filters.status == 'pending';
      final rows = await query.order('created_at', ascending: ascending).order('id', ascending: ascending).limit(pageSize);
      final items = [for (final row in rows as List) AdminVerificationRequest.fromJson(_verificationWithAvatars(row as Map))];
      dynamic countQuery = _client.from('verification_requests').count(CountOption.exact);
      if (filters.status != null) countQuery = countQuery.eq('status', filters.status!);
      if (filters.id != null) countQuery = countQuery.eq('id', filters.id!);
      final count = filters.badgeType == null ? await countQuery : await countQuery.eq('badge_type', filters.badgeType!);
      return AdminPageResult(page: _page(items, (item) => item.createdAt, (item) => item.id), count: count);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> createVerificationDocumentUrl(String path) async {
    try { return await storageSignedUrl(_client, 'verification-docs', path, expiresIn: 600); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminVerificationStats> fetchVerificationStats() async {
    try {
      final result = await _client.rpc('verification_stats');
      return AdminVerificationStats.fromJson(Map<String, dynamic>.from(result as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminVerificationRequest>> fetchVerificationHistory(String userId, String currentId) async {
    try {
      final rows = await _client.from('verification_requests').select('*,user:user_profiles!verification_requests_user_id_fkey($_personFields),reviewer:user_profiles!verification_requests_reviewed_by_fkey($_personFields),page:pages!verification_requests_page_id_fkey(id,slug,name,category)').eq('user_id', userId).neq('id', currentId).order('created_at', ascending: false).limit(20);
      return [for (final row in rows as List) AdminVerificationRequest.fromJson(_verificationWithAvatars(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> reviewVerification({required String id, required String decision, String? reason, DateTime? expiresAt}) async {
    try { await _client.rpc('review_verification_request', params: {'p_id': id, 'p_decision': decision, 'p_reason': reason, 'p_expires_at': expiresAt?.toUtc().toIso8601String()}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminVerificationMaintenanceResult> runVerificationMaintenance() async {
    try {
      final result = await _client.rpc('run_verification_maintenance');
      return AdminVerificationMaintenanceResult.fromJson(Map<String, dynamic>.from(result as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminListingRecord>> fetchListings({required AdminListingFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('listings').select('*,seller:user_profiles!listings_seller_id_fkey(*),category:categories!listings_category_id_fkey(*),media:listing_media(*)');
      query = _listingFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final listings = [for (final row in rows as List) Listing.fromJson(_listingWithUrls(row as Map))];
      final reportCounts = <String, int>{};
      if (listings.isNotEmpty) {
        final reports = await _client.from('reports').select('target_id').eq('target_type', 'listing').inFilter('target_id', listings.map((item) => item.id).toList());
        for (final row in reports as List) reportCounts.update(row['target_id'] as String, (value) => value + 1, ifAbsent: () => 1);
      }
      final items = [for (final listing in listings) AdminListingRecord(listing: listing, reportCount: reportCounts[listing.id] ?? 0)];
      return AdminPageResult(page: _page(items, (item) => item.listing.createdAt, (item) => item.listing.id), count: await countListings(filters));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<int> countListings(AdminListingFilters filters) async {
    dynamic query = _client.from('listings').count(CountOption.exact);
    query = _listingFilters(query, filters);
    return await query as int;
  }

  Future<AdminListingDetail> fetchListingDetail(Listing listing) async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('listings').count(CountOption.exact).eq('seller_id', listing.sellerId).eq('status', 'active'),
        _client.from('reports').select('*,reporter:user_profiles!reports_reporter_id_fkey($_personFields),target_author:user_profiles!reports_target_author_id_fkey($_personFields),assignee:user_profiles!reports_assigned_to_fkey($_personFields)').eq('target_type', 'listing').eq('target_id', listing.id).order('created_at', ascending: false),
        if (listing.isMediated) _client.from('country_policies').select('policy_data').eq('country_code', listing.countryCode).eq('policy_type', 'firearms_marketplace').maybeSingle() else Future.value(null),
      ]);
      return AdminListingDetail(sellerActiveCount: results[0] as int, reports: [for (final row in results[1] as List) AdminReportRecord.fromJson(_reportWithAvatars(row as Map))], firearmsPolicy: results[2] == null ? null : Map<String, dynamic>.from(((results[2] as Map)['policy_data'] as Map?) ?? const {}));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminCalendarRecord>> fetchCalendars({required AdminCalendarFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('hunting_calendars').select('*,region:regions!hunting_calendars_region_id_fkey(name),hunting_unit:hunting_units!hunting_calendars_hunting_unit_id_fkey(name),publisher:user_profiles!hunting_calendars_published_by_fkey(display_name),species:species!inner(id,scientific_name,category,names:species_names(locale,name)),rules:calendar_rules(id,kind,date_from,date_to,allowed_days,time_rule,bag_limit,bag_period,notes,sort_order)');
      query = _calendarFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final row in rows as List) AdminCalendarRecord.fromJson(Map<String, dynamic>.from(row as Map))];
      return AdminPageResult(page: _page(items, (item) => item.createdAt, (item) => item.calendar.id), count: await countCalendars(filters));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<int> countCalendars(AdminCalendarFilters filters) async {
    if (filters.speciesCategory != null) {
      dynamic query = _client.from('hunting_calendars').select('id,species:species!inner(category)').eq('species.category', filters.speciesCategory!);
      if (filters.status != null) query = query.eq('status', filters.status!);
      if (filters.countryCode != null) query = query.eq('country_code', filters.countryCode!);
      if (filters.regionId != null) query = query.eq('region_id', filters.regionId!);
      if (filters.seasonLabel != null) query = query.eq('season_label', filters.seasonLabel!);
      return (await query as List).length;
    }
    dynamic query = _client.from('hunting_calendars').count(CountOption.exact);
    query = _calendarFilters(query, filters);
    return await query as int;
  }

  Future<AdminCalendarOptions> fetchCalendarOptions() async {
    try {
      final rows = await _client.from('hunting_calendars').select('country_code,status,season_label,region_id,region:regions!hunting_calendars_region_id_fkey(name),species:species!hunting_calendars_species_id_fkey(category)');
      final regions = <String, String>{};
      final countries = <String>{};
      final statuses = <String>{};
      final seasons = <String>{};
      final categories = <String>{};
      for (final raw in rows as List) {
        final row = raw as Map;
        countries.add((row['country_code'] as String).trim());
        statuses.add(row['status'] as String);
        seasons.add(row['season_label'] as String);
        final region = row['region'] as Map?;
        if (region != null) regions[row['region_id'] as String] = region['name'] as String;
        final species = row['species'] as Map?;
        if (species != null) categories.add(species['category'] as String);
      }
      return AdminCalendarOptions(regions: regions, countries: countries.toList()..sort(), statuses: statuses.toList()..sort(), seasons: seasons.toList()..sort(), categories: categories.toList()..sort());
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminSpeciesRecord>> fetchSpecies() async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('species').select('id,scientific_name,category,names:species_names(locale,name)').order('scientific_name'),
        _client.from('hunting_calendars').select('species_id').eq('status', 'published'),
      ]);
      final counts = <String, int>{};
      for (final row in results[1] as List) counts.update((row as Map)['species_id'] as String, (value) => value + 1, ifAbsent: () => 1);
      return [for (final row in results[0] as List) AdminSpeciesRecord(species: SpeciesInfo.fromJson(Map<String, dynamic>.from(row as Map)), publishedCalendarCount: counts[row['id'] as String] ?? 0)];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminRolesData> fetchRolesData() async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('admin_roles').select('id,name,description,permissions:admin_role_permissions(module,access)').order('name'),
        _client.from('admin_users').select('mfa_enabled,created_at,role:admin_roles!admin_users_role_id_fkey(name),profile:user_profiles!admin_users_user_id_fkey($_personFields),creator:user_profiles!admin_users_created_by_fkey($_personFields)').order('created_at', ascending: false),
      ]);
      final staff = [for (final row in results[1] as List) AdminStaffRecord.fromJson(_staffWithAvatar(row as Map))];
      final roles = <AdminRoleRecord>[];
      for (final raw in results[0] as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final permissions = <String, String>{for (final item in row['permissions'] as List? ?? const []) (item as Map)['module'] as String: item['access'] as String};
        roles.add(AdminRoleRecord(id: row['id'] as String, name: row['name'] as String, description: row['description'] as String?, permissions: permissions, staffCount: staff.where((item) => item.roleName == row['name']).length));
      }
      return AdminRolesData(roles: roles, staff: staff);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setStaffMfaRequired({required String userId, required bool enabled}) async {
    try {
      final actorId = _client.auth.currentUser?.id;
      if (actorId == null) throw const AuthException('not_authenticated');
      await _client.from('admin_users').update({'mfa_enabled': enabled, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('user_id', userId);
      await _client.from('admin_audit_log').insert({'admin_id': actorId, 'action': enabled ? 'security.mfa_enable' : 'security.mfa_disable', 'resource_type': 'admin_user', 'resource_id': userId, 'changes': {'mfa_enabled': {'before': !enabled, 'after': enabled}}});
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPlatformConfiguration> fetchPlatformConfiguration() async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('countries').select().order('sort_order'),
        _client.from('feature_flags').select().order('module'),
        _client.from('country_policies').select().order('country_code').order('policy_type'),
        _client.from('exchange_rates').select().order('valid_on', ascending: false),
        _client.from('regions').select('country_code'),
        _client.from('user_profiles').select('country_code'),
      ]);
      final regionCounts = _countryCounts(results[4] as List);
      final userCounts = _countryCounts(results[5] as List);
      final countries = [for (final raw in results[0] as List) AdminCountryRecord(code: ((raw as Map)['code'] as String).trim(), name: raw['name'] as String, currencyCode: (raw['default_currency'] as String).trim(), locale: raw['default_locale'] as String, unitSystem: raw['unit_system'] as String, isActive: raw['is_active'] as bool? ?? false, regionCount: regionCounts[(raw['code'] as String).trim()] ?? 0, userCount: userCounts[(raw['code'] as String).trim()] ?? 0)];
      return AdminPlatformConfiguration(countries: countries, flags: [for (final row in results[1] as List) AdminFeatureFlag.fromJson(Map<String, dynamic>.from(row as Map))], policies: [for (final row in results[2] as List) AdminCountryPolicy.fromJson(Map<String, dynamic>.from(row as Map))], exchangeRates: [for (final row in results[3] as List) AdminExchangeRate.fromJson(Map<String, dynamic>.from(row as Map))]);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminCountryPolicyOverview>> fetchCountryPoliciesOverview() async {
    try { final rows = await _client.rpc('country_policies_overview'); return [for (final row in rows as List) AdminCountryPolicyOverview.fromJson(Map<String, dynamic>.from(row as Map))]; } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> upsertCountryPolicy({required String countryCode, required String policyType, required Map<String, dynamic> data}) async {
    try { await _client.rpc('upsert_country_policy', params: {'p_country': countryCode, 'p_policy_type': policyType, 'p_policy_data': data}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminAuditOptions> fetchAuditOptions() async {
    try {
      final rows = await _client.from('admin_audit_log').select('action,resource_type,admin:user_profiles!admin_audit_log_admin_id_fkey($_personFields)');
      final actions = <String>{};
      final resourceTypes = <String>{};
      final admins = <String, AdminPerson>{};
      for (final raw in rows as List) {
        final row = raw as Map;
        actions.add(row['action'] as String);
        if (row['resource_type'] != null) resourceTypes.add(row['resource_type'] as String);
        final admin = _personFromRaw(row['admin']);
        if (admin != null) admins[admin.id] = admin;
      }
      return AdminAuditOptions(actions: actions.toList()..sort(), resourceTypes: resourceTypes.toList()..sort(), admins: admins.values.toList()..sort((left, right) => left.displayName.compareTo(right.displayName)));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminAuditRecord>> fetchAuditLog({required AdminAuditFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('admin_audit_log').select('*,admin:user_profiles!admin_audit_log_admin_id_fkey($_personFields)');
      query = _auditFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final jsonRows = [for (final row in rows as List) _auditWithAvatar(row as Map)];
      final pageIds = [for (final row in jsonRows) if (row['resource_type'] == 'page' && row['resource_id'] != null) row['resource_id'] as String];
      if (pageIds.isNotEmpty) {
        final pages = await _client.from('pages').select('id,slug').inFilter('id', pageIds);
        final slugs = {for (final page in pages as List) (page as Map)['id'] as String: page['slug'] as String};
        for (final row in jsonRows) row['resource_slug'] = slugs[row['resource_id']];
      }
      final items = [for (final row in jsonRows) AdminAuditRecord.fromJson(row)];
      dynamic countQuery = _client.from('admin_audit_log').count(CountOption.exact);
      countQuery = _auditFilters(countQuery, filters);
      return AdminPageResult(page: _page(items, (item) => item.createdAt, (item) => item.id), count: await countQuery as int);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminPostRecord>> fetchAdminPosts({required AdminContentFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('posts').select('*,author:user_profiles!posts_author_id_fkey($_personFields),media:post_media(*),group:groups!posts_group_id_fkey(slug,name),page:pages!posts_page_id_fkey(slug,name)');
      query = await _contentFilters(query, filters, includePostFields: true);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final raw in rows as List) _postRecord(raw as Map)];
      return AdminPageResult(page: _page(items, (item) => item.post.createdAt, (item) => item.post.id), count: await countAdminContent('posts', filters));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminStoryRecord>> fetchAdminStories({required AdminContentFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('stories').select('*,author:user_profiles!stories_author_id_fkey($_personFields)');
      query = await _contentFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final raw in rows as List) _storyRecord(raw as Map)];
      return AdminPageResult(page: _page(items, (item) => item.createdAt, (item) => item.id), count: await countAdminContent('stories', filters));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminCommentRecord>> fetchAdminComments({required AdminContentFilters filters, PageCursor? cursor}) async {
    try {
      dynamic query = _client.from('comments').select('*,author:user_profiles!comments_author_id_fkey($_personFields),post:posts!comments_post_id_fkey(id,content,author_id)');
      if (filters.id != null) query = query.eq('id', filters.id!);
      if (filters.status != null) query = query.eq('status', filters.status!);
      final search = _search(filters.search);
      if (search != null) query = query.ilike('content', '%$search%');
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final raw in rows as List) _commentRecord(raw as Map)];
      dynamic countQuery = _client.from('comments').count(CountOption.exact);
      if (filters.id != null) countQuery = countQuery.eq('id', filters.id!);
      if (filters.status != null) countQuery = countQuery.eq('status', filters.status!);
      if (search != null) countQuery = countQuery.ilike('content', '%$search%');
      return AdminPageResult(page: _page(items, (item) => item.createdAt, (item) => item.id), count: await countQuery as int);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<int> countAdminContent(String table, AdminContentFilters filters) async {
    dynamic query = _client.from(table).count(CountOption.exact);
    query = await _contentFilters(query, filters, includePostFields: table == 'posts');
    return await query as int;
  }

  Future<AdminPostDetail> fetchAdminPostDetail(String postId) async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('comments').select('*,author:user_profiles!comments_author_id_fkey($_personFields),post:posts!comments_post_id_fkey(id,content,author_id)').eq('post_id', postId).order('created_at').limit(10),
        _client.from('reports').select('*,reporter:user_profiles!reports_reporter_id_fkey($_personFields),target_author:user_profiles!reports_target_author_id_fkey($_personFields),assignee:user_profiles!reports_assigned_to_fkey($_personFields)').eq('target_type', 'post').eq('target_id', postId).order('created_at', ascending: false),
      ]);
      return AdminPostDetail(comments: [for (final row in results[0] as List) _commentRecord(row as Map)], reports: [for (final row in results[1] as List) AdminReportRecord.fromJson(_reportWithAvatars(row as Map))]);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminCommunityRecord>> fetchAdminCommunities({required AdminCommunityFilters filters, PageCursor? cursor}) async {
    try {
      final table = filters.kind;
      dynamic query = _client.from(table).select('*,owner:user_profiles!${table}_owner_id_fkey($_personFields)${table == 'pages' ? ',region:regions!pages_region_id_fkey(name)' : table == 'groups' ? ',region:regions!groups_region_id_fkey(name)' : ''}');
      query = _communityFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final raw in rows as List) _communityRecord(raw as Map, table)];
      dynamic countQuery = _client.from(table).count(CountOption.exact);
      countQuery = _communityFilters(countQuery, filters);
      return AdminPageResult(page: _page(items, (item) => item.createdAt, (item) => item.id), count: await countQuery as int);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminPageResult<AdminEventRecord>> fetchAdminEvents({required AdminCommunityFilters filters, PageCursor? cursor}) async {
    try {
      const embed = '*,organizer_user:user_profiles!events_organizer_user_id_fkey(*),organizer_page:pages!events_organizer_page_id_fkey(id,slug,name,avatar_url),organizer_group:groups!events_organizer_group_id_fkey(id,slug,name,avatar_url)';
      dynamic query = _client.from('events').select(embed);
      query = _communityFilters(query, filters);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = [for (final raw in rows as List) _eventRecord(raw as Map)];
      dynamic countQuery = _client.from('events').count(CountOption.exact);
      countQuery = _communityFilters(countQuery, filters);
      return AdminPageResult(page: _page(items, (item) => item.event.createdAt, (item) => item.event.id), count: await countQuery as int);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminCommunityDetail> fetchAdminCommunityDetail(AdminCommunityRecord community) async {
    try {
      if (community.kind == 'groups') {
        final results = await Future.wait<dynamic>([
          _client.from('group_members').select('id,role,status,profile:user_profiles!group_members_user_id_fkey($_personFields)').eq('group_id', community.id).order('created_at').limit(pageSize),
          _client.from('posts').select('*,author:user_profiles!posts_author_id_fkey($_personFields),media:post_media(*),group:groups!posts_group_id_fkey(slug,name),page:pages!posts_page_id_fkey(slug,name)').eq('group_id', community.id).order('created_at', ascending: false).limit(5),
        ]);
        return AdminCommunityDetail(members: [for (final row in results[0] as List) _membership(row as Map)], posts: [for (final row in results[1] as List) _postRecord(row as Map)]);
      }
      if (community.kind == 'pages') {
        final results = await Future.wait<dynamic>([
          _client.from('page_roles').select('id,role,profile:user_profiles!page_roles_user_id_fkey($_personFields)').eq('page_id', community.id).order('created_at').limit(pageSize),
          _client.from('posts').select('*,author:user_profiles!posts_author_id_fkey($_personFields),media:post_media(*),group:groups!posts_group_id_fkey(slug,name),page:pages!posts_page_id_fkey(slug,name)').eq('page_id', community.id).order('created_at', ascending: false).limit(5),
        ]);
        return AdminCommunityDetail(members: [for (final row in results[0] as List) _membership(row as Map)], posts: [for (final row in results[1] as List) _postRecord(row as Map)]);
      }
      final results = await Future.wait<dynamic>([
        _client.from('forum_members').select('id,role,status,profile:user_profiles!forum_members_user_id_fkey($_personFields)').eq('forum_id', community.id).order('created_at').limit(pageSize),
        _client.from('forum_threads').select('id,title,reply_count,is_pinned,is_locked,solution_reply_id,author:user_profiles!forum_threads_author_id_fkey($_personFields)').eq('forum_id', community.id).order('created_at', ascending: false).limit(5),
      ]);
      return AdminCommunityDetail(members: [for (final row in results[0] as List) _membership(row as Map)], threads: [for (final raw in results[1] as List) _thread(raw as Map)]);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminEventDetail> fetchAdminEventDetail(String eventId) async {
    try {
      final rows = await _client.from('event_participants').select('id,status,profile:user_profiles!event_participants_user_id_fkey(*)').eq('event_id', eventId).order('created_at').limit(pageSize);
      return AdminEventDetail(participants: [for (final raw in rows as List) EventParticipant.fromJson(_participantWithAvatar(raw as Map))]);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  dynamic _userFilters(dynamic query, AdminUserFilters filters) {
    if (filters.id != null) query = query.eq('id', filters.id!);
    if (filters.status != null) query = query.eq('status', filters.status);
    if (filters.countryCode != null) query = query.eq('country_code', filters.countryCode);
    if (filters.verificationLevel != null) query = query.eq('verification_level', filters.verificationLevel);
    if (filters.regionId != null) query = query.eq('home_region_id', filters.regionId);
    if (filters.expiringSoon) {
      final now = DateTime.now().toUtc();
      query = query.gte('verification_expires_at', now.toIso8601String()).lte('verification_expires_at', now.add(const Duration(days: 30)).toIso8601String());
    }
    final search = _search(filters.search);
    if (search != null) query = query.or('username.ilike.%$search%,display_name.ilike.%$search%');
    return query;
  }

  dynamic _reportFilters(dynamic query, AdminReportFilters filters) {
    if (filters.id != null) query = query.eq('id', filters.id!);
    if (filters.statuses != null) query = query.inFilter('status', filters.statuses!);
    if (filters.priority != null) query = query.eq('priority', filters.priority);
    if (filters.targetType != null) query = query.eq('target_type', filters.targetType);
    if (filters.reason != null) query = query.eq('reason', filters.reason);
    if (filters.countryCode != null) query = query.eq('country_code', filters.countryCode);
    return query;
  }

  dynamic _listingFilters(dynamic query, AdminListingFilters filters) {
    if (filters.id != null) query = query.eq('id', filters.id!);
    if (filters.status != null) query = query.eq('status', filters.status);
    if (filters.categoryId != null) query = query.eq('category_id', filters.categoryId);
    if (filters.isMediated != null) query = query.eq('is_mediated', filters.isMediated);
    if (filters.countryCode != null) query = query.eq('country_code', filters.countryCode);
    if (filters.regionId != null) query = query.eq('region_id', filters.regionId);
    final search = _search(filters.search);
    if (search != null) query = query.ilike('title', '%$search%');
    return query;
  }

  dynamic _calendarFilters(dynamic query, AdminCalendarFilters filters) {
    if (filters.status != null) query = query.eq('status', filters.status);
    if (filters.countryCode != null) query = query.eq('country_code', filters.countryCode);
    if (filters.regionId != null) query = query.eq('region_id', filters.regionId);
    if (filters.seasonLabel != null) query = query.eq('season_label', filters.seasonLabel);
    if (filters.speciesCategory != null) query = query.eq('species.category', filters.speciesCategory);
    return query;
  }

  dynamic _auditFilters(dynamic query, AdminAuditFilters filters) {
    if (filters.action != null) query = query.eq('action', filters.action);
    if (filters.resourceType != null) query = query.eq('resource_type', filters.resourceType);
    if (filters.adminId != null) query = query.eq('admin_id', filters.adminId);
    if (filters.since != null) query = query.gte('created_at', filters.since!.toUtc().toIso8601String());
    final search = _search(filters.search);
    if (search != null) query = query.or('resource_id.ilike.%$search%,action.ilike.%$search%');
    return query;
  }

  Future<dynamic> _contentFilters(dynamic query, AdminContentFilters filters, {bool includePostFields = false}) async {
    if (filters.id != null) query = query.eq('id', filters.id!);
    if (filters.status != null) query = query.eq('status', filters.status!);
    if (filters.kind != null) query = query.eq('kind', filters.kind!);
    if (filters.countryCode != null) query = query.eq('country_code', filters.countryCode!);
    if (includePostFields) {
      if (filters.visibility != null) query = query.eq('visibility', filters.visibility!);
      if (filters.isSensitive != null) query = query.eq('is_sensitive', filters.isSensitive!);
    }
    final search = _search(filters.search);
    if (search != null) {
      final profiles = await _client.from('user_profiles').select('id').or('username.ilike.%$search%,display_name.ilike.%$search%');
      final ids = [for (final row in profiles as List) (row as Map)['id'] as String];
      if (includePostFields) {
        query = ids.isEmpty ? query.ilike('content', '%$search%') : query.or('content.ilike.%$search%,author_id.in.(${ids.join(',')})');
      } else if (ids.isNotEmpty) { query = query.inFilter('author_id', ids); }
    }
    return query;
  }

  dynamic _communityFilters(dynamic query, AdminCommunityFilters filters) {
    if (filters.id != null) query = query.eq('id', filters.id!);
    if (filters.status != null) query = query.eq('status', filters.status!);
    if (filters.visibility != null && filters.kind != 'events') query = query.eq('visibility', filters.visibility!);
    if (filters.joinPolicy != null && filters.kind == 'groups') query = query.eq('join_policy', filters.joinPolicy!);
    if (filters.category != null && filters.kind != 'groups') query = query.eq('category', filters.category!);
    if (filters.verificationStatus != null && filters.kind == 'pages') query = query.eq('verification_status', filters.verificationStatus!);
    if (filters.countryCode != null) query = query.eq('country_code', filters.countryCode!);
    if (filters.regionId != null && (filters.kind == 'groups' || filters.kind == 'pages' || filters.kind == 'events')) query = query.eq('region_id', filters.regionId!);
    if (filters.kind == 'events' && filters.period != 'all') query = filters.period == 'future' ? query.gte('starts_at', DateTime.now().toUtc().toIso8601String()) : query.lt('starts_at', DateTime.now().toUtc().toIso8601String());
    final search = _search(filters.search);
    if (search != null) query = filters.kind == 'events' ? query.ilike('title', '%$search%') : query.or('name.ilike.%$search%,slug.ilike.%$search%');
    return query;
  }

  String? _search(String raw) {
    final value = raw.trim();
    if (value.length < 2) return null;
    return value.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_').replaceAll(',', ' ');
  }

  Page<T> _page<T>(List<T> items, DateTime Function(T) date, String Function(T) id) {
    final last = items.length == pageSize ? items.last : null;
    return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: date(last), id: id(last)));
  }

  Map<String, dynamic> _profileWithAvatar(Map row) {
    final json = Map<String, dynamic>.from(row);
    json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
    return json;
  }

  Map<String, dynamic> _reportWithAvatars(Map row) {
    final json = Map<String, dynamic>.from(row);
    for (final key in ['reporter', 'target_author', 'assignee']) {
      if (json[key] is Map) json[key] = _profileWithAvatar(json[key] as Map);
    }
    return json;
  }

  Map<String, dynamic> _verificationWithAvatars(Map row) {
    final json = Map<String, dynamic>.from(row);
    json['user'] = _profileWithAvatar(json['user'] as Map);
    if (json['reviewer'] is Map) json['reviewer'] = _profileWithAvatar(json['reviewer'] as Map);
    return json;
  }

  Map<String, dynamic> _listingWithUrls(Map row) {
    final json = Map<String, dynamic>.from(row);
    json['seller'] = _profileWithAvatar(json['seller'] as Map);
    json['media'] = [for (final item in (json['media'] as List? ?? const [])) {...Map<String, dynamic>.from(item as Map), 'path': storagePublicUrl(_client, 'listing-media', (item as Map)['path'] as String?)}];
    return json;
  }

  Map<String, dynamic> _staffWithAvatar(Map row) {
    final json = Map<String, dynamic>.from(row);
    json['profile'] = _profileWithAvatar(json['profile'] as Map);
    if (json['creator'] is Map) json['creator'] = _profileWithAvatar(json['creator'] as Map);
    return json;
  }

  Map<String, int> _countryCounts(List rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      final code = ((row as Map)['country_code'] as String).trim();
      counts.update(code, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  AdminPerson? _personFromRaw(dynamic raw) => raw is Map ? AdminPerson.fromJson(_profileWithAvatar(raw)) : null;

  Map<String, dynamic> _auditWithAvatar(Map row) {
    final json = Map<String, dynamic>.from(row);
    if (json['admin'] is Map) json['admin'] = _profileWithAvatar(json['admin'] as Map);
    return json;
  }

  AdminPostRecord _postRecord(Map row) {
    final json = Map<String, dynamic>.from(row);
    json['author'] = _profileWithAvatar(json['author'] as Map);
    json['media'] = [for (final raw in json['media'] as List? ?? const []) {...Map<String, dynamic>.from(raw as Map), 'url': storagePublicUrl(_client, 'post-media', raw['path'] as String?)}];
    final group = json['group'] as Map?;
    final page = json['page'] as Map?;
    return AdminPostRecord(post: FeedPost.fromJson(json), status: json['status'] as String, visibility: json['visibility'] as String, isSensitive: json['is_sensitive'] as bool? ?? false, countryCode: (json['country_code'] as String).trim(), groupName: group?['name'] as String?, groupSlug: group?['slug'] as String?, pageName: page?['name'] as String?, pageSlug: page?['slug'] as String?);
  }

  AdminStoryRecord _storyRecord(Map row) {
    final json = Map<String, dynamic>.from(row);
    return AdminStoryRecord(id: json['id'] as String, author: AdminPerson.fromJson(_profileWithAvatar(json['author'] as Map)), mediaUrl: storagePublicUrl(_client, 'story-media', json['media_path'] as String?) ?? '', kind: json['kind'] as String, caption: json['caption'] as String?, viewCount: (json['view_count'] as num?)?.toInt() ?? 0, status: json['status'] as String, countryCode: (json['country_code'] as String).trim(), expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(), createdAt: DateTime.parse(json['created_at'] as String).toUtc());
  }

  AdminCommentRecord _commentRecord(Map row) {
    final json = Map<String, dynamic>.from(row);
    final post = json['post'] as Map?;
    return AdminCommentRecord(id: json['id'] as String, author: AdminPerson.fromJson(_profileWithAvatar(json['author'] as Map)), postId: json['post_id'] as String, postExcerpt: post?['content'] as String? ?? '', content: json['content'] as String, reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0, status: json['status'] as String, createdAt: DateTime.parse(json['created_at'] as String).toUtc());
  }

  AdminCommunityRecord _communityRecord(Map row, String kind) {
    final json = Map<String, dynamic>.from(row);
    final bucket = kind == 'groups' ? 'group-media' : kind == 'pages' ? 'page-media' : null;
    return AdminCommunityRecord(id: json['id'] as String, kind: kind, slug: json['slug'] as String, name: json['name'] as String, description: json['description'] as String?, avatarUrl: bucket == null ? null : storagePublicUrl(_client, bucket, json['avatar_url'] as String?), owner: AdminPerson.fromJson(_profileWithAvatar(json['owner'] as Map)), status: json['status'] as String, countryCode: (json['country_code'] as String).trim(), regionId: json['region_id'] as String?, regionName: (json['region'] as Map?)?['name'] as String?, category: json['category'] as String?, visibility: json['visibility'] as String?, joinPolicy: json['join_policy'] as String?, verificationStatus: json['verification_status'] as String?, verifiedAt: json['verified_at'] == null ? null : DateTime.tryParse(json['verified_at'].toString())?.toUtc(), memberCount: (json['member_count'] as num?)?.toInt() ?? 0, contentCount: (json[kind == 'forums' ? 'thread_count' : 'post_count'] as num?)?.toInt() ?? 0, followerCount: (json['follower_count'] as num?)?.toInt() ?? 0, website: json['website'] as String?, phone: json['phone'] as String?, email: json['email'] as String?, address: json['address'] as String?, createdAt: DateTime.parse(json['created_at'] as String).toUtc());
  }

  AdminMembershipRecord _membership(Map row) => AdminMembershipRecord(id: row['id'] as String, person: AdminPerson.fromJson(_profileWithAvatar(row['profile'] as Map)), role: row['role'] as String, status: row['status'] as String?);

  AdminThreadSummary _thread(Map row) => AdminThreadSummary(id: row['id'] as String, title: row['title'] as String, author: AdminPerson.fromJson(_profileWithAvatar(row['author'] as Map)), replyCount: (row['reply_count'] as num?)?.toInt() ?? 0, isPinned: row['is_pinned'] as bool? ?? false, isLocked: row['is_locked'] as bool? ?? false, isSolved: row['solution_reply_id'] != null);

  AdminEventRecord _eventRecord(Map row) {
    final json = Map<String, dynamic>.from(row);
    for (final entry in const {'organizer_user': 'avatars', 'organizer_page': 'page-media', 'organizer_group': 'group-media'}.entries) {
      if (json[entry.key] is Map) {
        final item = Map<String, dynamic>.from(json[entry.key] as Map);
        item['avatar_url'] = storagePublicUrl(_client, entry.value, item['avatar_url'] as String?);
        json[entry.key] = item;
      }
    }
    json['cover_url'] = storagePublicUrl(_client, 'event-media', json['cover_url'] as String?);
    return AdminEventRecord(event: HuntingEvent.fromJson(json), status: json['status'] as String, countryCode: (json['country_code'] as String).trim(), regionId: json['region_id'] as String?);
  }

  Map<String, dynamic> _participantWithAvatar(Map row) {
    final json = Map<String, dynamic>.from(row);
    json['profile'] = _profileWithAvatar(json['profile'] as Map);
    return json;
  }
}