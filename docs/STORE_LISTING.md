# HB Social - Store listing

## Testi store

| Lingua | Nome (30) | Sottotitolo (30) | Descrizione breve (80) | Parole chiave (100) |
|---|---|---|---|---|
| IT | HB Social | La community dei cacciatori | Community, territori, calendari, diario, cani, eventi e marketplace. | caccia,cacciatori,calendario,diario,cani,eventi,meteo,mappe,community |
| EN | HB Social | The hunters' community | Community, hunting calendars, diary, dogs, events, weather and marketplace. | hunting,hunters,calendar,diary,dogs,events,weather,maps,community |
| FR | HB Social | La communaute des chasseurs | Communaute, calendriers, carnet, chiens, evenements, meteo et annonces. | chasse,chasseurs,calendrier,carnet,chiens,evénements,meteo,cartes |
| ES | HB Social | La comunidad de cazadores | Comunidad, calendarios, diario, perros, eventos, tiempo y anuncios. | caza,cazadores,calendario,diario,perros,eventos,tiempo,mapas |
| DE | HB Social | Die Community fuer Jaeger | Community, Jagdzeiten, Tagebuch, Hunde, Events, Wetter und Marktplatz. | jagd,jaeger,jagdzeiten,tagebuch,hunde,events,wetter,karten,community |

### Descrizione lunga IT
HB Social riunisce la community internazionale dei cacciatori in uno spazio responsabile e moderato. Segui persone e territori, consulta calendari venatori e meteo, organizza il diario delle uscite, gestisci i profili dei cani, scopri eventi e partecipa a gruppi e forum. Condividi post, storie, reel e dirette, conversa in chat e trova annunci nel marketplace. Le funzioni disponibili rispettano il paese e la piattaforma. Posizione e notifiche sono facoltative. L'accesso e riservato ai maggiorenni.

### Long description EN
HB Social brings the international hunting community together in a responsible, moderated space. Follow people and territories, check hunting calendars and weather, keep an outing diary, manage dog profiles, discover events, and join groups and forums. Share posts, stories, reels and live streams, chat, and browse marketplace listings. Features adapt to country and platform rules. Location and notifications are optional. Adults only.

### Description longue FR
HB Social reunit la communaute internationale des chasseurs dans un espace responsable et modere. Suivez des personnes et des territoires, consultez calendriers et meteo, tenez votre carnet de sorties, gerez vos chiens, decouvrez des evenements, groupes et forums. Partagez publications, stories, reels et directs, discutez et consultez les annonces. Les fonctions respectent les regles du pays et de la plateforme. Position et notifications facultatives. Reserve aux adultes.

### Descripcion larga ES
HB Social reune a la comunidad internacional de cazadores en un espacio responsable y moderado. Sigue personas y territorios, consulta calendarios y meteorologia, organiza tu diario de salidas, gestiona perfiles de perros, descubre eventos y participa en grupos y foros. Comparte publicaciones, historias, reels y directos, conversa y explora anuncios. Las funciones se adaptan al pais y a la plataforma. Ubicacion y notificaciones opcionales. Solo adultos.

### Lange Beschreibung DE
HB Social vereint die internationale Jagdgemeinschaft in einem verantwortungsvollen, moderierten Raum. Folge Menschen und Revieren, pruefe Jagdzeiten und Wetter, fuehre dein Jagdtagebuch, verwalte Hundeprofile, entdecke Veranstaltungen, Gruppen und Foren. Teile Beitraege, Stories, Reels und Livestreams, chatte und entdecke Anzeigen. Funktionen richten sich nach Land und Plattform. Standort und Benachrichtigungen sind optional. Nur fuer Erwachsene.

## Note per la revisione

- Account di test: credenziali da fornire nel campo riservato della submission, mai in questo repository.
- Dirette: aprire `Altro > Live`, creare una diretta e avviarla; chiamate: aprire una chat 1:1 e usare audio/video.
- Marketplace: aprire Marketplace e un annuncio. La vetrina armi mediata e intenzionalmente assente dalle build iOS e Android per conformita alle policy degli store; non sono disponibili acquisti in-app di armi o munizioni.
- Eliminazione account: `Impostazioni > Privacy e sicurezza > Elimina account` con 14 giorni di grazia.
- Supporto: supporto@huntingbook.app.
- Privacy: https://huntingbook.app/legal/privacy - Termini: https://huntingbook.app/legal/terms.

## Classificazione 18+

- Apple: contenuti generati dagli utenti con moderazione e segnalazione; temi di caccia e armi contestuali; nessun gioco d'azzardo; nessuna vendita di armi nelle build store; accesso 18+.
- Google Play / IARC: interazione utenti, condivisione posizione facoltativa e riferimenti contestuali a caccia/armi; moderazione, blocco e segnalazione disponibili; classificazione richiesta 18+.

## Privacy labels e Data safety

Raccolti per funzionalita dell'app: contatti, posizione facoltativa, contenuti utente, identificativi, utilizzo e diagnostica. I dati sono associabili all'account dove necessario, cifrati in transito e cancellabili dall'app. Nessun tracciamento cross-app e nessuna vendita di dati.

## Checklist iOS

- Verificare in `Info.plist` i testi localizzati per camera, microfono, foto e posizione; mantenere `UIBackgroundModes` audio per le chiamate.
- Dichiarare export compliance, privacy labels e classificazione 18+ in App Store Connect.
- Verificare Sign in with Apple, notifiche, deep link, ripristino chiamata e cancellazione account in TestFlight.

## Checklist Android

- Verificare permessi camera, microfono, foto, posizione e notifiche; mantenere il canale chiamate `hb_calls`.
- Usare target SDK corrente, firma Play App Signing, Data safety e classificazione IARC 18+.
- Verificare deep link, notifiche, chiamate, upload e cancellazione account nel canale Internal testing.