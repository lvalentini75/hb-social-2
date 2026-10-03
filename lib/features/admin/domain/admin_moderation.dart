import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';

enum UserStatus { active, suspended, banned, pendingVerification }

enum ReportStatus { pending, inProgress, resolved, removed }

enum ReportPriority { high, medium, low }

enum ReportTargetType { post, comment, listing, profile, thread, story, message }

enum BadgeType { hunter, gunShop, guide, association }

enum BadgeRequestStatus { pending, approved, rejected }

enum SupportedCountry { italy, france, spain, germany, austria, switzerland, unitedKingdom }

extension UserStatusPresentation on UserStatus {
  String get labelKey => 'admin.users.status.$name';

  HBStatusKind get statusKind => switch (this) {
    UserStatus.active => HBStatusKind.approved,
    UserStatus.pendingVerification => HBStatusKind.pending,
    UserStatus.banned => HBStatusKind.rejected,
    UserStatus.suspended => HBStatusKind.neutral,
  };
}

extension ReportStatusPresentation on ReportStatus {
  String get labelKey => 'admin.reports.status.$name';

  HBStatusKind get statusKind => switch (this) {
    ReportStatus.pending => HBStatusKind.pending,
    ReportStatus.inProgress => HBStatusKind.info,
    ReportStatus.resolved => HBStatusKind.approved,
    ReportStatus.removed => HBStatusKind.rejected,
  };
}

extension ReportPriorityPresentation on ReportPriority {
  String get labelKey => 'admin.reports.priority.$name';

  HBStatusKind get statusKind => switch (this) {
    ReportPriority.high => HBStatusKind.rejected,
    ReportPriority.medium => HBStatusKind.pending,
    ReportPriority.low => HBStatusKind.neutral,
  };
}

extension ReportTargetTypePresentation on ReportTargetType {
  String get labelKey => 'admin.reports.target.$name';
}

extension BadgeTypePresentation on BadgeType {
  String get labelKey => 'admin.badges.type.$name';

  HBBadgeKind get badgeKind => switch (this) {
    BadgeType.hunter => HBBadgeKind.verified,
    BadgeType.gunShop => HBBadgeKind.gunShop,
    BadgeType.guide => HBBadgeKind.guide,
    BadgeType.association => HBBadgeKind.association,
  };
}

extension BadgeRequestStatusPresentation on BadgeRequestStatus {
  String get labelKey => 'admin.badges.status.$name';

  HBStatusKind get statusKind => switch (this) {
    BadgeRequestStatus.pending => HBStatusKind.pending,
    BadgeRequestStatus.approved => HBStatusKind.approved,
    BadgeRequestStatus.rejected => HBStatusKind.rejected,
  };
}

extension SupportedCountryPresentation on SupportedCountry {
  String get labelKey => 'admin.common.country.$name';
}

class AdminUserRecord {
  final String id;
  const AdminUserRecord({required this.id});
}

class AdminReportRecord {
  final String id;
  const AdminReportRecord({required this.id});
}

class AdminBadgeRequest {
  final String id;
  const AdminBadgeRequest({required this.id});
}