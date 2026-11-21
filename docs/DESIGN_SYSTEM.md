# HB Social 2.0 — Design System 2026 (riferimento visivo PD4)

## Principi
Interfaccia bianca ed editoriale su una pagina grigio-azzurra sul web e grigio-verde su mobile. Il verde Bosco identifica solo l'azione primaria, gli stati attivi e i badge della chat; il rosso solo i contatori non letti e il cuore attivo. Nessun gradiente decorativo, nessun bordo sulle card bianche, icone monocrome a linea 1,8 px (le uniche eccezioni sono le quattro icone del composer web). I dati reali vengono prima della decorazione: dove non c'è un dato la card si nasconde o mostra uno stato vuoto disegnato.

## Colori (`lib/core/theme/app_colors.dart`, unico posto in cui vive un hex)
| Token | Valore | Uso |
|---|---|---|
| bosco | `#1F4A3A` | pulsanti primari, nav attiva, chip attive, FAB, badge non letti, link "Vedi tutti" |
| boscoDeep | `#17392C` | hover e pressed del primario |
| boscoSoft | `#DCE7E0` | pulsanti secondari verdi, card informative, riquadri data neutri |
| boscoTint | `#E8F0EB` | hover delle righe e sfondo icone |
| surface | `#FFFFFF` | card e superfici |
| surfaceRaised | `#F8F9FB` | pannello di navigazione web |
| surfaceSoft | `#EEF2EF` | campi, tile scorciatoie, chip tag, binario del segmented |
| pageWeb | `#EAEEF3` | sfondo pagina web |
| pageMobile | `#F8F9F8` | sfondo pagina mobile |
| divider | `#E6EAE7` | filetti |
| border | `#E1E6E2` | bordi di chip e campi |
| text | `#141C18` | testo principale |
| textSecondary | `#67736D` | metadati |
| textTertiary | `#9AA49E` | placeholder |
| danger | `#E04B3E` | contatori, cuore attivo, pallino notifiche |
| dateUrgentBg / dateUrgentText | `#FBE6E6` / `#D2403A` | riquadro data di un evento entro 7 giorni |
| link | `#5A78AD` | hashtag e link nel testo dei post |
| success | `#22A06B` | pallino online |
| accentGreen / accentBlue / accentOrange / accentPurple | `#34A36A` / `#3B7DE0` / `#EE9A2D` / `#8B5CF6` | solo icone del composer web |
| overlay | `#141C18` 35 % | velo sulle immagini con testo bianco |
| storyRingSeen | `#C9D1CC` | anello delle storie già viste (non viste: bosco) |

## Tipografia — Inter (unica famiglia, 400/500/600/700/800)
| Ruolo | Specifica | Uso |
|---|---|---|
| hero | 40/700/−1 | solo banner Home web |
| display | 34/800/−0,8 | titoli pagina mobile e saluto |
| heading | 28/700/−0,5 | titoli pagina web, titolo evento |
| title | 20/700/−0,3 | titoli card colonna destra, "Oggi a caccia", "Storie" |
| cardTitle | 17/600/−0,2 | titoli card gruppo e post |
| body | 15/400 interlinea 1,5 | testo dei post |
| ui | 15/500 | voci nav, etichette azioni, righe |
| label | 14/500 | sottotitoli e meta |
| caption | 13/500 | anteprime e ore |
| small | 12/500 | etichette barra inferiore, mesi |
| price / kpi | 20/700 e 22/700 tabellari | prezzi e contatori |
| buttonLg / buttonSm | 15/600 (pillole 48–52) e 14/600 (pillole 36–40) | pulsanti |

## Raggi e ombre
`card 20` web · `card 22` mobile · `inner 16` · `media 14` · `nav 12` · `pill 999`.
`cardShadow` = `0 1 2 rgba(20,28,24,.04)` + `0 8 24 rgba(20,28,24,.06)`; `fabShadow` = `0 8 20 rgba(31,74,58,.35)`; barra inferiore mobile `0 −2 12 rgba(20,28,24,.06)`. Le card bianche non hanno bordi: il filetto `border` resta su chip e campi.

