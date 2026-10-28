# UrBackup Tiger PowerPC

Client UrBackup nativo per Mac OS X 10.4.11 PowerPC, basato su 2.0.34client.
Backend, CLI e GUI wx sono Mach-O PowerPC e vengono eseguiti sul G4.

## Stato

- Build e self-test del backend: PASS.
- GUI wx Carbon: funzionante con backend attivo.
- Impostazioni: i tre tab `Backup File`, `Client` e `Internet` si attivano e i
  campi sono modificabili; il salvataggio e' stato verificato sul G4.
- Log e Infos: aperti senza il crash CoreText osservato nelle prime build.
- Pacchetto: app in `/Applications`, DMG e TAR redistribuibili generati da
  `tiger/package.sh`. Il bundle bit HFS e' impostato sia nell'app installata
  sia nella copia dentro il DMG.
- Menu bar: implementata con `NSStatusItem` nativa Tiger. L'icona e' stata
  vista nelle prove precedenti, ma nella sessione console attuale del G4 gli
  status item di terze parti non vengono mostrati nemmeno da un'app minima di
  test. Il limite e' quindi dell'ambiente Tiger/SystemUIServer di quella
  sessione, non della GUI. Dettagli e prove in `docs/tiger/gui.md`.

## Installazione

1. Aprire `UrBackupTiger-2.0.34-ppc.dmg`.
2. Trascinare `UrBackup Client` in `Applicazioni`.
3. Avviarlo da `Applicazioni`: il backend parte automaticamente.
4. Aprire `Impostazioni` dal menu dell'icona o con:
   `/Applications/UrBackup\ Client.app/Contents/MacOS/urbackupclientgui settings`

I dati utente sono separati per account in:

```text
~/Library/Application Support/UrBackupTiger
```

Il pacchetto non contiene server, credenziali o dati personali. Il server
UrBackup va configurato nelle Impostazioni del client.

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
- [Valutazione macTLS e macsurf](docs/tiger/mactls.md)
- `tiger/probes`: profilo macTLS e resource fork.
- `tiger/build.sh`: build GCC 4.0.1 con SDK 10.4u.

Limite HFS+ noto: Darwin 8 non imposta i timestamp dei symlink; contenuto,
permessi e destinazione vengono comunque ripristinati.
