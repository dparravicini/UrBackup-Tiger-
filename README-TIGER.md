# UrBackup Tiger PowerPC

Client UrBackup nativo per Mac OS X 10.4.11 PowerPC, basato su 2.0.34client.
Backend, CLI e GUI wx sono Mach-O PowerPC e vengono eseguiti sul G4.

## Stato

- Build e self-test del backend: PASS.
- GUI wx Carbon: funzionante con backend attivo.
- Impostazioni: i tre tab `Backup File`, `Client` e `Internet` si attivano e i
  campi sono modificabili; il salvataggio e' stato verificato sul G4.
- Percorsi di backup: apertura della finestra, aggiunta e rimozione di una
  cartella, salvataggio, riavvio del backend e persistenza verificati sul G4.
  Il selettore nativo Tiger non viene usato perche' `NavigationServices`
  provoca un crash; la GUI chiede il percorso completo della cartella.
- Log e Infos: aperti senza il crash CoreText osservato nelle prime build.
- Icona applicativa: ICNS Tiger valido ricavato dall'asset UrBackup
  `backup-ok.ico`; Finder mostra il cilindro UrBackup al posto dell'icona
  generica. Verificato sul G4 dopo il riavvio di Finder.
- Backup di `/etc`: verificato completo sul server. Il client esclude soltanto
  i file root-only non leggibili dall'utente `daniele`, come descritto in
  `docs/tiger/gui.md`.
- Backup incrementale con il bundle finale installato in `/Applications`:
  avviato dal server e completato con `Completed successfully`.
- Pacchetto: app in `/Applications`, DMG e TAR redistribuibili generati da
  `tiger/package.sh`. Il bundle bit HFS e' impostato sia nell'app installata
  sia nella copia dentro il DMG.
- Accesso alla GUI: il bundle si avvia da `Applicazioni` e le finestre
  rispondono. Nella sessione Tiger usata per la verifica non sono state viste
  ne' l'icona nel Dock ne' lo status item nella barra dei menu, quindi il menu
  non e' un punto di accesso verificato. Usare i comandi indicati sotto.
  Dettagli e prove in `docs/tiger/gui.md`.

## Installazione

1. Aprire `UrBackupTiger-2.0.34-ppc.dmg`.
2. Trascinare `UrBackup Client` in `Applicazioni`.
3. Avviarlo da `Applicazioni`: il backend parte automaticamente.
4. Aprire `Impostazioni` con:
   `/Applications/UrBackup\ Client.app/Contents/MacOS/urbackupclientgui settings`
5. Per configurare le cartelle usare `paths`; la GUI chiede il percorso
   completo, ad esempio `/etc`, e non apre il selettore nativo instabile:
   `/Applications/UrBackup\ Client.app/Contents/MacOS/urbackupclientgui paths`

I dati utente sono separati per account in:

```text
~/Library/Application Support/UrBackupTiger
```

Il pacchetto non contiene server, credenziali o dati personali. Il server
UrBackup va configurato nelle Impostazioni del client.

Se si abilita il backup di `/etc`, configurare prima le esclusioni per i file
di sistema non leggibili dall'utente del client. La procedura verificata e'
in [Porting GUI wx e verifiche Tiger](docs/tiger/gui.md#backup-di-etc).

## Build e pacchetto

La build Tiger usa GCC 4.0.1, SDK 10.4u e la wx Carbon statica gia' preparata
nel devkit:

```sh
PATH=/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  make -j2 urbackupclientbackend urbackupclientctl urbackupclientgui
PATH=/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  sh tiger/package.sh
```

`tiger/package.sh` esegue il self-test, produce
`UrBackupTiger-2.0.34-ppc.dmg` e `UrBackupTiger-2.0.34-ppc.tar.gz`, e verifica
il DMG con `hdiutil verify`.

## Documentazione

- [Analisi, architettura e limiti](docs/tiger/analisi.md)
- [Porting GUI wx e verifiche Tiger](docs/tiger/gui.md)
- [Lezioni apprese e checklist per un nuovo porting Tiger](docs/tiger/porting-lessons.md)
- [Valutazione macTLS e macsurf](docs/tiger/mactls.md)
- `tiger/probes`: profilo macTLS e resource fork.
- `tiger/build.sh`: build GCC 4.0.1 con SDK 10.4u.

Limite HFS+ noto: Darwin 8 non imposta i timestamp dei symlink; contenuto,
permessi e destinazione vengono comunque ripristinati.
