-- ============================================================================
-- HB Social 2.0 — Storage buckets and object policies (P03 / part a2)
-- Public media buckets: anyone reads, owners write under <user_id>/...
-- Private bucket verification-docs: owner uploads, only moderation roles read; 30-day retention is a pg_cron job (P31).
-- Idempotent. Deploy after supabase_policies.sql (uses has_admin_role).
-- ============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('avatars',           'avatars',           true,  5242880,   array['image/jpeg','image/png','image/webp']),
  ('covers',            'covers',            true,  8388608,   array['image/jpeg','image/png','image/webp']),
  ('post-media',        'post-media',        true,  104857600, array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']),
  ('story-media',       'story-media',       true,  52428800,  array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']),
  ('group-media',       'group-media',       true,  8388608,   array['image/jpeg','image/png','image/webp']),
  ('page-media',        'page-media',        true,  8388608,   array['image/jpeg','image/png','image/webp']),
  ('listing-media',     'listing-media',     true,  10485760,  array['image/jpeg','image/png','image/webp']),
  ('event-media',       'event-media',       true,  8388608,   array['image/jpeg','image/png','image/webp']),
  ('chat-media',        'chat-media',        false, 26214400,  array['image/jpeg','image/png','image/webp','audio/mp4','audio/mpeg','audio/ogg','audio/webm']),
  ('verification-docs', 'verification-docs', false, 10485760,  array['image/jpeg','image/png','application/pdf'])
on conflict (id) do nothing;

-- Public buckets ---------------------------------------------------------------

drop policy if exists "public media read" on storage.objects;
create policy "public media read" on storage.objects for select
  using (bucket_id in ('avatars','covers','post-media','story-media','group-media','page-media','listing-media','event-media'));

drop policy if exists "public media insert own folder" on storage.objects;
create policy "public media insert own folder" on storage.objects for insert to authenticated
  with check (
    bucket_id in ('avatars','covers','post-media','story-media','group-media','page-media','listing-media','event-media')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "public media update own folder" on storage.objects;
create policy "public media update own folder" on storage.objects for update to authenticated
  using (
    bucket_id in ('avatars','covers','post-media','story-media','group-media','page-media','listing-media','event-media')
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check ((storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "public media delete own folder" on storage.objects;
create policy "public media delete own folder" on storage.objects for delete to authenticated
  using (
    bucket_id in ('avatars','covers','post-media','story-media','group-media','page-media','listing-media','event-media')
    and ((storage.foldername(name))[1] = auth.uid()::text or has_admin_role(auth.uid(), array['superadmin','admin','moderator']))
  );

-- Chat media: readable only by participants of the conversation named in the first folder ----
-- path convention: <conversation_id>/<user_id>/<uuid>.<ext>

drop policy if exists "chat media read participants" on storage.objects;
create policy "chat media read participants" on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-media'
    and is_conversation_participant(((storage.foldername(name))[1])::uuid, auth.uid())
  );

drop policy if exists "chat media insert participants" on storage.objects;
create policy "chat media insert participants" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-media'
    and is_conversation_participant(((storage.foldername(name))[1])::uuid, auth.uid())
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "chat media delete own" on storage.objects;
create policy "chat media delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'chat-media' and (storage.foldername(name))[2] = auth.uid()::text);

-- Verification documents: private ---------------------------------------------------------
-- path convention: <user_id>/<uuid>.<ext>

drop policy if exists "verification docs insert own" on storage.objects;
create policy "verification docs insert own" on storage.objects for insert to authenticated
  with check (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "verification docs read own or moderation" on storage.objects;
create policy "verification docs read own or moderation" on storage.objects for select to authenticated
  using (
    bucket_id = 'verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text or has_admin_role(auth.uid(), array['superadmin','admin','moderator']))
  );

drop policy if exists "verification docs delete own or moderation" on storage.objects;
create policy "verification docs delete own or moderation" on storage.objects for delete to authenticated
  using (
    bucket_id = 'verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text or has_admin_role(auth.uid(), array['superadmin','admin','moderator']))
  );