## Shell web
- Pagina `pageWeb`, barra superiore 64 senza linea: wordmark (quadrato Bosco 44 raggio 12 con "HB" 20/700 bianco, "Social" 28/700, tagline 12/500), ricerca a pillola 520×44 bianca con lente 20, placeholder 15/400 e chip "⌘ K" 12/500 su `surfaceSoft`, poi due pulsanti rotondi 40 bianchi (campanella con badge danger 18, chat) e avatar 36 con nome 15/600 e chevron.
- Pannello di navigazione: colonna 240 in un margine 20; card `surfaceRaised` raggio 20, ombra `cardShadow`, padding 12. Riga utente 72 su `surfaceSoft` raggio 16 (avatar 44, nome 15/600, @username 13/500, chevron 18). Voci 44, raggio 12, icona 22 e etichetta 15/500; attiva su fondo Bosco con testo bianco, hover `boscoTint`; badge danger 22 su Messaggi e Notifiche solo con non letti. Sezione "Strumenti di caccia" 13/500. In fondo pulsante "Crea contenuto" 48 Bosco a pillola. Sotto, card community (immagine 96 con overlay + tre kpi 22/700 da `hb_community_stats()`, nascosta se la RPC fallisce).
- Colonna destra 368 (gap 16): card bianche raggio 20, ombra, padding 20, nell'ordine zona 88, Messaggi (3 conversazioni), Online (fino a 8 amici da `online_friends(8)`), Eventi vicino a te (riquadro data 56×64 raggio 14, pila avatar 24, "Partecipo" 40), Di tendenza (chip 36 bordate) e card invito 176, infine il riquadro sponsorizzato P38. Ogni card si nasconde se vuota.
- Centro fluido 600–880; sotto 1280 la colonna destra sparisce e compare il dock Messaggi (contratto PD3: modelli `feed`, `standard`, `wide`).

## Home web
Hero 180 raggio 20 (immagine con velo più scuro a sinistra, titolo hero 40/700 e sottotitolo 18/400), card storie (tile 96×128 raggio 14, avatar 56 con anello 3 px, prima tile "Crea storia", ultima "Vedi tutte"), composer (avatar 48, pillola 56, riga 48 con Foto/Video verde, Check-in blu, Sondaggio arancio, Evento viola e "Altro"), barra filtri (chip 40, pillola tipo contenuto, pulsante filtri 40) e card post (avatar 44, nome 16/600, meta 13/500, testo 15/400 con hashtag `link`, media raggio 16, azioni 48 con icone 22 e "Salva" a destra). Gap tra card 16.

## Shell mobile
Pagina `pageMobile`, barra superiore 56 senza ombra (wordmark con quadrato 40 e "HB Social" 20/700, due pulsanti rotondi 44 `surfaceSoft`, avatar 40). Barra inferiore bianca 64 + safe area con ombra verso l'alto: Home, Cerca, [+], Notifiche, Profilo; icone 24, etichette 12/500, attiva Bosco, pallino danger 8 sulla campanella. FAB centrale 64 Bosco sollevato di 20 con `fabShadow`, nessun ripple colorato sulle voci.

## Home mobile
Data locale compatta 13/500 sopra il contenuto, senza saluto; distanza di 8 px dalla card principale. Card "Oggi a caccia" bianca raggio 22 padding 20 con chip regione Bosco 36, due chip bianche 40, testo di stato 15/500 e illustrazione trasparente 180 in basso a destra. Quattro tile scorciatoia 72×72 `surfaceSoft` raggio 20 con icona Bosco 28 e etichetta 14/600. "Storie" con cerchi 72 e anello 2,5 px. Composer bianco raggio 22 con pillola 48 e tre azioni monocrome. Card post raggio 22 con azioni senza etichette. Spaziature: 24 tra sezioni, 16 tra card, padding orizzontale 16.

## Componenti condivisi (`lib/core/widgets/`)
`HBCard`, `HBButton` (primary/secondary/soft/ghost/icon), `HBInput`, `HBChip`, `HBSegmentedTabs`, `HBEmptyState`, `HBBadge`, `HBAvatar`, `HBStatusChip`, `HBMarketingImage`. Le immagini di marketing (`hero_home.jpg`, `region_banner.jpg`, `invite.jpg`, `community.jpg`, `today_illustration.png`) sono asset statici: se mancano, `HBMarketingImage` usa un fondo pieno Bosco con gli stessi testi, mai un gradiente e mai un'immagine di prova.

## Movimento
Animazioni implicite che rispettano `MediaQuery.disableAnimations`: fast 120 ms, base 180 ms, medium 220 ms, slow 260 ms. Nessuna animazione continua salvo lo shimmer di caricamento.

