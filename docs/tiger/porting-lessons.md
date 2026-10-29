# Lezioni apprese e checklist per un nuovo porting su Mac OS X 10.4 Tiger

Stato: verificato sul porting UrBackup 2.0.34 per PowerPC, aggiornato al
2026-10-29. Questa guida raccoglie le trappole incontrate realmente e le
verifiche da fare prima di dichiarare utilizzabile un altro porting Tiger.

Il contesto di riferimento e' Mac OS X 10.4.11 su PowerPC 32 bit, GCC 4.0.1,
SDK 10.4u, C++98 e wxWidgets 3.0.5.1 Carbon statica. Le indicazioni non
presumono che un'altra applicazione abbia le stesse dipendenze, ma la
metodologia e i controlli di packaging restano validi.

## Le trappole che hanno pesato di piu'

1. Una patch a wxWidgets non basta se il link usa ancora la vecchia libreria
   statica in un altro prefisso.
2. Il selettore directory nativo `NavigationServices` puo' chiudere la GUI su
   Tiger; serve un'alternativa verificata.
3. CoreText puo' restituire attributi font nulli e far crashare `wxListBox`.
4. L'ICNS deve essere nel formato legacy Tiger; `iconutil` moderno e `sips` di
   Tiger non bastano.
5. Senza bundle bit HFS `B`, LaunchServices puo' rifiutare l'app (`-10829`).
6. PowerPC e' big-endian: ogni campo di protocollo little-endian va provato
   esplicitamente in lettura e scrittura.
7. La GUI dipende dal backend IPC: tab e Impostazioni non sono validi se il
   backend non risponde.
8. Un processo grafico avviato senza sessione Aqua non dimostra che finestre,
   Dock o menu bar funzionino.
9. Il TAR non conserva automaticamente il bundle bit: il DMG resta il formato
   di distribuzione verificato.
10. Se una verifica non e' stata completata, va dichiarata come limite e non
    trasformata in una promessa.

## Regola principale

Non dichiarare riuscito un porting perche' compila o perche' il processo resta
attivo. Un porting Tiger e' completo solo quando sono stati verificati, sulla
macchina reale:

1. avvio del bundle da `/Applications`;
2. backend e IPC attivi;
3. tutte le finestre e i tab realmente usati;
4. salvataggio e rilettura della configurazione;
5. almeno un'operazione end-to-end con il servizio esterno;
6. apertura del DMG su Tiger, non soltanto sull'host di build;
7. icona, bundle bit e istruzioni di installazione;
8. limiti residui scritti in modo esplicito.

Se una verifica non e' stata fatta, va scritta come non fatta. Non usare
"dovrebbe funzionare" come stato di consegna.

## 1. Prima di scrivere codice

### Bloccare la toolchain

- Usare GCC 4.0.1 e SDK 10.4u coerenti con Tiger; non mescolare SDK, header e
  librerie di versioni macOS successive.
- Compilare per PPC 32 bit e verificare ogni binario con `file`: deve risultare
  `Mach-O executable ppc`.
- Tenere una copia archiviata del devkit e delle librerie statiche esatte.
- Annotare commit upstream, versione SDK, versione wxWidgets e patch applicate.
- Non aggiornare automaticamente il devkit durante il porting: una libreria
  ricompilata in un altro prefisso puo' non essere quella linkata.

### Fare subito probe minimi

Prima di trasportare l'applicazione completa, compilare piccoli programmi che
provino le API sospette. Nel porting UrBackup sono stati necessari probe per:

- `realpath(path, NULL)`, non supportato da Tiger;
- `setattrlist` e gestione dei timestamp dei symlink;
- xattr, FinderInfo e resource fork;
- serializzazione little endian su CPU big-endian;
- caricamento delle icone e conversione RGBA;
- avvio di un processo grafico nella sessione Aqua.

Un probe riuscito non certifica il round trip dell'applicazione, ma evita di
confondere un errore di piattaforma con un errore del porting.

### Preparare l'ambiente di prova

- Usare un account e un profilo applicativo dedicati, non dati personali.
- Non modificare backup, client o configurazioni gia' in produzione.
- Definire in anticipo una fixture con file normali, vuoti, Unicode, binari,
  symlink, xattr, FinderInfo e resource fork.
