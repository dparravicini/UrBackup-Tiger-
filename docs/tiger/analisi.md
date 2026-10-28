# Porting sperimentale UrBackup per Tiger

Stato: avviato, non ancora un client utilizzabile. Nessun backup o ripristino certificato.

## Base

Upstream: https://github.com/uroni/urbackup_backend . Client selezionato 2.0.34client,
commit 8cd27193b8370df739ad08c6f72750ebe3c7fe11. Il ramo recente richiede C++17;
1.4.9 è più vecchio ma manca dei percorsi Darwin e metadati estesi già presenti
in 2.0.34. Non si presume compatibilità del protocollo 2.0 con server 2.5.
La prova con il server reale resta obbligatoria.

Il client headless combina core, SQLite, plugin statici client/fileserv/crypto e
CLI di controllo. Il server scopre il client e richiede indice e contenuti;
il client gestisce scansione, trasferimento a blocchi, stato e ripristino.
Si compila esclusivamente Makefile.am_client, nessun server o GUI.
Le componenti image upstream sono dipendenze di link: non viene autorizzato
né testato il backup immagine. Snapshot e aggiornamento automatico disabilitati.

Dipendenze: pthread/socket/zlib di Tiger, SQLite incorporata, Crypto++ 5.6.3
(commit 298988a5b9687f64de733ce01319e90e94b0b688), compilate con GCC 4.0.1,
SDK 10.4u, PPC 32 bit, C++98. Nessun compilatore nuovo.
Le firme, AES-CFB/GCM, PBKDF ed ECDH del protocollo non sono TLS.
Non si sostituisce il trasporto UrBackup con HTTPS.

## Rete e protocollo

Le porte standard del client sono UDP 35622 (discovery), TCP 35623 (comandi)
e TCP 35621 (file); Internet usa normalmente TCP 55415 sul server.
Queste porte devono ancora essere confermate nel binario portato.
Non cambiare le impostazioni degli altri client e non avviare backup personali.
La prima identità deve essere dedicata alle prove Tiger e le directory ammesse
esplicitamente limitate a fixture create dal porting.

## HFS+

Il codice 2.0.34 trasmette e ripristina extended attributes via getxattr/listxattr
su Darwin. Non è ancora una garanzia per resource fork: verificare un ciclo
backup/ripristino con com.apple.ResourceFork, FinderInfo, nomi Unicode, link,
permessi, mtime e contenuto. La prova di piattaforma ha creato un file temporaneo,
scritto 8 byte in /..namedfork/rsrc e letto gli stessi byte da getxattr;
compilazione Mach-O ppc e test/run sul Tiger completati con exit 0.
Questo prova solo le API di Tiger, non il round trip UrBackup.

## Prime correzioni verificate dal compilatore

Il primo configure falliva perché Apple ld riceveva due volte -syslibroot.
Il secondo configure completa i controlli con GCC 4.0.1 e rileva assenza
di syncfs/fallocate64, già facoltative. Il build raggiunge Database.cpp,
dove il pragma pack(push) senza valore è rifiutato dal compilatore Apple.
Si fornisce un valore esplicito; i layout serializzati vanno verificati
con test reali. pthread si trova in libSystem e non richiede -pthread,
flag non riconosciuto dal driver Apple. Queste correzioni non cambiano
il protocollo.

## Secondo passaggio sul G4

Il core, SQLite e Crypto++ 5.6.3 sono entrati nella compilazione nativa;
la compilazione estesa ha trovato usi vector::data non disponibili nella
libstdc++ Tiger. Il port fornisce un adattatore C++98 per i vettori, lasciando
invariato il contenuto dei buffer. Sono inoltre necessari cast espliciti
size_t→int64 nei parametri SQLite su PPC32.

Il trasferimento usa su Tiger il percorso upstream read/SendInt già presente,
poiché sendfile è successivo a Tiger e il vecchio ramo Darwin conteneva un
cast size_t*→off_t* scorretto su PPC32. Nessuna nuova implementazione di rete.

