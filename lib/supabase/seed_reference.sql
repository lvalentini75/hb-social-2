-- ============================================================================
-- HB Social 2.0 — Reference data (P03 / part a2)
-- Product taxonomy and public reference data only: currencies, countries, Italian regions (ISTAT),
-- marketplace categories, admin roles + permission matrix, feature flags, country policies,
-- huntable species (Italy, art. 18 L. 157/92 list — to be validated with the hunting-data editor in P24).
-- NO users, posts, groups or any user-generated content: sample content comes from Dreamflow Sample Data.
-- Idempotent: every insert is "on conflict do nothing" or an upsert.
-- Deploy last, after supabase_tables.sql, supabase_policies.sql and storage.sql.
-- ============================================================================

-- 1. Currencies -----------------------------------------------------------------
insert into currencies (code, name, symbol, minor_units) values
  ('EUR', 'Euro', '€', 2),
  ('GBP', 'Pound sterling', '£', 2),
  ('CHF', 'Swiss franc', 'CHF', 2),
  ('USD', 'US dollar', '$', 2)
on conflict (code) do nothing;

-- 2. Countries (launch IT; FR/ES/DE/AT/GB designed in from day one) -------------
insert into countries (code, name, default_currency, default_locale, unit_system, is_active, sort_order) values
  ('IT', 'Italia',         'EUR', 'it', 'metric',   true, 1),
  ('FR', 'France',         'EUR', 'fr', 'metric',   true, 2),
  ('ES', 'España',         'EUR', 'es', 'metric',   true, 3),
  ('DE', 'Deutschland',    'EUR', 'de', 'metric',   true, 4),
  ('AT', 'Österreich',     'EUR', 'de', 'metric',   true, 5),
  ('GB', 'United Kingdom', 'GBP', 'en', 'imperial', true, 6)
on conflict (code) do nothing;

-- 3. Italian regions (ISTAT codes) ------------------------------------------------
insert into regions (country_code, code, name, kind, istat_code, sort_order) values
  ('IT', 'PIE', 'Piemonte',              'region', '01', 1),
  ('IT', 'VDA', 'Valle d''Aosta',        'region', '02', 2),
  ('IT', 'LOM', 'Lombardia',             'region', '03', 3),
  ('IT', 'TAA', 'Trentino-Alto Adige',   'region', '04', 4),
  ('IT', 'VEN', 'Veneto',                'region', '05', 5),
  ('IT', 'FVG', 'Friuli-Venezia Giulia', 'region', '06', 6),
  ('IT', 'LIG', 'Liguria',               'region', '07', 7),
  ('IT', 'EMR', 'Emilia-Romagna',        'region', '08', 8),
  ('IT', 'TOS', 'Toscana',               'region', '09', 9),
  ('IT', 'UMB', 'Umbria',                'region', '10', 10),
  ('IT', 'MAR', 'Marche',                'region', '11', 11),
  ('IT', 'LAZ', 'Lazio',                 'region', '12', 12),
  ('IT', 'ABR', 'Abruzzo',               'region', '13', 13),
  ('IT', 'MOL', 'Molise',                'region', '14', 14),
  ('IT', 'CAM', 'Campania',              'region', '15', 15),
  ('IT', 'PUG', 'Puglia',                'region', '16', 16),
  ('IT', 'BAS', 'Basilicata',            'region', '17', 17),
  ('IT', 'CAL', 'Calabria',              'region', '18', 18),
  ('IT', 'SIC', 'Sicilia',               'region', '19', 19),
  ('IT', 'SAR', 'Sardegna',              'region', '20', 20)
on conflict (country_code, code) do nothing;

-- 4. Marketplace categories (closed set; firearms & ammunition is a mediated showcase) ----
insert into categories (kind, slug, name_key, is_restricted, sort_order) values
  ('marketplace', 'optics',        'marketplace.category.optics',        false, 1),
  ('marketplace', 'apparel',       'marketplace.category.apparel',       false, 2),
  ('marketplace', 'accessories',   'marketplace.category.accessories',   false, 3),
  ('marketplace', 'dogs',          'marketplace.category.dogs',          false, 4),
  ('marketplace', 'vehicles',      'marketplace.category.vehicles',      false, 5),
  ('marketplace', 'firearms_ammo', 'marketplace.category.firearms_ammo', true,  6),
  ('marketplace', 'services',      'marketplace.category.services',      false, 7),
  ('marketplace', 'other',         'marketplace.category.other',         false, 8)
