# UrBackup Tiger PowerPC — porting in corso

Client UrBackup nativo per Mac OS X 10.4.11 PPC, basato su 2.0.34client.
**Non ancora pronto per backup reali.** Nessun backup/ripristino ancora verificato.

- [Analisi, architettura e limiti](docs/tiger/analisi.md)
- [Valutazione macTLS e macsurf](docs/tiger/mactls.md)
- `tiger/probes`: prova reale del profilo macTLS e resource fork.
- `tiger/build.sh`: build headless GCC 4.0.1 con SDK 10.4u.

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
