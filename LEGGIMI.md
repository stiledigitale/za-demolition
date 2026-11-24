# ZA DEMOLITION — versione web (Ver. B.9.16)

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
(Cloudflare Pages: cartella di uscita `gioco`, nessun comando di build. L'app Cloudflare su GitHub deve avere accesso al repository, altrimenti compare l'avviso "disconnected from your Git account" e le modifiche non vengono pubblicate.)
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

## Novità B.8.0
- **Bonus nuovi** (oltre a ⏱️ +TEMPO, ⛑️ CASCO, ⭐ PUNTI x2): ☕ **caffè** (la barra del tempo resta ferma 8 s, diventa azzurra), 🔨 **martello turbo** (5 s: ogni colpo abbatte 2 piani, il secondo senza rischi; sulle travi colpisce doppio), 🧨 **TNT** (fa saltare da sola 5 piani, rompe anche le travi), **mattone d'oro** (+50, raro, compare dopo 30 piani). Probabilità in `pickItem()`.
- **Eventi delle città** (`CITY_EVENTS`): 🌬️ Bora a Trieste (balconi che oscillano, raffiche), 🌊 acqua alta a Venezia (l'acqua sale fino all'escavatore), 🌫️ nebbia a Milano (nasconde i piani in arrivo), 🌋 Vesuvio a Napoli (scosse e cenere). Durano 5-6 s, con avviso; ogni 18-32 s.
- **Sfida del giorno** (menu → 📅): ogni giorno una città (`dailyCity()`) e lo stesso palazzo per tutti (generatore con seme del giorno, `seededRand`). Classifica in Classifica → OGGI (modalità server `dAAAAMMGG`). Il record di oggi è in `zademo_dailyRec`.
- **Medaglie** (15, menu → MEDAGLIE): 100 e 300 piani, combo x30, 3 travi, TNT, mattone d'oro, casco, caffè, Bora, acqua alta, nebbia, Vesuvio, arrivo a Roma, 50 piani nella sfida, condivisione. Avviso a schermo quando se ne conquista una; salvate anche online insieme ai progressi.
- **Pausa** (B.8.1): pulsante giallo in alto a destra sempre visibile in partita (anche prima del VIA), oppure Esc/P. Dentro: RIPRENDI, RICOMINCIA, TORNA AL MENU, audio.
- **Condividi il gioco** (B.8.2): pulsante giallo in fondo al menu. Crea un'immagine promozionale (logo, "Demolisci in 20 città italiane", cartoline di Venezia, Firenze e Roma, indirizzo del gioco) con un testo d'invito nella lingua del giocatore (`promoCard`, `shareGame`).
- **Link cliccabile** (B.8.4): le immagini condivise non riportano più l'indirizzo; il link (cliccabile) è nel messaggio che le accompagna. Anteprima del link (`og.jpg` 1200×630 + meta Open Graph in `index.html`): su WhatsApp, Facebook, LinkedIn e Telegram il link mostra una scheda con immagine che apre il gioco.
- **Isoipse**: provate in B.9.0/B.9.1 (stile grafica ZA srl) e **rimosse in B.9.2** su richiesta: pulsanti e schede tornano in tinta unita.
- **Condividi** nel game over: crea un'immagine 1080×1350 (logo, piani, città, modalità, operatore, nome, indirizzo del gioco). Sul telefono apre la condivisione (WhatsApp, social...), sul computer scarica l'immagine e copia il testo.
- Server: `za_submit_score` accetta `dAAAAMMGG`; limite di plausibilità 120 + 16 piani al secondo (per TNT e mattone d'oro).

## Come funziona il gioco (stato attuale)

- **Schermata d'avvio** "TOCCA PER INIZIARE": il primo tocco accende la musica (i browser bloccano l'audio automatico).
- **Primo avvio, nome obbligatorio** (B.4.1): se sul dispositivo non c'è un nome, dopo lo Splash si apre "COME TI CHIAMI?" senza ANNULLA (2-14 caratteri, stessa pulizia del server, in MAIUSCOLO). Il nome viene salvato subito in locale (`zademo_pname`) e inviato al server; se si è offline resta il flag `zademo_nameSync` e viene reinviato al prossimo avvio. Si può cambiare in seguito dalla Classifica (✎).
- **Modalità ROADMAP:** città in sequenza Riva del Garda → Trento → Bolzano → Verona (dopo Roma ricomincia: "2° GIRO", "3° GIRO"…), **100 piani per città** (`LEVEL_EVERY` in `index.html`). Tra una città e l'altra: scena del trasferimento con camion Mercedes bianco e carrellone a 4 assi.
- **Modalità PARTITA SINGOLA:** si sceglie una città già sbloccata nella Roadmap, palazzo infinito.
- **Classifiche online:** una per la Roadmap e una per ogni città (`mode` = `road`, `s0`, `s1`, `s2`, `s3`), "di sempre" e "settimana"; a parità di piani vince il tempo più basso. Nome giocatore, codice di recupero progressi a 6 caratteri.
- **Ambientazioni:** giorno / tramonto / notte / alba per città; cannoni nebulizzatori bianchi. Il palazzo da demolire è diroccato; i **fondali** (B.6.1) usano lo stesso stile (intonaco, cantonali, marcapiani, finestre con persiane) ma con palazzi curati e vivi: fioriere di gerani, tetti in coppi, tende dei negozi, glicine, vasi di limoni e oleandri, alberi in fiore, aiuole, siepi. Riva: lungolago; Trento: Castello, case affrescate e giardino; Bolzano: Duomo, case tirolesi con bovindo e banco della frutta; Verona: Arena e Liston con i bar.
- **Roadmap a 20 città** (B.7.0): Riva del Garda, Trento, Bolzano, Verona, Trieste (Municipio, Faro della Vittoria, Miramare, Barcolana), Venezia (palazzi gotici, campanile di San Marco, Palazzo Ducale, gondole), Padova (Santo, Palazzo della Ragione, Prato della Valle), Bergamo (Città Alta, Mura, Campanone, funicolare), Brescia (Pallata, Duomo Nuovo, Loggia, Mille Miglia), Torino (Mole, Gran Madre, Alpi, tram), Milano (Duomo e Madonnina, Bosco Verticale, grattacielo), Bologna (Due Torri, San Petronio, portici, San Luca), Genova (Lanterna, porto, case colorate), Firenze (Cupola, campanile di Giotto, Palazzo Vecchio, Ponte Vecchio), Napoli (Vesuvio, Maschio Angioino, panni stesi, pino, Vespa), Bari (San Nicola, Teatro Margherita, lungomare, orecchiette), Catanzaro (Ponte Bisantis, fichi d'india), Palermo (Cattedrale, San Giovanni degli Eremiti, palme, carretto), Cagliari (Bastione di Saint Remy, Torre dell'Elefante, fenicotteri, Sella del Diavolo), Roma (Colosseo, Vittoriano, San Pietro, pini, Vespa). Ogni città ha anche i colori del suo palazzo da demolire (`FACADES`). Roadmap e scelta della città si scorrono (dito, mouse, rotellina); in classifica la città si cambia con ◀ ▶. Record della partita singola `s0`..`s19`. Dopo Roma il giro ricomincia: la città si scrive "TRENTO · 3° GIRO" (B.9.16, prima "TRENTO ★3"; chiave `lap` in 5 lingue); in partita il giro è una riga sotto "prossima città". Tutto disegnato nel codice (`sceneKit` → `palazzo`, `window`, `flowerBox`, `pot`, `bloomTree`...), senza immagini.
- **Ostacoli e bonus:** balconi di varie misure, piani vuoti, travi in cemento (20 pinzate), bonus tempo / casco / stella x2.
- **Escavatori** (stessa livrea ZA bianca): CAT 323, CAT 319M gommato, CAT 329, CAT 330, CAT 340, sbloccati con il record.
- **Operatori:** con foto e nome, 11 in tutto (OPS = 0-7, 9, 10, 11). Tolto solo Seba (indice 8); FRANZ e DJ ZANELLA restano. B.9.3: aggiunta l'operatrice **MARYLU ❤** (indice 11, `op11.jpg` + `name11.png` con il cuore rosso). B.9.4: l'operatore ARTIGIANO (indice 1) si chiama ora **ARTISTA** (`name1.png` ricomposto con le lettere originali). B.9.5: nuova foto di MARYLU (occhi azzurri).
- **Classifica scorrevole** (B.9.6): mostra fino a **100 posizioni** (prima 13); si scorre col dito, la rotellina o le frecce ↑↓, con barra laterale. Se il giocatore è in classifica, all'apertura la sua riga è già in vista. Il server (`za_leaderboard`) accetta al massimo 100: per andare oltre va alzato quel limite.
- **Sfida del giorno numerata** (B.9.7): in classifica OGGI ogni riga riporta "📅 Sfida del giorno n° N · GG/MM" accanto alla città (n° 1 = 16/11/2026, `dailyNum()`), e così il sottotitolo. Il giorno della sfida ora segue l'**ora italiana** (`dailyYMD()` con fuso Europe/Rome): cambia a mezzanotte in Italia invece che all'01:00. La città della sfida si gioca anche se non è sbloccata nella Roadmap: è normale vedere punteggi lì.
- **Classifica OGGI con tutte le partite** (B.9.8): la scheda OGGI ha due pulsanti. **TUTTE LE PARTITE** (predefinito) mostra il miglior risultato di oggi di ogni giocatore, in qualsiasi modalità (modalità server `today`, giorno in ora italiana), con l'etichetta ROADMAP / PARTITA SINGOLA / 📅 Sfida del giorno. **📅 SFIDA DEL GIORNO** mostra solo la sfida. `za_leaderboard` restituisce anche `mode` per ogni riga (migrazione `za_leaderboard_today`).
- **Giocatori collegati** (B.9.8): numerino nell'angolo in alto a destra, su tutte le schermate. Ogni gioco aperto (in primo piano) fa un ping ogni 30 s con `za_ping`; il numero conta chi ha pingato negli ultimi 75 s. Tabella `za_presence` (chiusa, si ripulisce da sola dopo un giorno), migrazione `za_presence`. Non compare se si è offline.
- **Difficoltà rivista** (B.9.9): la Roadmap resta un giro unico da Riva a Roma (1.900 piani in una partita). Prima la barra calava fino a 0,36/s già a 130 piani: servivano ~5,8 piani al secondo per minuti, impossibile (record 331, Verona). Ora `drain = 0,10 + 0,10·min(1, piani/300) + 0,002·città`: sale fino a 300 piani, poi solo un pelo per città; a Roma 0,238/s ≈ 3,8 piani al secondo (ogni piano ricarica 0,062). Simulazione senza bonus: chi tiene ~5 colpi al secondo arriva a Roma, a 4,5 si arriva in media verso Padova-Bergamo; con i bonus va meglio.
- **Vita extra ❤️** (B.9.9): nuovo bonus (compare dopo 60 piani, max 3 vite, cuori sotto il nome della città). Al prossimo errore (balcone, tempo finito, trave) non si perde: barra piena, ostacoli davanti tolti, 1,5 s di respiro, e la partita continua con lo stesso punteggio.
- **Banner aggiornamento** (B.9.11): nella schermata "TOCCA PER INIZIARE" una fascia gialla "🆕 AGGIORNAMENTO · NUOVE FUNZIONALITÀ" (solo la scritta, senza elenco; chiave `upd_title`, disegnata in `Splash.render`).
- **Più contrasto** (B.9.12, "si vedono poco i balconi"): i balconi sono disegnati una volta su una tela a parte (`balconySprite`) con un **contorno scuro** di 3 px e incollati con un'**ombra**; lo sfondo (cielo e città) ha un velo scuro (30% di giorno, 18% di notte) e ai lati del palazzo c'è un'ombra sfumata. Il palazzo non è scurito. `ctx` ora è `let` per poter disegnare sulla tela del balcone. B.9.13: anche il palazzo ha lo stesso stile, con un contorno scuro di 5 px ai due lati e un'ombra interna sfumata lungo i bordi. B.9.14: stesso stile per ciò che si muove: i fotogrammi dell'**escavatore** hanno il contorno (`outlineCanvas`, calcolato una volta in `excFrames`) e l'ombra a terra; il **camion** con il carrellone viene disegnato su una tela a parte con contorno e ombra (`outlineLayer`) durante il trasferimento.
- **Copertina all'avvio** (B.9.15): lo Splash mostra a tutto schermo l'illustrazione `img/cover.webp` (escavatore bianco ZA sul Garda al tramonto, stile poster) con un leggero zoom; per 5 secondi una **finta barra di caricamento** gialla (`SPLASH_LOAD`), poi "PREMI PER INIZIARE" nella lingua del sistema (o quella scelta con la bandierina) e sotto la fascia "🆕 AGGIORNAMENTO · NUOVE FUNZIONALITÀ". Durante il caricamento i tocchi sono ignorati; lo Splash non salta più da solo al menu. Corretto anche un errore raro trascinando il dito mentre si cambiava schermata (`move` con `this.sc` vuoto).
- Tempo stimato per arrivare a Roma (simulazione, 1.900 piani + ~95 travi da 20 colpi): 14 min a 5 colpi/s, 12 min a 6, 10-11 min a 7; i bonus (x2, TNT, martello, mattone d'oro) lo accorciano.
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
- Nuove città dalla lista  (nel codice: `COMING`).

## Per riprendere con Claude su un altro account
Collega il repository stiledigitale/za-demolition (o carica lo zip) e scrivi: *"Questo è il mio gioco ZA DEMOLITION (versione web). Leggi LEGGIMI.md e continuiamo da qui."*