- Prevedere un server o servizio di test e un ripristino reale verificabile.
- Salvare i log con data, PID, comando esatto e risultato.

## 2. Portabilita' del codice e delle API

### C++ e runtime di Tiger

Tiger usa una libstdc++ e un SDK molto piu' vecchi degli strumenti attuali.
Errori gia' incontrati:

- `vector::data()` non disponibile: serve un adattatore compatibile C++98;
- `#pragma pack(push)` senza valore rifiutato da Apple GCC: specificare sempre
  l'allineamento e verificare i layout serializzati;
- cast espliciti `size_t` -> `int64` nelle API SQLite su PPC32;
- `stat64`, `O_SYMLINK`, `O_CLOEXEC`, `UF_HIDDEN` e altre API successive a
  Tiger non disponibili;
- `sendfile` non disponibile: mantenere il percorso read/write;
- `syncfs` e `fallocate64` assenti o facoltativi;
- `pthread` in `libSystem`: il driver Apple non accetta `-pthread` come un GCC
  moderno;
- doppio `-syslibroot` rifiutato dal linker: il configure/build va corretto,
  non aggirato con link manuali non documentati.

Ogni sostituzione va verificata a runtime, non soltanto compilata. In
particolare, una funzione che restituisce successo su Tiger puo' non applicare
la modifica richiesta.

### Endianness

PowerPC e' big-endian; molti protocolli di rete e formati su disco sono
little-endian. Nel porting UrBackup sono state corrette conversioni doppie in
campi a 64 bit e nelle lunghezze dei nomi. Regole pratiche:

- definire per ogni campo il byte order del protocollo, non quello della CPU;
- leggere e scrivere con funzioni esplicite;
- preparare fixture con byte noti e confrontare il risultato;
- provare sia invio sia ricezione, non solo la serializzazione locale;
- non usare `memcpy` di strutture C++ come formato persistente.

### HFS+ e metadati

- I resource fork e FinderInfo non sono normali file: vanno provati con un
  ciclo backup/ripristino reale.
- Gli xattr possono contenere byte NUL; non trattarli come stringhe C.
- I symlink vanno preparati prima degli xattr del target e verificati con
  `lstat`/API no-follow.
- Tiger/HFS+ non aggiorna i timestamp dei symlink: `setattrlist` puo'
  restituire successo senza modificarli. Il limite va dichiarato, non nascosto.
- Non confondere FinderInfo con il flag BSD `UF_HIDDEN`.

## 3. GUI wxWidgets Carbon

### La libreria statica puo' essere obsoleta

Una patch applicata ai sorgenti wx non basta. Se il link usa una copia statica
in un altro prefisso, il binario finale continua a contenere il codice vecchio.
Procedura corretta:

1. ricompilare wxWidgets con la patch;
2. installare la nuova libreria nel prefisso usato dal link;
3. eseguire `ranlib` sulla libreria statica;
4. ricompilare l'applicazione;
5. verificare il binario o il disassemblato, non solo la data dell'oggetto.

Nel porting UrBackup questo passaggio ha fatto la differenza tra un crash e una
GUI funzionante.

### CoreText e font di sistema

Su Tiger il descrittore del font di sistema puo' avere attributi nulli. Il
percorso `wxListBox` -> `wxNativeFontInfo::Init` -> `CFNumberGetValue` può
chiudere l'app. La patch
`tiger/deps/wx-3.0.5.1-tiger-fontattrs.patch` controlla i descrittori e gli
attributi prima di usarli.

Da tenere presente:

- una patch wx va mantenuta nel repository, non solo nel devkit;
- va verificata con `patch -p1 --dry-run` sull'albero esatto;
- il crash puo' comparire soltanto aprendo una lista o un dialogo, non
  all'avvio;
- dopo la patch va rifatto il link contro la libreria statica aggiornata.

### Selettori file nativi

Il selettore directory `wxDirDialog`/`NavigationServices` di Tiger può
chiudere l'app in `InitializeDragIPC`, `TBrowseDialog` o
`NavChooseFolderDialog`. Per il porting UrBackup e' stato sostituito da una
finestra wx con campo di testo e validazione del percorso assoluto.

Prima di usare un file dialog nativo:

