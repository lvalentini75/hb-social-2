-- ============================================================================
-- HB Social 2.0 — pending migration P42 (Console: commercio e inserzioni — approvazione degli annunci per categoria, ordini/dispute/rimborsi dalla console,
-- codici promozionali per crediti pubblicitari (al posto di "piani e coupon": l'app è gratuita), coda creatività (già P36) e report ricavi)
-- Contenuto di lib/supabase/pending_migrations.sql. Idempotente. Da lanciare nel SQL editor (hb-dev) DOPO P41.
-- Criterio della roadmap (adattato al modello senza wallet/abbonamenti): "il rimborso dalla console aggiorna l'ordine (Stripe via Edge payments) e il report ricavi".
-- Aggiunge:
--   categories.requires_review (default false; true per firearms_ammo) · listings.review_status/review_note/reviewed_by/reviewed_at/review_requested_at;
--     trigger zz_listings_review_gate: la pubblicazione (e la modifica di titolo/descrizione/categoria/attributi) in una categoria con revisione tiene l'annuncio
--     in bozza con review_status 'pending' e avvisa il venditore; my_listings espone review_status/review_note
--   RPC console: admin_listings_queue, admin_listing_review (approve|reject), admin_set_category_review, admin_listings_stats
--   Ordini: admin_orders_list, admin_orders_stats, admin_order_refund (ordine pagato/spedito/completato → refund_requested con motivo; il rimborso Stripe lo esegue
--     la Edge payments `refund` chiamata dalla console e il webhook chiude in refunded), admin_order_note (evento interno)
--   Codici promozionali: ad_promo_codes + ad_promo_redemptions; redeem_ad_promo_code (proprietario/admin dell'account); admin_promo_codes_list,
--     admin_promo_code_upsert, admin_promo_code_set_status; hb_ad_credit_apply (interna, riusata dai codici)
--   Inserzioni: admin_ad_charges_list (addebiti con filtri), ads_review_queue invariata (P36)
--   Report: admin_revenue_report(p_from, p_to, p_group) — ricavi pubblicitari incassati per periodo/paese/valuta, crediti consumati, in sospeso e falliti,
--     top inserzionisti; GMV marketplace e biglietti (commissioni 0), rimborsi
--   Notifiche nuove: listing_in_review, listing_approved, listing_rejected (testi push in edge/push-dispatch)
-- ============================================================================

-- 1. Approvazione annunci per categoria ----------------------------------------------------------------------------------------------------------------------------------------
alter table categories add column if not exists requires_review boolean not null default false;
update categories set requires_review = true where kind = 'marketplace' and slug = 'firearms_ammo' and requires_review = false;
alter table listings add column if not exists review_status text not null default 'approved' check (review_status in ('approved','pending','rejected'));
alter table listings add column if not exists review_note text;
alter table listings add column if not exists reviewed_by uuid references user_profiles(id) on delete set null;
alter table listings add column if not exists reviewed_at timestamptz;
alter table listings add column if not exists review_requested_at timestamptz;
create index if not exists idx_listings_review on listings(review_status, review_requested_at) where review_status <> 'approved';

create or replace function trg_listings_review_gate()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare v_requires boolean; v_substantive boolean;
begin
  if coalesce(current_setting('hb.internal', true), '') = 'on' then return new; end if;
  select c.requires_review into v_requires from categories c where c.id = new.category_id;
  if not coalesce(v_requires, false) then
    if tg_op = 'UPDATE' and old.category_id is distinct from new.category_id and new.review_status = 'pending' then new.review_status := 'approved'; new.review_requested_at := null; end if;   -- spostato in una categoria libera
    return new;
  end if;
  v_substantive := tg_op = 'INSERT' or new.title is distinct from old.title or new.description is distinct from old.description or new.category_id is distinct from old.category_id or new.attributes is distinct from old.attributes;
  if new.status = 'active' and (tg_op = 'INSERT' or old.status <> 'active' or v_substantive) then
    -- riattivazione di un annuncio già approvato senza modifiche sostanziali (es. da prenotato o scaduto): consentita
    if tg_op = 'UPDATE' and old.status <> 'active' and not v_substantive and old.review_status = 'approved' and old.reviewed_at is not null then return new; end if;
    new.status := 'draft'; new.review_status := 'pending'; new.review_requested_at := now(); new.review_note := null; new.reviewed_by := null; new.reviewed_at := null;
  end if;
  return new;
end $$;
drop trigger if exists zz_listings_review_gate on listings;
create trigger zz_listings_review_gate before insert or update on listings for each row execute function trg_listings_review_gate();

-- avviso al venditore quando l'annuncio entra in revisione (after, così l'id esiste)
create or replace function trg_listings_review_notify()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  if new.review_status = 'pending' and (tg_op = 'INSERT' or old.review_status is distinct from 'pending') then
    perform notify_user(new.seller_id, null, 'listing_in_review', 'listing', new.id, jsonb_build_object('title', new.title));
  end if;
  return null;
end $$;
drop trigger if exists zz_listings_review_notify on listings;
create trigger zz_listings_review_notify after insert or update of review_status on listings for each row execute function trg_listings_review_notify();

drop function if exists my_listings(text, integer, integer);
create function my_listings(p_status text default null, p_limit integer default 20, p_offset integer default 0)
returns table (id uuid, title text, price_minor bigint, currency_code char(3), condition text, category_id uuid, category_slug text, status text, is_mediated boolean, municipality text, media_path text, media_count integer,
               favorite_count integer, view_count integer, contact_count integer, created_at timestamptz, updated_at timestamptz, expires_at timestamptz, reserved_at timestamptz, sold_at timestamptz, days_left integer,
               review_status text, review_note text)
language sql stable security definer set search_path = public, extensions as $$
  select l.id, l.title, l.price_minor, l.currency_code, l.condition, l.category_id, c.slug, l.status, l.is_mediated, l.municipality,
         (select m.path from listing_media m where m.listing_id = l.id order by m.sort_order limit 1), l.media_count, l.favorite_count, l.view_count, l.contact_count,
         l.created_at, l.updated_at, l.expires_at, l.reserved_at, l.sold_at, case when l.status = 'active' and l.expires_at is not null then (extract(epoch from (l.expires_at - now())) / 86400)::integer end,
         l.review_status, l.review_note
  from listings l join categories c on c.id = l.category_id
  where l.seller_id = auth.uid() and l.status <> 'removed' and (p_status is null or l.status = p_status or (p_status = 'pending' and l.review_status = 'pending'))
  order by case when l.review_status = 'pending' then 0 end, case l.status when 'active' then 1 when 'reserved' then 2 when 'draft' then 3 when 'expired' then 4 else 5 end, l.updated_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100) offset greatest(coalesce(p_offset, 0), 0)
$$;
revoke all on function my_listings(text, integer, integer) from public, anon; grant execute on function my_listings(text, integer, integer) to authenticated;

create or replace function admin_listings_queue(p_review text default 'pending', p_status text default null, p_category_id uuid default null, p_q text default null, p_limit integer default 50, p_offset integer default 0)
returns table (id uuid, title text, description text, price_minor bigint, currency_code char(3), condition text, status text, review_status text, review_note text, review_requested_at timestamptz, reviewed_at timestamptz,
               category_id uuid, category_slug text, requires_review boolean, is_mediated boolean, attributes jsonb, municipality text, region_name text, country_code char(2), media jsonb, media_count integer,
               seller_id uuid, seller_username citext, seller_name text, seller_avatar_url text, seller_verification text, seller_active_strikes integer, seller_active_listings bigint, page_id uuid, page_name text,
               view_count integer, favorite_count integer, contact_count integer, created_at timestamptz, updated_at timestamptz, total bigint)
language sql stable security definer set search_path = public, extensions as $$
  with f as (
    select l.* from listings l
    where has_admin_access(auth.uid(), 'listings', 'read')
      and (coalesce(p_review, 'pending') = 'all' or l.review_status = p_review)
      and (nullif(p_status, '') is null or l.status = p_status)
      and (p_category_id is null or l.category_id = p_category_id)
      and (nullif(trim(coalesce(p_q, '')), '') is null or l.title ilike '%' || trim(p_q) || '%' or l.id::text = trim(p_q) or exists (select 1 from user_profiles u where u.id = l.seller_id and (u.username ilike '%' || trim(p_q) || '%' or u.display_name ilike '%' || trim(p_q) || '%'))))
  select f.id, f.title, f.description, f.price_minor, f.currency_code, f.condition, f.status, f.review_status, f.review_note, f.review_requested_at, f.reviewed_at,
         f.category_id, c.slug, c.requires_review, f.is_mediated, f.attributes, f.municipality, (select r.name from regions r where r.id = f.region_id), f.country_code,
         (select coalesce(jsonb_agg(jsonb_build_object('path', m.path) order by m.sort_order), '[]'::jsonb) from listing_media m where m.listing_id = f.id), f.media_count,
         f.seller_id, u.username, u.display_name, u.avatar_url, u.verification_level, active_strike_count(f.seller_id), (select count(*) from listings x where x.seller_id = f.seller_id and x.status = 'active'),
         f.page_id, (select p.name from pages p where p.id = f.page_id), f.view_count, f.favorite_count, f.contact_count, f.created_at, f.updated_at, (select count(*) from f)
  from f join categories c on c.id = f.category_id join user_profiles u on u.id = f.seller_id
  order by case when f.review_status = 'pending' then f.review_requested_at end asc nulls last, f.updated_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200) offset greatest(coalesce(p_offset, 0), 0)