on conflict (kind, slug) do nothing;

-- 5. Admin roles and permission matrix (mirrors the console matrix; read by the console from P40) ----
insert into admin_roles (name, description) values
  ('superadmin',          'Full access, including payments and security'),
  ('admin',               'Everything except payments and security'),
  ('moderator',           'Content, communities, reports, rules, badges, support'),
  ('ads_reviewer',        'Creative review and advertiser accounts'),
  ('finance',             'Marketplace, orders, revenue'),
  ('hunting_data_editor', 'Hunting calendars, units and species')
on conflict (name) do nothing;

with modules(module) as (
  values ('dashboard'),('users'),('badges'),('roles'),('content'),('communities'),('reports'),('approvals'),('rules'),
         ('listings'),('orders'),('payments'),('plans'),('ad-review'),('advertisers'),('revenue'),('calendars'),('maps'),
         ('plugins'),('localization'),('system-notifications'),('security'),('system'),('support')
),
grants(role_name, module, access) as (
  -- superadmin: everything
  select 'superadmin', module, 'write' from modules
  union all
  -- admin: everything except payments and security
  select 'admin', module, case when module in ('payments','security') then 'none' else 'write' end from modules
  union all
  -- moderator
  select 'moderator', module,
         case when module in ('content','communities','reports','rules','badges','support') then 'write'
              when module in ('dashboard','users') then 'read' else 'none' end from modules
  union all
  -- ads reviewer
  select 'ads_reviewer', module,
         case when module in ('ad-review','advertisers') then 'write'
              when module in ('dashboard','approvals') then 'read' else 'none' end from modules
  union all
  -- finance
  select 'finance', module,
         case when module in ('listings','orders','revenue') then 'write'
              when module in ('dashboard','payments','plans') then 'read' else 'none' end from modules
  union all
  -- hunting data editor
  select 'hunting_data_editor', module,
         case when module in ('calendars','maps') then 'write'
              when module = 'dashboard' then 'read' else 'none' end from modules
)
insert into admin_role_permissions (role_id, module, access)
select r.id, g.module, g.access
from grants g join admin_roles r on r.name = g.role_name
on conflict (role_id, module) do update set access = excluded.access;

-- 6. Feature flags (module × country; null country = everywhere) ------------------
insert into feature_flags (module, country_code, is_enabled, rollout_percentage, description) values
  ('marketplace',                  null, true,  100, 'Marketplace listings'),
  ('marketplace_firearms_mediated','IT', true,  100, 'Firearms & ammunition as mediated showcase (verified gun shops only)'),
  ('events_paid',                  null, false, 100, 'Paid events with Stripe (P21/P34)'),
  ('ads',                          null, false, 100, 'Ads Manager and sponsored placements (P36–P39)'),
  ('reels',                        null, false, 0,   'Short vertical video feed (P45)'),
  ('live',                         null, false, 0,   'Live streaming and calls (P46)'),
  ('auto_translation',             null, false, 100, 'Automatic translation of posts and messages (P48)')
on conflict (module, coalesce(country_code, '**')) do nothing;

-- 7. Country policies (defaults pending legal review in P33) ----------------------
insert into country_policies (country_code, policy_type, policy_data) values
  ('IT', 'minimum_age',         '{"age": 18}'),
  ('IT', 'firearms_marketplace','{"mode": "mediated_showcase", "requires_badge": "hunter", "contact_via": "gun_shop", "in_app_payment": false}'),
  ('IT', 'sensitive_content',   '{"blur_harvest_photos": true, "allow_harvest_photos": true}'),
  ('FR', 'minimum_age',         '{"age": 18}'),
  ('FR', 'firearms_marketplace','{"mode": "mediated_showcase", "requires_badge": "hunter", "contact_via": "gun_shop", "in_app_payment": false}'),
  ('FR', 'sensitive_content',   '{"blur_harvest_photos": true, "allow_harvest_photos": true}'),
  ('ES', 'minimum_age',         '{"age": 18}'),
  ('ES', 'firearms_marketplace','{"mode": "mediated_showcase", "requires_badge": "hunter", "contact_via": "gun_shop", "in_app_payment": false}'),
  ('ES', 'sensitive_content',   '{"blur_harvest_photos": true, "allow_harvest_photos": true}'),
  ('DE', 'minimum_age',         '{"age": 18}'),
  ('DE', 'firearms_marketplace','{"mode": "disabled", "note": "pending legal review"}'),
  ('DE', 'sensitive_content',   '{"blur_harvest_photos": true, "allow_harvest_photos": true}'),
  ('AT', 'minimum_age',         '{"age": 18}'),
  ('AT', 'firearms_marketplace','{"mode": "disabled", "note": "pending legal review"}'),
  ('AT', 'sensitive_content',   '{"blur_harvest_photos": true, "allow_harvest_photos": true}'),
  ('GB', 'minimum_age',         '{"age": 18}'),
  ('GB', 'firearms_marketplace','{"mode": "disabled", "note": "pending legal review"}'),
  ('GB', 'sensitive_content',   '{"blur_harvest_photos": true, "allow_harvest_photos": true}')
