# Release announcement: where to send it

This note is for the English 2.0.34 Tiger/PowerPC release. The message is
plain text on purpose: the classic-computing lists reject HTML, styled mail
and large attachments.

## Recommended places

### 1. MacRumors Forums — PowerPC Macs

<https://forums.macrumors.com/forums/powerpc-macs.145/>

The most active general PowerPC community. Post the announcement as a normal
thread. Good place for G3/G4/G5 owners who still run Tiger and for people who
can test on different hardware.

### 2. VCFed Forums — Apple PowerPC Macs

<https://forum.vcfed.org/>

Vintage Computer Federation forum. Use the Apple computers / Apple PowerPC
Macs section. Slower than MacRumors, but the audience is exactly the
retrocomputing crowd and values documented ports and original software.

### 3. Low End Mac G-Group (Google Group)

Subscribe: <https://groups.google.com/g/g3-5-list>  
Email subscribe: `g3-5-list+subscribe@googlegroups.com`

Low End Mac's G3/G4/G5 group, with more than 1,600 members. It is a mailing
list rather than a web forum, so use the plain-text message below and post the
download link instead of an attachment. Once subscribed, use the posting
address shown by Google Groups.

### 4. ClassicCmp / cctalk

<https://www.classiccmp.org/lists.html>

The long-running classic-computing mailing list (about 650 members, 50–100
messages/day). Tiger is at the newer end of "classic", so introduce it as a
preservation/porting project for a 2005 PowerPC system, not as a modern
backup product. Follow the list's plain-text rules and do not attach the DMG.

### 5. 68kMLA Forums

<https://68kmla.org/bb/>

The oldest classic Mac community. It is 68k-focused but has PowerPC sections.
A good secondary post, especially for people with G3/G4 hardware and for
cross-posting the technical notes.

### 6. Macintosh Garden and Macintosh Repository

<https://macintoshgarden.org/>  
<https://www.macintoshrepository.org/>

Not mailing lists, but the right permanent archives for a Tiger software
release. Upload the DMG and the source snapshot with a short description and a
link to the project page. This is what people will find years from now.

### 7. UrBackup community forum

<https://forums.urbackup.org/>

Announce the client port in the UrBackup community as well. This is where
server users will ask about protocol compatibility and restore behavior.

## What not to do

- Do not attach a 5 MB DMG or a 20 MB source archive to a mailing-list post.
  Upload the bundle to a file host or a project release page and post the URL.
- Do not send HTML mail, styled text or tracking links.
- Do not claim that the menu-bar icon works in every Tiger session. It was
  seen in earlier sessions but did not appear in the final verification
  session; the application and backend still worked.
- Do not claim image backups. The macOS client does not support them.
- Do not call it a new GUI. It is the original UrBackup frontend rebuilt for
  Tiger.

## Plain-text announcement

Subject:

```text
[ANN] UrBackup client 2.0.34 for Mac OS X 10.4 Tiger / PowerPC
```

Body:

```text
Hello,

I have ported the official UrBackup 2.0.34 client and its original wxWidgets
frontend to Mac OS X 10.4.11 on 32-bit PowerPC. The result is a native Mach-O
PPC application, not an emulator and not a new GUI. The windows, menus, icons,
translations and status handling are the original UrBackup frontend, rebuilt
with a Tiger-compatible wxWidgets Carbon port.

What works:
- full and incremental file backups to an UrBackup 2.x server;
- restore from the server, including HFS+ resource forks, FinderInfo and
  extended attributes;
- the original Settings, Paths, Logs and Infos windows;
- tested on a real iBook G4 running 10.4.11.

Known limitations:
- image backups are not supported by the macOS client;
- Darwin 8 cannot set timestamps on symlinks on HFS+, so symlink timestamps
  are not preserved (target, permissions and flags are);
- the native Tiger folder picker is unstable, so the path editor asks for an
  absolute path instead;
- the menu-bar status item is implemented with NSStatusItem, but in some Tiger
  sessions SystemUIServer does not display it. The application remains usable
  through Settings, Paths and Logs.

Download:
<URL>

SHA-256:
<CHECKSUM>

The download contains the DMG, a tar.gz archive, this README, the license
files and a source snapshot. UrBackup is AGPLv3-or-later.

I am looking for testers with G3, G4 and G5 machines, especially:
- different Tiger installations and clean user accounts;
- backup/restore of resource forks, FinderInfo and xattrs;
- machines where the menu-bar icon does or does not appear.

Please report the exact Mac model, Tiger version, server version and the
relevant client/server log lines. I will collect the results and update the
project notes.

Thanks,
Daniele Parravicini
```

## Short version for forums

```text
[ANN] UrBackup 2.0.34 client for Mac OS X 10.4 Tiger / PowerPC

I have ported the official UrBackup 2.0.34 client and its original wxWidgets
frontend to 10.4.11 on 32-bit PowerPC. Native Mach-O PPC build, original GUI,
full/incremental file backups, restore with HFS+ resource forks, FinderInfo
and xattrs. Tested on an iBook G4. Image backups are not supported; symlink
timestamps cannot be set by Darwin 8; the menu-bar status item is
session-dependent. DMG, tar.gz, source snapshot and checksums:
<URL>

Feedback and test reports welcome.
```

## Publication checklist

1. Upload `UrBackupTiger-2.0.34-ppc-en.zip` and the source archive to a stable
   download location.
2. Put the real URL and SHA-256 in the message.
3. Post the plain-text message to one list first; wait for replies and fix any
   factual issue before cross-posting.
4. Keep the same subject and text across lists so the archive stays coherent.
5. Do not publish personal email addresses, LAN IPs or credentials in the
   public message. The draft signs with the maintainer name only; add a
   contact address only if you are comfortable making it public.