$$;

create or replace function admin_listing_review(p_id uuid, p_decision text, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid(); l listings%rowtype; v_note text := left(nullif(trim(coalesce(p_note, '')), ''), 500); v_limit integer;
begin
  if v_uid is null then raise exception using errcode = '42501', message = 'not_authenticated'; end if;
  if not has_admin_access(v_uid, 'listings', 'write') then raise exception using errcode = '42501', message = 'admin_permission_denied'; end if;
  if p_decision not in ('approve','reject') then raise exception using errcode = '23514', message = 'listing_review_decision_invalid'; end if;
  select * into l from listings x where x.id = p_id;
  if l.id is null then raise exception using errcode = 'P0001', message = 'listing_not_found'; end if;
  if l.review_status <> 'pending' then raise exception using errcode = '23514', message = 'listing_review_closed'; end if;
  if p_decision = 'reject' and (v_note is null or length(v_note) < 3) then raise exception using errcode = '23514', message = 'admin_reason_required'; end if;
  perform set_config('hb.internal', 'on', true); perform set_config('hb.audit_skip', 'on', true);
  if p_decision = 'approve' then
    v_limit := hb_user_limit(l.seller_id, 'active_listings');
    if (select count(*) from listings x where x.seller_id = l.seller_id and x.status = 'active') >= v_limit then raise exception using errcode = '23514', message = 'listing_limit_reached'; end if;
    update listings set status = 'active', review_status = 'approved', review_note = v_note, reviewed_by = v_uid, reviewed_at = now(), review_requested_at = null,
                        expires_at = coalesce(expires_at, now() + interval '60 days'), updated_at = now() where id = l.id;
    perform notify_user(l.seller_id, null, 'listing_approved', 'listing', l.id, jsonb_build_object('title', l.title));
  else
    update listings set status = 'draft', review_status = 'rejected', review_note = v_note, reviewed_by = v_uid, reviewed_at = now(), review_requested_at = null, updated_at = now() where id = l.id;
    perform notify_user(l.seller_id, null, 'listing_rejected', 'listing', l.id, jsonb_build_object('title', l.title, 'note', v_note));
  end if;
  perform hb_audit('listing.review.' || p_decision, 'listing', l.id::text, jsonb_build_object('seller_id', l.seller_id, 'category_id', l.category_id, 'note', v_note));
  return jsonb_build_object('status', case when p_decision = 'approve' then 'active' else 'draft' end, 'review_status', case when p_decision = 'approve' then 'approved' else 'rejected' end);
end $$;

create or replace function admin_set_category_review(p_category_id uuid, p_requires_review boolean)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid(); v_old boolean;
begin
  if v_uid is null then raise exception using errcode = '42501', message = 'not_authenticated'; end if;
  if not has_admin_access(v_uid, 'listings', 'write') then raise exception using errcode = '42501', message = 'admin_permission_denied'; end if;
  select requires_review into v_old from categories where id = p_category_id and kind = 'marketplace';
  if v_old is null then raise exception using errcode = 'P0001', message = 'category_not_found'; end if;
  perform set_config('hb.audit_skip', 'on', true);
  update categories set requires_review = coalesce(p_requires_review, false) where id = p_category_id;
  perform hb_audit('category.requires_review', 'category', p_category_id::text, jsonb_build_object('before', v_old, 'after', coalesce(p_requires_review, false)));
end $$;

create or replace function admin_listings_stats()
returns jsonb language sql stable security definer set search_path = public, extensions as $$
  select case when not has_admin_access(auth.uid(), 'listings', 'read') then '{}'::jsonb else jsonb_build_object(
    'pending', (select count(*) from listings l where l.review_status = 'pending'),
    'pending_oldest_hours', (select round(extract(epoch from (now() - min(l.review_requested_at))) / 3600) from listings l where l.review_status = 'pending'),
    'rejected_7d', (select count(*) from listings l where l.review_status = 'rejected' and l.reviewed_at >= now() - interval '7 days'),
    'approved_7d', (select count(*) from listings l where l.review_status = 'approved' and l.reviewed_at >= now() - interval '7 days'),
    'active', (select count(*) from listings l where l.status = 'active'), 'mediated_active', (select count(*) from listings l where l.status = 'active' and l.is_mediated),
    'categories', (select coalesce(jsonb_agg(jsonb_build_object('id', c.id, 'slug', c.slug, 'name_key', c.name_key, 'requires_review', c.requires_review, 'is_restricted', c.is_restricted,
                                                                 'active', (select count(*) from listings l where l.category_id = c.id and l.status = 'active'), 'pending', (select count(*) from listings l where l.category_id = c.id and l.review_status = 'pending')) order by c.sort_order), '[]'::jsonb)
                   from categories c where c.kind = 'marketplace')) end
$$;

-- 2. Ordini dalla console ---------------------------------------------------------------------------------------------------------------------------------------------------------
create or replace function admin_orders_list(p_status text default null, p_kind text default null, p_q text default null, p_from timestamptz default null, p_to timestamptz default null, p_limit integer default 50, p_offset integer default 0)
returns table (id uuid, kind text, title text, status text, dispute_status text, amount_minor bigint, shipping_minor bigint, total_minor bigint, currency_code char(3), delivery_method text,
               buyer_id uuid, buyer_username citext, buyer_name text, seller_id uuid, seller_username citext, seller_name text, listing_id uuid, event_id uuid,
               stripe_payment_intent_id text, stripe_refund_id text, refund_reason text, cancel_reason text, paid_at timestamptz, shipped_at timestamptz, completed_at timestamptz, refunded_at timestamptz, created_at timestamptz, total bigint)
language sql stable security definer set search_path = public, extensions as $$
  with f as (
    select o.* from orders o
    where has_admin_access(auth.uid(), 'orders', 'read')
      and (nullif(p_status, '') is null or (p_status = 'open' and o.status in ('paid','shipped','refund_requested','disputed')) or o.status = p_status)
      and (nullif(p_kind, '') is null or o.kind = p_kind)
      and (p_from is null or o.created_at >= p_from) and (p_to is null or o.created_at < p_to)
      and (nullif(trim(coalesce(p_q, '')), '') is null or o.title ilike '%' || trim(p_q) || '%' or o.id::text = trim(p_q) or o.stripe_payment_intent_id = trim(p_q)
           or exists (select 1 from user_profiles u where u.id in (o.buyer_id, o.seller_id) and (u.username ilike '%' || trim(p_q) || '%' or u.display_name ilike '%' || trim(p_q) || '%'))))
  select f.id, f.kind, f.title, f.status, f.dispute_status, f.amount_minor, f.shipping_minor, f.total_minor, f.currency_code, f.delivery_method,
         f.buyer_id, b.username, b.display_name, f.seller_id, s.username, s.display_name, f.listing_id, f.event_id,
         f.stripe_payment_intent_id, f.stripe_refund_id, f.refund_reason, f.cancel_reason, f.paid_at, f.shipped_at, f.completed_at, f.refunded_at, f.created_at, (select count(*) from f)
  from f left join user_profiles b on b.id = f.buyer_id left join user_profiles s on s.id = f.seller_id
  order by case when f.status in ('disputed','refund_requested') then 0 else 1 end, f.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200) offset greatest(coalesce(p_offset, 0), 0)