- provarlo in una build minima;
- provarlo da una sessione Aqua reale, non soltanto via SSH;
- controllare se il crash avviene solo con IPC drag o con il pannello;
- prevedere un percorso alternativo, ad esempio input testuale validato;
- non considerare il selettore nativo un requisito se l'ambiente lo rende
  instabile, ma documentare la diversa interazione.

La finestra dei percorsi deve verificare che il percorso sia assoluto, esista,
sia una directory e non sia già presente. Aggiunta, rimozione, salvataggio e
persistenza dopo riavvio del backend vanno testati separatamente.

### Backend, tab e stato della finestra

La GUI UrBackup dipende dal backend IPC. I tab delle Impostazioni possono
sembrare non cliccabili se il backend non risponde o se la finestra non e' in
primo piano. Il primo click su una finestra inattiva serve a portarla davanti;
il click successivo cambia tab.

Un test valido deve partire da un backend pulito, verificare i tab, modificare
un valore, salvarlo, riavviare il backend e rileggere il file di configurazione.
Non basta vedere il tab disegnato.

### Menu bar, Dock e LSUIElement

- In wxWidgets 3.0.5.1 il port Carbon di `wxTaskBarIcon` non implementa gli
  status item: il comportamento può ricadere sull'icona Dock.
- Un `NSStatusItem` nativo è implementabile su Tiger, ma la sua presenza non
  garantisce che SystemUIServer lo mostri in ogni sessione.
- `LSUIElement=1` rende l'app invisibile nel Dock. Rimuoverlo consente l'avvio
  come applicazione normale, ma nel test UrBackup non ha fatto comparire
  automaticamente l'icona nel Dock.
- Non dichiarare funzionante l'icona nella menu bar o nel Dock senza una nuova
  verifica dopo login/reboot e senza screenshot o riscontro visivo.
- Prevedere sempre comandi espliciti per aprire Impostazioni e Log, cosi' la
  GUI resta accessibile anche se il tray non e' disponibile.

## 4. Bundle, icone e distribuzione

### Bundle bit HFS

Un `.app` copiato con semplici tool POSIX può perdere il bundle bit. Tiger
LaunchServices può rifiutare l'apertura con errore `-10829`.

Prima di distribuire:

```sh
/Developer/Tools/SetFile -a B "/percorso/UrBackup Client.app"
/Developer/Tools/GetFileInfo -a "/percorso/UrBackup Client.app"
```

L'output deve contenere la `B` maiuscola. Va impostata sia sull'app installata
sia sulla copia dentro il DMG.

### Icona ICNS

`iconutil` moderno produce un ICNS con elementi come `ic12` che Tiger non
riconosce. `sips` di Tiger non sa scrivere ICNS. Un file di istruzioni ASCII
rinominato `.icns` non e' un'icona.

Per Tiger servono elementi legacy, almeno `is32`, `il32`, `ih32` e `it32`.
Una procedura verificata e':

```sh
png2icns urbackup.icns icon16.png icon32.png icon48.png icon128.png
```

Il pacchetto `libicns` genera questi elementi. Verificare sul G4:

```sh
/usr/bin/sips -g pixelWidth -g pixelHeight \
  "/Applications/UrBackup Client.app/Contents/Resources/urbackup.icns"
```

Deve essere leggibile, ad esempio 128x128. Poi aggiornare LaunchServices e
Finder:

```sh
/System/Library/Frameworks/ApplicationServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f \
  "/Applications/UrBackup Client.app"
killall Finder
```

La verifica finale e' visiva: l'icona UrBackup deve comparire in Finder. Il
solo `file` o il solo `CFBundleIconFile` non bastano.

### DMG e TAR

- Il DMG e' il formato di distribuzione verificato: conserva bundle bit,
  FinderInfo e struttura HFS.
- Un TAR estratto con il `tar` di Tiger non conserva il bundle bit; l'app può
  quindi richiedere un intervento esplicito dopo l'estrazione. Non presentarlo
  come equivalente al DMG senza un installer o una verifica separata.
- Il DMG va creato, verificato e montato su Tiger. `hdiutil verify` sull'host
  di build non sostituisce la prova sul target.
