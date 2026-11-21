# HB Social - Release report

## Acceptance evidence

| Check | Date | Result |
|---|---|---|
| Lighthouse Performance (Mobile, release) | Pending | Pending |
| Lighthouse Accessibility (Mobile, release) | Pending | Pending |
| Lighthouse Best Practices (Mobile, release) | Pending | Pending |
| Lighthouse SEO (Mobile, release) | Pending | Pending |
| PWA install and offline behavior | Pending | Pending |
| TestFlight review | Pending | Pending |
| Play Internal review | Pending | Pending |

## Lighthouse (build pubblicata su huntingbook.app, Chrome DevTools > Lighthouse > Mobile)

| Area | Valore atteso | Valore reale | Data |
|---|---:|---:|---|
| Performance | Da riportare (CanvasKit mobile raramente supera 80) | Da compilare | Da compilare |
| Accessibilita | > 90 | Da compilare | Da compilare |
| Best practice | > 90 | Da compilare | Da compilare |
| SEO | > 90 | Da compilare | Da compilare |

Il differimento di Reel, Live e chiamate genera part file separati nella build web. La dimensione di `build/web/main.dart.js` prima/dopo e il numero definitivo dei part file vanno registrati dalla build pubblicata; Dreamflow Preview non espone questi artefatti.

## Store

| Canale | Data invio | Esito | Note |
|---|---|---|---|
| TestFlight | Da compilare | Da compilare | Allegare esito della build elaborata |
| Play Internal | Da compilare | Da compilare | Allegare esito della revisione interna |

## Asset mancanti

- `web/og-image.png` definitivo 1200x630 fornito dal designer; fino ad allora SEO usa `web/icons/Icon-512.png`.
- Screenshot PWA per il manifest (`screenshots` desktop e mobile).
- Screenshot App Store e Google Play nelle dimensioni richieste.

## Evidenze software P49b

- Editor legale a cinque lingue con anteprima Markdown, salvataggio per lingua, pubblicazione e lettura aggregata dei consensi.
- Header Supabase globale `x-hb-platform`; filtro client per browse, creazione, preferiti, ricerca, notifiche e deep link degli annunci mediati.
- SEO client dinamico per documenti legali, pagine, articoli, eventi, profili e download; rotte private con metadati generici.
- Riduzione movimento per skeleton, reel e stories; route di Reel, Live e chiamate caricate tramite `DeferredPage`.

Le evidenze Lighthouse e store sono esterne al codice e devono essere copiate dalla release pubblicata; non vengono inferite dall'analisi statica o dalla Preview.