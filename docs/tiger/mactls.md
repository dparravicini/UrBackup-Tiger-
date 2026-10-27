# Valutazione macTLS prima delle altre dipendenze crypto

Sorgenti esaminati:
- https://github.com/mplsllc/macTLS , commit 66b48e9b58e69696718995bc7b3ce0b051be74ac
- https://github.com/mplsllc/macsurf , commit a67cda7956678bf410c046258926cda15cbb9a3e

macTLS espone TLS 1.2 tramite BearSSL e TLS 1.3 tramite il proprio handshake
che riusa primitive BearSSL. Il README riporta prove su G3/OS 9; queste prove
non sono state ripetute qui. API stream OSTLS_New/Start/Pump/Read/Write/Close.
Nel codice sono presenti trust anchor Mozilla, validatore X.509 BearSSL,
passaggio del nome server, verifica tempo e rifiuto degli errori. La versione
esaminata non fornisce autenticazione tramite certificato client.

Impedimento verificato: macsurf_runtime_profile.h classifica __APPLE__ con GCC
come MACSURF_HOST_STUB_BUILD=1 e MACSURF_CLASSIC_RUNTIME=0. La prova compilata
ed eseguita sul Tiger tramite build/test/deploy/run conferma classic=0,
host_stubs=1. ostls_async.c in questo profilo usa OTConnect/OTRcv e TickCount
simulati; ostls_time.c usa GetDateTime simulato a zero. Una compilazione che
passa non implica una connessione reale o verifica certificati utilizzabile.
Il percorso reale richiede Carbon/Open Transport, contesto OT, notifier e
runtime Classic/CFM selezionato da CodeWarrior o macMAKE Classic PPC. Non è
stato provato che forzare quel profilo produca una libreria Mach-O funzionante.
Il repository macsurf esaminato pubblica README e immagini, non i sorgenti
del browser necessari a recuperare un eventuale adattatore Darwin.

Decisione: non riusare direttamente macTLS nel client UrBackup. Un adattatore
TLS socket non implementa AES-CFB/GCM, firme DSA/ECDSA, ECDH e derivazione
richiesti da ICryptoFactory/CryptoFactory e InternetServicePipe(2). Sostituirlo
modificherebbe il protocollo, senza necessità. Si mantiene Crypto++ 5.6.3
richiesto dall'upstream. Non si implementa una nuova libreria TLS, né si
aggiunge una dipendenza TLS non usata dal protocollo. Se servirà HTTPS per
una funzione successiva, valutare separatamente un trasporto TLS con socket
BSD e validazione completa su Tiger, senza riaprire infrastruttura OS 9.
