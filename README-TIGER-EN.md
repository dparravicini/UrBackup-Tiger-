# UrBackup Client for Mac OS X 10.4 Tiger (PowerPC)

**Version:** 2.0.34-tiger1  
**Platform:** Mac OS X 10.4.11 Tiger, 32-bit PowerPC (G3, G4, G5)  
**Distribution:** `UrBackupTiger-2.0.34-ppc.dmg` (recommended) and `UrBackupTiger-2.0.34-ppc.tar.gz`  
**Source snapshot:** `urbackup-tiger-2.0.34-ppc-src.tar.gz`

This is a native PowerPC build of the official UrBackup 2.0.34 client and its original wxWidgets frontend. It lets a Tiger Mac perform file backups to an UrBackup server, run incremental backups, browse backup status, and restore files. The windows, menus, icons, translations and status handling come from the official UrBackup frontend; this is a port, not a new or simplified interface.

The port was developed and tested on a real iBook G4 running Mac OS X 10.4.11. The backend, command-line client and GUI are all 32-bit PowerPC Mach-O executables. No Intel code, Rosetta, or modern macOS component is required.

## What works

- Native PowerPC client for UrBackup 2.x servers.
- Full and incremental **file** backups.
- Restore of files and directory trees from the UrBackup server.
- HFS+ metadata preservation: resource forks, Finder attributes/FinderInfo, extended attributes (xattrs), POSIX permissions, ownership where permitted, and regular file timestamps.
- Symlink backup and restore of the link target, permissions and flags.
- The original UrBackup GUI: Backup File, Client and Internet settings tabs; path configuration; logs; information; status messages and the original status icons.
- Automatic start of the client backend when the GUI is launched from the application bundle.
- Per-user configuration and state under `~/Library/Application Support/UrBackupTiger`.

Image backups are **not** supported by the macOS/Tiger client. This is a limitation of the original macOS client, not of this port. The server may show `Image backup status: Not supported` for the client.

## Requirements

- A PowerPC Mac capable of running Mac OS X 10.4 Tiger. The verified configuration is Mac OS X 10.4.11 on a G4; G3 and G5 machines with 10.4.11 should also work but have not been tested by the author.
- An UrBackup **2.x** server reachable over the network. The client was tested against a 2.x server. If you use a much newer server, test a restore before relying on it.
- The server address and, for Internet mode, the authentication key shown by the UrBackup server.
- Administrator access to copy the application into `/Applications`.
- Enough disk space for the application and for the client-side metadata/cache. Backups themselves are stored on the server.

Network ports: an UrBackup server normally uses TCP 55414 for its HTTP web interface and LAN client communication, TCP 55415 for Internet-mode clients, and UDP 35623 for discovery broadcasts. The client listens on TCP 35621 (file transfer), TCP 35623 (commands) and UDP 35622 (discovery). On a LAN, UrBackup discovery normally finds the server; for a server on another network, enable Internet mode and use TCP 55415 with the authentication key.

## Installing from the DMG

1. Open `UrBackupTiger-2.0.34-ppc.dmg`.
2. Drag **UrBackup Client** to `/Applications`.
3. Eject the disk image.
4. Launch **UrBackup Client** from `/Applications`. The client backend starts automatically.
5. Open the settings window and configure the server and backup paths.

If the application was copied without preserving HFS metadata and Tiger refuses to open it with error `-10829`, copy it again from the DMG with Finder or `ditto`; the DMG contains the required HFS bundle bit. The `.tar.gz` archive is provided for inspection and for systems where a DMG cannot be used, but the DMG is the verified distribution format.

## Configuring the client

### Settings window

Open the settings window with:

```sh
"/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" settings
```

The original Settings window has three tabs:

- **Backup File** — backup windows, include/exclude rules and related file-backup settings.
- **Client** — client name and local client settings.
- **Internet** — Internet-mode server name, port (default `55415`) and authentication key.

On a local network, UrBackup discovery normally finds the server automatically. If it does not, or if the server is on another network, enable Internet mode and enter the server hostname/IP, port and authentication key.

Click **OK** to save. The settings are written to the per-user configuration under `~/Library/Application Support/UrBackupTiger`. The save operation was verified on the G4 by changing a value, saving it, restarting the backend and reading it back.

### Backup paths

Open the path configuration window with:

```sh
"/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" paths
```

Select **Add path**, type an **absolute** path such as `/Users/yourname/Documents`, and confirm. The path must exist, must be a directory, and must not already be in the list. Add as many paths as needed, then save.

The native Tiger directory picker (`NavigationServices`) can terminate the application in some Tiger configurations. For that reason this port uses a plain text field with validation instead of the native folder browser. This is the only intentional interaction change in the GUI.

### Logs and information

```sh
"/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" logs
```

The **Infos** window is available from the tray menu and from the GUI. On Tiger the CoreText font attributes can be incomplete; the wxWidgets patch shipped with this port guards against the resulting crash in list and information windows.

### Menu-bar icon and Dock

The original tray menu is implemented with a native `NSStatusItem`, using the original UrBackup status icons. On the test machine the status item was visible in earlier sessions, but in the final Tiger session neither the status item nor a Dock tile appeared even though the application and backend were running. A minimal `NSStatusItem` test behaved the same way, and restarting `SystemUIServer` did not fix it. This is a Tiger session/SystemUIServer behavior, not an application crash.

If the menu-bar icon is not visible, the application is still usable. Use the `settings`, `paths` and `logs` commands above. You can also launch the GUI normally from Finder; the backend and its IPC service remain active.

## First backup

