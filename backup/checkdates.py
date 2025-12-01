#!/usr/bin/env python3
import sys, json, ast, re, datetime

# args: retention_days, filen_dest
if len(sys.argv) < 3:
    print("usage: checkdates.py <retention_days> <filen_dest>", file=sys.stderr)
    sys.exit(2)

ret_days = int(sys.argv[1])
filen_dest = sys.argv[2].rstrip('/')
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    try:
        data = ast.literal_eval(raw)
    except Exception:
        data = []

cutoff = datetime.datetime.utcnow() - datetime.timedelta(days=ret_days)
pat = re.compile(r'backup-([0-9]{8})-([0-9]{6})')
out = []
for item in data:
    if not isinstance(item, str):
        continue
    m = pat.search(item)
    if not m:
        continue
    ymd = m.group(1)
    hms = m.group(2)
    try:
        dt = datetime.datetime.strptime(ymd + hms, "%Y%m%d%H%M%S")
    except Exception:
        continue
    if dt < cutoff:
        print(f"{filen_dest}/{item}")
