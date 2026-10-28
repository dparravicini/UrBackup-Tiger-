# Porting GUI UrBackup 2.0.34 su Tiger PowerPC

## Provenienza e obiettivo

Il frontend riutilizzato è quello ufficiale `uroni/urbackup_frontend_wx`, tag
`2.0.34`, commit `7c76b0e23e5e33ae355bd59bf9b59f2e91e1ab71`. I sorgenti sono
stati importati in `client/` senza la cronologia Git del repository originale
(175 file, circa 5,3 MiB). Il backend di riferimento resta il tag ufficiale
`2.0.34client`, commit `8cd27193b8370df739ad08c6f72750ebe3c7fe11`.

L'obiettivo è compilare il tray wx originale su Mac OS X 10.4 PPC, conservando
icone, voci di menu, finestre, traduzioni e stati. Non sono stati creati nuovi
asset o una nuova interfaccia.

## Toolchain scelta

La GUI usa wxWidgets 3.0.5.1 con backend Carbon, compilato staticamente per
PowerPC con SDK 10.4u e GCC 4.0.1. wxOSX/Cocoa moderno non è adatto a Tiger;
wxWidgets 3.0.5.1 dispone ancora del port Carbon, con alcune API che richiedono
però adattamenti a 10.4.

Directory sul G4:

```text
/Volumes/Daniele/Projects/.tiger-devkit/deps/wxWidgets-3.0.5.1
/Volumes/Daniele/Projects/.tiger-devkit/deps/wxWidgets-3.0.5.1/build-carbon-ppc-nogl
/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc
```

Configurazione usata:

```sh
../configure --with-carbon \
  --with-macosx-sdk=/Developer/SDKs/MacOSX10.4u.sdk \
  --with-macosx-version-min=10.4 --enable-macosx_arch=ppc \
  --disable-shared --enable-static --enable-monolithic --disable-debug \
  --disable-dependency-tracking --without-opengl --disable-stc \
  --disable-webview --disable-webkit --disable-richtooltip \
  --prefix=/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc
```

## Adattamenti nel repository

- `client/osxutils.mm`: foreground con `SetFrontProcess` Carbon; login item
  tramite `NSAppleScript`/System Events su Tiger e `LSSharedFileList` solo sul
  ramo 10.5+.
- `Makefile.am` e `Makefile.in`: framework Carbon, CoreServices e Security al
  posto di ServiceManagement, assente in Tiger.
- `client/main.cpp`: lookup delle traduzioni sia in `DATADIR/urbackup` sia in
  `DATADIR/urbackup/lang`.
- `client/stringtools.cpp`, `client/stringtools.h`: `#undef isnumber` e
  `#undef isletter` su Darwin, dove `<ctype.h>` le definisce come macro e
  impedisce la dichiarazione delle funzioni omonime del client.
- `tiger/build.sh`: richiede `wx-config` e compila backend, CLI e GUI senza
  `--enable-headless`.
- `tiger/package.sh`: include il binario GUI, le risorse originali e il bundle
  `UrBackup Client.app`.
- `tiger/install.sh`: installa GUI, risorse e bundle nel prefisso di
  laboratorio, mantenendo il controllo che vieta l'avvio automatico senza
  directory esplicite.

## Patch wxWidgets per Tiger

`tiger/deps/wx-3.0.5.1-tiger-10.4.patch` è stato rigenerato per diff diretto
contro il tarball ufficiale `wxWidgets-3.0.5.1.tar.bz2`: 741 righe, 18 file.
Copre:

- `AudioServices` e `HIWindowGetAvailablePositioningBounds`, assenti
  nell'SDK 10.4 (`utils.cpp`, `utils_osx.cpp`, `nonownedwnd.cpp`);
- limiti dello schermo tramite `GetMainDevice`, con ritorno alle API moderne
  quando disponibili;
- costanti IconServices per 16/32/48/128/512 px assenti nell'header Tiger,
  necessarie alle icone originali del tray (`core/bitmap.cpp`);
- fallback `CGColorCreate`/`CGColorCreateGenericRGB` per Quartz su 10.4
  (`core/colour.cpp`);
- `typedef SRefCon`/`URefCon` e tabella `kVK_` completa (`app.cpp`);
- shim CoreText per `CTFontCreateWithName`, `CTFontCreateWithFontDescriptor`,
  `CTFontCreateCopyWithAttributes`, `CTFontGetSymbolicTraits`,
  `CTFontGetStringEncoding`, `CTFontUIFontType` e `kCTFontMonoSpaceTrait`
  (`font.cpp`, `core/fontenum.cpp`);
- costanti `kCGBlendMode*` assenti in 10.4; `kCGBlendModePlusLighter` vale
  **27** (il valore 26 è `kCGBlendModePlusDarker`, usato per errore nella
  prima build del 2026-10-28 e corretto in questa sessione) (`graphics.cpp`);
- `kHIThemeTextInfoVersionZero` (`listctrl_mac.cpp`);
- `typedef URefCon` (`menu.cpp`, `nonownedwnd.cpp`, `taskbar.cpp`);
- `kEventControlFocusPartChanged = 164`, conversione del mouse con
  `GetGlobalMouse`/`HIPointConvert` e font di controllo con
  `SetControlFontStyle` (`window.cpp`);
- ritocchi minori in `dataobj.cpp`, `dcprint.cpp`, `fontdlg.cpp`,
  `region.cpp`, `core/printmac.cpp`.

Verifica di riproducibilità: `patch -p1 --dry-run` sull'albero 3.0.5.1
appena scompattato applica tutti e 18 i file senza reject (2026-10-28).

## Stato al 2026-10-28 (seconda sessione)

Build completata sul G4, con `wx-config --version` = `3.0.5` e libreria
statica `libwx_osx_carbonu-3.0.a`:

```sh
PATH=/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/bin:$PATH \
  sh tiger/build.sh
```

Risultati verificati:

- `urbackupclientbackend`, `urbackupclientctl` e `urbackupclientgui` sono
  `Mach-O executable ppc`;
- `otool -L urbackupclientgui` non elenca alcuna libreria wx dinamica: il
  frontend è linkato staticamente;
- pacchetto `UrBackupTiger-2.0.34-ppc.tar.gz` (47.023.663 byte, 2026-10-28
  15:37) con `install.sh`, bundle, risorse, traduzioni e documentazione;
- installazione in `/Volumes/Daniele/Library/UrBackupTigerLab` completata;
- `--tiger-self-test` superato: resource fork, FinderInfo, timestamp regolari,
  flag dei symlink, xattr NUL-separati, enumerazione account, framing little
  endian, Crypto++ AES/SHA256, `realpath` con buffer del chiamante;
- limite noto confermato: Darwin 8 non imposta i timestamp dei symlink su HFS+
  (`LIMIT verified`);
- backend di laboratorio riavviato con
  `--daemon --pidfile ... --logfile ... --restore client-confirms`.

## Verifica visiva: ancora aperta

La verifica dell'icona nella menu bar e delle finestre originali non è stata
eseguita. Dopo il riavvio del G4 `/dev/console` appartiene a `root`, cioè la
macchina è ferma al login window: da SSH non esiste alcuna sessione Aqua e
qualunque processo grafico non può comparire nella barra dei menu. Serve un
login grafico dell'utente `daniele` sul monitor del G4 prima di poter
dichiarare riuscito questo punto.

## Nota sull'icona del bundle

`osx_installer/urbackup.icns` nel sorgente ufficiale è un file di istruzioni
testuale di 720 byte, non un ICNS valido. Le icone di stato usate dal tray sono
invece gli asset originali `client/data/*.ico`. Il bundle non deve essere
presentato come dotato di una nuova icona applicativa: l'eventuale icona
Finder resta un limite da verificare senza modifiche estetiche.

## Prossimi passi

1. Login grafico di `daniele` sul G4 con il display acceso.
2. Avviare `/Volumes/Daniele/Library/UrBackupTigerLab/Applications/UrBackup
   Client.app` nella sessione Aqua e catturare uno screenshot con
   `screencapture`.
3. Verificare icona nella menu bar, menu contestuale, Settings, Logs, stati
   dinamici e collegamento al backend già in esecuzione.
4. Aggiornare questo documento con l'esito reale, quindi commit e push.

## Nota sullo stato "Disabled"

La web UI mostra `File backup status: Disabled` perché il profilo di
laboratorio ha `update_freq_incr`, `update_freq_full`,
`update_freq_image_incr` e `update_freq_image_full` impostati a `-86400`.
UrBackup interpreta i valori negativi come pianificazione disabilitata; non è
un errore del server né del porting. Non è stato cambiato per non introdurre
backup automatici indesiderati nel laboratorio.

## Esito della verifica visiva (2026-10-28 16:52)

Con l'utente `daniele` regolarmente loggato in console (`who` mostra
`daniele console`, `/dev/console` di `daniele`) il bundle è stato avviato con
`open` e il processo resta attivo (PID 5834, poi 5935); screencapture su
`:0` funziona.

Risultato reale: **nessuna icona nella menu bar e nessuna icona nel Dock.**

Causa individuata nel codice, non presunta:

- `client/TrayIcon.cpp:65` deriva da `wxTaskBarIcon()` senza tipo esplicito.
- In wxWidgets 3.0.5.1 il port **Carbon non implementa gli status item**:
  `src/osx/carbon/taskbar.cpp` crea `wxDockTaskBarIcon` e asserisce
  `Only the wxTBI_DOCK implementation of wxTaskBarIcon on Mac-Carbon is
  currently supported!`. Su Carbon quindi `wxTaskBarIcon` coincide con
  l'icona del Dock dell'applicazione (`SetApplicationDockTileImage`).
- Il bundle dichiara `LSUIElement=1` in `osx_installer/info.plist`, quindi
  l'applicazione è invisibile nel Dock: l'icona viene impostata su una tile
  che non esiste e non è visibile da nessuna parte.

Non è un errore di build né di linkaggio: `SetIcon` restituisce successo
(nessun `Setting icon failed.` nei log) e il backend IPC funziona. È una
lacuna del port Carbon di wx 3.0.5.1 rispetto al port Cocoa, dove esiste
`wxTBI_CUSTOM_STATUSITEM` (NSStatusItem).

### Lavoro residuo necessario

Per ottenere la vera icona nella barra dei menu su Tiger serve uno status item
nativo: `NSStatusItem` esiste in 10.4 e l'applicazione linka già
`Cocoa.framework`, quindi l'intervento minimo è un piccolo file
Objective-C++ (sul modello di `client/osxutils.mm`) che:

1. crea `[[NSStatusBar systemStatusBar] statusItemWithLength:...]`;
2. converte il `wxIcon`/`wxBitmap` già usato dal tray in `NSImage`;
3. inoltra il click al menu wx esistente (`TrayIcon::CreatePopupMenu`).

Va mantenuto lo stesso set di icone originali e lo stesso menu; non è una
nuova GUI, è l'implementazione mancante dell'host toolkit. Fino a quel
momento il requisito "icona nella menu bar" resta **non soddisfatto**.

### Alternativa immediata, senza nuovo codice

Rimuovere `LSUIElement` dal bundle: l'icona del tray comparirebbe nel Dock
con il menu funzionante (implementazione dock di wx Carbon). Non è la menu
bar e cambia il comportamento originale, quindi non è stata applicata.