$$;

create or replace function admin_orders_stats()
returns jsonb language sql stable security definer set search_path = public, extensions as $$
  select case when not has_admin_access(auth.uid(), 'orders', 'read') then '{}'::jsonb else jsonb_build_object(
    'by_status', (select coalesce(jsonb_object_agg(s.status, s.n), '{}'::jsonb) from (select o.status, count(*) n from orders o group by o.status) s),
    'open_refunds', (select count(*) from orders o where o.status = 'refund_requested'), 'open_disputes', (select count(*) from orders o where o.status = 'disputed'),
    'gmv_30d', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select o.currency_code, sum(o.total_minor) v from orders o where o.paid_at >= now() - interval '30 days' and o.status in ('paid','shipped','completed') group by o.currency_code) x),
    'refunded_30d', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select o.currency_code, sum(o.total_minor) v from orders o where o.refunded_at >= now() - interval '30 days' group by o.currency_code) x),
    'orders_30d', (select count(*) from orders o where o.paid_at >= now() - interval '30 days'),
    'tickets_30d', (select count(*) from orders o where o.kind = 'event_ticket' and o.paid_at >= now() - interval '30 days')) end
$$;

-- rimborso deciso dalla console (anche senza richiesta dell'acquirente): l'ordine passa in refund_requested; la console chiama subito la Edge payments `refund` e il webhook chiude in refunded
create or replace function admin_order_refund(p_order_id uuid, p_reason text)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid(); o orders%rowtype; v_reason text := left(nullif(trim(coalesce(p_reason, '')), ''), 500);
begin
  if v_uid is null then raise exception using errcode = '42501', message = 'not_authenticated'; end if;
  if not has_admin_access(v_uid, 'orders', 'write') then raise exception using errcode = '42501', message = 'admin_permission_denied'; end if;
  select * into o from orders x where x.id = p_order_id for update;
  if o.id is null then raise exception using errcode = 'P0001', message = 'order_not_found'; end if;
  if v_reason is null or length(v_reason) < 3 then raise exception using errcode = '23514', message = 'admin_reason_required'; end if;
  if o.status = 'refund_requested' then return jsonb_build_object('status', o.status, 'needs_stripe_refund', true, 'payment_intent_id', o.stripe_payment_intent_id); end if;
  if o.status not in ('paid','shipped','completed','disputed') then raise exception using errcode = '23514', message = 'order_transition_invalid'; end if;
  if o.stripe_payment_intent_id is null then raise exception using errcode = '23514', message = 'order_not_refundable'; end if;
  if o.paid_at < now() - interval '180 days' then raise exception using errcode = '23514', message = 'order_refund_window'; end if;
  perform set_config('hb.audit_skip', 'on', true);
  update orders set status = 'refund_requested', status_before_dispute = o.status, refund_reason = v_reason, updated_at = now() where id = o.id;
  perform hb_order_event(o.id, v_uid, 'refund_requested', jsonb_build_object('reason', v_reason, 'by', 'admin'));
  perform hb_order_event(o.id, v_uid, 'refund_approved', jsonb_build_object('note', v_reason, 'by', 'admin'));
  perform notify_user(o.buyer_id, null, 'order_refund_requested', 'order', o.id, jsonb_build_object('title', o.title, 'by', 'admin'));
  perform notify_user(o.seller_id, null, 'order_refund_requested', 'order', o.id, jsonb_build_object('title', o.title, 'by', 'admin', 'reason', v_reason));
  perform hb_audit('order.refund', 'order', o.id::text, jsonb_build_object('reason', v_reason, 'before_status', o.status, 'total_minor', o.total_minor, 'currency_code', o.currency_code));
  return jsonb_build_object('status', 'refund_requested', 'needs_stripe_refund', true, 'payment_intent_id', o.stripe_payment_intent_id);
end $$;

create or replace function admin_order_note(p_order_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception using errcode = '42501', message = 'not_authenticated'; end if;
  if not has_admin_access(v_uid, 'orders', 'write') then raise exception using errcode = '42501', message = 'admin_permission_denied'; end if;
  if not exists (select 1 from orders o where o.id = p_order_id) then raise exception using errcode = 'P0001', message = 'order_not_found'; end if;
  if length(trim(coalesce(p_note, ''))) not between 1 and 1000 then raise exception using errcode = '23514', message = 'admin_note_invalid'; end if;
  perform hb_order_event(p_order_id, v_uid, 'admin_note', jsonb_build_object('note', trim(p_note)));
  perform hb_audit('order.note', 'order', p_order_id::text, jsonb_build_object('note', left(trim(p_note), 300)));
end $$;

-- 3. Codici promozionali per crediti pubblicitari --------------------------------------------------------------------------------------------------------------------------------------
create table if not exists ad_promo_codes (
  id uuid primary key default gen_random_uuid(),
  code citext not null unique check (length(code) between 4 and 32 and code ~ '^[A-Za-z0-9_-]+$'),
  credit_minor bigint not null check (credit_minor between 100 and 100000),
  currency_code char(3) not null references currencies(code),
  max_redemptions integer check (max_redemptions is null or max_redemptions >= 1),
  redeemed_count integer not null default 0,
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  status text not null default 'active' check (status in ('active','disabled')),
  note text check (note is null or length(note) <= 300),
  created_by uuid references user_profiles(id) on delete set null,
  country_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists ad_promo_redemptions (
  id uuid primary key default gen_random_uuid(),
  code_id uuid not null references ad_promo_codes(id) on delete cascade,
  account_id uuid not null references ad_accounts(id) on delete cascade,
  user_id uuid references user_profiles(id) on delete set null,
  credit_id uuid references ad_account_credits(id) on delete set null,
  country_code text,
  created_at timestamptz not null default now(),
  unique (code_id, account_id)
);
create index if not exists idx_ad_promo_redemptions_account on ad_promo_redemptions(account_id, created_at desc);
alter table ad_promo_codes enable row level security;
alter table ad_promo_redemptions enable row level security;
drop policy if exists ad_promo_codes_select on ad_promo_codes;
create policy ad_promo_codes_select on ad_promo_codes for select using (has_admin_role(auth.uid(), array['superadmin','admin','finance']));
drop policy if exists ad_promo_redemptions_select on ad_promo_redemptions;
create policy ad_promo_redemptions_select on ad_promo_redemptions for select using (can_manage_ad_account(account_id, auth.uid()) or has_admin_role(auth.uid(), array['superadmin','admin','finance']));
grant select on ad_promo_codes, ad_promo_redemptions to authenticated;

-- accredito interno (riusato dai codici promozionali; grant_ad_credit di P36 resta per la console Finanza)
create or replace function hb_ad_credit_apply(p_account_id uuid, p_amount_minor bigint, p_note text, p_actor uuid default null, p_notify boolean default true)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare a ad_accounts%rowtype; v_id uuid := gen_random_uuid();
begin
  select * into a from ad_accounts x where x.id = p_account_id for update;
  if a.id is null then raise exception using errcode = 'P0001', message = 'ads_account_not_found'; end if;
  if coalesce(p_amount_minor, 0) <= 0 then raise exception using errcode = '23514', message = 'ads_credit_invalid'; end if;
  insert into ad_account_credits (id, account_id, kind, amount_minor, balance_after_minor, note, created_by, country_code) values (v_id, a.id, 'grant', p_amount_minor, a.credit_balance_minor + p_amount_minor, left(p_note, 300), p_actor, a.country_code);
  update ad_accounts set credit_balance_minor = credit_balance_minor + p_amount_minor, lifetime_credit_minor = lifetime_credit_minor + p_amount_minor, updated_at = now() where id = a.id;
  if p_notify then perform notify_user(a.owner_id, p_actor, 'ads_credit_granted', 'ad_account', a.id, jsonb_build_object('account_name', a.name, 'amount_minor', p_amount_minor, 'currency_code', a.currency_code, 'welcome', false, 'promo', true)); end if;
  return v_id;
end $$;

create or replace function redeem_ad_promo_code(p_account_id uuid, p_code text)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid(); c ad_promo_codes%rowtype; a ad_accounts%rowtype; v_credit uuid;
begin
  if v_uid is null then raise exception using errcode = '42501', message = 'not_authenticated'; end if;
  select * into a from ad_accounts x where x.id = p_account_id;
  if a.id is null then raise exception using errcode = 'P0001', message = 'ads_account_not_found'; end if;
  if not can_manage_ad_account(a.id, v_uid) then raise exception using errcode = '42501', message = 'ads_permission_denied'; end if;
  if a.status <> 'active' then raise exception using errcode = '23514', message = 'ads_account_closed'; end if;
  select * into c from ad_promo_codes x where lower(x.code::text) = lower(trim(coalesce(p_code, ''))) for update;
  if c.id is null or c.status <> 'active' then raise exception using errcode = '23514', message = 'promo_code_invalid'; end if;
  if c.valid_from > now() or (c.valid_to is not null and c.valid_to < now()) then raise exception using errcode = '23514', message = 'promo_code_expired'; end if;
  if c.max_redemptions is not null and c.redeemed_count >= c.max_redemptions then raise exception using errcode = '23514', message = 'promo_code_exhausted'; end if;
  if c.currency_code <> a.currency_code then raise exception using errcode = '23514', message = 'promo_code_currency_mismatch'; end if;
  if exists (select 1 from ad_promo_redemptions r where r.code_id = c.id and r.account_id = a.id) then raise exception using errcode = '23514', message = 'promo_code_already_used'; end if;
  if exists (select 1 from ad_promo_redemptions r join ad_accounts x on x.id = r.account_id where r.code_id = c.id and x.owner_id = a.owner_id) then raise exception using errcode = '23514', message = 'promo_code_already_used'; end if;   -- una volta per persona
  v_credit := hb_ad_credit_apply(a.id, c.credit_minor, 'ads.credit.promo:' || c.code, v_uid, true);
  insert into ad_promo_redemptions (code_id, account_id, user_id, credit_id, country_code) values (c.id, a.id, v_uid, v_credit, a.country_code);
  update ad_promo_codes set redeemed_count = redeemed_count + 1, updated_at = now() where id = c.id;
  return jsonb_build_object('credit_minor', c.credit_minor, 'currency_code', c.currency_code, 'credit_balance_minor', a.credit_balance_minor + c.credit_minor);
end $$;

create or replace function admin_promo_codes_list()
returns table (id uuid, code citext, credit_minor bigint, currency_code char(3), max_redemptions integer, redeemed_count integer, valid_from timestamptz, valid_to timestamptz, status text, note text,
               created_by uuid, created_by_name text, created_at timestamptz, total_credit_minor bigint, last_redeemed_at timestamptz)
language sql stable security definer set search_path = public, extensions as $$
  select c.id, c.code, c.credit_minor, c.currency_code, c.max_redemptions, c.redeemed_count, c.valid_from, c.valid_to,
         case when c.status = 'disabled' then 'disabled' when c.valid_to < now() then 'expired' when c.max_redemptions is not null and c.redeemed_count >= c.max_redemptions then 'exhausted' else 'active' end,
         c.note, c.created_by, (select coalesce(u.display_name, u.username::text) from user_profiles u where u.id = c.created_by), c.created_at,
         c.credit_minor * c.redeemed_count, (select max(r.created_at) from ad_promo_redemptions r where r.code_id = c.id)
  from ad_promo_codes c where has_admin_role(auth.uid(), array['superadmin','admin','finance'])
  order by c.created_at desc
$$;

create or replace function admin_promo_code_upsert(p_id uuid default null, p_code text default null, p_credit_minor bigint default null, p_currency_code text default 'EUR', p_max_redemptions integer default null,
                                                   p_valid_from timestamptz default null, p_valid_to timestamptz default null, p_note text default null)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid(); v_id uuid; v_code text := upper(trim(coalesce(p_code, '')));
begin
  if v_uid is null then raise exception using errcode = '42501', message = 'not_authenticated'; end if;
  if not has_admin_role(v_uid, array['superadmin','admin','finance']) then raise exception using errcode = '42501', message = 'admin_permission_denied'; end if;
  if v_code !~ '^[A-Z0-9_-]{4,32}$' then raise exception using errcode = '23514', message = 'promo_code_format_invalid'; end if;
  if coalesce(p_credit_minor, 0) not between 100 and 100000 then raise exception using errcode = '23514', message = 'promo_credit_invalid'; end if;
  if not exists (select 1 from currencies c where c.code = upper(p_currency_code) and c.is_active) then raise exception using errcode = '23514', message = 'promo_currency_invalid'; end if;
  if p_max_redemptions is not null and p_max_redemptions < 1 then raise exception using errcode = '23514', message = 'promo_max_invalid'; end if;
  if p_valid_to is not null and p_valid_to <= coalesce(p_valid_from, now()) then raise exception using errcode = '23514', message = 'promo_dates_invalid'; end if;
  perform set_config('hb.audit_skip', 'on', true);
  if p_id is null then
    if exists (select 1 from ad_promo_codes c where lower(c.code::text) = lower(v_code)) then raise exception using errcode = '23514', message = 'promo_code_exists'; end if;
    v_id := gen_random_uuid();
    insert into ad_promo_codes (id, code, credit_minor, currency_code, max_redemptions, valid_from, valid_to, note, created_by, country_code)
    values (v_id, v_code, p_credit_minor, upper(p_currency_code), p_max_redemptions, coalesce(p_valid_from, now()), p_valid_to, left(nullif(trim(coalesce(p_note, '')), ''), 300), v_uid, (select u.country_code from user_profiles u where u.id = v_uid));
  else
    if not exists (select 1 from ad_promo_codes c where c.id = p_id) then raise exception using errcode = 'P0001', message = 'promo_code_not_found'; end if;
    if exists (select 1 from ad_promo_codes c where lower(c.code::text) = lower(v_code) and c.id <> p_id) then raise exception using errcode = '23514', message = 'promo_code_exists'; end if;
    if exists (select 1 from ad_promo_redemptions r where r.code_id = p_id) and exists (select 1 from ad_promo_codes c where c.id = p_id and (c.credit_minor <> p_credit_minor or c.currency_code <> upper(p_currency_code))) then
      raise exception using errcode = '23514', message = 'promo_code_locked';                  -- già usato: importo e valuta non cambiano
    end if;
    v_id := p_id;
    update ad_promo_codes set code = v_code, credit_minor = p_credit_minor, currency_code = upper(p_currency_code), max_redemptions = p_max_redemptions, valid_from = coalesce(p_valid_from, valid_from), valid_to = p_valid_to,
      note = left(nullif(trim(coalesce(p_note, '')), ''), 300), updated_at = now() where id = v_id;
  end if;
  perform hb_audit('promo_code.upsert', 'ad_promo_code', v_id::text, jsonb_build_object('code', v_code, 'credit_minor', p_credit_minor, 'currency_code', upper(p_currency_code), 'max_redemptions', p_max_redemptions, 'valid_to', p_valid_to));
  return v_id;
end $$;

create or replace function admin_promo_code_set_status(p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception using errcode = '42501', message = 'not_authenticated'; end if;
  if not has_admin_role(v_uid, array['superadmin','admin','finance']) then raise exception using errcode = '42501', message = 'admin_permission_denied'; end if;
  if p_status not in ('active','disabled') then raise exception using errcode = '23514', message = 'promo_status_invalid'; end if;
  if not exists (select 1 from ad_promo_codes c where c.id = p_id) then raise exception using errcode = 'P0001', message = 'promo_code_not_found'; end if;
  perform set_config('hb.audit_skip', 'on', true);
  update ad_promo_codes set status = p_status, updated_at = now() where id = p_id;
  perform hb_audit('promo_code.' || p_status, 'ad_promo_code', p_id::text, '{}'::jsonb);
end $$;

-- 4. Addebiti inserzioni dalla console -----------------------------------------------------------------------------------------------------------------------------------------------
create or replace function admin_ad_charges_list(p_status text default null, p_from timestamptz default null, p_to timestamptz default null, p_q text default null, p_limit integer default 50, p_offset integer default 0)
returns table (id uuid, account_id uuid, account_name text, account_kind text, owner_id uuid, owner_username citext, owner_name text, amount_minor bigint, currency_code char(3), reason text, status text, attempts integer,
               next_attempt_at timestamptz, failure_code text, failure_message text, receipt_url text, stripe_payment_intent_id text, period_from date, period_to date, succeeded_at timestamptz, created_at timestamptz, total bigint)
language sql stable security definer set search_path = public, extensions as $$
  with f as (
    select c.* from ad_charges c
    where has_admin_role(auth.uid(), array['superadmin','admin','finance'])
      and (nullif(p_status, '') is null or c.status = p_status)
      and (p_from is null or c.created_at >= p_from) and (p_to is null or c.created_at < p_to)
      and (nullif(trim(coalesce(p_q, '')), '') is null or c.stripe_payment_intent_id = trim(p_q) or c.id::text = trim(p_q)
           or exists (select 1 from ad_accounts a join user_profiles u on u.id = a.owner_id where a.id = c.account_id and (a.name ilike '%' || trim(p_q) || '%' or u.username ilike '%' || trim(p_q) || '%'))))
  select f.id, f.account_id, a.name, a.kind, a.owner_id, u.username, u.display_name, f.amount_minor, f.currency_code, f.reason, f.status, f.attempts, f.next_attempt_at, f.failure_code, f.failure_message, f.receipt_url,
         f.stripe_payment_intent_id, f.period_from, f.period_to, f.succeeded_at, f.created_at, (select count(*) from f)
  from f join ad_accounts a on a.id = f.account_id join user_profiles u on u.id = a.owner_id
  order by f.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200) offset greatest(coalesce(p_offset, 0), 0)
$$;

-- 5. Report ricavi ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
create or replace function admin_revenue_report(p_from date default (current_date - 29), p_to date default current_date, p_group text default 'day')
returns jsonb language plpgsql stable security definer set search_path = public, extensions as $$
declare v_from timestamptz := p_from::timestamptz; v_to timestamptz := (p_to + 1)::timestamptz; v_unit text := case when coalesce(p_group, 'day') in ('day','week','month') then p_group else 'day' end;
begin
  if not has_admin_access(auth.uid(), 'revenue', 'read') then raise exception using errcode = '42501', message = 'admin_permission_denied'; end if;
  if v_to <= v_from or v_to - v_from > interval '400 days' then raise exception using errcode = '23514', message = 'report_range_invalid'; end if;
  return jsonb_build_object(
    'from', p_from, 'to', p_to, 'group', v_unit,
    'ads', jsonb_build_object(
      'charged', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select c.currency_code, sum(c.amount_minor) v from ad_charges c where c.status = 'succeeded' and c.succeeded_at >= v_from and c.succeeded_at < v_to group by c.currency_code) x),
      'charges_count', (select count(*) from ad_charges c where c.status = 'succeeded' and c.succeeded_at >= v_from and c.succeeded_at < v_to),
      'credits_consumed', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select a.currency_code, -sum(k.amount_minor) v from ad_account_credits k join ad_accounts a on a.id = k.account_id where k.kind = 'consume' and k.created_at >= v_from and k.created_at < v_to group by a.currency_code) x),
      'credits_granted', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select a.currency_code, sum(k.amount_minor) v from ad_account_credits k join ad_accounts a on a.id = k.account_id where k.kind in ('welcome','grant') and k.created_at >= v_from and k.created_at < v_to group by a.currency_code) x),
      'outstanding', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select c.currency_code, sum(c.amount_minor) v from ad_charges c where c.status in ('pending','processing') group by c.currency_code) x),
      'failed', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select c.currency_code, sum(c.amount_minor) v from ad_charges c where c.status = 'failed' group by c.currency_code) x),
      'unbilled', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select a.currency_code, sum(a.unbilled_micro / 1000000) v from ad_accounts a where a.status <> 'closed' group by a.currency_code) x),
      'active_accounts', (select count(distinct c.account_id) from ad_campaigns c where c.status = 'active'), 'suspended_accounts', (select count(*) from ad_accounts a where a.billing_status = 'suspended'),
      'spend_period', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select a.currency_code, sum(e.cost_micro) / 1000000 v from ad_events e join ad_accounts a on a.id = e.account_id where e.created_at >= v_from and e.created_at < v_to group by a.currency_code) x),
      'by_country', (select coalesce(jsonb_agg(jsonb_build_object('country_code', x.country_code, 'currency_code', x.currency_code, 'charged', x.v) order by x.v desc), '[]'::jsonb) from (select c.country_code, c.currency_code, sum(c.amount_minor) v from ad_charges c where c.status = 'succeeded' and c.succeeded_at >= v_from and c.succeeded_at < v_to group by 1, 2) x),
      'top_advertisers', (select coalesce(jsonb_agg(jsonb_build_object('account_id', x.account_id, 'name', x.name, 'kind', x.kind, 'currency_code', x.currency_code, 'charged', x.v, 'charges', x.n) order by x.v desc), '[]'::jsonb)
                          from (select a.id account_id, a.name, a.kind, c.currency_code, sum(c.amount_minor) v, count(*) n from ad_charges c join ad_accounts a on a.id = c.account_id where c.status = 'succeeded' and c.succeeded_at >= v_from and c.succeeded_at < v_to group by a.id, a.name, a.kind, c.currency_code order by v desc limit 10) x),
      'series', (select coalesce(jsonb_agg(jsonb_build_object('period', x.period, 'currency_code', x.currency_code, 'charged', x.v, 'charges', x.n) order by x.period), '[]'::jsonb)
                 from (select date_trunc(v_unit, c.succeeded_at)::date period, c.currency_code, sum(c.amount_minor) v, count(*) n from ad_charges c where c.status = 'succeeded' and c.succeeded_at >= v_from and c.succeeded_at < v_to group by 1, 2) x)),
    'marketplace', jsonb_build_object(
      'gmv', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select o.currency_code, sum(o.total_minor) v from orders o where o.kind = 'listing' and o.paid_at >= v_from and o.paid_at < v_to and o.status in ('paid','shipped','completed','refund_requested','refunded','disputed') group by o.currency_code) x),
      'orders', (select count(*) from orders o where o.kind = 'listing' and o.paid_at >= v_from and o.paid_at < v_to),
      'refunded', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select o.currency_code, sum(o.total_minor) v from orders o where o.kind = 'listing' and o.refunded_at >= v_from and o.refunded_at < v_to group by o.currency_code) x),
      'platform_fees', (select coalesce(sum(o.platform_fee_minor), 0) from orders o where o.paid_at >= v_from and o.paid_at < v_to),
      'series', (select coalesce(jsonb_agg(jsonb_build_object('period', x.period, 'currency_code', x.currency_code, 'gmv', x.v, 'orders', x.n) order by x.period), '[]'::jsonb)
                 from (select date_trunc(v_unit, o.paid_at)::date period, o.currency_code, sum(o.total_minor) v, count(*) n from orders o where o.kind = 'listing' and o.paid_at >= v_from and o.paid_at < v_to group by 1, 2) x)),
    'events', jsonb_build_object(
      'gmv', (select coalesce(jsonb_object_agg(x.currency_code, x.v), '{}'::jsonb) from (select o.currency_code, sum(o.total_minor) v from orders o where o.kind = 'event_ticket' and o.paid_at >= v_from and o.paid_at < v_to and o.status in ('paid','completed') group by o.currency_code) x),
      'tickets', (select count(*) from orders o where o.kind = 'event_ticket' and o.paid_at >= v_from and o.paid_at < v_to and o.status in ('paid','completed'))),
    'promo', jsonb_build_object('codes_active', (select count(*) from ad_promo_codes c where c.status = 'active' and (c.valid_to is null or c.valid_to >= now())),
                                'redemptions', (select count(*) from ad_promo_redemptions r where r.created_at >= v_from and r.created_at < v_to)));