## Pattern unico delle pagine elenco (PD4b)
Vale per Gruppi, Marketplace, Eventi, Forum, Pagine, Avvistamenti, Diario, I miei cani, Cerca cani e ogni altra lista.
- Mobile: titolo `display` 34/800/−0,8 e sottotitolo 15/400 `textSecondary` (padding 16, 8 sotto la barra superiore); `HBSegmentedTabs` a pillola a tutta larghezza (binario `surfaceSoft` 48 raggio 999, segmento attivo Bosco testo bianco 15/600, inattivo 15/500, scorrimento 180 ms); `HBFilterChipsRow` con chip 40 raggio 999 che vanno a capo (`Wrap`, gap 8/10) fino a 8 chip, oltre restano su una riga scorrevole; lista con gap 12.
- Ricerca (Marketplace, Cerca cani): `HBListSearchBar` — pillola bianca 52 con bordo `border`, lente 20, placeholder 15/400 `textSecondary` e pulsante quadrato 52 con icona filtri che apre il foglio esistente.
- Web: titolo `heading` 28/700 + sottotitolo a sinistra, azione primaria Bosco a pillola 44 a destra, segmented max 420, chip a capo, lista nel centro (modelli `standard`/`wide` di PD3).
- Azione flottante mobile: `HBScrollHidingAction`, pillola Bosco 52 con `fabShadow`, sparisce scorrendo in giù e torna in su (200 ms).

## Card e dettagli PD4b
- **Card gruppo**: bianca raggio 20 padding 12; copertina 100×112 raggio 14 a sinistra (senza copertina riquadro `surfaceSoft` con icona gruppo Bosco 28); nome `cardTitle` 17/600 (2 righe), conteggi reali 14/500 `textSecondary` (`NumberFormat.compact`), fino a 2 chip tag `surfaceSoft` 26 raggio 999 12/500, descrizione 13/400 su 2 righe; azione in basso a destra 36 raggio 999: "Unisciti" Bosco, "Richiesto" `boscoSoft`, "Apri" bianca con bordo.
- **Dettaglio gruppo/pagina**: copertina edge-to-edge 220 (mobile) / 280 (web), pulsanti rotondi bianchi 40 in overlay, avatar 72 sovrapposto di 36, nome 28/700, meta 14/500 e azioni; tab sottolineate.
- **Tile annuncio**: bianca raggio 18 padding 8; immagine quadrata raggio 14, cuore in pulsante rotondo 36 (attivo `danger` pieno), chip "In evidenza" Bosco 28 con razzo 14 solo per contenuti promossi; prezzo `price` 20/700 via `MoneyFormatter`, titolo 15/500, categoria 14/500, riga venditore (avatar 28, nome abbreviato 13/500, città 12/500). Variante `compact` 160 pronta per la striscia In evidenza di P39.
- **Card evento**: bianca raggio 20 padding 12; copertina 160 raggio 14 con chip categoria bianca 28 in overlay e riquadro data 48×56 sovrapposto (giorno 18/700, mese 11/600 maiuscolo; `dateUrgentBg`/`dateUrgentText` entro 7 giorni, altrimenti `surfaceSoft`/Bosco); titolo 17/600, luogo 14/500, pila avatar 24 con "+N" (nascosta a 0), azione "Partecipo" Bosco 36.
- **Dettaglio evento**: copertina 360 mobile / 320 web raggio 20; back 40, condividi e ⋯ 40, cuore 48 a 120 dall'alto; riquadro data bianco 96×112 raggio 20 con `cardShadow` sovrapposto di 40 (giorno settimana 12/600 Bosco, numero 34/800, mese 12/600 Bosco); titolo `heading` + chip categoria, luogo 15/500, riga organizzatore (avatar 48, chevron 18), due celle statistiche divise da divider verticale, due pulsanti 52 raggio 999 ("Partecipo" Bosco, "Mi interessa" `boscoSoft`), card informativa `boscoSoft` raggio 18 con calendario 24 (gratuito o biglietto e posti), tab sottolineate e righe icona 20 + etichetta 110 + valore 15/500.

## Tab sottolineate
Dentro i dettagli (gruppo, pagina, profilo, evento, venditore, campagna) le tab usano `HBSegmentedTabs(variant: underlined)`: etichetta attiva 15/600 `text` con sottolineatura Bosco 2 px larga quanto l'etichetta, inattive 15/500 `textSecondary`, divider `divider` sotto. I segmented a pillola restano solo per gli elenchi (Scopri | I miei).

## Console e Centro inserzioni
La console amministrativa e la barra laterale del Centro inserzioni usano la superficie scura `night` `#112623` con la voce attiva su fondo Bosco; tutto il resto segue i token PD4a.