- Controllare il contenuto montato, non soltanto il file DMG: app, permessi,
  `Info.plist`, icone, `Leggimi.txt` e licenze.
- Conservare gli hash SHA-256 di DMG e TAR e verificare gli allegati dopo il
  caricamento sulla release.

### Repackaging senza ricompilare

Se il binario finale e' già verificato ma il devkit non e' disponibile, si può
aggiornare solo la documentazione o una risorsa nel DMG. In quel caso:

1. calcolare l'hash del binario prima della modifica;
2. modificare soltanto i file previsti;
3. ricreare il DMG conservando il bundle bit;
4. verificare che l'hash del binario dentro il nuovo DMG sia identico;
5. eseguire `hdiutil verify` e montare il DMG su Tiger.

Non ricompilare "al volo" durante un timeout o una connessione instabile: si
rischia di pubblicare un artefatto misto. Se un comando `package.sh` o
`hdiutil` viene interrotto, controllare i processi, rigenerare e verificare di
nuovo invece di fidarsi dello stato lasciato a metà.

## 5. Backup, permessi e configurazione

- Non eseguire il backend come root solo per aggirare un permesso. Nel test
  UrBackup l'utente normale non poteva leggere alcuni file root-only di `/etc`
  e il server eliminava il backup parziale; la soluzione verificata e' stata
  escludere quei percorsi, non elevare i privilegi.
- Su Tiger `/etc` e' un collegamento a `/private/etc`: usare la forma canonica
  nelle esclusioni.
- Verificare che l'esclusione sia applicata dal server al client e che il
  risultato sia un backup completo, non soltanto un indice costruito.
- Un valore di pianificazione negativo può significare "disabilitato" nella UI
  UrBackup. Non interpretarlo come errore del porting senza controllare il
  significato dei campi.
- Dopo ogni modifica di configurazione riavviare il backend e rileggere lo
  stato, invece di assumere che la GUI e il processo condividano la stessa
  copia in memoria.

## 6. Diagnostica su Tiger

Il sistema ha utility diverse da macOS moderno. Alcuni comandi assenti o con
opzioni differenti incontrati durante il porting:

- `pgrep`: usare `ps ax | grep`;
- `plutil -p`: usare `plutil` o `defaults read`;
- `head -c`: usare `head -n`;
- `shasum`: usare `md5` o `openssl`;
- `base64`: assente o non nella forma moderna;
- `mount`: percorso e comportamento diversi;
- OpenSSH moderno può rifiutare le chiavi host `ssh-rsa`/`ssh-dss` di Tiger.
  Usare un host intermedio fidato o opzioni temporanee, senza disattivare
  globalmente la verifica delle chiavi.

Quando si diagnostica via SSH, controllare anche il proprietario di
`/dev/console` e la presenza di una sessione Aqua: un processo grafico avviato
da una sessione senza console può non mostrare finestre o status item.

## 7. Matrice minima di accettazione

Prima di considerare concluso un altro porting Tiger:

- [ ] build pulita con SDK 10.4u e binari `Mach-O executable ppc`;
- [ ] `otool -L` mostra solo dipendenze disponibili su Tiger;
- [ ] GUI avviata da `/Applications`, non solo dal build tree;
- [ ] backend avviato e IPC verificato;
- [ ] tutti i tab usati aperti e modificabili;
- [ ] configurazione salvata, backend riavviato e valore riletto;
- [ ] aggiunta/rimozione percorso e persistenza verificate;
- [ ] Log/Info aperti senza crash;
- [ ] backup completo e incrementale completati sul server;
- [ ] restore reale verificato, inclusi symlink e metadati previsti;
- [ ] DMG montato e verificato su Tiger;
- [ ] bundle bit `B` presente nell'app installata e nel DMG;
- [ ] ICNS leggibile da `sips` e icona visibile in Finder;
- [ ] limiti menu bar/Dock dichiarati dopo una prova in sessione Aqua;
- [ ] hash degli artefatti pubblicati e verificati dopo il download;
- [ ] documentazione, commit e release aggiornati nello stesso lavoro.

## Collegamenti utili

- [Porting GUI wx e verifiche Tiger](gui.md)
- [Analisi del backend e limiti HFS+](analisi.md)
- [Valutazione macTLS e macsurf](mactls.md)