on conflict (country_code, policy_type) do nothing;

-- 8. Species — huntable species in Italy (art. 18 L. 157/92; validate in P24) ------
insert into species (scientific_name, category) values
  ('Scolopax rusticola',     'migratory'),
  ('Turdus philomelos',      'migratory'),
  ('Turdus pilaris',         'migratory'),
  ('Turdus iliacus',         'migratory'),
  ('Turdus merula',          'migratory'),
  ('Alauda arvensis',        'migratory'),
  ('Coturnix coturnix',      'migratory'),
  ('Columba palumbus',       'migratory'),
  ('Streptopelia turtur',    'migratory'),
  ('Phasianus colchicus',    'small_game'),
  ('Perdix perdix',          'small_game'),
  ('Alectoris rufa',         'small_game'),
  ('Alectoris graeca',       'small_game'),
  ('Lepus europaeus',        'small_game'),
  ('Oryctolagus cuniculus',  'small_game'),
  ('Sylvilagus floridanus',  'small_game'),
  ('Anas platyrhynchos',     'waterfowl'),
  ('Anas crecca',            'waterfowl'),
  ('Anas acuta',             'waterfowl'),
  ('Mareca penelope',        'waterfowl'),
  ('Spatula clypeata',       'waterfowl'),
  ('Spatula querquedula',    'waterfowl'),
  ('Aythya ferina',          'waterfowl'),
  ('Gallinago gallinago',    'waterfowl'),
  ('Fulica atra',            'waterfowl'),
  ('Gallinula chloropus',    'waterfowl'),
  ('Vulpes vulpes',          'predator'),
  ('Pica pica',              'other'),
  ('Corvus cornix',          'other'),
  ('Garrulus glandarius',    'other'),
  ('Sus scrofa',             'ungulate'),
  ('Capreolus capreolus',    'ungulate'),
  ('Cervus elaphus',         'ungulate'),
  ('Dama dama',              'ungulate'),
  ('Ovis gmelini musimon',   'ungulate'),
  ('Rupicapra rupicapra',    'ungulate')
on conflict (scientific_name) do nothing;

