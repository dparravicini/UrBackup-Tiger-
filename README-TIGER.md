# UrBackup Tiger PowerPC — porting in corso

Client UrBackup nativo per Mac OS X 10.4.11 PPC, basato su 2.0.34client.
**Porting in verifica.** Backend e CLI Mach-O PowerPC compilati ed eseguiti sul G4. Backup incrementale e restore incrementale verificati su fixture dedicata, inclusi contenuti, resource fork, FinderInfo, permessi e symlink. La chiusura del restore sul server non lascia più processi fantasma nel caso osservato.

- [Analisi, architettura e limiti](docs/tiger/analisi.md)
- Stato restore e test incrementale: verificati il 2026-10-28; resta il limite HFS+ sui timestamp dei symlink.
- [Valutazione macTLS e macsurf](docs/tiger/mactls.md)
- [Porting GUI wx originale: stato e ripresa](docs/tiger/gui.md)
- `tiger/probes`: prova reale del profilo macTLS e resource fork.
- `tiger/build.sh`: build GCC 4.0.1 con SDK 10.4u per backend, CLI e GUI wx.

Il frontend ufficiale `uroni/urbackup_frontend_wx` 2.0.34 è importato in
`client/`. La GUI wx Carbon è compilata staticamente per PowerPC, impacchettata
e installata nel prefisso di laboratorio; l'icona nella menu bar e le finestre
non sono ancora verificate perché richiedono una sessione grafica attiva sul
G4. Il dettaglio aggiornato e il punto di ripresa sono in
`docs/tiger/gui.md`.

Usa Vintage-DevKit separato, senza modificarlo. Sulla Freebox:
```
cd /home/freebox/ports/urbackup-tiger/tiger/probes
tiger build && tiger test && tiger deploy && tiger run
cd ../..
# configure and Makefile.in are supplied; regenerate on Debian if needed:
# sh tiger/prepare.sh
tiger --timeout 3600 build
```

Non installare ancora il client né configurare avvio automatico. La fase corrente
compila in directory isolate del DevKit. Le prove usano esclusivamente fixture
temporanee proprie; non modificano directory personali o configurazioni server.
I log grezzi e gli artefatti .tiger/build non entrano nel repository.

Il controller locale richiede anch'esso lunghezze pacchetto little endian;
il port corregge questo framing e la selezione della fixture tramite CLI
è passata sul target. Il laboratorio usa un'identità distinta, frequenze
automatiche disabilitate e la sola directory di fixture; nessun altro client
è stato modificato. `tiger/lab/server_api.py` è un client di test per l'API
FastCGI già presente sul server: non avvia servizi e non salva sessioni.
