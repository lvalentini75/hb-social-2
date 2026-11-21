import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Formats a UTC timestamp relative to now in the active app language.
String relativeTime(BuildContext context, DateTime value) => timeago.format(value.toLocal(), locale: Localizations.localeOf(context).languageCode, allowFromNow: true);