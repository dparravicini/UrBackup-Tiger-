# Porting GUI UrBackup 2.0.34 su Tiger PowerPC

## Provenienza e obiettivo

Il frontend riutilizzato è quello ufficiale `uroni/urbackup_frontend_wx`, tag
`2.0.34`, commit `7c76b0e23e5e33ae355bd59bf9b59f2e91e1ab71`. I sorgenti sono
stati importati in `client/` senza la cronologia Git del repository originale
(175 file, circa 5,3 MiB). Il backend di riferimento resta il tag ufficiale
`2.0.34client`, commit `8cd27193b8370df739ad08c6f72750ebe3c7fe11`.

La checklist riutilizzabile per un altro porting Tiger e' in
[Lezioni apprese](porting-lessons.md).

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
Vanno applicate anche `tiger/deps/wx-3.0.5.1-tiger-uifont.patch` e
`tiger/deps/wx-3.0.5.1-tiger-fontattrs.patch`, che contengono le correzioni
CoreText finali. Insieme coprono:

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
  (`font.cpp`, `core/fontenum.cpp`); su Tiger `MacFindFont` usa direttamente
  il font UI Carbon e non i descrittori CoreText 1.0.4, che causavano
  `EXC_BAD_ACCESS` alla creazione delle finestre con campi di testo;
- costanti `kCGBlendMode*` assenti in 10.4; `kCGBlendModePlusLighter` vale
  **27** (il valore 26 è `kCGBlendModePlusDarker`, usato per errore nella
  prima build del 2026-10-28 e corretto in questa sessione) (`graphics.cpp`);
- `kHIThemeTextInfoVersionZero` (`listctrl_mac.cpp`);
- `typedef URefCon` (`menu.cpp`, `nonownedwnd.cpp`, `taskbar.cpp`);
- `kEventControlFocusPartChanged = 164`, conversione del mouse con
  `GetGlobalMouse`/`HIPointConvert` e font di controllo con
  `SetControlFontStyle` (`window.cpp`);
- attributi CoreText nulli su Tiger: `wxNativeFontInfo::Init` e la creazione
  del font di sistema ora controllano descrittore, dimensione, traits e nome
  famiglia prima di chiamare `CFNumberGetValue` (`font.cpp`, patch
  `wx-3.0.5.1-tiger-fontattrs.patch`);
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

## Prima verifica visiva: sessione Aqua assente

La verifica dell'icona nella menu bar e delle finestre originali non è stata
eseguita. Dopo il riavvio del G4 `/dev/console` appartiene a `root`, cioè la
macchina è ferma al login window: da SSH non esiste alcuna sessione Aqua e
qualunque processo grafico non può comparire nella barra dei menu. Serve un
login grafico dell'utente `daniele` sul monitor del G4 prima di poter
dichiarare riuscito questo punto.

## Icona del bundle

`osx_installer/urbackup.icns` nel sorgente ufficiale è un file di istruzioni
testuale di 720 byte, non un ICNS valido. Il bundle finale usa invece un ICNS
generato dall'asset originale `client/data/backup-ok.ico` con gli elementi
legacy `is32`, `il32`, `ih32` e `it32`, necessari per la compatibilità con
Mac OS X 10.4. Dopo l'installazione e il riavvio di Finder, sul G4 l'app
mostra il cilindro UrBackup al posto dell'icona generica.

Il formato moderno creato da `iconutil` non viene riconosciuto da Tiger: il
file viene visto come `data` e non mostra l'icona. Anche `sips` di Tiger non
supporta la scrittura ICNS. La verifica corretta richiede quindi un ICNS con
gli elementi legacy e un refresh di LaunchServices/Finder.

## Prossimi passi originali (superati dalla sezione finale)

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
- Il bundle usato in quella prova dichiarava `LSUIElement=1` in
  `osx_installer/info.plist`, quindi l'applicazione era invisibile nel Dock:
  l'icona veniva impostata su una tile che non esisteva.

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

### Alternativa senza nuovo codice

Rimuovere `LSUIElement` dal bundle: l'icona del tray comparirebbe nel Dock
con il menu funzionante (implementazione dock di wx Carbon). Non è la menu
bar e cambia il comportamento originale. È stata applicata nel bundle finale,
ma nella sessione usata per la verifica l'icona del Dock non è comparsa:
pertanto non viene considerata una soluzione verificata.

## Stato finale al 2026-10-28 23:00

### Risultato funzionale

La GUI e il backend sono utilizzabili sul G4 con la build definitiva in
`/Applications/UrBackup Client.app`. Il backend viene avviato automaticamente
dal bundle e usa i dati dell'utente in:

```text
~/Library/Application Support/UrBackupTiger
```

Il problema iniziale delle Impostazioni non era un errore dei widget: con il
backend attivo il tab `Client` si attiva, i campi sono modificabili e il valore
viene salvato in `var/urbackup/data/settings.cfg`. La prova di laboratorio ha
salvato `update_freq_incr=3600`; il profilo di laboratorio e' stato poi
ripristinato a `-86400`. Il primo click su una finestra non attiva serve solo a
portarla in primo piano; il click successivo cambia tab.

