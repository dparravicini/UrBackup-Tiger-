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
