-- Behavioural RLS tests. Run as superuser against a DB with stub + all four files applied.
-- Everything happens in one transaction and is rolled back at the end.
\set ON_ERROR_STOP on
begin;

create or replace function t_as(uid uuid) returns void language plpgsql as $$
begin
  if uid is null then
    perform set_config('role', 'anon', true);
    perform set_config('request.jwt.claim.sub', '', true);
    perform set_config('request.jwt.claim.role', 'anon', true);
  else
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claim.sub', uid::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
  end if;
end $$;

create or replace function t_root() returns void language plpgsql as $$
begin
  perform set_config('role', 'none', true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claim.role', '', true);
end $$;

-- expect a statement to FAIL with an RLS / check / FK error
create or replace function t_expect_fail(sql text, label text) returns void language plpgsql as $$
begin
  begin
    execute sql;
  exception when insufficient_privilege or check_violation or foreign_key_violation or unique_violation or not_null_violation then
    raise notice 'OK (rejected as expected): %', label;
    return;
  end;
  raise exception 'FAILED: expected rejection but statement succeeded: %', label;
end $$;


-- expect a data-modifying statement to affect exactly N rows (RLS silently filters updates)
create or replace function t_expect_rows(sql text, expected int, label text) returns void language plpgsql as $$
declare n int;
begin
  execute sql;
  get diagnostics n = row_count;
  if n = expected then raise notice 'OK: % (% rows)', label, n; else raise exception 'FAILED: % (expected % rows, got %)', label, expected, n; end if;
end $$;

create or replace function t_check(cond boolean, label text) returns void language plpgsql as $$
begin
  if cond then raise notice 'OK: %', label; else raise exception 'FAILED: %', label; end if;
end $$;

-- ---------------------------------------------------------------------------
-- Fixtures: three users through auth.users (trigger builds profiles)
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'anna@example.com',  '{"username":"anna_h","display_name":"Anna","country_code":"IT","locale":"it"}'),
  ('22222222-2222-2222-2222-222222222222', 'bruno@example.com', '{"username":"bruno","country_code":"FR"}'),
  ('33333333-3333-3333-3333-333333333333', 'carla.admin@example.com', '{"country_code":"ZZ","locale":"xx"}');

select t_check((select count(*) from user_profiles) = 3, 'handle_new_user created 3 profiles');
select t_check((select username::text from user_profiles where id = '22222222-2222-2222-2222-222222222222') = 'bruno', 'username from metadata');
select t_check((select locale from user_profiles where id = '22222222-2222-2222-2222-222222222222') = 'fr', 'locale defaults from country FR');
select t_check((select country_code from user_profiles where id = '33333333-3333-3333-3333-333333333333') = 'IT', 'unknown country falls back to IT');
select t_check((select username::text from user_profiles where id = '33333333-3333-3333-3333-333333333333') = 'carla_admin', 'username derived from email');
select t_check((select count(*) from user_settings) = 3, 'user_settings created');

-- Carla becomes superadmin (root action, as the P40 bootstrap would do)
insert into admin_users (user_id, role_id) select '33333333-3333-3333-3333-333333333333', id from admin_roles where name = 'superadmin';

-- ---------------------------------------------------------------------------
-- Anna: groups and posts
-- ---------------------------------------------------------------------------
select t_as('11111111-1111-1111-1111-111111111111');
insert into groups (id, slug, name, owner_id, visibility, join_policy, country_code)
  values ('aaaa0001-0000-0000-0000-000000000001', 'beccacciai', 'Beccacciai', '11111111-1111-1111-1111-111111111111', 'public', 'open', 'IT');
insert into groups (id, slug, name, owner_id, visibility, join_policy, country_code)
  values ('aaaa0002-0000-0000-0000-000000000002', 'squadra-nord', 'Squadra Nord', '11111111-1111-1111-1111-111111111111', 'private', 'approval', 'IT');
