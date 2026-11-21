# P03a — Come mettere e deployare lo schema (hb-dev)

## 1. File nel progetto Dreamflow (via Git, 5 minuti)
Nel clone locale del repo `hb-social-2`:

```
lib/supabase/supabase_tables.sql     ← sostituisce il file generato
lib/supabase/supabase_policies.sql   ← sostituisce il file generato
lib/supabase/storage.sql             ← nuovo
lib/supabase/seed_reference.sql      ← nuovo
docs/SCHEMA_REVIEW.md                ← nuovo
test/00_supabase_stub.sql            ← solo per test locali, mai deployare
test/10_rls_tests.sql                ← test comportamentali RLS (58 check)
test/verify_deploy.sql               ← query di verifica da lanciare nel SQL editor dopo il deploy
```

Non toccare `lib/supabase/supabase_config.dart` (è corretto: solo URL e anon key).
Commit `P03a: foundation schema, policies, storage, reference seed` → push → in Dreamflow Source Control → **Pull**.

## 2. Deploy, nell'ordine, dal pannello Supabase → Schema Deployment
1. `supabase_tables.sql` → Deploy Schema Changes. Attendi "success".
2. `supabase_policies.sql` → Deploy.
3. `storage.sql` → Deploy.
4. `seed_reference.sql` → Deploy.

Se il pannello mostra solo i tre file standard (tables, policies, pending_migrations): incolla il contenuto di `storage.sql` seguito da `seed_reference.sql` dentro `lib/supabase/pending_migrations.sql` e deploya quello come passo 3.

Se un deploy fallisce: copia l'errore completo e mandamelo. I file sono idempotenti: dopo la correzione si rilancia lo stesso file, non serve ripulire nulla.

## 3. Verifica (Supabase dashboard → SQL editor)
Incolla `test/verify_deploy.sql` ed esegui. Attesi: la prima tabella tutta "ok" (52 tabelle, ≥141 policy, 10 bucket, 6 paesi, 20 regioni, 36 specie, trigger su auth.users), le altre cinque query vuote.

## 4. Primo utente reale (serve per Sample Data)
Authentication → Users → "Add user" → email + password (il tuo). Poi in SQL editor:

```sql
select id, username, display_name, country_code, locale, currency_code from user_profiles;
```
Deve esserci la riga creata dal trigger. Per renderti superadmin (una sola volta, da SQL editor):

```sql
insert into admin_users (user_id, role_id)
select u.id, r.id from auth.users u, admin_roles r
where u.email = 'LA_TUA_EMAIL' and r.name = 'superadmin';
```

## 5. Sample Data di Dreamflow
Pannello Supabase → Sample Data → inserisci la tua email → Create Sample Data. Genera righe nelle tabelle rispettando lo schema. Dopo, in SQL editor:

```sql
select 'posts', count(*) from posts union all select 'groups', count(*) from groups
union all select 'listings', count(*) from listings union all select 'events', count(*) from events;
```

Poi P03b (Dart): collegamento auth email, repository Supabase al posto degli Empty*, e la Home che legge i post reali.
