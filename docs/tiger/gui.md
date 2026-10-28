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
- `tiger/build.sh`: richiede `wx-config` e compila backend, CLI e GUI senza
  `--enable-headless`.
- `tiger/package.sh`: include il binario GUI, le risorse originali e il bundle
  `UrBackup Client.app`.
- `tiger/install.sh`: installa GUI, risorse e bundle nel prefisso di
  laboratorio, mantenendo il controllo che vieta l'avvio automatico senza
  directory esplicite.

Patch riproducibile per wxWidgets:
`tiger/deps/wx-3.0.5.1-tiger-10.4.patch`. Copre:

- `AudioServices` e `HIWindowGetAvailablePositioningBounds`, non disponibili
  nell'SDK 10.4;
- limiti dello schermo tramite `GetMainDevice`, con ritorno alle API moderne
  quando disponibili;
- costanti IconServices per 16/32/48/128/512 px assenti nell'header Tiger,
  necessarie alle icone originali del tray;
- fallback `CGColorCreate`/`CGColorCreateGenericRGB` per Quartz su 10.4.

## Stato della build al 2026-10-28

La build wx ha superato la libreria base e una parte di common/OSX, arrivando a
252 oggetti compilati. Si è poi fermata sull'API CoreText assente in Tiger:

```text
../src/osx/core/fontenum.cpp:117: error: 'kCTFontMonoSpaceTrait' was not declared in this scope
make: *** [monolib_core_fontenum.o] Error 1
```

Il prossimo intervento deve aggiungere in
`tiger/deps/wx-3.0.5.1-tiger-10.4.patch` il fallback CoreText per Tiger,
riprendere `make -j2` nella directory build e ripetere il controllo per le
eventuali ulteriori API 10.5 usate dal port Carbon.

Non sono ancora stati eseguiti build del frontend UrBackup, installazione del
bundle, avvio sul G4, verifica dell'icona nella menu bar o test delle finestre.
Questi punti non vanno considerati riusciti finché non vengono eseguiti sul
Macintosh reale.

## Nota sull'icona del bundle

`osx_installer/urbackup.icns` nel sorgente ufficiale è un file di istruzioni
testuale di 720 byte, non un ICNS valido. Le icone di stato usate dal tray sono
invece gli asset originali `client/data/*.ico`. Il bundle non deve essere
presentato come dotato di una nuova icona applicativa: l'eventuale icona
Finder resta un limite da verificare senza modifiche estetiche.

## Ripresa prevista

1. Completare la patch CoreText/Tiger e verificare `wx-config` con `file` e
   `otool` (PPC, SDK 10.4).
2. Trasferire il checkout aggiornato al G4 ed eseguire:

```sh
PATH=/Volumes/Daniele/Projects/.tiger-devkit/deps/wx-3.0.5.1-carbon-ppc/bin:$PATH \
  sh tiger/build.sh
```

3. Correggere gli eventuali errori di compilazione del frontend UrBackup.
4. Fermare solo il backend di laboratorio, installare il pacchetto e
   riavviarlo con gli stessi argomenti; non toccare i servizi di produzione.
5. Verificare con `screencapture` l'icona nella menu bar, l'apertura del menu,
   le finestre Settings/Logs, gli stati dinamici e il collegamento al backend.
6. Aggiornare questo documento con i risultati reali, quindi eseguire il
   commit e il push su Gitea.

## Nota sullo stato “Disabled”

La web UI mostra `File backup status: Disabled` perché il profilo di
laboratorio ha `update_freq_incr`, `update_freq_full`,
`update_freq_image_incr` e `update_freq_image_full` impostati a `-86400`.
UrBackup interpreta i valori negativi come pianificazione disabilitata; non è
un errore del server né del porting. Non è stato cambiato per non introdurre
backup automatici indesiderati nel laboratorio.
