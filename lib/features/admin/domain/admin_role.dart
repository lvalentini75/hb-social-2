import 'package:hb_social/core/widgets/hb_status_chip.dart';

enum AdminRole { superadmin, admin, moderator, adsReviewer, finance, huntingDataEditor }

extension AdminRolePresentation on AdminRole {
  String get labelKey => 'admin.roles.$name';

  HBStatusKind get statusKind => switch (this) {
    AdminRole.superadmin => HBStatusKind.superAdmin,
    AdminRole.admin => HBStatusKind.admin,
    AdminRole.moderator || AdminRole.adsReviewer => HBStatusKind.moderator,
    AdminRole.finance => HBStatusKind.pending,
    AdminRole.huntingDataEditor => HBStatusKind.approved,
  };
}