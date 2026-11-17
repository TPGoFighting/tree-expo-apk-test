#!/usr/bin/env bash
# Tree-expo APK emulator screenshots, run 4 (v2 APK).
#
# Runs as ONE bash script, invoked by the workflow as `bash scripts/run-shots.sh`.
# Do NOT inline this into the emulator-runner `script:` block: that action
# executes every line as a separate `/usr/bin/sh -c`, so variables and
# functions would not survive between lines (run 1 lesson).
#
# Run 2 lesson: the emulator's System UI can freeze (ANR dialogs) before the
# app even launches, hiding the app surface. So this script:
#   1. waits 60 s after boot for System UI to settle and probes responsiveness
#   2. checks for an ANR dialog before every screenshot and taps "Wait"
#      (coordinates parsed from the UI dump, never hardcoded)
#   3. screenshots the home screen at 60 s and 120 s after launch
#      (run 3: the tree never appeared in a 30 s window — this emulator is
#      ~10-20x slower than a phone, so give the loading gate real time)
#   4. taps "me" and waits 10 s before its screenshot (key shot: camera pan,
#      intro text, and whether the 4 photos render on native)
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# Dump the UI hierarchy and, if an "isn't responding" dialog is showing,
# tap its Wait button (coordinates parsed from the dump, never hardcoded).
# $1 = label for logging
handle_anr() {
  local label="$1"
  if ! timeout 30 adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; then
    log "[$label] uiautomator dump failed (system busy?)"
    return 0
  fi
  if ! timeout 30 adb pull /sdcard/ui.xml /tmp/ui.xml >/dev/null 2>&1; then
    log "[$label] ui.xml pull failed"
    return 0
  fi
  if ! grep -q "isn't responding" /tmp/ui.xml; then
    log "[$label] no ANR dialog"
    return 0
  fi
  log "[$label] ANR dialog present"
  local xy
  if xy=$(python3 "$SCRIPT_DIR/wait_button.py" /tmp/ui.xml 2>/dev/null); then
    log "[$label] tapping Wait at $xy"
    timeout 30 adb shell input tap "$xy" || true
    sleep 5
    log "[$label] tapped Wait, waited 5s"
  else
    log "[$label] Wait button not found in dump - leaving dialog up"
  fi
}

shot() {
  local file="$1"
  timeout 30 adb exec-out screencap -p > "$file" || true
  ls -la "$file" 2>/dev/null || log "screenshot $file missing"
}

# --- 1. let System UI settle after boot (run 2: ANRs started before app launch) ---
log "== waiting 60s for System UI to settle =="
sleep 60
for i in 1 2 3; do
  if timeout 30 adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; then
    log "system responsive on try $i"
    break
  fi
  log "system not responsive yet (try $i), waiting 15s"
  sleep 15
done
handle_anr "pre-launch"

# --- 2. install + launch ---
adb shell wm size
adb install -r app.apk
ACT="$(adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER top.tpgofighting.tree | tr -d '\r' | tail -n 1)"
if [ -n "$ACT" ]; then
  log "launching $ACT"
  adb shell am start -n "$ACT"
else
  log "resolve-activity empty, falling back to .MainActivity"
  adb shell am start -n top.tpgofighting.tree/.MainActivity
fi

# --- 3. screenshots over time (run 4: long waits — the emulator is very slow) ---
# First home shot at 60 s after launch; second at 120 s (taken regardless,
# so the run log can show whether the gate cleared late).
sleep 60
handle_anr "home-60s"
shot tree-home-60s.png
sleep 60
handle_anr "home-120s"
shot tree-home-120s.png

# tap "me" (bottom-right on 1080x2400) — key shot: pan, intro, 4 photos?
adb shell input tap 930 1980 || true
sleep 10
handle_anr "me"
shot tree-me.png

# tap back arrow (bottom-left)
adb shell input tap 100 2200 || true
sleep 5
handle_anr "back"
shot tree-back.png

adb logcat -d > logcat.txt || true
timeout 30 adb pull /sdcard/ui.xml ui-last.xml >/dev/null 2>&1 || true
ls -la *.png *.txt *.xml 2>/dev/null || true
log "== done =="
