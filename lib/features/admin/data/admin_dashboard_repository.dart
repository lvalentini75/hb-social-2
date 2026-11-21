import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/admin/domain/admin_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardRepository {
  final SupabaseClient _client;

  const AdminDashboardRepository(this._client);

  Future<DashboardData> getDashboard() async {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 7)).toUtc();
    final previousStart = now.subtract(const Duration(days: 14)).toUtc();
    final chartStartLocal = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
    final results = await Future.wait<Object>([
      _safeCount('user_profiles'),
      _safeCount('user_profiles', gteColumn: 'created_at', gteValue: currentStart.toIso8601String()),
      _safeCount('user_profiles', gteColumn: 'created_at', gteValue: previousStart.toIso8601String(), ltColumn: 'created_at', ltValue: currentStart.toIso8601String()),
      _safeCount('posts', gteColumn: 'created_at', gteValue: currentStart.toIso8601String()),
      _safeCount('posts', gteColumn: 'created_at', gteValue: previousStart.toIso8601String(), ltColumn: 'created_at', ltValue: currentStart.toIso8601String()),
      _safeCount('listings', eqColumn: 'status', eqValue: 'active'),
      _safeCount('reports', inColumn: 'status', inValues: const ['pending', 'in_progress']),
      _safeCount('verification_requests', eqColumn: 'status', eqValue: 'pending'),
      _safeCount('events', eqColumn: 'status', eqValue: 'published', gteColumn: 'starts_at', gteValue: now.toUtc().toIso8601String()),
      _safeCount('groups', eqColumn: 'status', eqValue: 'active'),
      _createdDates('user_profiles', chartStartLocal.toUtc()),
      _createdDates('posts', chartStartLocal.toUtc()),
      _openReports(),
      _badgeRequests(),
      _auditEntries(),
    ]);
    return DashboardData(
      totalUsers: results[0] as DashboardMetric,
      newUsersCurrent: results[1] as DashboardMetric,
      newUsersPrevious: results[2] as DashboardMetric,
      postsCurrent: results[3] as DashboardMetric,
      postsPrevious: results[4] as DashboardMetric,
      activeListings: results[5] as DashboardMetric,
      openReports: results[6] as DashboardMetric,
      pendingBadges: results[7] as DashboardMetric,
      upcomingEvents: results[8] as DashboardMetric,
      activeGroups: results[9] as DashboardMetric,
      dailyCounts: _buildDailyCounts(chartStartLocal, results[10] as List<DateTime>, results[11] as List<DateTime>),
      reports: results[12] as List<DashboardReport>,
      badgeRequests: results[13] as List<DashboardBadgeRequest>,
      auditEntries: results[14] as List<DashboardAuditEntry>,
    );
  }

  Future<DashboardMetric> _safeCount(
    String table, {
    String? eqColumn,
    Object? eqValue,
    String? inColumn,
    List<Object>? inValues,
    String? gteColumn,
    Object? gteValue,
    String? ltColumn,
    Object? ltValue,
  }) async {
    try {
      dynamic query = _client.from(table).count(CountOption.exact);
      if (eqColumn != null) query = query.eq(eqColumn, eqValue);
      if (inColumn != null) query = query.inFilter(inColumn, inValues!);
      if (gteColumn != null) query = query.gte(gteColumn, gteValue);
      if (ltColumn != null) query = query.lt(ltColumn, ltValue);
      final response = await query;
      return DashboardMetric.success(response as int);
    } catch (error) {
      return DashboardMetric.failure(ErrorMapper.fromSupabase(error).messageKey);
    }
  }

  Future<List<DateTime>> _createdDates(String table, DateTime start) async {
    try {
      final rows = await _client.from(table).select('created_at').gte('created_at', start.toIso8601String()).limit(5000);
      return [for (final row in rows as List) DateTime.parse(row['created_at'] as String).toUtc()];
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  List<DailyCount> _buildDailyCounts(DateTime start, List<DateTime> registrations, List<DateTime> posts) {
    final registrationCounts = <DateTime, int>{};
    final postCounts = <DateTime, int>{};
    for (final value in registrations) {
      final local = value.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      registrationCounts[day] = (registrationCounts[day] ?? 0) + 1;
    }
    for (final value in posts) {
      final local = value.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      postCounts[day] = (postCounts[day] ?? 0) + 1;
    }
    return [for (var index = 0; index < 30; index++) DailyCount(day: start.add(Duration(days: index)), registrations: registrationCounts[start.add(Duration(days: index))] ?? 0, posts: postCounts[start.add(Duration(days: index))] ?? 0)];
  }

  Future<List<DashboardReport>> _openReports() async {
    try {
      final batches = await Future.wait([
        _reportsByPriority('high'),
        _reportsByPriority('medium'),
        _reportsByPriority('low'),
      ]);
      return batches.expand((batch) => batch).take(5).toList(growable: false);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<DashboardReport>> _reportsByPriority(String priority) async {
    final rows = await _client
        .from('reports')
        .select('id, priority, reason, target_type, created_at, reporter:user_profiles!reports_reporter_id_fkey(id, display_name, avatar_url), target_author:user_profiles!reports_target_author_id_fkey(id, display_name, avatar_url)')
        .inFilter('status', const ['pending', 'in_progress'])
        .eq('priority', priority)
        .order('created_at', ascending: false)
        .limit(5);
    return [for (final row in rows as List) DashboardReport.fromJson(row as Map<String, dynamic>)];
  }

  Future<List<DashboardBadgeRequest>> _badgeRequests() async {
    try {
      final rows = await _client
          .from('verification_requests')
          .select('id, badge_type, created_at, user:user_profiles!verification_requests_user_id_fkey(id, display_name, avatar_url)')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(5);
      return [for (final row in rows as List) DashboardBadgeRequest.fromJson(row as Map<String, dynamic>)];
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<DashboardAuditEntry>> _auditEntries() async {
    try {
      final rows = await _client
          .from('admin_audit_log')
          .select('id, action, resource_type, resource_id, created_at, admin:user_profiles!admin_audit_log_admin_id_fkey(id, display_name, avatar_url)')
          .order('created_at', ascending: false)
          .limit(10);
      return [for (final row in rows as List) DashboardAuditEntry.fromJson(row as Map<String, dynamic>)];
    } on AppException {
      rethrow;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}