end $$;

-- 6. Permessi --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
revoke all on function admin_listings_queue(text, text, uuid, text, integer, integer), admin_listing_review(uuid, text, text), admin_set_category_review(uuid, boolean), admin_listings_stats(),
  admin_orders_list(text, text, text, timestamptz, timestamptz, integer, integer), admin_orders_stats(), admin_order_refund(uuid, text), admin_order_note(uuid, text),
  hb_ad_credit_apply(uuid, bigint, text, uuid, boolean), redeem_ad_promo_code(uuid, text), admin_promo_codes_list(), admin_promo_code_upsert(uuid, text, bigint, text, integer, timestamptz, timestamptz, text), admin_promo_code_set_status(uuid, text),
  admin_ad_charges_list(text, timestamptz, timestamptz, text, integer, integer), admin_revenue_report(date, date, text), trg_listings_review_gate(), trg_listings_review_notify() from public, anon;
revoke all on function hb_ad_credit_apply(uuid, bigint, text, uuid, boolean), trg_listings_review_gate(), trg_listings_review_notify() from authenticated;
grant execute on function admin_listings_queue(text, text, uuid, text, integer, integer), admin_listing_review(uuid, text, text), admin_set_category_review(uuid, boolean), admin_listings_stats(),
  admin_orders_list(text, text, text, timestamptz, timestamptz, integer, integer), admin_orders_stats(), admin_order_refund(uuid, text), admin_order_note(uuid, text),
  redeem_ad_promo_code(uuid, text), admin_promo_codes_list(), admin_promo_code_upsert(uuid, text, bigint, text, integer, timestamptz, timestamptz, text), admin_promo_code_set_status(uuid, text),
  admin_ad_charges_list(text, timestamptz, timestamptz, text, integer, integer), admin_revenue_report(date, date, text) to authenticated;

