-- ============================================================================
-- HB Social 2.0 — Row Level Security (P03 / part a2)
-- Helper functions (SECURITY DEFINER, defined BEFORE any policy), RLS enablement,
-- policies for every table. Idempotent: drop policy if exists + create policy.
-- Principles:
--   * public content is readable by everyone (anon included): the web is public;
--   * every write requires an authenticated user and ownership or a role;
--   * no policy ever queries its own table directly: membership checks go through helpers;
--   * admin access via admin_users + admin_roles, checked with has_admin_role().
-- ============================================================================

-- ============================================================================
-- 1. HELPERS
-- ============================================================================

create or replace function is_admin(uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select uid is not null and exists (select 1 from admin_users where user_id = uid)
$$;

create or replace function has_admin_role(uid uuid, roles text[])
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select uid is not null and exists (
    select 1 from admin_users au join admin_roles ar on ar.id = au.role_id
    where au.user_id = uid and ar.name = any(roles)
  )
$$;

create or replace function is_following(follower uuid, followed uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select follower is not null and exists (
    select 1 from follows where follower_id = follower and following_id = followed
  )
$$;

create or replace function is_group_member(gid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select gid is not null and uid is not null and exists (
    select 1 from group_members where group_id = gid and user_id = uid and status = 'active'
  )
$$;

create or replace function is_group_manager(gid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select gid is not null and uid is not null and exists (
    select 1 from group_members
    where group_id = gid and user_id = uid and status = 'active' and role in ('owner','admin','moderator')
  )
$$;

create or replace function group_visibility(gid uuid)
returns text language sql security definer stable set search_path = public, extensions as $$
  select visibility from groups where id = gid
$$;

create or replace function group_join_policy(gid uuid)
returns text language sql security definer stable set search_path = public, extensions as $$
  select join_policy from groups where id = gid
$$;

create or replace function can_view_group(gid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select gid is not null and exists (
    select 1 from groups g
    where g.id = gid and g.status = 'active'
      and (g.visibility in ('public','private') or is_group_member(gid, uid) or is_admin(uid))
  )
$$;

create or replace function can_view_group_content(gid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select gid is not null and exists (
    select 1 from groups g
    where g.id = gid and g.status = 'active'
      and (g.visibility = 'public' or is_group_member(gid, uid) or is_admin(uid))
  )
$$;

create or replace function is_page_owner(pid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select pid is not null and uid is not null and exists (
    select 1 from pages where id = pid and owner_id = uid
  )
$$;

create or replace function is_page_manager(pid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select pid is not null and uid is not null and (
    exists (select 1 from pages where id = pid and owner_id = uid)
    or exists (select 1 from page_roles where page_id = pid and user_id = uid)
  )
$$;

create or replace function is_forum_member(fid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select fid is not null and uid is not null and exists (
    select 1 from forum_members where forum_id = fid and user_id = uid and status = 'active'
  )
$$;

create or replace function is_forum_manager(fid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select fid is not null and uid is not null and exists (
    select 1 from forum_members
    where forum_id = fid and user_id = uid and status = 'active' and role in ('owner','moderator')
  )
$$;

create or replace function forum_visibility(fid uuid)
returns text language sql security definer stable set search_path = public, extensions as $$
  select visibility from forums where id = fid
$$;

create or replace function can_view_forum(fid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select fid is not null and exists (
    select 1 from forums f
    where f.id = fid and f.status = 'active'
      and (f.visibility = 'public' or is_forum_member(fid, uid) or is_admin(uid))
  )
$$;

create or replace function thread_forum_id(tid uuid)
returns uuid language sql security definer stable set search_path = public, extensions as $$
  select forum_id from forum_threads where id = tid
$$;

create or replace function thread_is_open(tid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select exists (select 1 from forum_threads where id = tid and status = 'published' and not is_locked)
$$;

create or replace function is_conversation_participant(cid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select cid is not null and uid is not null and exists (
    select 1 from conversation_participants where conversation_id = cid and user_id = uid
  )
$$;

create or replace function is_conversation_owner(cid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select cid is not null and uid is not null and exists (
    select 1 from conversation_participants where conversation_id = cid and user_id = uid and role = 'owner'
  )
$$;

create or replace function is_event_organizer(eid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select eid is not null and uid is not null and exists (
    select 1 from events e
    where e.id = eid and (
      e.created_by = uid
      or e.organizer_user_id = uid
      or is_page_manager(e.organizer_page_id, uid)
      or is_group_manager(e.organizer_group_id, uid)
    )
  )
$$;

create or replace function is_post_author(pid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select pid is not null and uid is not null and exists (
    select 1 from posts where id = pid and author_id = uid
  )
$$;

-- Full visibility rule for a post, reused by posts, post_media, reactions, comments, post_hashtags
create or replace function can_view_post(pid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select exists (
    select 1 from posts p
    where p.id = pid and (
      is_admin(uid)
      or p.author_id = uid
      or (
        p.status = 'published'
        and not is_blocked(p.author_id, uid)
        and (p.group_id is null or can_view_group_content(p.group_id, uid))
        and (
          p.visibility = 'public'
          or (p.visibility = 'followers' and is_following(uid, p.author_id))
          or (p.visibility = 'group' and is_group_member(p.group_id, uid))
        )
      )
    )
  )
$$;

create or replace function is_listing_seller(lid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select lid is not null and uid is not null and exists (
    select 1 from listings where id = lid and seller_id = uid
  )
$$;

create or replace function can_view_listing(lid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select exists (
    select 1 from listings l
    where l.id = lid and (l.status in ('active','reserved','sold') or l.seller_id = uid or is_admin(uid))
  )
$$;

create or replace function is_log_owner(lid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select lid is not null and uid is not null and exists (
    select 1 from hunting_logs where id = lid and user_id = uid
  )
$$;

create or replace function can_view_log(lid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public, extensions as $$
  select exists (
    select 1 from hunting_logs h
    where h.id = lid and (
      h.user_id = uid or is_admin(uid)
      or h.visibility = 'public'
      or (h.visibility = 'followers' and is_following(uid, h.user_id))
    )
  )
$$;

-- Users cannot promote themselves: protected columns are restored unless an admin edits
create or replace function trg_user_profiles_protect()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  -- counter triggers set hb.internal while they touch user_profiles
  if coalesce(current_setting('hb.internal', true), '') = 'on' then
    return new;
  end if;
  if not is_admin(auth.uid()) then
    new.status := old.status;
    new.verification_level := old.verification_level;
    new.follower_count := old.follower_count;
    new.following_count := old.following_count;
    new.post_count := old.post_count;
    new.outing_count := old.outing_count;
  end if;
  return new;
end $$;

drop trigger if exists user_profiles_protect on user_profiles;
create trigger user_profiles_protect before update on user_profiles
  for each row execute function trg_user_profiles_protect();

-- ============================================================================
-- 2. ENABLE RLS ON EVERY TABLE
-- ============================================================================

do $$
declare t text;
begin
  for t in
    select tablename from pg_tables where schemaname = 'public'
  loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

-- ============================================================================
-- 3. REFERENCE TABLES — public read, admin write
-- ============================================================================

drop policy if exists currencies_select on currencies;
create policy currencies_select on currencies for select using (true);
drop policy if exists currencies_write on currencies;
create policy currencies_write on currencies for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin']));

drop policy if exists countries_select on countries;
create policy countries_select on countries for select using (true);
drop policy if exists countries_write on countries;
create policy countries_write on countries for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin']));

drop policy if exists regions_select on regions;
create policy regions_select on regions for select using (true);
drop policy if exists regions_write on regions;
create policy regions_write on regions for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']));

drop policy if exists hunting_units_select on hunting_units;
create policy hunting_units_select on hunting_units for select using (true);
drop policy if exists hunting_units_write on hunting_units;
create policy hunting_units_write on hunting_units for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']));

drop policy if exists species_select on species;
create policy species_select on species for select using (true);
drop policy if exists species_write on species;
create policy species_write on species for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']));

drop policy if exists species_names_select on species_names;
create policy species_names_select on species_names for select using (true);
drop policy if exists species_names_write on species_names;
create policy species_names_write on species_names for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']));

drop policy if exists categories_select on categories;
create policy categories_select on categories for select using (true);
drop policy if exists categories_write on categories;
create policy categories_write on categories for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin']));

drop policy if exists exchange_rates_select on exchange_rates;
create policy exchange_rates_select on exchange_rates for select using (true);
drop policy if exists exchange_rates_write on exchange_rates;
create policy exchange_rates_write on exchange_rates for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','finance']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','finance']));

drop policy if exists feature_flags_select on feature_flags;
create policy feature_flags_select on feature_flags for select using (true);
drop policy if exists feature_flags_write on feature_flags;
create policy feature_flags_write on feature_flags for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin']));

drop policy if exists country_policies_select on country_policies;
create policy country_policies_select on country_policies for select using (true);
drop policy if exists country_policies_write on country_policies;
create policy country_policies_write on country_policies for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin']));

-- hunting calendars: published ones are public, drafts only to editors
drop policy if exists hunting_calendars_select on hunting_calendars;
create policy hunting_calendars_select on hunting_calendars for select
  using (status = 'published' or has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']));
drop policy if exists hunting_calendars_write on hunting_calendars;
create policy hunting_calendars_write on hunting_calendars for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']));

drop policy if exists calendar_rules_select on calendar_rules;
create policy calendar_rules_select on calendar_rules for select
  using (
    exists (select 1 from hunting_calendars c where c.id = calendar_id and c.status = 'published')
    or has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor'])
  );
drop policy if exists calendar_rules_write on calendar_rules;
create policy calendar_rules_write on calendar_rules for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','hunting_data_editor']));

-- ============================================================================
-- 4. IDENTITY
-- ============================================================================

drop policy if exists user_profiles_select on user_profiles;
create policy user_profiles_select on user_profiles for select
  using (status = 'active' or id = auth.uid() or is_admin(auth.uid()));
-- no insert policy: profiles are created by handle_new_user() (security definer)
drop policy if exists user_profiles_update_own on user_profiles;
create policy user_profiles_update_own on user_profiles for update to authenticated
  using (id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']))
  with check (id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));
-- no delete policy: account deletion goes through auth.users (cascade) via the GDPR flow (P41)

drop policy if exists user_settings_own on user_settings;
create policy user_settings_own on user_settings for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists user_interests_select on user_interests;
create policy user_interests_select on user_interests for select
  using (user_id = auth.uid() or is_admin(auth.uid()));
drop policy if exists user_interests_write on user_interests;
create policy user_interests_write on user_interests for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists follows_select on follows;
create policy follows_select on follows for select using (true);
drop policy if exists follows_insert on follows;
create policy follows_insert on follows for insert to authenticated
  with check (follower_id = auth.uid() and not is_blocked(follower_id, following_id));
drop policy if exists follows_delete on follows;
create policy follows_delete on follows for delete to authenticated
  using (follower_id = auth.uid() or following_id = auth.uid());

drop policy if exists blocks_own on blocks;
create policy blocks_own on blocks for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

drop policy if exists notifications_select on notifications;
create policy notifications_select on notifications for select to authenticated
  using (user_id = auth.uid());
-- no insert policy for clients: notifications are written by triggers / edge functions
drop policy if exists notifications_update on notifications;
create policy notifications_update on notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists notifications_delete on notifications;
create policy notifications_delete on notifications for delete to authenticated
  using (user_id = auth.uid());

drop policy if exists push_tokens_own on push_tokens;
create policy push_tokens_own on push_tokens for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists verification_requests_select on verification_requests;
create policy verification_requests_select on verification_requests for select to authenticated
  using (user_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));
drop policy if exists verification_requests_insert on verification_requests;
create policy verification_requests_insert on verification_requests for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending' and reviewed_by is null);
drop policy if exists verification_requests_update on verification_requests;
create policy verification_requests_update on verification_requests for update to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','moderator']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','moderator']));
drop policy if exists verification_requests_delete on verification_requests;
create policy verification_requests_delete on verification_requests for delete to authenticated
  using ((user_id = auth.uid() and status = 'pending') or has_admin_role(auth.uid(), array['superadmin','admin']));

-- ============================================================================
-- 5. COMMUNITY
-- ============================================================================

drop policy if exists groups_select on groups;
create policy groups_select on groups for select
  using (can_view_group(id, auth.uid()) or owner_id = auth.uid());
drop policy if exists groups_insert on groups;
create policy groups_insert on groups for insert to authenticated
  with check (owner_id = auth.uid() and status = 'active');
drop policy if exists groups_update on groups;
create policy groups_update on groups for update to authenticated
  using (is_group_manager(id, auth.uid()) or is_admin(auth.uid()))
  with check (is_group_manager(id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists groups_delete on groups;
create policy groups_delete on groups for delete to authenticated
  using (owner_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));

drop policy if exists group_members_select on group_members;
create policy group_members_select on group_members for select
  using (
    user_id = auth.uid()
    or is_group_member(group_id, auth.uid())
    or group_visibility(group_id) = 'public'
    or is_admin(auth.uid())
  );
drop policy if exists group_members_insert on group_members;
create policy group_members_insert on group_members for insert to authenticated
  with check (
    is_group_manager(group_id, auth.uid())
    or (
      user_id = auth.uid() and role = 'member'
      and group_visibility(group_id) in ('public','private')
      and (
        (status = 'active' and group_join_policy(group_id) = 'open')
        or (status = 'pending' and group_join_policy(group_id) = 'approval')
      )
    )
  );
drop policy if exists group_members_update on group_members;
create policy group_members_update on group_members for update to authenticated
  using (is_group_manager(group_id, auth.uid()) or is_admin(auth.uid()))
  with check (is_group_manager(group_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists group_members_delete on group_members;
create policy group_members_delete on group_members for delete to authenticated
  using (user_id = auth.uid() or is_group_manager(group_id, auth.uid()) or is_admin(auth.uid()));

drop policy if exists pages_select on pages;
create policy pages_select on pages for select
  using (status = 'active' or is_page_manager(id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists pages_insert on pages;
create policy pages_insert on pages for insert to authenticated
  with check (owner_id = auth.uid() and verification_status in ('none','pending'));
drop policy if exists pages_update on pages;
create policy pages_update on pages for update to authenticated
  using (is_page_manager(id, auth.uid()) or is_admin(auth.uid()))
  with check (is_page_manager(id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists pages_delete on pages;
create policy pages_delete on pages for delete to authenticated
  using (owner_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));

drop policy if exists page_roles_select on page_roles;
create policy page_roles_select on page_roles for select
  using (user_id = auth.uid() or is_page_manager(page_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists page_roles_write on page_roles;
create policy page_roles_write on page_roles for all to authenticated
  using (is_page_owner(page_id, auth.uid()) or is_admin(auth.uid()))
  with check (is_page_owner(page_id, auth.uid()) or is_admin(auth.uid()));

drop policy if exists page_followers_select on page_followers;
create policy page_followers_select on page_followers for select using (true);
drop policy if exists page_followers_insert on page_followers;
create policy page_followers_insert on page_followers for insert to authenticated
  with check (user_id = auth.uid());
drop policy if exists page_followers_delete on page_followers;
create policy page_followers_delete on page_followers for delete to authenticated
  using (user_id = auth.uid() or is_page_manager(page_id, auth.uid()));

drop policy if exists forums_select on forums;
create policy forums_select on forums for select
  using (can_view_forum(id, auth.uid()) or owner_id = auth.uid() or (visibility = 'private' and status = 'active'));
drop policy if exists forums_insert on forums;
create policy forums_insert on forums for insert to authenticated
  with check (owner_id = auth.uid() and status = 'active');
drop policy if exists forums_update on forums;
create policy forums_update on forums for update to authenticated
  using (is_forum_manager(id, auth.uid()) or is_admin(auth.uid()))
  with check (is_forum_manager(id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists forums_delete on forums;
create policy forums_delete on forums for delete to authenticated
  using (owner_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));

drop policy if exists forum_members_select on forum_members;
create policy forum_members_select on forum_members for select
  using (user_id = auth.uid() or is_forum_member(forum_id, auth.uid()) or forum_visibility(forum_id) = 'public' or is_admin(auth.uid()));
drop policy if exists forum_members_insert on forum_members;
create policy forum_members_insert on forum_members for insert to authenticated
  with check (
    is_forum_manager(forum_id, auth.uid())
    or (
      user_id = auth.uid() and role = 'member'
      and (
        (status = 'active' and forum_visibility(forum_id) = 'public')
        or (status = 'pending' and forum_visibility(forum_id) = 'private')
      )
    )
  );
drop policy if exists forum_members_update on forum_members;
create policy forum_members_update on forum_members for update to authenticated
  using (is_forum_manager(forum_id, auth.uid()) or is_admin(auth.uid()))
  with check (is_forum_manager(forum_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists forum_members_delete on forum_members;
create policy forum_members_delete on forum_members for delete to authenticated
  using (user_id = auth.uid() or is_forum_manager(forum_id, auth.uid()) or is_admin(auth.uid()));

drop policy if exists forum_threads_select on forum_threads;
create policy forum_threads_select on forum_threads for select
  using (
    can_view_forum(forum_id, auth.uid())
    and (status = 'published' or author_id = auth.uid() or is_forum_manager(forum_id, auth.uid()) or is_admin(auth.uid()))
  );
drop policy if exists forum_threads_insert on forum_threads;
create policy forum_threads_insert on forum_threads for insert to authenticated
  with check (author_id = auth.uid() and status = 'published' and not is_pinned and not is_locked and is_forum_member(forum_id, auth.uid()));
drop policy if exists forum_threads_update on forum_threads;
create policy forum_threads_update on forum_threads for update to authenticated
  using (author_id = auth.uid() or is_forum_manager(forum_id, auth.uid()) or is_admin(auth.uid()))
  with check (author_id = auth.uid() or is_forum_manager(forum_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists forum_threads_delete on forum_threads;
create policy forum_threads_delete on forum_threads for delete to authenticated
  using (author_id = auth.uid() or is_forum_manager(forum_id, auth.uid()) or is_admin(auth.uid()));

drop policy if exists forum_replies_select on forum_replies;
create policy forum_replies_select on forum_replies for select
  using (
    can_view_forum(thread_forum_id(thread_id), auth.uid())
    and (status = 'published' or author_id = auth.uid() or is_forum_manager(thread_forum_id(thread_id), auth.uid()) or is_admin(auth.uid()))
  );
drop policy if exists forum_replies_insert on forum_replies;
create policy forum_replies_insert on forum_replies for insert to authenticated
  with check (
    author_id = auth.uid() and status = 'published'
    and thread_is_open(thread_id)
    and is_forum_member(thread_forum_id(thread_id), auth.uid())
  );
drop policy if exists forum_replies_update on forum_replies;
create policy forum_replies_update on forum_replies for update to authenticated
  using (author_id = auth.uid() or is_forum_manager(thread_forum_id(thread_id), auth.uid()) or is_admin(auth.uid()))
  with check (author_id = auth.uid() or is_forum_manager(thread_forum_id(thread_id), auth.uid()) or is_admin(auth.uid()));
drop policy if exists forum_replies_delete on forum_replies;
create policy forum_replies_delete on forum_replies for delete to authenticated
  using (author_id = auth.uid() or is_forum_manager(thread_forum_id(thread_id), auth.uid()) or is_admin(auth.uid()));

drop policy if exists events_select on events;
create policy events_select on events for select
  using (status = 'published' or is_event_organizer(id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists events_insert on events;
create policy events_insert on events for insert to authenticated
  with check (
    created_by = auth.uid()
    and (
      organizer_user_id = auth.uid()
      or is_page_manager(organizer_page_id, auth.uid())
      or is_group_manager(organizer_group_id, auth.uid())
    )
  );
drop policy if exists events_update on events;
create policy events_update on events for update to authenticated
  using (is_event_organizer(id, auth.uid()) or is_admin(auth.uid()))
  with check (is_event_organizer(id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists events_delete on events;
create policy events_delete on events for delete to authenticated
  using (created_by = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));

drop policy if exists event_participants_select on event_participants;
create policy event_participants_select on event_participants for select to authenticated
  using (user_id = auth.uid() or is_event_organizer(event_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists event_participants_insert on event_participants;
create policy event_participants_insert on event_participants for insert to authenticated
  with check (user_id = auth.uid() and status in ('going','interested','waitlist') and ticket_code is null and checked_in_at is null);
drop policy if exists event_participants_update on event_participants;
create policy event_participants_update on event_participants for update to authenticated
  using (user_id = auth.uid() or is_event_organizer(event_id, auth.uid()) or is_admin(auth.uid()))
  with check (user_id = auth.uid() or is_event_organizer(event_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists event_participants_delete on event_participants;
create policy event_participants_delete on event_participants for delete to authenticated
  using (user_id = auth.uid() or is_event_organizer(event_id, auth.uid()) or is_admin(auth.uid()));

-- ============================================================================
-- 6. CONTENT
-- ============================================================================

drop policy if exists posts_select on posts;
create policy posts_select on posts for select using (can_view_post(id, auth.uid()));
drop policy if exists posts_insert on posts;
create policy posts_insert on posts for insert to authenticated
  with check (
    author_id = auth.uid() and status = 'published'
    and (group_id is null or is_group_member(group_id, auth.uid()))
    and (page_id is null or is_page_manager(page_id, auth.uid()))
  );
drop policy if exists posts_update on posts;
create policy posts_update on posts for update to authenticated
  using (author_id = auth.uid() or is_group_manager(group_id, auth.uid()) or is_page_manager(page_id, auth.uid()) or is_admin(auth.uid()))
  with check (author_id = auth.uid() or is_group_manager(group_id, auth.uid()) or is_page_manager(page_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists posts_delete on posts;
create policy posts_delete on posts for delete to authenticated
  using (author_id = auth.uid() or is_group_manager(group_id, auth.uid()) or is_page_manager(page_id, auth.uid()) or is_admin(auth.uid()));

drop policy if exists post_media_select on post_media;
create policy post_media_select on post_media for select using (can_view_post(post_id, auth.uid()));
drop policy if exists post_media_write on post_media;
create policy post_media_write on post_media for all to authenticated
  using (is_post_author(post_id, auth.uid()) or is_admin(auth.uid()))
  with check (is_post_author(post_id, auth.uid()));

drop policy if exists reactions_select on reactions;
create policy reactions_select on reactions for select using (can_view_post(post_id, auth.uid()));
drop policy if exists reactions_insert on reactions;
create policy reactions_insert on reactions for insert to authenticated
  with check (user_id = auth.uid() and can_view_post(post_id, auth.uid()));
drop policy if exists reactions_update on reactions;
create policy reactions_update on reactions for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists reactions_delete on reactions;
create policy reactions_delete on reactions for delete to authenticated
  using (user_id = auth.uid());

drop policy if exists comments_select on comments;
create policy comments_select on comments for select
  using (can_view_post(post_id, auth.uid()) and (status = 'published' or author_id = auth.uid() or is_admin(auth.uid())));
drop policy if exists comments_insert on comments;
create policy comments_insert on comments for insert to authenticated
  with check (author_id = auth.uid() and status = 'published' and can_view_post(post_id, auth.uid()));
drop policy if exists comments_update on comments;
create policy comments_update on comments for update to authenticated
  using (author_id = auth.uid() or is_post_author(post_id, auth.uid()) or is_admin(auth.uid()))
  with check (author_id = auth.uid() or is_post_author(post_id, auth.uid()) or is_admin(auth.uid()));
drop policy if exists comments_delete on comments;
create policy comments_delete on comments for delete to authenticated
  using (author_id = auth.uid() or is_post_author(post_id, auth.uid()) or is_admin(auth.uid()));

drop policy if exists stories_select on stories;
create policy stories_select on stories for select
  using (
    author_id = auth.uid() or is_admin(auth.uid())
    or (status = 'active' and expires_at > now() and not is_blocked(author_id, auth.uid()))
  );
drop policy if exists stories_insert on stories;
create policy stories_insert on stories for insert to authenticated
  with check (author_id = auth.uid() and status = 'active');
drop policy if exists stories_update on stories;
create policy stories_update on stories for update to authenticated
  using (author_id = auth.uid() or is_admin(auth.uid()))
  with check (author_id = auth.uid() or is_admin(auth.uid()));
drop policy if exists stories_delete on stories;
create policy stories_delete on stories for delete to authenticated
  using (author_id = auth.uid() or is_admin(auth.uid()));

drop policy if exists hashtags_select on hashtags;
create policy hashtags_select on hashtags for select using (true);
drop policy if exists hashtags_insert on hashtags;
create policy hashtags_insert on hashtags for insert to authenticated with check (true);

drop policy if exists post_hashtags_select on post_hashtags;
create policy post_hashtags_select on post_hashtags for select using (can_view_post(post_id, auth.uid()));
drop policy if exists post_hashtags_write on post_hashtags;
create policy post_hashtags_write on post_hashtags for all to authenticated
  using (is_post_author(post_id, auth.uid()) or is_admin(auth.uid()))
  with check (is_post_author(post_id, auth.uid()));

-- ============================================================================
-- 7. CHAT — participants only, always
-- ============================================================================

drop policy if exists conversations_select on conversations;
create policy conversations_select on conversations for select to authenticated
  using (is_conversation_participant(id, auth.uid()));
drop policy if exists conversations_insert on conversations;
create policy conversations_insert on conversations for insert to authenticated
  with check (created_by = auth.uid());
drop policy if exists conversations_update on conversations;
create policy conversations_update on conversations for update to authenticated
  using (is_conversation_owner(id, auth.uid()))
  with check (is_conversation_owner(id, auth.uid()));

drop policy if exists conversation_participants_select on conversation_participants;
create policy conversation_participants_select on conversation_participants for select to authenticated
  using (is_conversation_participant(conversation_id, auth.uid()));
drop policy if exists conversation_participants_insert on conversation_participants;
create policy conversation_participants_insert on conversation_participants for insert to authenticated
  with check (
    is_conversation_owner(conversation_id, auth.uid())
    and role = 'member'
    and not is_blocked(auth.uid(), user_id)
  );
drop policy if exists conversation_participants_update on conversation_participants;
create policy conversation_participants_update on conversation_participants for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists conversation_participants_delete on conversation_participants;
create policy conversation_participants_delete on conversation_participants for delete to authenticated
  using (user_id = auth.uid() or is_conversation_owner(conversation_id, auth.uid()));

drop policy if exists messages_select on messages;
create policy messages_select on messages for select to authenticated
  using (is_conversation_participant(conversation_id, auth.uid()));
drop policy if exists messages_insert on messages;
create policy messages_insert on messages for insert to authenticated
  with check (
    sender_id = auth.uid() and status = 'sent' and kind <> 'system'
    and is_conversation_participant(conversation_id, auth.uid())
  );
drop policy if exists messages_update on messages;
create policy messages_update on messages for update to authenticated
  using (sender_id = auth.uid()) with check (sender_id = auth.uid());
drop policy if exists messages_delete on messages;
create policy messages_delete on messages for delete to authenticated
  using (sender_id = auth.uid() or is_admin(auth.uid()));

-- ============================================================================
-- 8. COMMERCE
-- ============================================================================

drop policy if exists listings_select on listings;
create policy listings_select on listings for select using (can_view_listing(id, auth.uid()));
drop policy if exists listings_insert on listings;
create policy listings_insert on listings for insert to authenticated
  with check (seller_id = auth.uid() and status in ('draft','active'));
drop policy if exists listings_update on listings;
create policy listings_update on listings for update to authenticated
  using (seller_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']))
  with check (seller_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));
drop policy if exists listings_delete on listings;
create policy listings_delete on listings for delete to authenticated
  using (seller_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));

drop policy if exists listing_media_select on listing_media;
create policy listing_media_select on listing_media for select using (can_view_listing(listing_id, auth.uid()));
drop policy if exists listing_media_write on listing_media;
create policy listing_media_write on listing_media for all to authenticated
  using (is_listing_seller(listing_id, auth.uid()) or is_admin(auth.uid()))
  with check (is_listing_seller(listing_id, auth.uid()));

-- ============================================================================
-- 9. HUNTING — user data
-- ============================================================================

drop policy if exists hunting_logs_select on hunting_logs;
create policy hunting_logs_select on hunting_logs for select using (can_view_log(id, auth.uid()));
drop policy if exists hunting_logs_write on hunting_logs;
create policy hunting_logs_write on hunting_logs for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists hunting_log_species_select on hunting_log_species;
create policy hunting_log_species_select on hunting_log_species for select using (can_view_log(log_id, auth.uid()));
drop policy if exists hunting_log_species_write on hunting_log_species;
create policy hunting_log_species_write on hunting_log_species for all to authenticated
  using (is_log_owner(log_id, auth.uid())) with check (is_log_owner(log_id, auth.uid()));

drop policy if exists hunting_log_dogs_select on hunting_log_dogs;
create policy hunting_log_dogs_select on hunting_log_dogs for select using (can_view_log(log_id, auth.uid()));
drop policy if exists hunting_log_dogs_write on hunting_log_dogs;
create policy hunting_log_dogs_write on hunting_log_dogs for all to authenticated
  using (is_log_owner(log_id, auth.uid())) with check (is_log_owner(log_id, auth.uid()));

drop policy if exists dogs_select on dogs;
create policy dogs_select on dogs for select using (true);
drop policy if exists dogs_write on dogs;
create policy dogs_write on dogs for all to authenticated
  using (owner_id = auth.uid() or is_admin(auth.uid())) with check (owner_id = auth.uid());

-- ============================================================================
-- 10. MODERATION & ADMIN
-- ============================================================================

drop policy if exists reports_select on reports;
create policy reports_select on reports for select to authenticated
  using (reporter_id = auth.uid() or has_admin_role(auth.uid(), array['superadmin','admin','moderator']));
drop policy if exists reports_insert on reports;
create policy reports_insert on reports for insert to authenticated
  with check (reporter_id = auth.uid() and status = 'pending' and assigned_to is null and resolved_at is null);
drop policy if exists reports_update on reports;
create policy reports_update on reports for update to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin','moderator']))
  with check (has_admin_role(auth.uid(), array['superadmin','admin','moderator']));
drop policy if exists reports_delete on reports;
create policy reports_delete on reports for delete to authenticated
  using (has_admin_role(auth.uid(), array['superadmin']));

drop policy if exists admin_roles_select on admin_roles;
create policy admin_roles_select on admin_roles for select to authenticated using (is_admin(auth.uid()));
drop policy if exists admin_roles_write on admin_roles;
create policy admin_roles_write on admin_roles for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin'])) with check (has_admin_role(auth.uid(), array['superadmin']));

drop policy if exists admin_role_permissions_select on admin_role_permissions;
create policy admin_role_permissions_select on admin_role_permissions for select to authenticated using (is_admin(auth.uid()));
drop policy if exists admin_role_permissions_write on admin_role_permissions;
create policy admin_role_permissions_write on admin_role_permissions for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin'])) with check (has_admin_role(auth.uid(), array['superadmin']));

drop policy if exists admin_users_select on admin_users;
create policy admin_users_select on admin_users for select to authenticated using (is_admin(auth.uid()));
drop policy if exists admin_users_write on admin_users;
create policy admin_users_write on admin_users for all to authenticated
  using (has_admin_role(auth.uid(), array['superadmin'])) with check (has_admin_role(auth.uid(), array['superadmin']));

drop policy if exists admin_audit_log_select on admin_audit_log;
create policy admin_audit_log_select on admin_audit_log for select to authenticated
  using (has_admin_role(auth.uid(), array['superadmin','admin']));
drop policy if exists admin_audit_log_insert on admin_audit_log;
create policy admin_audit_log_insert on admin_audit_log for insert to authenticated
  with check (admin_id = auth.uid() and is_admin(auth.uid()));
