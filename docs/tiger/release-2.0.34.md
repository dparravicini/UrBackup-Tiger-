# Release 2.0.34-tiger1 — English bundle

Data: 2026-10-29  
Tag: `v2.0.34-tiger1`  
Commit: `3fef5bff`  
Release Gitea: <http://192.168.1.68:8418/daniele/UrBackup-Tiger/releases/tag/v2.0.34-tiger1>

## Contenuto

Il bundle `UrBackupTiger-2.0.34-ppc-en.zip` (16 MB) contiene:

- `UrBackupTiger-2.0.34-ppc.dmg` — immagine disco verificata, con bundle bit
  HFS e README/ReadMe in inglese;
- `UrBackupTiger-2.0.34-ppc.tar.gz` — app, README, ReadMe e licenze;
- `urbackup-tiger-2.0.34-ppc-src.tar.gz` — snapshot sorgente del commit
  `3fef5bff`, senza build e senza devkit wx;
- `README.md`, `ReadMe.txt`, `BUILD-INFO.txt`, `SHA256SUMS`;
- `URBACKUP-COPYING.txt` (AGPLv3) e `CRYPTOPP-LICENSE.txt`;
- `ANNOUNCEMENT.txt` — messaggio pronto per la lista, con URL da sostituire.

## Checksum

```text
85e5423eb236507fd9fdf112f67c306090bc7cfbc951b2141ddb9458ce6122c6  UrBackupTiger-2.0.34-ppc.dmg
464a1fa25bc7879e8877a4720fbb570c7bf0ca4eded0be86a95b8c3cc9075d79  UrBackupTiger-2.0.34-ppc.tar.gz
7a857d58a76bea176baf9266daaab6601790180ec4a337ca0a1a73ab9019073a  urbackup-tiger-2.0.34-ppc-src.tar.gz
0518e12083be3a6960626efe06495661bf5c5902a3672371a3d223bb9f33fac8  UrBackupTiger-2.0.34-ppc-en.zip
```

## Verifiche

- `tiger/package.sh` eseguito sul G4 con i binari PPC gia' verificati.
- `urbackupclientbackend --tiger-self-test`: PASS.
- Tutti e tre i binari: `Mach-O executable ppc`.
- `hdiutil verify` del DMG: VALID (sia sul G4 sia sull'host macOS).
- DMG montato e controllato: README inglese, `ReadMe.txt`, licenze e ICNS
  Tiger da 207633 byte.
- Il TAR contiene app, README, ReadMe e licenze.
- La GUI e il backend non sono stati ricompilati in questa fase: sono gli
  stessi binari gia' verificati sul G4; il pacchetto e' stato ricostruito per
  includere la documentazione inglese e l'icona definitiva.

## Pubblicazione esterna

La release pubblica e' su GitHub:

- pagina: https://github.com/dparravicini/UrBackup-Tiger-/releases/tag/v2.0.34-tiger1
- asset: `UrBackupTiger-2.0.34-ppc-en.zip`, `UrBackupTiger-2.0.34-ppc.dmg`,
  `UrBackupTiger-2.0.34-ppc.tar.gz`, `urbackup-tiger-2.0.34-ppc-src.tar.gz`,
  `SHA256SUMS`
- SHA-256 dello zip: `1aa0cfeba5daa10070de0d386b379e929be68f171eab62722464a9d3af5512cb`

Il repository Gitea resta privato e non e' il link da inviare alle liste.
`ANNOUNCEMENT.txt` contiene gia' l'URL pubblico. Le note tecniche italiane
restano in `README-TIGER.md`; la pagina principale del repository e' il
`README.md` inglese.

Il messaggio e la scelta dei destinatari sono in
[mailing-list-message.md](mailing-list-message.md). Non allegare il DMG o lo
zip alle email: usare il link e mantenere il messaggio in testo semplice.

## Limiti dichiarati

- Image backup non supportati dal client macOS.
- Darwin 8 non imposta i timestamp dei symlink su HFS+.
- Il selettore directory nativo e' sostituito da un campo percorso validato.
- Lo status item nella menu bar dipende dalla sessione Tiger/SystemUIServer;
  la GUI resta utilizzabile con `settings`, `paths` e `logs`.
