# HB Social - Release runbook

## Web

1. In Dreamflow aprire Publish, selezionare Web release e configurare `huntingbook.app`.
2. Usare strategia PWA offline-first e renderer CanvasKit, coerente con `ARCHITECTURE.md`.
3. Impostare `FLUTTER_WEB_CANVASKIT_URL` sulla CDN della release se il publish espone il relativo campo di build.
4. Verificare `/offline.html`, manifest, icone, route pubbliche, `robots.txt` e `sitemap.xml` dalla build pubblicata.
5. Eseguire Lighthouse Mobile sulla build release e registrare data e quattro punteggi nel report di rilascio.

## iOS e Android

1. In Publish impostare versione applicazione e build number, quindi creare la build iOS per TestFlight e Android per Play Internal.
2. Configurare gli stessi valori come define di build `HB_APP_VERSION` e aggiornare `AppConstants.appVersion` prima del tag.
3. Completare metadati, privacy, classificazione 18+, screenshot e note revisore da `docs/STORE_LISTING.md`.
4. Dopo l'approvazione interna, aggiornare Console > Sistema > Release: `latest_app_version`, `min_app_version`, URL store e piattaforme consentite.

## Aggiornamenti e manutenzione

- `latest_app_version`: mostra l'avviso non bloccante; `force_update_below`: blocca le versioni inferiori con collegamento allo store corretto.
- Attivare la manutenzione dalla Console con messaggi in tutte le lingue. Verificare prima con un amministratore, che mantiene l'accesso.
- Disattivare la manutenzione appena conclusa l'operazione e usare Checklist di lancio per ricontrollare la piattaforma.

## Sicurezza e produzione

- Ruotare periodicamente secret OAuth, LiveKit, Bunny, DeepL, Firebase e Stripe dalle rispettive console; non inserirli nel client.
- Prima del lancio passare Stripe a Live, completare KYC piattaforma, webhook e riconciliazione; mantenere separate le chiavi dev/prod.
- Pubblicare e far revisionare privacy e termini in tutte e cinque le lingue prima di aumentare `legal_versions`.