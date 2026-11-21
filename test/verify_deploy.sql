-- Run in the Supabase SQL editor (hb-dev) AFTER deploying the four files.
-- Every row of the first query should read "ok". The other queries must return zero rows.

-- 1. Counts
select 'tables' as what, count(*)::text as value, case when count(*) = 52 then 'ok' else 'CHECK' end as status
  from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE'
union all
select 'policies', count(*)::text, case when count(*) >= 141 then 'ok' else 'CHECK' end from pg_policies where schemaname = 'public'
union all
select 'triggers', count(*)::text, case when count(*) >= 59 then 'ok' else 'CHECK' end from information_schema.triggers where trigger_schema in ('public','auth')
union all
select 'helper functions', count(*)::text, case when count(*) >= 27 then 'ok' else 'CHECK' end
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.prosecdef
union all
select 'buckets', count(*)::text, case when count(*) = 10 then 'ok' else 'CHECK' end from storage.buckets
union all
select 'countries', count(*)::text, case when count(*) = 6 then 'ok' else 'CHECK' end from countries
union all
select 'regions IT', count(*)::text, case when count(*) = 20 then 'ok' else 'CHECK' end from regions where country_code = 'IT'
union all
select 'species', count(*)::text, case when count(*) = 36 then 'ok' else 'CHECK' end from species
union all
select 'admin roles', count(*)::text, case when count(*) = 6 then 'ok' else 'CHECK' end from admin_roles
union all
select 'auth trigger', count(*)::text, case when count(*) = 1 then 'ok' else 'CHECK' end
  from information_schema.triggers where event_object_schema = 'auth' and event_object_table = 'users' and trigger_name = 'on_auth_user_created';

-- 2. Tables WITHOUT row level security (must be empty)
select c.relname as table_without_rls
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;

-- 3. Tables without any policy (must be empty)
select t.tablename as table_without_policies
from pg_tables t
where t.schemaname = 'public'
  and not exists (select 1 from pg_policies p where p.schemaname = 'public' and p.tablename = t.tablename);

-- 4. Policies that query their own table directly (must be empty — recursion risk)
select p.tablename, p.policyname
from pg_policies p
where p.schemaname = 'public'
  and (coalesce(p.qual, '') || ' ' || coalesce(p.with_check, '')) ~* ('\mfrom\s+' || p.tablename || '\M');

-- 5. Security definer functions without a fixed search_path (must be empty)
select p.proname
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.prosecdef
  and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%');

-- 6. Money columns that are not bigint (must be empty)
select table_name, column_name, data_type
from information_schema.columns
where table_schema = 'public' and column_name like '%\_minor' and data_type <> 'bigint';