with names(scientific_name, it, en, fr, es, de) as (values
  ('Scolopax rusticola',    'Beccaccia',          'Eurasian woodcock',      'Bécasse des bois',          'Becada',                 'Waldschnepfe'),
  ('Turdus philomelos',     'Tordo bottaccio',    'Song thrush',            'Grive musicienne',          'Zorzal común',           'Singdrossel'),
  ('Turdus pilaris',        'Cesena',             'Fieldfare',              'Grive litorne',             'Zorzal real',            'Wacholderdrossel'),
  ('Turdus iliacus',        'Tordo sassello',     'Redwing',                'Grive mauvis',              'Zorzal alirrojo',        'Rotdrossel'),
  ('Turdus merula',         'Merlo',              'Common blackbird',       'Merle noir',                'Mirlo común',            'Amsel'),
  ('Alauda arvensis',       'Allodola',           'Eurasian skylark',       'Alouette des champs',       'Alondra común',          'Feldlerche'),
  ('Coturnix coturnix',     'Quaglia',            'Common quail',           'Caille des blés',           'Codorniz común',         'Wachtel'),
  ('Columba palumbus',      'Colombaccio',        'Common wood pigeon',     'Pigeon ramier',             'Paloma torcaz',          'Ringeltaube'),
  ('Streptopelia turtur',   'Tortora',            'European turtle dove',   'Tourterelle des bois',      'Tórtola europea',        'Turteltaube'),
  ('Phasianus colchicus',   'Fagiano',            'Common pheasant',        'Faisan de Colchide',        'Faisán común',           'Fasan'),
  ('Perdix perdix',         'Starna',             'Grey partridge',         'Perdrix grise',             'Perdiz pardilla',        'Rebhuhn'),
  ('Alectoris rufa',        'Pernice rossa',      'Red-legged partridge',   'Perdrix rouge',             'Perdiz roja',            'Rothuhn'),
  ('Alectoris graeca',      'Coturnice',          'Rock partridge',         'Perdrix bartavelle',        'Perdiz griega',          'Steinhuhn'),
  ('Lepus europaeus',       'Lepre comune',       'European hare',          'Lièvre d''Europe',          'Liebre europea',         'Feldhase'),
  ('Oryctolagus cuniculus', 'Coniglio selvatico', 'European rabbit',        'Lapin de garenne',          'Conejo europeo',         'Wildkaninchen'),
  ('Sylvilagus floridanus', 'Minilepre',          'Eastern cottontail',     'Lapin de Floride',          'Conejo de Florida',      'Florida-Waldkaninchen'),
  ('Anas platyrhynchos',    'Germano reale',      'Mallard',                'Canard colvert',            'Ánade azulón',           'Stockente'),
  ('Anas crecca',           'Alzavola',           'Eurasian teal',          'Sarcelle d''hiver',         'Cerceta común',          'Krickente'),
  ('Anas acuta',            'Codone',             'Northern pintail',       'Canard pilet',              'Ánade rabudo',           'Spießente'),
  ('Mareca penelope',       'Fischione',          'Eurasian wigeon',        'Canard siffleur',           'Silbón europeo',         'Pfeifente'),
  ('Spatula clypeata',      'Mestolone',          'Northern shoveler',      'Canard souchet',            'Cuchara común',          'Löffelente'),
  ('Spatula querquedula',   'Marzaiola',          'Garganey',               'Sarcelle d''été',           'Cerceta carretona',      'Knäkente'),
  ('Aythya ferina',         'Moriglione',         'Common pochard',         'Fuligule milouin',          'Porrón europeo',         'Tafelente'),
  ('Gallinago gallinago',   'Beccaccino',         'Common snipe',           'Bécassine des marais',      'Agachadiza común',       'Bekassine'),
  ('Fulica atra',           'Folaga',             'Eurasian coot',          'Foulque macroule',          'Focha común',            'Blässhuhn'),
  ('Gallinula chloropus',   'Gallinella d''acqua','Common moorhen',         'Gallinule poule-d''eau',    'Gallineta común',        'Teichhuhn'),
  ('Vulpes vulpes',         'Volpe',              'Red fox',                'Renard roux',               'Zorro rojo',             'Rotfuchs'),
  ('Pica pica',             'Gazza',              'Eurasian magpie',        'Pie bavarde',               'Urraca común',           'Elster'),
  ('Corvus cornix',         'Cornacchia grigia',  'Hooded crow',            'Corneille mantelée',        'Corneja cenicienta',     'Nebelkrähe'),
  ('Garrulus glandarius',   'Ghiandaia',          'Eurasian jay',           'Geai des chênes',           'Arrendajo euroasiático', 'Eichelhäher'),
  ('Sus scrofa',            'Cinghiale',          'Wild boar',              'Sanglier',                  'Jabalí',                 'Wildschwein'),
  ('Capreolus capreolus',   'Capriolo',           'Roe deer',               'Chevreuil',                 'Corzo',                  'Reh'),
  ('Cervus elaphus',        'Cervo',              'Red deer',               'Cerf élaphe',               'Ciervo rojo',            'Rothirsch'),
  ('Dama dama',             'Daino',              'Fallow deer',            'Daim',                      'Gamo',                   'Damhirsch'),
  ('Ovis gmelini musimon',  'Muflone',            'Mouflon',                'Mouflon',                   'Muflón',                 'Mufflon'),
  ('Rupicapra rupicapra',   'Camoscio alpino',    'Alpine chamois',         'Chamois des Alpes',         'Rebeco alpino',          'Gämse')
)
insert into species_names (species_id, locale, name)
select s.id, l.locale, l.name
from names n
join species s on s.scientific_name = n.scientific_name
cross join lateral (values ('it', n.it), ('en', n.en), ('fr', n.fr), ('es', n.es), ('de', n.de)) as l(locale, name)
on conflict (species_id, locale) do nothing;
