#!/usr/bin/env bash
# Content-addressed eVld rename for untabled builds. Runs only if the
# table patcher declined (no $OUT/vold_patched). Count-guarded: refuses
# unless there is exactly one NUL-delimited "vold" string, so it can never
# write garbage. On refusal it leaves the contract path (guest keeps "vold").
WORK="$1"; OUT="$2"
[ -s "$WORK/vold" ] || exit 0
[ -s "$OUT/vold_patched" ] && exit 0   # table already patched it
python3 - "$WORK/vold" "$WORK/service.incremental.so" "$OUT/vold_patched" "$OUT/service.incremental_patched.so" <<'PYV' || { echo "generic vold refused (count!=1 or dump missing); keeping contract path"; exit 0; }
import sys, os
sv, si, ov, oi = sys.argv[1:5]
def ren(a, b):
    d = open(a, "rb").read()
    n = d.count(b"\x00vold\x00")
    if n != 1:
        sys.exit("generic vold: %s has %d NUL-vold strings (want 1)" % (a, n))
    open(b, "wb").write(d.replace(b"\x00vold\x00", b"\x00eVld\x00"))
    print("generic vold: renamed 1 string in", a)
ren(sv, ov)
if os.path.isfile(si) and os.path.getsize(si) > 0:
    ren(si, oi)
else:
    sys.exit("generic vold: service.incremental.so dump missing")
PYV
[ -s "$OUT/vold_patched" ] && (cd "$OUT" && sha256sum vold_patched service.incremental_patched.so) >> "$OUT/guards.txt"
