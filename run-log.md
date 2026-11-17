# tree-expo APK emulator screenshot runs

Repo: https://github.com/TPGoFighting/tree-expo-apk-test
APK: https://tpgofighting.top/preview/tree-expo/app.apk (124,308,733 bytes, top.tpgofighting.tree)
Workflow: `.github/workflows/emulator-shots.yml` (ubuntu-latest, API 34, x86_64, pixel_6)

## Run 1 — 44016004494 — FAILURE (2026-11-17 04:16 UTC, 18m51s)
- APK download passed (size verified). Emulator booted fine.
- `adb install -r app.apk` → Success.
- `ACT=$(adb shell cmd package resolve-activity ...)` returned EMPTY, and the
  `if [ -z "$ACT" ]` fallback never took effect: the runner executes EACH
  script line as a separate `/usr/bin/sh -c`, so variables do not persist
  between lines. `am start -n ""` → IllegalArgumentException, exit 255.
- No screenshots, no artifact.

## Run 2 — 44018357830 — SUCCESS (2026-11-17 04:36 UTC, 10m37s)
- https://github.com/TPGoFighting/tree-expo-apk-test/actions/runs/44018357830
- Fix: every script line self-contained; launch line is a single line with an
  inline `$(resolve-activity ...)` and `|| am start -n top.tpgofighting.tree/.MainActivity`.
- Artifact `tree-expo-shots`: tree-home.png, tree-me.png, tree-back.png, logcat.txt
  (downloaded to `~/workspace/tree-expo-apk-test/shots/`).

## Result — screenshots UNUSABLE (emulator System UI ANR, not an app failure)
- All three screenshots show an Android ANR dialog instead of the app:
  - tree-home.png (04:45): grey dimmed screen, "System UI isn't responding"
  - tree-me.png (04:45): black screen, "System UI isn't responding"
  - tree-back.png (04:46): black screen, "Process system isn't responding"
- Logcat: ZERO `FATAL EXCEPTION`, ZERO app ANR. ANRs are all system processes
  (system, com.android.systemui x2, android.ext.services,
  com.android.providers.media.module, com.android.phone x2,
  com.android.bluetooth), starting 04:42:45 — BEFORE the app launched.
  The taps at (930,1980) and (100,2200) timed out at NavigationBar input
  dispatch; they never reached the app.
- App itself launched cleanly: dex2oat ok, MainActivity START 04:45:35,
  process start 04:45:37, SoLoader + Hermes ok, ExpoModulesCore ✅,
  `Displayed .MainActivity +11s516ms` (04:45:47), `ReactNativeJS: Running "main"`
  (04:45:50), no JS errors after. Only warning is the benign emulator
  SwiftShader "Failed to initialize 101010-2 format" line (also seen for
  system processes).
- Verdict: whether the tree renders on screen is UNPROVEN by this run — the
  frozen System UI/compositor hides the app surface. Same CI-emulator
  launcher-ANR artifact as the voice-brain v1.3.6 smoke run (2026-11-13).
  Decisive check remains TP's real phone (he has the APK) or a re-run hoping
  for a healthy emulator.

## Run 3 — 44020506013 — SUCCESS (2026-11-17 04:55 UTC, 13m8s)
- https://github.com/TPGoFighting/tree-expo-apk-test/actions/runs/44020506013
- Changes (commit 5da9286): logic moved to `scripts/run-shots.sh`, called by
  one line from the workflow — the runner's per-line `sh -c` makes inline
  multi-line scripting impossible; 60 s System UI settle wait + responsiveness
  probe after boot; ANR handling before every screenshot (uiautomator dump →
  grep "isn't responding" → parse the Wait button center from the dump via
  `scripts/wait_button.py` → tap it); home screenshots at 15 s and 30 s after
  launch. Stayed on API 34 — run-2 log gave no evidence the ANR is
  API-34-specific (system-wide ANRs across systemui/phone/bluetooth/media).
- Artifact `tree-expo-shots` downloaded to `shots/run3/`
  (tree-home-15s.png, tree-home-30s.png, tree-me.png, tree-back.png,
  logcat.txt, ui-last.xml).

## Result — ANR handling WORKED, but the tree never appeared in the window
- Job log: system responsive on first probe (05:03:05), pre-launch "no ANR
  dialog" (05:03:23). ANR dialog present at home-15s (05:06:08) → Wait tapped
  at parsed (540,1328); still present at home-30s (05:07:03) → Wait tapped at
  parsed (540,1332); gone by the "me" (05:07:45) and "back" (05:08:18)
  checks. The dialog was a leftover of pre-launch system ANRs (05:01:59–
  05:03:54, com.android.phone etc.), not the app — no "ANR in
  top.tpgofighting.tree" anywhere.
- Screenshots (viewed): home-15s = ANR dialog over black; home-30s / me /
  back = dialog gone, app showing a dark screen with a central "…" loading
  placeholder — no tree, no labels in any shot. The taps at (930,1980) and
  (100,2200) landed while the app was still on the loading gate, so they
  prove nothing about the "me" interaction.
- Logcat: app healthy — dex2oat OK, MainActivity Displayed +21s602ms,
  SoLoader OK, `ReactNativeJS: Running "main"` 05:06:03, ZERO FATAL EXCEPTION,
  ZERO app ANR, zero JS errors after start. App process silent after 05:06:05
  (normal — no per-frame logging). Only warnings are benign (SkFontMgr
  fonts_customization.xml missing, SwiftShader format fallback).
- Verdict: INCONCLUSIVE on native rendering. The app launches and runs JS
  cleanly; the "…" gate never cleared within the ~2.5 min observation window
  after launch. Either the emulator is just extremely slow (everything here
  is ~10–20× slower than a phone: dex2oat 20 s, Displayed +21 s) and the tree
  would have appeared later, or the app is genuinely stuck at the loading
  gate on native. This run ended before the two could be distinguished.
  Suggested next step if retried: wait 60–90 s after launch before the first
  screenshot (not decided — needs a new instruction; do not loop on this
  without one).
