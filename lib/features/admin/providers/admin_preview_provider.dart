import 'package:flutter_riverpod/legacy.dart';

/// Unlocks only the admin layout for debug previews. It never creates a
/// session, user or role.
final adminPreviewProvider = StateProvider<bool>((ref) => false);