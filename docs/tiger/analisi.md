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