notify pgrst, 'reload schema';

-- 7. Verifica (attesi: colonne 6 / categorie con revisione 1 / tabelle 2 / rpc 16 / trigger 2 / policy scritture 0)
select 'colonne' as what, count(*) from information_schema.columns where (table_name = 'categories' and column_name = 'requires_review') or (table_name = 'listings' and column_name in ('review_status','review_note','reviewed_by','reviewed_at','review_requested_at'))
union all select 'categorie con revisione', count(*) from categories where requires_review
union all select 'tabelle', count(*) from information_schema.tables where table_schema = 'public' and table_name in ('ad_promo_codes','ad_promo_redemptions')
union all select 'rpc', count(*) from pg_proc where proname in ('admin_listings_queue','admin_listing_review','admin_set_category_review','admin_listings_stats','admin_orders_list','admin_orders_stats','admin_order_refund','admin_order_note',
  'hb_ad_credit_apply','redeem_ad_promo_code','admin_promo_codes_list','admin_promo_code_upsert','admin_promo_code_set_status','admin_ad_charges_list','admin_revenue_report','my_listings')
union all select 'trigger', count(*) from pg_trigger where tgname in ('zz_listings_review_gate','zz_listings_review_notify')
union all select 'policy scritture', count(*) from pg_policies where tablename in ('ad_promo_codes','ad_promo_redemptions') and cmd <> 'SELECT';