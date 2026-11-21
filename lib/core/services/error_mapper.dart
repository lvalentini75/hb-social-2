import 'package:hb_social/core/services/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts backend failures into translation keys safe to show to users.
class ErrorMapper {
  const ErrorMapper._();

  static void Function()? onAccountSuspended;

  static AppException fromSupabase(Object error) {
    if (error is AppException) return error;
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('unsupported provider') || message.contains('provider is not enabled')) return const AppException('auth.provider_unavailable');
      if (message.contains('identity_already_exists')) return const AppException('auth.identity_already_linked');
      if (message.contains('single_identity_not_deletable') || message.contains('manual_linking_disabled')) return const AppException('auth.cannot_unlink_last');
      if (message.contains('email_exists')) return const AppException('auth.email_in_use');
      const friendErrors = {'friend_self', 'friend_user_not_found', 'friend_blocked', 'friend_already', 'friend_request_exists', 'friend_request_not_found', 'friend_request_not_pending', 'not_authenticated'};
      for (final key in friendErrors) {
        if (message.contains(key)) return AppException(key == 'not_authenticated' ? 'errors.login_required' : 'friendship.error');
      }
      if (message.contains('invalid totp') || message.contains('invalid code') || message.contains('challenge')) return const AppException('errors.mfa_invalid_code');
      if (message.contains('invalid login credentials')) return const AppException('auth.errors.invalid_credentials');
      if (message.contains('already registered') || message.contains('already exists')) return const AppException('auth.errors.email_in_use');
      if (message.contains('password')) return const AppException('auth.errors.weak_password');
      if (message.contains('email not confirmed')) return const AppException('auth.errors.email_not_confirmed');
      if (message.contains('rate limit') || message.contains('too many')) return const AppException('auth.errors.too_many_requests');
    }
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      const authProfileErrors = {
        'not_authenticated': 'errors.login_required', 'profile_not_found': 'auth.profile_not_found', 'account_not_active': 'auth.account_not_active',
        'birth_date_required': 'auth.complete_profile.errors.birth_date_required', 'birth_date_invalid': 'auth.complete_profile.errors.birth_date_invalid',
        'country_invalid': 'auth.complete_profile.errors.country_invalid', 'region_invalid': 'auth.complete_profile.errors.region_invalid', 'locale_invalid': 'auth.complete_profile.errors.locale_invalid',
        'username_invalid': 'auth.complete_profile.errors.username_invalid', 'username_taken': 'auth.complete_profile.errors.username_taken', 'display_name_invalid': 'auth.complete_profile.errors.display_name_invalid',
        'avatar_url_invalid': 'auth.complete_profile.errors.avatar_url_invalid',
        'admin_permission_denied': 'p41.errors.admin_permission_denied', 'admin_superadmin_required': 'p43.errors.admin_superadmin_required', 'settings_value_invalid': 'p43.errors.settings_value_invalid',
      };
      for (final entry in authProfileErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      if (message.contains('account_suspended')) {
        onAccountSuspended?.call();
        return const AppException('suspended.write_blocked');
      }
      if (message.contains('content_blocked')) return const AppException('sensitive.content_blocked');
      const p47Errors = {
        'post_schedule_invalid': 'composer.schedule.invalid',
        'post_schedule_limit': 'composer.schedule.limit',
        'post_not_scheduled': 'posts.scheduled.errors.not_scheduled',
        'article_not_found': 'articles.errors.article_not_found',
        'page_not_found': 'articles.errors.page_not_found',
        'page_not_manager': 'articles.errors.page_not_manager',
        'article_title_invalid': 'articles.errors.title_invalid',
        'article_subtitle_invalid': 'articles.errors.subtitle_invalid',
        'article_body_too_long': 'articles.errors.body_too_long',
        'article_body_too_short': 'articles.errors.body_too_short',
        'article_cover_invalid': 'articles.errors.cover_invalid',
        'article_slug_locked': 'articles.errors.slug_locked',
        'article_slug_exists': 'articles.errors.slug_exists',
        'article_already_published': 'articles.errors.already_published',
        'memory_type_invalid': 'memories.errors.type_invalid',
        'gif_url_invalid': 'gifs.errors.url_invalid',
      };
      for (final entry in p47Errors.entries) { if (message.contains(entry.key)) return AppException(entry.value, namedArgs: entry.key == 'post_schedule_limit' ? const {'n': '20'} : const {}); }
      const p44Errors = {'map_permission_denied','calendar_region_invalid','calendar_unit_invalid','calendar_species_invalid','calendar_dates_invalid','calendar_season_invalid','calendar_source_invalid','calendar_exists','calendar_not_found','calendar_rules_invalid','calendar_rule_kind_invalid','calendar_rule_dates_invalid','calendar_rule_days_invalid','calendar_rule_time_invalid','calendar_rule_bag_invalid','calendar_rule_scope_invalid','calendar_status_invalid','calendar_has_errors','calendar_import_invalid','calendar_published_locked','species_name_invalid','species_category_invalid','species_name_it_required','species_names_invalid','species_image_invalid','species_exists','species_not_found','species_merge_same','species_in_use','layer_region_invalid','layer_country_invalid','layer_kind_invalid','layer_name_invalid','layer_color_invalid','layer_source_invalid','layer_dates_invalid','layer_not_found','layer_geojson_too_large','layer_geojson_invalid','layer_geojson_missing','layer_status_invalid','unit_type_invalid','unit_code_missing','map_polygon_invalid','map_not_found'};
      for (final key in p44Errors) { if (message.contains(key)) return AppException('p44.errors.$key'); }
      const p41Errors = {'admin_permission_denied','admin_self_action','admin_target_protected','admin_reason_required','admin_days_invalid','admin_user_banned','admin_user_not_suspended','admin_note_invalid','admin_note_not_found','user_not_found','export_already_running','export_too_soon','export_not_found','export_not_ready','account_deletion_admin','account_deletion_not_pending','report_not_found','report_closed','report_assignee_invalid','report_action_invalid','report_author_unknown','settings_value_invalid'};
      for (final key in p41Errors) { if (message.contains(key)) return AppException('p41.errors.$key'); }
      const orderErrors = {'order_not_found', 'order_permission_denied', 'order_listing_not_purchasable', 'order_own_listing', 'order_seller_not_onboarded', 'order_delivery_invalid', 'order_address_required', 'order_open_exists', 'order_amount_too_small', 'order_currency_unsupported', 'order_transition_invalid', 'order_tracking_required', 'order_cancel_window', 'order_refund_window', 'order_reason_required', 'order_event_not_payable', 'order_participant_required', 'order_already_paid', 'order_not_paid', 'settings_permission_denied', 'settings_key_invalid', 'settings_value_invalid', 'stripe_error', 'stripe_not_configured'};
      for (final key in orderErrors) { if (message.contains(key)) return AppException(const {'order_cancel_window', 'order_refund_window', 'order_reason_required', 'order_event_not_payable', 'order_participant_required', 'order_already_paid', 'order_not_paid', 'settings_permission_denied', 'settings_key_invalid', 'settings_value_invalid'}.contains(key) ? 'p34b.errors.$key' : 'payments.errors.$key'); }
      const marketplaceErrors = {
        'listing_not_found': 'marketplace.errors.not_found', 'listing_own': 'marketplace.errors.own',
        'listing_badge_required': 'marketplace.errors.badge_required', 'listing_category_disabled': 'marketplace.errors.category_disabled',
        'listing_transition_invalid': 'marketplace.errors.unavailable', 'listing_contact_required': 'marketplace.errors.contact_required',
        'review_rating_invalid': 'marketplace.errors.rating_invalid', 'review_comment_too_long': 'marketplace.errors.comment_too_long',
        'review_reply_too_long': 'marketplace.errors.reply_too_long', 'review_edit_window': 'marketplace.errors.edit_window',
        'message_not_allowed': 'marketplace.errors.message_not_allowed', 'listing_permission_denied': 'marketplace.errors.permission_denied',
        'listing_title_invalid': 'marketplace.write_errors.title_invalid', 'listing_description_too_long': 'marketplace.write_errors.description_too_long',
        'listing_price_invalid': 'marketplace.write_errors.price_invalid', 'listing_currency_invalid': 'marketplace.write_errors.currency_invalid',
        'listing_category_invalid': 'marketplace.write_errors.category_invalid', 'listing_restricted_seller': 'marketplace.write_errors.restricted_seller',
        'listing_gun_shop_page_required': 'marketplace.gun_shop_page_required', 'listing_firearm_type_invalid': 'marketplace.firearm_type_invalid',
        'listing_firearm_attributes_required': 'marketplace.firearms.attributes_required',
        'listing_condition_invalid': 'marketplace.write_errors.condition_invalid', 'listing_region_invalid': 'marketplace.write_errors.region_invalid',
        'listing_place_invalid': 'marketplace.write_errors.place_invalid', 'listing_coordinates_invalid': 'marketplace.write_errors.coordinates_invalid',
        'listing_attributes_invalid': 'marketplace.write_errors.attributes_invalid', 'listing_status_invalid': 'marketplace.write_errors.status_invalid',
        'listing_limit_reached': 'marketplace.write_errors.limit_reached', 'listing_media_invalid': 'marketplace.write_errors.media_invalid',
      };
      for (final entry in marketplaceErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const policyErrors = {'policy_permission_denied': 'admin.countries.errors.permission_denied', 'policy_country_invalid': 'admin.countries.errors.country_invalid', 'policy_type_invalid': 'admin.countries.errors.type_invalid', 'policy_data_invalid': 'admin.countries.errors.data_invalid'};
      for (final entry in policyErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const verificationErrors = {
        'verification_type_invalid': 'verification.errors.type_invalid', 'verification_data_invalid': 'verification.errors.data_invalid',
        'verification_documents_invalid': 'verification.errors.documents_invalid', 'verification_already_pending': 'verification.errors.already_pending',
        'verification_already_approved': 'verification.errors.already_approved', 'verification_limit_reached': 'verification.errors.limit_reached',
        'verification_page_invalid': 'verification.errors.page_invalid', 'verification_not_found': 'verification.errors.not_found',
        'verification_not_pending': 'verification.errors.not_pending', 'verification_permission_denied': 'verification.errors.permission_denied',
        'verification_decision_invalid': 'admin.approvals.errors.decision_invalid', 'verification_reason_required': 'admin.approvals.errors.reason_required',
        'verification_expiry_invalid': 'admin.approvals.errors.expiry_invalid',
      };
      for (final entry in verificationErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      if (message.contains('post_sensitive_not_allowed')) return const AppException('sensitive.not_allowed');
      const groupErrors = {
        'group_name_invalid': 'groups.errors.name_invalid', 'group_description_too_long': 'groups.errors.description_too_long',
        'group_visibility_invalid': 'groups.errors.invalid_data', 'group_join_policy_invalid': 'groups.errors.invalid_data',
        'group_category_invalid': 'groups.errors.category_invalid', 'group_region_invalid': 'groups.errors.region_invalid',
        'group_not_found': 'groups.errors.not_found', 'group_banned': 'groups.errors.banned',
        'group_owner_cannot_leave': 'groups.errors.owner_cannot_leave', 'group_not_member': 'groups.errors.not_member',
        'group_permission_denied': 'group_studio.errors.permission_denied', 'group_member_not_found': 'group_studio.errors.member_not_found',
        'group_request_not_pending': 'group_studio.errors.request_not_pending', 'group_role_invalid': 'group_studio.errors.role_invalid',
        'group_member_not_active': 'group_studio.errors.member_not_active', 'group_status_invalid': 'group_studio.errors.status_invalid',
      };
      for (final entry in groupErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const pageErrors = {
        'page_name_invalid': 'pages.errors.name_invalid', 'page_description_too_long': 'pages.errors.description_too_long',
        'page_category_invalid': 'pages.errors.category_invalid', 'page_website_invalid': 'pages.errors.website_invalid',
        'page_email_invalid': 'pages.errors.email_invalid', 'page_phone_invalid': 'pages.errors.phone_invalid',
        'page_region_invalid': 'pages.errors.region_invalid', 'page_not_found': 'pages.errors.not_found',
        'page_not_manager': 'pages.errors.not_manager', 'post_context_invalid': 'pages.errors.post_context_invalid',
        'page_permission_denied': 'page_studio.errors.permission_denied', 'page_member_not_found': 'page_studio.errors.member_not_found',
        'page_member_exists': 'page_studio.errors.member_exists', 'page_role_invalid': 'page_studio.errors.role_invalid',
        'page_owner_protected': 'page_studio.errors.owner_protected', 'page_status_invalid': 'page_studio.errors.status_invalid',
        'user_not_found': 'page_studio.errors.user_not_found',
      };
      for (final entry in pageErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const forumErrors = {
        'forum_name_invalid': 'forums.errors.name_invalid', 'forum_description_too_long': 'forums.errors.description_too_long',
        'forum_visibility_invalid': 'forums.errors.invalid_data', 'forum_category_invalid': 'forums.errors.category_invalid',
        'forum_not_found': 'forums.errors.not_found', 'forum_banned': 'forums.errors.banned',
        'forum_not_member': 'forums.errors.not_member', 'forum_owner_cannot_leave': 'forums.errors.owner_cannot_leave',
        'thread_title_invalid': 'forums.errors.thread_title_invalid', 'thread_content_too_long': 'forums.errors.thread_content_too_long',
        'thread_not_found': 'forums.errors.thread_not_found', 'thread_locked': 'forums.errors.thread_locked',
        'reply_content_required': 'forums.errors.reply_required', 'reply_content_too_long': 'forums.errors.reply_too_long',
        'reply_parent_invalid': 'forums.errors.reply_parent_invalid', 'reply_depth_exceeded': 'forums.errors.reply_depth',
        'reply_not_found': 'forums.errors.reply_not_found', 'forum_permission_denied': 'forum_studio.errors.permission_denied',
        'forum_member_not_found': 'forum_studio.errors.member_not_found', 'forum_request_not_pending': 'forum_studio.errors.request_not_pending',
        'forum_role_invalid': 'forum_studio.errors.role_invalid', 'forum_member_not_active': 'forum_studio.errors.member_not_active',
        'forum_status_invalid': 'forum_studio.errors.status_invalid', 'thread_status_invalid': 'forum_studio.errors.thread_status_invalid',
        'attachments_invalid': 'forum_advanced.errors.attachments_invalid', 'attachments_too_many': 'forum_advanced.errors.attachments_too_many',
        'attachments_path_invalid': 'forum_advanced.errors.attachments_path_invalid', 'attachments_too_large': 'forum_advanced.errors.attachments_too_large',
        'thread_tags_too_many': 'forum_advanced.errors.thread_tags_too_many',
        'report_not_found': 'forum_studio.errors.report_not_found', 'report_action_invalid': 'forum_studio.errors.report_action_invalid',
      };
      for (final entry in forumErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const eventErrors = {
        'event_title_invalid': 'events.errors.title_invalid', 'event_description_too_long': 'events.errors.description_too_long',
        'event_category_invalid': 'events.errors.category_invalid', 'event_dates_invalid': 'events.errors.dates_invalid',
        'event_starts_in_past': 'events.errors.starts_in_past', 'event_capacity_invalid': 'events.errors.capacity_invalid',
        'event_capacity_below_attendees': 'events.errors.capacity_below_attendees', 'event_price_invalid': 'events.errors.price_invalid',
        'event_currency_invalid': 'events.errors.currency_invalid', 'event_organizer_invalid': 'events.errors.organizer_invalid',
        'event_region_invalid': 'events.errors.region_invalid', 'event_permission_denied': 'events.errors.permission_denied',
        'event_not_found': 'events.errors.not_found', 'event_not_open': 'events.errors.not_open',
        'rsvp_status_invalid': 'events.errors.rsvp_invalid', 'rsvp_checked_in': 'events.errors.already_checked_in',
        'participant_not_found': 'event_manage.errors.participant_not_found', 'ticket_not_found': 'event_manage.errors.ticket_not_found',
        'ticket_not_going': 'event_manage.errors.ticket_not_going', 'ticket_unpaid': 'event_manage.errors.ticket_unpaid',
        'ticket_already_used': 'event_manage.errors.ticket_already_used', 'event_status_invalid': 'event_manage.errors.status_invalid',
      };
      for (final entry in eventErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const outingErrors = {
        'outing_dates_invalid': 'diary.errors.dates_invalid', 'outing_title_too_long': 'diary.errors.title_too_long',
        'outing_notes_too_long': 'diary.errors.notes_too_long', 'outing_method_invalid': 'diary.errors.method_invalid',
        'outing_visibility_invalid': 'diary.errors.visibility_invalid', 'outing_species_invalid': 'diary.errors.species_invalid',
        'outing_dog_invalid': 'diary.errors.dog_invalid', 'outing_media_path_invalid': 'diary.errors.media_path_invalid',
        'outing_media_too_many': 'diary.errors.media_too_many', 'outing_not_found': 'diary.errors.not_found',
        'outing_permission_denied': 'diary.errors.permission_denied',
      };
      for (final entry in outingErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const dogErrors = {
        'dog_name_invalid': 'dogs.errors.name_invalid', 'dog_sex_invalid': 'dogs.errors.sex_invalid',
        'dog_birth_invalid': 'dogs.errors.birth_invalid', 'dog_breed_invalid': 'dogs.errors.breed_invalid',
        'dog_visibility_invalid': 'dogs.errors.visibility_invalid', 'dog_status_invalid': 'dogs.errors.status_invalid',
        'dog_microchip_taken': 'dogs.errors.microchip_taken', 'dog_breeder_invalid': 'dogs.errors.breeder_invalid',
        'dog_limit_reached': 'dogs.errors.limit_reached', 'dog_in_use': 'dogs.errors.in_use',
        'dog_not_found': 'dogs.errors.not_found', 'dog_permission_denied': 'dogs.errors.permission_denied',
        'trial_kind_invalid': 'errors.invalid_data', 'trial_title_invalid': 'dogs.errors.name_invalid',
        'trial_date_invalid': 'dogs.errors.birth_invalid', 'health_kind_invalid': 'errors.invalid_data',
        'health_title_invalid': 'dogs.errors.name_invalid', 'health_date_invalid': 'dogs.errors.birth_invalid',
        'dog_doc_path_invalid': 'errors.file_type_not_allowed', 'dog_trial_not_found': 'dogs.errors.not_found',
        'dog_health_not_found': 'dogs.errors.not_found',
      };
      for (final entry in dogErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const sightingErrors = {
        'sighting_species_invalid': 'sightings.errors.species_invalid', 'sighting_kind_invalid': 'sightings.errors.kind_invalid',
        'sighting_date_invalid': 'sightings.errors.date_invalid', 'sighting_count_invalid': 'sightings.errors.count_invalid',
        'sighting_coordinates_invalid': 'sightings.errors.coordinates_invalid', 'sighting_place_required': 'sightings.errors.place_required',
        'sighting_visibility_invalid': 'sightings.errors.visibility_invalid', 'sighting_notes_too_long': 'sightings.errors.notes_too_long',
        'sighting_media_path_invalid': 'sightings.errors.media_invalid', 'sighting_log_invalid': 'sightings.errors.log_invalid',
        'sighting_limit_reached': 'sightings.errors.limit_reached', 'sighting_not_found': 'sightings.errors.not_found',
        'sighting_permission_denied': 'sightings.errors.permission_denied',
      };
      for (final entry in sightingErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const alertErrors = {
        'alert_name_invalid': 'sighting_alerts.errors.name_invalid', 'alert_species_invalid': 'sighting_alerts.errors.species_invalid',
        'alert_kinds_invalid': 'sighting_alerts.errors.kinds_invalid', 'alert_radius_invalid': 'sighting_alerts.errors.radius_invalid',
        'alert_place_required': 'sighting_alerts.errors.place_required', 'alert_min_animals_invalid': 'sighting_alerts.errors.min_animals_invalid',
        'alert_cooldown_invalid': 'sighting_alerts.errors.cooldown_invalid', 'alert_limit_reached': 'sighting_alerts.errors.limit_reached',
        'alert_not_found': 'sighting_alerts.errors.not_found', 'alert_permission_denied': 'sighting_alerts.errors.permission_denied',
      };
      for (final entry in alertErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const mapErrors = {
        'map_name_invalid': 'map.errors.name_invalid', 'map_notes_too_long': 'map.errors.notes_too_long',
        'map_kind_invalid': 'map.errors.kind_invalid', 'map_visibility_invalid': 'map.errors.visibility_invalid',
        'map_coordinates_invalid': 'map.errors.coordinates_invalid', 'map_limit_reached': 'map.errors.limit_reached',
        'map_not_found': 'map.errors.not_found', 'map_permission_denied': 'map.errors.permission_denied',
        'map_polygon_invalid': 'map.errors.polygon_invalid', 'map_zone_too_large': 'map.errors.zone_too_large',
      };
      for (final entry in mapErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const safetyErrors = {
        'block_self': 'safety.errors.block_self', 'mute_self': 'safety.errors.mute_self', 'user_not_found': 'safety.errors.user_not_found',
        'post_not_found': 'safety.errors.post_not_found', 'report_own_content': 'safety.errors.report_own_content',
        'report_target_not_found': 'safety.errors.report_target_not_found', 'report_details_too_long': 'safety.errors.report_details_too_long',
        'report_target_type_invalid': 'safety.errors.generic', 'report_reason_invalid': 'safety.errors.generic',
      };
      for (final entry in safetyErrors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
      const friendErrors = {'friend_self', 'friend_user_not_found', 'friend_blocked', 'friend_already', 'friend_request_exists', 'friend_request_not_found', 'friend_request_not_pending', 'not_authenticated'};
      for (final key in friendErrors) {
        if (message.contains(key)) return AppException(key == 'not_authenticated' ? 'errors.login_required' : 'friendship.error');
      }
      const postErrors = {'post_kind_invalid', 'post_visibility_invalid', 'post_content_required', 'post_content_too_long', 'post_media_required', 'post_media_too_many', 'post_media_kind_invalid', 'post_media_path_invalid', 'poll_required', 'poll_options_invalid', 'poll_question_too_long', 'poll_ends_at_invalid', 'checkin_location_required', 'not_authenticated'};
      for (final key in postErrors) {
        if (message.contains(key)) return AppException('errors.$key');
      }
      if (message.contains('age_below_minimum')) return AppException('errors.age_below_minimum', namedArgs: {'n': error.hint ?? '18'});
      if (message.contains('birth_date_invalid')) return const AppException('errors.birth_date_invalid');
      switch (error.code) {
        case '23505':
          return AppException(error.message.toLowerCase().contains('username') ? 'auth.errors.username_in_use' : 'auth.errors.already_exists');
        case '42501':
        case 'PGRST301':
          return const AppException('errors.not_authorized');
        case 'PGRST116':
          return const AppException('errors.not_found');
        case '23514':
        case '23503':
          return const AppException('errors.invalid_data');
      }
    }
    final message = error.toString().toLowerCase();
    if (message.contains('socket') || message.contains('network') || message.contains('connection')) return const AppException('errors.network');
    return const AppException('auth.errors.generic');
  }
}