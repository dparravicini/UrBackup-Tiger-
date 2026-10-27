#!/usr/bin/env python3
"""Read only the dedicated lab log and suppress credential-bearing lines."""
import re
from pathlib import Path
import shlex
import subprocess
CLI = str(Path.home() / ".local/bin/tiger")
home = subprocess.check_output([CLI, "exec", "/usr/bin/printenv HOME"], text=True).strip()
LOG = home + "/Library/UrBackupTigerLab/log/client.log"
result = subprocess.run([CLI, "exec", "cat " + shlex.quote(LOG)], capture_output=True, text=True)
if result.returncode:
    raise SystemExit(result.returncode)
secret = re.compile(r"ClientService cmd:|FILE_METADATA[|]|pw[=_]|password|authkey|token|identity|access.key|session", re.I)
lines = [line for line in result.stdout.splitlines() if not secret.search(line) and re.match(r"^(?:\d{4}-\d\d-\d\d |[012]-\d+-)", line)]
print("\n".join(lines[-25:]))
