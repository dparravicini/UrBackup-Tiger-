#!/usr/bin/python
# Python 2.3 compatible; uses only Tiger's standard library.
import sys
from xml.sax.saxutils import escape
if len(sys.argv) != 3:
    raise SystemExit(2)
root = sys.argv[1]
plist = sys.argv[2]
root = escape(root)
text = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>org.urbackup.tiger.lab</string>
<key>ProgramArguments</key><array>
<string>ROOT/sbin/urbackupclientbackend</string>
<string>--logfile</string><string>ROOT/log/client.log</string>
<string>--pidfile</string><string>ROOT/client.pid</string>
<string>--restore</string><string>client-confirms</string>
</array>
<key>RunAtLoad</key><true/>
<key>OnDemand</key><false/>
<key>Nice</key><integer>5</integer>
<key>StandardOutPath</key><string>ROOT/log/launchd.stdout.log</string>
<key>StandardErrorPath</key><string>ROOT/log/launchd.stderr.log</string>
</dict></plist>
""".replace("ROOT", root)
f = open(plist, "w")
f.write(text)
f.close()