select t_check((select member_count from groups where id = 'aaaa0001-0000-0000-0000-000000000001') = 1, 'owner auto-member, member_count = 1');

insert into posts (id, author_id, kind, content, visibility, country_code)
  values ('bbbb0001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'text', 'post pubblico', 'public', 'IT');
insert into posts (id, author_id, kind, content, visibility, country_code)
  values ('bbbb0002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'text', 'solo follower', 'followers', 'IT');
insert into posts (id, author_id, group_id, kind, content, visibility, country_code)
  values ('bbbb0003-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'aaaa0002-0000-0000-0000-000000000002', 'text', 'post del gruppo privato', 'group', 'IT');
select t_check((select post_count from user_profiles where id = '11111111-1111-1111-1111-111111111111') = 3, 'post_count trigger');

-- Anna cannot promote herself
update user_profiles set verification_level = 'hunter', status = 'active', bio = 'ciao' where id = '11111111-1111-1111-1111-111111111111';
select t_check((select verification_level from user_profiles where id = '11111111-1111-1111-1111-111111111111') = 'none', 'protect trigger keeps verification_level');
select t_check((select bio from user_profiles where id = '11111111-1111-1111-1111-111111111111') = 'ciao', 'but ordinary fields update');

-- Anna cannot write someone else's profile
select t_expect_rows($q$update user_profiles set bio = 'hacked' where id = '22222222-2222-2222-2222-222222222222'$q$, 0, 'cannot update another profile');

-- Anna cannot insert a report pretending to be Bruno
select t_expect_fail($q$insert into reports (reporter_id, target_type, target_id, reason) values ('22222222-2222-2222-2222-222222222222','post','bbbb0001-0000-0000-0000-000000000001','spam')$q$, 'report with foreign reporter_id');

-- ---------------------------------------------------------------------------
-- Bruno: visibility rules
-- ---------------------------------------------------------------------------
select t_as('22222222-2222-2222-2222-222222222222');
select t_check((select count(*) from posts) = 1, 'Bruno sees only the public post');
select t_check((select count(*) from groups) = 2, 'Bruno sees public and private groups (not content)');
select t_check((select count(*) from group_members where group_id = 'aaaa0002-0000-0000-0000-000000000002') = 0, 'private group member list hidden to non-members');

insert into follows (follower_id, following_id) values ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111');
select t_check((select count(*) from posts) = 2, 'after following, Bruno sees the followers-only post');
select t_check((select follower_count from user_profiles where id = '11111111-1111-1111-1111-111111111111') = 1, 'follower_count trigger');

-- joining: open group → active; approval group → must be pending
insert into group_members (group_id, user_id) values ('aaaa0001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222');
select t_expect_fail($q$insert into group_members (group_id, user_id, status) values ('aaaa0002-0000-0000-0000-000000000002','22222222-2222-2222-2222-222222222222','active')$q$, 'self-join approval group as active');
select t_expect_fail($q$insert into group_members (group_id, user_id, role) values ('aaaa0001-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','owner')$q$, 'self-join as owner');
insert into group_members (group_id, user_id, status) values ('aaaa0002-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'pending');
select t_check((select count(*) from posts) = 2, 'pending member still cannot see private group post');

-- Anna approves Bruno
select t_as('11111111-1111-1111-1111-111111111111');
update group_members set status = 'active' where group_id = 'aaaa0002-0000-0000-0000-000000000002' and user_id = '22222222-2222-2222-2222-222222222222';
select t_check((select member_count from groups where id = 'aaaa0002-0000-0000-0000-000000000002') = 2, 'member_count counts only active');

select t_as('22222222-2222-2222-2222-222222222222');
select t_check((select count(*) from posts) = 3, 'active member sees private group post');

-- reactions & comments, counters
insert into reactions (post_id, user_id, reaction_type) values ('bbbb0001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'respect');
insert into comments (post_id, author_id, content) values ('bbbb0001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'bravo');
select t_check((select reaction_count from posts where id = 'bbbb0001-0000-0000-0000-000000000001') = 1, 'reaction_count trigger');
select t_check((select comment_count from posts where id = 'bbbb0001-0000-0000-0000-000000000001') = 1, 'comment_count trigger');
select t_expect_fail($q$insert into reactions (post_id, user_id) values ('bbbb0001-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111')$q$, 'reaction on behalf of another user');

-- ---------------------------------------------------------------------------
-- Chat: only participants
-- ---------------------------------------------------------------------------
select t_as('11111111-1111-1111-1111-111111111111');
insert into conversations (id, kind, created_by) values ('cccc0001-0000-0000-0000-000000000001', 'direct', '11111111-1111-1111-1111-111111111111');
select t_check((select count(*) from conversation_participants where conversation_id = 'cccc0001-0000-0000-0000-000000000001') = 1, 'creator auto-participant (owner)');

select t_as('22222222-2222-2222-2222-222222222222');
select t_check((select count(*) from conversations) = 0, 'Bruno cannot see a conversation he is not in');
select t_expect_fail($q$insert into messages (conversation_id, sender_id, body) values ('cccc0001-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','ciao')$q$, 'message into a conversation without being participant');

select t_as('11111111-1111-1111-1111-111111111111');
insert into conversation_participants (conversation_id, user_id) values ('cccc0001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222');

select t_as('22222222-2222-2222-2222-222222222222');
insert into messages (conversation_id, sender_id, body) values ('cccc0001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'ciao Anna');
select t_check((select last_message_at is not null from conversations where id = 'cccc0001-0000-0000-0000-000000000001'), 'last_message_at touched');
select t_expect_fail($q$insert into messages (conversation_id, sender_id, body) values ('cccc0001-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','spoof')$q$, 'message with foreign sender_id');

-- ---------------------------------------------------------------------------
-- Marketplace: mediated firearms
-- ---------------------------------------------------------------------------
insert into listings (id, seller_id, category_id, title, price_minor, currency_code, country_code, status)
  select 'dddd0001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', id, 'Carabina usata', 145000, 'EUR', 'FR', 'active'
  from categories where kind = 'marketplace' and slug = 'firearms_ammo';
select t_check((select is_mediated from listings where id = 'dddd0001-0000-0000-0000-000000000001'), 'firearms listing is mediated by trigger');
select t_expect_fail($q$insert into listings (seller_id, category_id, title, price_minor, country_code) select '22222222-2222-2222-2222-222222222222', id, 'x', -5, 'FR' from categories where slug = 'optics'$q$, 'negative price rejected');

-- ---------------------------------------------------------------------------
-- Reports & verification requests: owner and moderation roles only
-- ---------------------------------------------------------------------------
insert into reports (reporter_id, target_type, target_id, target_author_id, reason, country_code)
  values ('22222222-2222-2222-2222-222222222222', 'post', 'bbbb0001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'spam', 'FR');
insert into verification_requests (user_id, badge_type, declared_data)
  values ('22222222-2222-2222-2222-222222222222', 'hunter', '{"licence":"FR-123"}');
select t_check((select count(*) from reports) = 1, 'reporter sees own report');

select t_as('11111111-1111-1111-1111-111111111111');
select t_check((select count(*) from reports) = 0, 'reported author cannot see the report');
select t_check((select count(*) from verification_requests) = 0, 'other users cannot see verification requests');
select t_expect_rows($q$update reports set status = 'resolved' where true$q$, 0, 'non-moderator cannot resolve reports');

select t_as('33333333-3333-3333-3333-333333333333');
select t_check((select count(*) from reports) = 1, 'admin sees the report');
update reports set status = 'in_progress', assigned_to = '33333333-3333-3333-3333-333333333333' where true;
select t_check((select status from reports limit 1) = 'in_progress', 'admin updates the report');
select t_check((select count(*) from verification_requests) = 1, 'admin sees verification requests');
update user_profiles set verification_level = 'hunter' where id = '22222222-2222-2222-2222-222222222222';
select t_check((select verification_level from user_profiles where id = '22222222-2222-2222-2222-222222222222') = 'hunter', 'admin can set verification_level');
insert into admin_audit_log (admin_id, action, resource_type, resource_id) values ('33333333-3333-3333-3333-333333333333', 'report.assign', 'report', 'x');
select t_check((select count(*) from posts) = 3, 'admin sees every post');

-- ---------------------------------------------------------------------------
-- Anonymous: public read only
-- ---------------------------------------------------------------------------
select t_as(null);
select t_check((select count(*) from posts) = 1, 'anon sees only public posts');
select t_check((select count(*) from countries) = 6, 'anon reads reference data');
select t_check((select count(*) from species_names where locale = 'it') = 36, 'anon reads species names');
select t_check((select count(*) from reports) = 0, 'anon sees no reports');
select t_check((select count(*) from conversation_participants) = 0, 'anon sees no chat participants');
select t_check((select count(*) from verification_requests) = 0, 'anon sees no verification requests');
select t_check((select count(*) from hunting_calendars) = 0, 'anon sees no draft calendars');
select t_expect_fail($q$insert into posts (author_id, content, country_code) values ('11111111-1111-1111-1111-111111111111','x','IT')$q$, 'anon insert post');
select t_expect_fail($q$insert into follows (follower_id, following_id) values ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222')$q$, 'anon insert follow');

-- ---------------------------------------------------------------------------
-- Blocks hide content both ways
-- ---------------------------------------------------------------------------
select t_as('11111111-1111-1111-1111-111111111111');
insert into blocks (blocker_id, blocked_id) values ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
select t_as('22222222-2222-2222-2222-222222222222');
select t_check((select count(*) from posts where author_id = '11111111-1111-1111-1111-111111111111') = 0, 'blocked user no longer sees the blocker''s posts');
select t_check((select count(*) from blocks) = 0, 'blocked user cannot see the block row');
select t_expect_fail($q$insert into follows (follower_id, following_id) values ('22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111')$q$, 'blocked user cannot follow');

-- ---------------------------------------------------------------------------
-- Hunting calendars: editor role
-- ---------------------------------------------------------------------------
select t_root();
insert into auth.users (id, email, raw_user_meta_data) values ('44444444-4444-4444-4444-444444444444', 'dario@example.com', '{"username":"dario"}');
insert into admin_users (user_id, role_id) select '44444444-4444-4444-4444-444444444444', id from admin_roles where name = 'hunting_data_editor';
select t_as('44444444-4444-4444-4444-444444444444');
insert into hunting_calendars (id, country_code, region_id, species_id, season_label, valid_from, valid_to, status)
  select 'eeee0001-0000-0000-0000-000000000001', 'IT', r.id, s.id, '2026/27', '2026-09-20', '2027-01-31', 'draft'
  from regions r, species s where r.code = 'LOM' and s.scientific_name = 'Scolopax rusticola';
insert into calendar_rules (calendar_id, kind, date_from, date_to) values ('eeee0001-0000-0000-0000-000000000001', 'open_period', '2026-10-01', '2026-12-31');
select t_as('22222222-2222-2222-2222-222222222222');
select t_check((select count(*) from hunting_calendars) = 0, 'draft calendar hidden from users');
select t_as('44444444-4444-4444-4444-444444444444');
update hunting_calendars set status = 'published', published_at = now() where id = 'eeee0001-0000-0000-0000-000000000001';
select t_as(null);
select t_check((select count(*) from hunting_calendars) = 1, 'published calendar visible to anon');
select t_check((select count(*) from calendar_rules) = 1, 'rules of published calendar visible');
select t_expect_rows($q$update hunting_calendars set status = 'archived' where true$q$, 0, 'anon cannot update calendars');

select t_root();
select t_check((select count(*) from admin_audit_log) = 1, 'audit row written');
rollback;