Sono stati verificati:

- apertura dei tre tab `Backup File`, `Client` e `Internet`;
- modifica e salvataggio di un valore numerico;
- apertura di `Logs` e `Infos` senza il crash CoreText delle prime build;
- avvio del backend da `/Applications`, senza backend di laboratorio gia'
  attivo;
- bundle bit HFS presente nell'app installata e nella copia montata dal DMG;
- self-test del backend PASS e `hdiutil verify` del DMG VALID.

### Correzioni Tiger applicate

- framing IPC little endian e percorsi portabili;
- avvio automatico del backend dal bundle;
- bundle self-configurante e niente `sudo` su Carbon;
- gestione sicura delle icone nei dialoghi per evitare il crash CoreText;
- null dereference in `GUISettings` corretto;
- `SetFile -a B` sull'app, sia nello stage sia nella copia del DMG: senza
  bundle bit Tiger rifiuta l'apertura con LaunchServices `-10829`;
- rimosso `LSUIElement` dal bundle per consentire l'avvio come applicazione
  normale; l'icona nel Dock non è però comparsa nella sessione di prova;
- sostituito l'ICNS segnaposto con un'icona UrBackup legacy compatibile con
  Tiger e verificata in Finder;
- tray implementato con `NSStatusItem` e caricamento diretto dell'ICO in
  `NSBitmapImageRep` RGBA, per conservare alpha e trasparenza.

### Limite residuo della menu bar

Nella sessione console del G4 usata per l'ultima verifica non erano visibili
ne' l'icona UrBackup nel Dock ne' lo status item nella barra dei menu. Non e'
un errore del codice applicativo: un'app minima che crea soltanto un
`NSStatusItem` con titolo `TEST4` non compare, pur essendo il processo vivo e
nonostante il riavvio di `SystemUIServer`. Nelle prove precedenti l'icona
UrBackup era invece stata vista nella barra dei menu, quindi il comportamento
della barra e' legato allo stato della sessione grafica Tiger, non alla build.
L'icona nel Dock resta non verificata e non viene dichiarata funzionante.

Sono stati provati senza successo:

- riavvio di `SystemUIServer`;
- avvio dell'app da SSH, da `open`, e direttamente dal Terminale della sessione
  grafica;
- disattivazione temporanea di `MenuCracker` di iStat menus, poi ripristinata;
- app minima con e senza `LSUIElement`, con titolo e con icona.

Il limite va dichiarato tale finche' non viene verificato dopo un nuovo login
o reboot del G4. Il menu e' comunque raggiungibile con:

```sh
"/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" settings
"/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" logs
```

### Build e pacchetto definitivi

Sorgente di build sul G4:

```text
/Volumes/Daniele/Projects/.tiger-devkit/builds/urbackup-tiger-2.0.34/20261027T223940Z-4fab49b97b/src
```

Comandi usati:

```sh
PATH=/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  make -j2 urbackupclientbackend urbackupclientctl urbackupclientgui
PATH=/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  sh tiger/package.sh
```

Artefatti:

```text
UrBackupTiger-2.0.34-ppc.dmg
UrBackupTiger-2.0.34-ppc.tar.gz
```

Copie finali: `/Volumes/Daniele/Desktop` sul G4 e `~/Desktop` sull'host.
Il pacchetto non contiene credenziali, log grezzi o dati personali.

## Correzione percorsi GUI al 2026-10-29

### Primo crash: font di `wxListBox`

La build precedente chiudeva `urbackupclientgui paths` durante la creazione
della lista. Il report mostrava:

```text
CFNumberGetValue
wxNativeFontInfo::Init(CTFontDescriptorRef)
wxFontRefData::wxFontRefData(wxOSXSystemFont, int)
wxListBox::GetClassDefaultAttributes
GUIConfigPath::GUIConfigPath
```

Su CoreText 1.0.4 di Tiger il descrittore del font di sistema puo' non avere
gli attributi di dimensione o traits. La patch
`tiger/deps/wx-3.0.5.1-tiger-fontattrs.patch` aggiunge i controlli nulli. La
libreria statica corretta deve essere installata anche nel prefisso usato dal
link della GUI, non solo nella directory di build:

```sh
cp build-carbon-ppc-nogl/lib/libwx_osx_carbonu-3.0.a \
  /Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/lib/
ranlib /Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/lib/libwx_osx_carbonu-3.0.a
```

Senza il secondo passaggio il binario ricompilato continuava a contenere il
vecchio codice: verificato confrontando il disassemblato della funzione nel
binario e nell'oggetto `monolib_carbon_font.o`.

### Secondo crash: selettore directory nativo

Con la lista ora funzionante, il click su `Aggiungi percorso` apriva
`wxDirDialog` e chiudeva l'app in:

```text
CFMessagePortCreateRunLoopSource
InitializeDragIPC
TBrowseDialog::SetupDragHandlers
NavChooseFolderDialog::InitDialog
wxDirDialog::ShowModal
ConfigPath::OnClickNew
```

Il crash e' dentro `NavigationServices` di Tiger, non in UrBackup. La GUI ora
usa una finestra wx semplice con un campo di testo: l'utente inserisce il
percorso assoluto completo, che viene validato con `wxIsAbsolutePath` e
`wxDirExists`, controllato contro i duplicati e poi aggiunto alla lista. Non
viene piu' istanziato `wxDirDialog`/`NavChooseFolderDialog`.

### Prova GUI completa

Eseguita sul G4 il 2026-10-29 con la configurazione utente reale:

1. `urbackupclientgui paths` resta attivo e mostra `/etc`.
2. `Aggiungi percorso` apre la finestra senza crash.
3. Inserito `/Volumes/Daniele/Library/UrBackupTigerLab/gui-path-test`.
4. Dopo `Ok`, `urbackupclientctl list-backupdirs --raw` restituisce sia `/etc`
   sia la directory di prova con `id 5`.
5. Riavviato il backend con gli stessi `URBACKUP_TIGER_*` della GUI: entrambe
   le directory sono ancora presenti, quindi il salvataggio e' persistente.
6. Selezionata la directory di prova, usato `Rimuovi percorso`, quindi `Ok`:
   il backend restituisce soltanto `/etc`.

La directory di prova e' stata eliminata. Il profilo resta con il solo `/etc`.
Durante una prova precedente il backend aveva accettato i PONG ma non risposto
a `GET BACKUP DIRS`; un riavvio pulito del backend con
`URBACKUP_TIGER_VARDIR` e `URBACKUP_TIGER_DATADIR` corretti ha ripristinato la
risposta. Questo caso va distinto dall'errore GUI ed e' il motivo per cui il
test finale include un riavvio esplicito del backend.

### Verifica finale del pacchetto installato

Il bundle del DMG e' stato copiato in `/Applications` e avviato con
`urbackupclientgui paths`; la finestra ha mostrato `/etc`. Con lo stesso
bundle e lo stesso backend e' stato quindi eseguito:

```sh
urbackupclientctl start -i -p \
  "$HOME/Library/Application Support/UrBackupTiger/var/urbackup/pw_change.txt"
```

Esito: `Waiting for server to start backup... done`, `Preparing...` e
`Completed successfully`.

## Backup di `/etc`

Su Tiger `/etc` e' un collegamento a `/private/etc`. Il backend gira come
l'utente normale `daniele`, quindi non puo' leggere alcuni file e directory
riservati a `root`. Senza esclusioni la costruzione dell'indice si interrompe
su `/private/etc/cups/certs` con `Permission denied (13)` e il server elimina
il backup parziale.

Non e' necessario eseguire il backend come root. La soluzione verificata e'
escludere soltanto gli elementi root-only; tutto il resto di `/etc` viene
salvato. I percorsi vanno scritti nella forma canonica `/private/etc/...` e
separati con `;`:

```sh
B="/Applications/UrBackup Client.app/Contents/Resources/bin/urbackupclientctl"
D="$HOME/Library/Application Support/UrBackupTiger/var/urbackup"
EXCLUDES='/private/etc/cups/certs;/private/etc/cups/certs/*;/private/etc/cups/classes.conf;/private/etc/cups/printers.conf;/private/etc/cups/printers.conf.O;/private/etc/master.passwd;/private/etc/openldap/slapd.conf.default;/private/etc/racoon/psk.txt;/private/etc/racoon/remote/anonymous.conf;/private/etc/ssh_host_dsa_key;/private/etc/ssh_host_key;/private/etc/ssh_host_rsa_key;/private/etc/sudoers'
"$B" set-settings --pw-file "$D/pw_change.txt" \
  -k exclude_files -v "$EXCLUDES"
```

Per verificare quali altri percorsi non sono leggibili dall'utente del client:

```sh
find -H /etc -type d -print | while IFS= read -r p; do
  test -r "$p" || echo "$p"
done
find -H /etc -type f -print | while IFS= read -r p; do
  test -r "$p" || echo "$p"
done
```

Verifica eseguita il 2026-10-28 con un backup completo manuale:

```sh
"$B" start -f --pw-file "$D/pw_change.txt"
```

Esito:

- client: `Completed successfully`, `success: true`;
- server: record del backup `complete=1`, `done=1`, 4.576.842 byte;
- contenuto: 653 file sotto `etc`, inclusi `hostconfig`, `sshd_config` e
  `rc.local`;
- esclusi: i 12 elementi root-only dell'elenco precedente, tra cui
  `master.passwd`, `sudoers`, le chiavi SSH private e i certificati CUPS.

I messaggi `Creating shadowcopy ... failed` relativi ai due collegamenti
simbolici di `localtime` e `resolv.conf` non bloccano il backup: il record
finale sul server e' completo. Restano esclusi i segreti locali non leggibili
dal client, non l'intera directory `/etc`.