1. Confirm the client is connected to the server (the server's web interface should list the Tiger machine).
2. On the server, select the client and start a full file backup, or wait for the schedule configured on the server.
3. The client shows the original status icons and progress messages while the backup runs.
4. When the backup finishes, the server records the backup and the client reports success.

A server-side schedule with negative frequencies (for example `-86400`) intentionally disables automatic backups. If the server shows `File backup status: Disabled`, check the schedule in the server's client settings; it is not a client failure.

## Restoring files

Restores are initiated from the UrBackup server's web interface. The server sends the restore request to the connected client; the client writes the files and reports completion. The Tiger client was tested with real restores, including a completed restore reported as `Restore finished successfully`.

For the best result:

- Restore to a dedicated directory first if you are testing.
- Check file contents, permissions, resource forks, Finder attributes and xattrs after the restore.
- Remember the symlink timestamp limitation described below.

## HFS+ metadata and known limitations

### Preserved

- File contents and directory structure.
- POSIX permissions and ownership where the client has permission to apply them.
- Resource forks.
- FinderInfo / Finder attributes.
- Extended attributes (xattrs), including values containing NUL bytes.
- Regular file modification and access timestamps where Tiger permits them.
- Symlink target, permissions and flags.

### Not preserved or not fully supported

- **Symlink timestamps:** Darwin 8 (the kernel in Tiger) does not apply timestamps to symlinks on HFS+. The link target, permissions and flags are restored, and the operation reports success, but the symlink's own timestamps cannot be set. This is a documented platform limitation, not a silent data loss.
- **Image backups:** not supported by the macOS client.
- **Native folder picker:** disabled in favour of the validated text field described above.
- **Menu-bar/Dock visibility:** depends on the Tiger graphical session and `SystemUIServer`; see above.
- **Code signing:** the application is not signed or notarized. Tiger has no Gatekeeper requirement, but modern browsers may warn when downloading the DMG.
- **Server compatibility:** tested with UrBackup 2.x. Newer servers may change protocol details; verify a restore before production use.

## Data locations and uninstall

Per-user data:

```text
~/Library/Application Support/UrBackupTiger
```

The distribution contains no server, credentials, personal data or preconfigured backup paths.

To uninstall:

1. Quit the client from its menu, or stop the backend process.
2. Move `/Applications/UrBackup Client.app` to the Trash.
3. If you also want to remove local configuration and state, remove `~/Library/Application Support/UrBackupTiger`.

## Building from source

The source snapshot is the UrBackup 2.0.34 client plus the imported official wxWidgets frontend, with the Tiger compatibility patches. The verified toolchain is:

- Apple GCC 4.0.1
- Mac OS X 10.4u SDK
- wxWidgets 3.0.5.1 with the Carbon backend, built statically for 32-bit PowerPC
- GNU make and the Tiger command-line tools

The wxWidgets patches are in `tiger/deps/`:

- `wx-3.0.5.1-tiger-10.4.patch`
- `wx-3.0.5.1-tiger-uifont.patch`
- `wx-3.0.5.1-tiger-fontattrs.patch`

Build commands, after installing the patched static wxWidgets in the path used by `wx-config`:

```sh
PATH=/path/to/wx-3.0.5.1-carbon-ppc/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  sh tiger/build.sh

PATH=/path/to/wx-3.0.5.1-carbon-ppc/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  sh tiger/package.sh
```

`tiger/package.sh` creates the application bundle, runs the backend self-test, checks the Mach-O architectures and dynamic libraries, creates the DMG, verifies it with `hdiutil verify`, and creates the `.tar.gz` archive.

The port uses the original UrBackup protocol and the original frontend. It does not add a new GUI, new icons, or new backup features.

## Source provenance

- Backend: UrBackup `2.0.34client`, upstream commit `8cd27193b8370df739ad08c6f72750ebe3c7fe11`.
- Frontend: `uroni/urbackup_frontend_wx`, tag `2.0.34`, commit `7c76b0e23e5e33ae355bd59bf9b59f2e91e1ab71`.
- Tiger port: the source snapshot included with this release; build metadata is in `BUILD-INFO.txt`.

The port repository also contains the detailed Tiger engineering notes, including the wxWidgets patch rationale, tested failures and the reproducible build procedure.

## Verification performed

The following were verified on the real G4 running Mac OS X 10.4.11:

- `urbackupclientbackend --tiger-self-test` — PASS.
- All three binaries are `Mach-O executable ppc`; the GUI links no dynamic wxWidgets library.
- Full backup of a laboratory tree, including `/etc` (with documented exclusions for root-only unreadable files).
- Incremental backup with the final bundle installed in `/Applications`, started by the server and completed with `Completed successfully`.
- Real restore completed on the client and reported `Restore finished successfully`.
- HFS+ fixture checks for resource forks, FinderInfo, xattrs, permissions and symlinks.
- GUI tabs, field editing and settings persistence; Logs and Infos open without the earlier CoreText crash.
- DMG created with a valid HFS bundle bit and verified with `hdiutil verify`.

Not claimed: menu-bar/Dock visibility in every Tiger session; image backups; Intel or Rosetta operation; compatibility with every UrBackup server version.

## Credits

Port, Tiger packaging and testing: **Daniele Parravicini**.

UrBackup was created by Martin Raiber and contributors; the GUI is the official `uroni/urbackup_frontend_wx` frontend. The upstream copyright and license notices are preserved in the source snapshot and in the bundled license files.

## License

UrBackup is licensed under the GNU Affero General Public License, version 3 or later. See `URBACKUP-COPYING.txt`. The Tiger port is distributed under the same AGPLv3-or-later terms. The bundled Crypto++ library is covered by the Crypto++ license in `CRYPTOPP-LICENSE.txt`.

The source snapshot is included so recipients can rebuild and modify the client under the same license. If you redistribute a modified binary, you must also make the corresponding source available as required by the AGPL.
