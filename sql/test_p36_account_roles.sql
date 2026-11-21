-- ============================================================================
-- HB Social 2.0 — test P36: ruoli dell'account pubblicitario (criterio della roadmap: "pgTAP on account roles")
-- Da lanciare nel SQL editor di hb-dev DOPO pending_migrations_p35.sql e pending_migrations_p36.sql. Un solo blocco DO (il SQL editor può cambiare connessione tra statement).
-- Usa quattro utenti attivi esistenti (owner = il più vecchio; advertiser, analyst e non membro scelti tra i NON admin, altrimenti il bypass admin falserebbe i divieti); simula le sessioni con SET ROLE + request.jwt.claims come PostgREST.
-- ESITO: termina SEMPRE con un'eccezione che contiene il rapporto (così i dati di prova vengono annullati):
--   "P36 OK — n/n asserzioni superate"   → tutto bene      "P36 FAIL — …"   → il rapporto elenca le asserzioni fallite
-- ============================================================================
do $$
declare u_owner uuid; u_adv uuid; u_an uuid; u_out uuid; acc uuid; cmp uuid; cr uuid; aset uuid; ad uuid; n integer; results text[] := '{}'; fails integer := 0; t text;
begin
  if to_regprocedure('public.create_ad_account(text, uuid)') is null then raise exception 'pending_migrations_p36.sql non ancora eseguita: lanciarla prima del test'; end if;
  select id into u_owner from public.user_profiles where status = 'active' order by created_at limit 1;
  select id into u_adv from public.user_profiles p where p.status = 'active' and p.id <> u_owner and not exists (select 1 from public.admin_users a where a.user_id = p.id) order by p.created_at limit 1;
  select id into u_an from public.user_profiles p where p.status = 'active' and p.id not in (u_owner, u_adv) and not exists (select 1 from public.admin_users a where a.user_id = p.id) order by p.created_at limit 1;
  select id into u_out from public.user_profiles p where p.status = 'active' and p.id not in (u_owner, u_adv, u_an) and not exists (select 1 from public.admin_users a where a.user_id = p.id) order by p.created_at limit 1;
  if u_out is null then raise exception 'servono almeno quattro utenti attivi'; end if;
  -- carta di prova del proprietario (fatturazione a soglia: serve una carta attiva per inviare la campagna; annullata a fine test)
  insert into public.payment_methods (user_id, stripe_payment_method_id, type, brand, last4, exp_month, exp_year, is_default)
  values (u_owner, 'pm_test_p36', 'card', 'visa', '4242', 12, 2030, not exists (select 1 from public.payment_methods m where m.user_id = u_owner and m.is_default and m.status <> 'removed'));

  -- OWNER: crea account, aggiunge advertiser e analyst
  perform set_config('request.jwt.claims', json_build_object('sub', u_owner, 'role', 'authenticated')::text, true); set local role authenticated;
  acc := public.create_ad_account('Account test P36', null);
  perform public.add_ad_account_member(acc, u_adv, 'advertiser');
  perform public.add_ad_account_member(acc, u_an, 'analyst');
  select count(*) into n from public.ad_account_members where account_id = acc;
  results := array_append(results, (case when n = 3 then '[ok] ' else '[FAIL] ' end || 'owner crea account e aggiunge 2 membri (' || n || ')')::text); if n <> 3 then fails := fails + 1; end if;

  -- ADVERTISER: crea campagna, gruppo, creatività, inserzione e la invia in revisione; NON può aggiungere membri né chiudere l'account
  perform set_config('request.jwt.claims', json_build_object('sub', u_adv, 'role', 'authenticated')::text, true); set local role authenticated;
  cmp := public.upsert_ad_campaign(acc, null, 'Campagna test', 'awareness', now(), null, 2000, 500);
  aset := public.upsert_ad_set(cmp, null, 'Gruppo test', null, array['feed'], 'cpm', 200, 300, 3, 'standard', null, null);
  cr := public.upsert_ad_creative(acc, null, 'image', 'Titolo test', 'Corpo test', 'learn_more', 'url', null, 'https://example.com/test', jsonb_build_array(jsonb_build_object('path', u_adv::text || '/test.jpg', 'kind', 'image')));
  ad := public.upsert_ad(aset, null, cr, 'Inserzione test', 'active');
  t := public.set_ad_campaign_status(cmp, 'in_review');
  results := array_append(results, (case when t = 'in_review' then '[ok] ' else '[FAIL] ' end || 'advertiser crea e invia la campagna in revisione (' || t || ')')::text); if t <> 'in_review' then fails := fails + 1; end if;
  begin perform public.add_ad_account_member(acc, u_out, 'analyst'); results := array_append(results, '[FAIL] advertiser ha aggiunto un membro'::text); fails := fails + 1;
  exception when others then if sqlstate = '42501' then results := array_append(results, '[ok] advertiser non aggiunge membri'::text); else results := array_append(results, ('[FAIL] errore inatteso membri: ' || sqlstate)::text); fails := fails + 1; end if; end;
  begin perform public.update_ad_account(acc, null, null, 'closed'); results := array_append(results, '[FAIL] advertiser ha chiuso l''account'::text); fails := fails + 1;
  exception when others then if sqlstate = '42501' then results := array_append(results, '[ok] advertiser non chiude l''account'::text); else results := array_append(results, ('[FAIL] errore inatteso chiusura: ' || sqlstate)::text); fails := fails + 1; end if; end;

  -- ANALYST: legge account, campagne e report; NON crea campagne né creatività
  perform set_config('request.jwt.claims', json_build_object('sub', u_an, 'role', 'authenticated')::text, true); set local role authenticated;
  select count(*) into n from public.ad_campaigns where account_id = acc;
  results := array_append(results, (case when n = 1 then '[ok] ' else '[FAIL] ' end || 'analyst legge le campagne (' || n || ')')::text); if n <> 1 then fails := fails + 1; end if;
  results := array_append(results, (case when public.ad_campaign_report(cmp) is not null then '[ok] ' else '[FAIL] ' end || 'analyst legge il report')::text); if public.ad_campaign_report(cmp) is null then fails := fails + 1; end if;
  begin perform public.upsert_ad_campaign(acc, null, 'Non permessa', 'awareness', now(), null, 1000, null); results := array_append(results, '[FAIL] analyst ha creato una campagna'::text); fails := fails + 1;
  exception when others then if sqlstate = '42501' then results := array_append(results, '[ok] analyst non crea campagne'::text); else results := array_append(results, ('[FAIL] errore inatteso campagna: ' || sqlstate)::text); fails := fails + 1; end if; end;
  begin t := public.set_ad_campaign_status(cmp, 'draft'); results := array_append(results, '[FAIL] analyst ha cambiato stato'::text); fails := fails + 1;
  exception when others then if sqlstate = '42501' then results := array_append(results, '[ok] analyst non cambia lo stato'::text); else results := array_append(results, ('[FAIL] errore inatteso stato: ' || sqlstate)::text); fails := fails + 1; end if; end;

  -- NON MEMBRO: non vede nulla e non può agire; il tracciamento di una sua impression è invece consentito (campagna non attiva → ignorato ma senza errore)
  perform set_config('request.jwt.claims', json_build_object('sub', u_out, 'role', 'authenticated')::text, true); set local role authenticated;
  select count(*) into n from public.ad_accounts where id = acc;
  results := array_append(results, (case when n = 0 then '[ok] ' else '[FAIL] ' end || 'non membro non vede l''account (' || n || ')')::text); if n <> 0 then fails := fails + 1; end if;
  select count(*) into n from public.ad_campaigns where account_id = acc;
  results := array_append(results, (case when n = 0 then '[ok] ' else '[FAIL] ' end || 'non membro non vede le campagne (' || n || ')')::text); if n <> 0 then fails := fails + 1; end if;
  results := array_append(results, (case when public.ad_campaign_report(cmp) is null then '[ok] ' else '[FAIL] ' end || 'non membro non legge il report')::text); if public.ad_campaign_report(cmp) is not null then fails := fails + 1; end if;
  begin perform public.upsert_ad_set(cmp, null, 'Intruso', null, array['feed'], 'cpm', 200, null, 3, 'standard', null, null); results := array_append(results, '[FAIL] non membro ha creato un gruppo'::text); fails := fails + 1;
  exception when others then if sqlstate = '42501' then results := array_append(results, '[ok] non membro non crea gruppi'::text); else results := array_append(results, ('[FAIL] errore inatteso gruppo: ' || sqlstate)::text); fails := fails + 1; end if; end;
  results := array_append(results, (case when (public.record_ad_event(ad, 'impression', 'feed', null) ->> 'ignored') = 'campaign_inactive' then '[ok] ' else '[FAIL] ' end || 'tracciamento su campagna in revisione ignorato senza errore')::text);

  -- OWNER: declassa l''advertiser ad analyst → non può più creare; rimuove l''analyst; il proprietario non è rimovibile
  perform set_config('request.jwt.claims', json_build_object('sub', u_owner, 'role', 'authenticated')::text, true); set local role authenticated;
  perform public.set_ad_account_member_role(acc, u_adv, 'analyst');
  perform public.remove_ad_account_member(acc, u_an);
  begin perform public.remove_ad_account_member(acc, u_owner); results := array_append(results, '[FAIL] proprietario rimosso'::text); fails := fails + 1;
  exception when others then if sqlstate = '23514' then results := array_append(results, '[ok] proprietario non rimovibile'::text); else results := array_append(results, ('[FAIL] errore inatteso owner: ' || sqlstate)::text); fails := fails + 1; end if; end;
  perform set_config('request.jwt.claims', json_build_object('sub', u_adv, 'role', 'authenticated')::text, true); set local role authenticated;
  begin perform public.upsert_ad_campaign(acc, null, 'Dopo declassamento', 'awareness', now(), null, 1000, null); results := array_append(results, '[FAIL] ex advertiser crea ancora'::text); fails := fails + 1;
  exception when others then if sqlstate = '42501' then results := array_append(results, '[ok] ex advertiser (ora analyst) non crea più'::text); else results := array_append(results, ('[FAIL] errore inatteso declassamento: ' || sqlstate)::text); fails := fails + 1; end if; end;
  reset role;

  if fails = 0 then
    raise exception 'P36 OK — %/% asserzioni superate (dati di prova annullati). %', array_length(results, 1), array_length(results, 1), array_to_string(results, ' | ');
  else
    raise exception 'P36 FAIL — % su % asserzioni fallite. %', fails, array_length(results, 1), array_to_string(results, ' | ');
  end if;
end $$;
