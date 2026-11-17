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
