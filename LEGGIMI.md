# ZA DEMOLITION — versione web (Ver. B.6.0)

Gioco aziendale ZA srl in stile Timberman: si demolisce un palazzo piano per piano con l'escavatore.
Nato in GDevelop, poi riscritto da zero come pagina web (un solo file `index.html`, canvas 2D, JavaScript senza librerie).

## Dove sta tutto (dal 15/11/2026, account Stile Digitale)

| Cosa | Dove |
|---|---|
| Codice | GitHub **stiledigitale/za-demolition** (branch `main`) |
| Gioco online | **Cloudflare Pages** (account Stile Digitale), progetto `za-demolition`, cartella pubblicata `gioco` → https://za-demolition.pages.dev |
| Classifica | **Supabase**, progetto `stiledigitale_games`, tabelle `za_players` e `za_scores` |

Stesso schema di Tactical Racing Simulator. Regole comuni per i giochi web: documento `claude/standard-portali-web.md` nel progetto Claude "01_SVILUPPO GIOCHI".

### Cartelle del repository
| Cartella | Cosa contiene |
|---|---|
| `gioco/` | Il gioco pubblicato: `index.html`, `config.js`, `collision.wav`, `img/` |
| `server/supabase.sql` | Tabelle e funzioni della classifica su Supabase (già applicato) |
| `LEGGIMI.md` | Questa scheda |

Il progetto GDevelop di partenza (`gdevelop-originale/`, 34 MB) e il vecchio server Cloudflare restano solo nello zip di archivio, non nel repository.

### Aggiornare il gioco
Ogni modifica caricata su GitHub (branch `main`) viene pubblicata da sola da Cloudflare Pages in circa un minuto. Non si trascinano più file a mano.

### Classifica online (Supabase)
- `gioco/config.js` contiene indirizzo e chiave **publishable** del progetto (pubblica per natura). Mai mettere la secret key nel gioco.
- Le tabelle sono chiuse (RLS senza policy): il gioco usa solo le funzioni `za_new_player`, `za_get_progress`, `za_set_name`, `za_save_progress`, `za_restore`, `za_submit_score`, `za_leaderboard`. Ogni funzione controlla la chiave segreta del giocatore (`token`, salvata solo sul suo dispositivo in `zademo_sbid`).
- Controlli: nome 2-14 caratteri ripulito; massimo ~14 piani al secondo; un punteggio ogni 3 secondi per giocatore; i record nei progressi non possono scendere.
- Il nome sta solo in `za_players`: cambiandolo, cambia in tutta la classifica.
- Per vedere o correggere i dati: pannello Supabase → Table Editor → `za_players` / `za_scores` (per togliere un giocatore basta cancellarlo da `za_players`: i suoi punteggi spariscono con lui).
- Per spegnere la classifica (es. un portale che blocca i servizi esterni): `window.ZA_ONLINE = false;` prima del gioco.
- Supabase gratuito mette in pausa il progetto dopo 7 giorni senza richieste: si riattiva dal pannello.
- Verificata dal sito il 15/11/2026 sul database vero (giocatore, punteggio, posizione, blocco dei punteggi falsi).
- Dal 15/11/2026 la classifica è ripartita da zero (la vecchia, su Cloudflare D1 dell'account personale, non è stata importata). Chi aveva giocato reinserisce solo il nome.

## Come funziona il gioco (stato attuale)

- **Schermata d'avvio** "TOCCA PER INIZIARE": il primo tocco accende la musica (i browser bloccano l'audio automatico).
- **Primo avvio, nome obbligatorio** (B.4.1): se sul dispositivo non c'è un nome, dopo lo Splash si apre "COME TI CHIAMI?" senza ANNULLA (2-14 caratteri, stessa pulizia del server, in MAIUSCOLO). Il nome viene salvato subito in locale (`zademo_pname`) e inviato al server; se si è offline resta il flag `zademo_nameSync` e viene reinviato al prossimo avvio. Si può cambiare in seguito dalla Classifica (✎).
- **Modalità ROADMAP:** città in sequenza Riva del Garda → Trento → Bolzano → Verona (poi ricomincia con ★2…), **100 piani per città** (`LEVEL_EVERY` in `index.html`). Tra una città e l'altra: scena del trasferimento con camion Mercedes bianco e carrellone a 4 assi.
- **Modalità PARTITA SINGOLA:** si sceglie una città già sbloccata nella Roadmap, palazzo infinito.
- **Classifiche online:** una per la Roadmap e una per ogni città (`mode` = `road`, `s0`, `s1`, `s2`, `s3`), "di sempre" e "settimana"; a parità di piani vince il tempo più basso. Nome giocatore, codice di recupero progressi a 6 caratteri.
- **Ambientazioni:** giorno / tramonto / notte / alba per città; facciate diroccate; cannoni nebulizzatori bianchi.
- **Ostacoli e bonus:** balconi di varie misure, piani vuoti, travi in cemento (20 pinzate), bonus tempo / casco / stella x2.
- **Escavatori** (stessa livrea ZA bianca): CAT 323, CAT 319M gommato, CAT 329, CAT 330, CAT 340, sbloccati con il record.
- **Operatori:** con foto e nome, 10 in tutto (OPS = 0-7, 9, 10). Tolto solo Seba (indice 8); FRANZ e DJ ZANELLA restano.
- **Multilingua** (B.5.0): italiano, inglese, tedesco, francese, spagnolo. Bandierina in alto a sinistra (schermata d'avvio e menu) con menu a scomparsa; le bandiere sono disegnate nel codice (le emoji delle bandiere non si vedono su Windows). Al primo avvio la lingua è quella del browser (se non è una delle 5: inglese); la scelta è salvata in `zademo_lang`. Tutti i testi sono nel dizionario `I18N` in `index.html` (ogni voce: [it, en, de, fr, es]) e si leggono con `txt("chiave")`. Restano in italiano i nomi delle città e le scritte disegnate sulle facciate; l'immagine `select.png` (SELECT OPERATOR) è già in inglese.
- Al primo avvio (nessun nome salvato) la schermata "TOCCA PER INIZIARE" resta sempre visibile, così si può scegliere la lingua prima di inserire il nome.
- Musica generata con WebAudio (menu e partita), comandi: tocco sinistra/destra, frecce, A/D.

## Regole decise (da rispettare)
- **Mai la foto dell'operatore nella cabina dell'escavatore.**
- Escavatori tutti dello stesso colore: cambiano i modelli, non i colori.
- La pinza "pinza/frantuma", non "picchia"; la trave è all'altezza della pinza.
- Cannoni bianchi; camion senza riga rossa, rampe grigie, braccio piegato basso dietro la cabina.
- Account dei servizi (GitHub, Cloudflare, Supabase): **Stile Digitale** (`stiledigitale`), come gli altri giochi web. Prima si usavano christianpasini-code e l'account Cloudflare personale.

## Idee per i prossimi passi
- Sfide / multiplayer.
- Nuove città dalla lista COMING SOON (nel codice: `COMING`).

## Per riprendere con Claude su un altro account
Collega il repository stiledigitale/za-demolition (o carica lo zip) e scrivi: *"Questo è il mio gioco ZA DEMOLITION (versione web). Leggi LEGGIMI.md e continuiamo da qui."*