Il ripristino upstream usava stat64/O_SYMLINK/O_CLOEXEC e UF_HIDDEN non
presenti nell'SDK Tiger. Si usa stat nativo, e setattrlist con FSOPT_NOFOLLOW
per tempi/flag dei link; il bit UF_HIDDEN non esposto da Tiger è escluso.
Non confondere FinderInfo con il flag BSD UF_HIDDEN. Queste funzioni richiedono
ancora verifica runtime, oltre alla compilazione.

Corrette doppie conversioni little endian nel campo dimensione file inviato
con CWData::addUInt64 e nel campo lunghezza nome del canale metadati.
Il test --tiger-self-test confronterà byte attesi, layout, AES/SHA256 e
metadati locali appena disponibile il binario completo; non è ancora passato.

Server installato: 2.5.37.0. HTTP 55414 non in ascolto alla verifica; FastCGI
55413 risponde a richieste API e richiede inizializzazione/autenticazione di
sessione. Non sono stati riavviati processi o modificati backup esistenti.

## Limite HFS+ verificato sul sistema reale

setattrlist modifica correttamente il tempo dei file regolari ma restituisce
successo senza modificare quello dei link simbolici. La prova C indipendente
conferma il comportamento. Il sorgente Apple XNU 792.24.17 lo spiega:
[hfs_vnop_setattr](https://github.com/apple-oss-distributions/xnu/blob/xnu-792.24.17/bsd/hfs/hfs_vnops.c)
salta esplicitamente gli aggiornamenti dei timestamp per i vnode symlink.
Il port restituisce ENOTSUP per questa operazione e il restore registra
un avviso specifico, conservando link e destinazione senza toccare il target.
Non si dichiara preservato il timestamp dei symlink.

Il primo binario backend Mach-O ppc ha superato confronto byte del protocollo,
layout sparse extent, vettori noti AES/SHA256 e generazione casuale OS.
SQLite usa l'opzione upstream SQLITE_WITHOUT_ZONEMALLOC: evita la dipendenza
OSAtomicCompareAndSwapPtrBarrier assente in Tiger, senza riscrivere atomiche.
La CLI controller è compilata e --version passa sul G4.
Le fixture dedicate create e verificate sul G4 comprendono file binario, vuoto,
Unicode, symlink relativo, FinderInfo, resource fork e file con solo resource
fork; verifica locale di contenuto, mode, uid/gid e mtime passata.

## Avvio e controllo locale

Backend avviato e autoverifica completa passata, incluso il limite symlink
verificato. Il controller ha richiesto conversione little endian esplicita
anche nel proprio tcpstack, distinto da quello del backend.
add-backupdir/list-backupdirs passati con una sola fixture, senza seguire
link verso l'esterno e con limite al filesystem. L'avvio internet-only
richiede impostazioni Internet anche se si vuole soltanto il controllo
locale: per preparare il laboratorio si usa un endpoint locale chiuso e
una chiave fittizia, poi si disattiva Internet e si abilita la LAN.

Nuova identità server dedicata alle fixture: schedulazioni file e immagini
disabilitate, image_letters vuoto, default_dirs limitato alla fixture.
Nessun parametro degli altri sei client è stato cambiato. Il backend è
ora avviato in modalità LAN; riconoscimento e backup ancora da confermare.

## Comunicazione e primi full backup

Il server 2.5.37 riconosce il client 2.0.34-tiger1 come Mac OS X 10.4.11
Power Macintosh. TCP 35621/35623 raggiungibili, canale di controllo attivo.
Il primo full ha trasferito contenuti ma presentava un errore di metadati
con lunghezza nome invertita. Non viene considerato un backup verificato.
I full successivi hanno terminato con tutti i metadati presenti e zero
problemi segnalati dal server. Si usa una codifica esplicita little endian
per il campo lunghezza del canale metadati, verificata sul G4.

Durante l'avvio con directory configurata è emerso un crash riproducibile:
realpath(path,NULL) non è supportato da Tiger. Si fornisce PATH_MAX come
buffer e si preserva il comportamento di fallback dell'upstream.
Autoverifica di percorsi normali, link e ultimo componente assente passata.

Il client Darwin upstream chiamava dscacheutil, assente su Tiger, per utenti
e gruppi. Ora usa getpwent/getgrent con privilegi root, o l'utente effettivo
e i suoi gruppi senza root. I file credenziali dei gruppi in modalità utente
restano di proprietà dell'utente effettivo e leggibili dal processo.
L'autoverifica verifica la presenza dell'utente/gruppo correnti senza
stamparne i nomi. Il browser CLI del backup ora elenca il full completato.
L'installazione per utente può ripristinare i proprietari consentiti dal
sistema; il servizio root non è stato verificato e non viene installato.

I log grezzi upstream possono includere credenziali di controllo e identificativi
di canale: non si pubblicano. Il lettore di laboratorio filtra i messaggi
sensibili; nessun file di stato, chiave o inventario utenti entra nel pacchetto.

## Primo confronto di ripristino: difetti trovati e correzioni

Un restore via CLI in directory separata è terminato secondo il protocollo,
ma il verificatore ha rilevato resource fork mancante su un file che aveva
anche FinderInfo e mtime errato su un file con solo resource fork.
Questi backup di prova precedenti alla correzione NON certificano HFS+.

Causa della prima perdita: l'upstream passava "\0" come std::string di
separatori, che diventa una stringa vuota. I nomi di più xattr venivano
concatenati; il sistema vedeva soltanto il primo nome. Si passa un separatore
NUL di lunghezza uno sia nella lettura backup sia nella rimozione restore.
Il ripristino rifiuta ora un nome xattr vuoto o contenente NUL, invece di
applicarlo parzialmente e dichiarare successo. L'autoverifica confronta
una lista NUL-separated di due attributi con i due nomi attesi.

Causa del tempo errato: scrivere un resource fork cambia mtime su HFS+.
Per file regolari e directory Darwin, permessi/tempi/flag finali vengono
applicati dopo tutti gli xattr, con propagazione degli errori. I symlink
vengono preparati prima degli xattr e conservano il limite documentato.
La prova full/restore deve essere ripetuta dopo queste correzioni.

La fixture è estesa anche a directory annidata con permessi propri e
file figlio. L'installazione preparata è per l'utente dell'iBook, non root,
con LaunchAgent Tiger (OnDemand=false), nessun componente Freebox a runtime.
L'installazione e l'avvio launchd devono ancora essere verificati.

## Verifica incrementale e chiusura dello stato restore (2026-10-28)

Stato iniziale rilevato: il client Tiger completava i restore e conservava i
metadati HFS+, ma il server poteva mostrare un processo `action=8` con
`pcdone=0`. Nel database il restore 2 risultava `done=1`, `success=0`, con
chiusura alle 21:50:21, esattamente al timeout del watchdog di cinque minuti.
Il client aveva invece registrato `Restore finished successfully` alle 22:45:21
locali (21:45:21 UTC). Non era quindi un processo realmente attivo: era stato
perso il messaggio di completamento sul canale di controllo.

Causa verificata: durante restore molto piccoli il `FileClient` va in timeout,
si riconnette e aggiunge un nuovo canale in coda a `channel_pipes`.
`sendMessageToChannel` cercava il primo canale con il token del server, cioè il
più vecchio, senza scartare canali chiusi o in errore. `RESTORE DONE` poteva
quindi essere scritto su un socket obsoleto; il server non aggiornava il DB e
chiudeva il restore come fallito dopo cinque minuti.

Correzione: la selezione dei canali per log, avanzamento e completamento ora
parte dal più recente, ignora canali in uscita, nulli o con errore e prosegue
con gli altri se una scrittura non riesce. Non cambia il protocollo e resta
compatibile con il server upstream.

Verifica eseguita sul G4 con fixture dedicata:

1. backup incrementale server id 3480, `incremental=1`, `complete=1`,
   `done=1` e nessun problema;
2. fixture mutata in modo controllato (contenuto, mtime e resource fork,
   inclusa la variante con solo resource fork);
3. restore dell'incrementale nel nuovo path di laboratorio
   `fixtures/restored-incr-fix-20261028`;
4. restore server id 3 chiuso in due secondi con `done=1`, `success=1`;
5. verifica fixture PASS per contenuto, mode, uid/gid, mtime, resource fork,
   FinderInfo, Unicode, directory annidata e symlink relativo;
6. stato live subito dopo: client online, lista processi vuota, nessun
   `action=8` residuo.

Durante il test il client ha ripresentato lo stesso timeout del `FileClient` e
la stessa riconnessione che avevano causato il difetto: il server ha comunque
ricevuto il completamento. Questo distingue la verifica dalla semplice
rimozione del record.

Nota operativa sulla web UI: al riavvio di verifica il processo manuale del
server aveva trovato la porta HTTP 55414 già occupata da una vecchia istanza,
pur continuando a servire la porta client 55413. Dopo aver verificato che non
c'erano job attivi, il processo è stato chiuso e il servizio systemd è stato
avviato: 55413, 55414 e 55415 sono in ascolto e la UI risponde HTTP 200.
Questo problema era di avvio del servizio, non del porting Tiger.

Nota sullo stato "Disabled" della UI: il profilo di laboratorio del client
Tiger ha gli intervalli `update_freq_incr`, `update_freq_full`,
`update_freq_image_incr` e `update_freq_image_full` impostati a `-86400`.
Significa che i backup pianificati sono intenzionalmente disabilitati; i test
sono stati eseguiti con backup avviati manualmente. La UI 2.5.37 distingue
questo caso da "No recent backup" e mostra "Disabled" in verde. "Not supported"
per le immagini è invece atteso su Tiger/PowerPC. Per riattivare la
pianificazione basta impostare frequenze positive nelle impostazioni del
client; la modifica non è stata applicata perché introdurrebbe job automatici
nel laboratorio.

Limiti residui: Tiger HFS+ non consente di impostare il timestamp dei symlink;
il solo avvio tramite LaunchAgent non è ancora stato verificato. Il server
upstream conserva il watchdog di cinque minuti e non esiste ancora un ACK
applicativo bilaterale per `RESTORE DONE`; la correzione elimina la selezione
del canale obsoleto osservata, ma non trasforma il protocollo in una consegna
con conferma end-to-end.

## Avvio del porting GUI (2026-10-28)

Il frontend ufficiale `uroni/urbackup_frontend_wx` tag 2.0.34, commit
`7c76b0e23e5e33ae355bd59bf9b59f2e91e1ab71`, è stato importato in `client/`
(175 file, circa 5,3 MiB) per riutilizzare il tray wx originale. Il backend
resta basato su `2.0.34client`, commit
`8cd27193b8370df739ad08c6f72750ebe3c7fe11`.

Gli adattamenti sono limitati a foreground e login item Tiger, framework
Carbon/CoreServices/Security, lookup delle traduzioni, packaging del bundle e
installazione nel prefisso di laboratorio. La build usa wxWidgets 3.0.5.1
Carbon statico PPC; le incompatibilità SDK 10.4 trovate finora sono raccolte
nella patch riproducibile `tiger/deps/wx-3.0.5.1-tiger-10.4.patch`.

La build wx ha compilato 252 oggetti e si è fermata su
`kCTFontMonoSpaceTrait` in `src/osx/core/fontenum.cpp`, costante CoreText non
disponibile nell'SDK 10.4. Non sono ancora stati compilati, installati o
verificati il frontend UrBackup, il bundle, l'icona nella menu bar e le
finestre Settings/Logs. Stato e comandi di ripresa sono in
`docs/tiger/gui.md`; nessun test GUI è dichiarato riuscito.

## Build GUI completata (2026-10-28, seconda sessione)

La nota precedente è superata. wxWidgets 3.0.5.1 Carbon PPC è stato compilato
per intero e installato; `kCTFontMonoSpaceTrait` e le altre costanti 10.5 sono
state coperte da fallback nella patch. Anche `kCGBlendModePlusLighter` è stato
corretto a 27 (il valore 26 è `kCGBlendModePlusDarker`).

Sono stati prodotti `urbackupclientgui` (Mach-O ppc, link statico a wx), il
pacchetto `UrBackupTiger-2.0.34-ppc.tar.gz` e l'installazione in
`/Volumes/Daniele/Library/UrBackupTigerLab`, con `--tiger-self-test` superato.
Resta aperta la sola verifica visiva su sessione Aqua (icona nella menu bar,
menu, Settings/Logs), che richiede il login grafico dell'utente `daniele`.

Dettaglio completo in `docs/tiger/gui.md`.
