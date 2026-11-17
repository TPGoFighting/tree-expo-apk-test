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

## Run 4 — 44031052727 — SUCCESS (2026-11-17 06:25 UTC, 22m41s)
- https://github.com/TPGoFighting/tree-expo-apk-test/actions/runs/44031052727
- Changes (commit cd6d3d3): **v2 APK** — EAS build 960300a5 (shader fix:
  `uInk.eval`, 124,347,441 bytes, sha256
  a2e113dcd9b69e824dedc9af7ac0794d37ab757410dbed36ba93f15f0bea96b1),
  downloaded from the EAS artifact link with size verification (the preview
  URL still serves v1 — ATP SSH down, deploy pending). First home shots at
  60 s and 120 s after launch; "me" tap waits 10 s before its shot.
- Artifact `tree-expo-shots` downloaded to `shots/run4/`
  (tree-home-60s.png, tree-home-120s.png, tree-me.png, tree-back.png,
  logcat.txt, ui-last.xml).

## Result — v2 app runs, but the tree NEVER appears; ANR dialogs again
- Job log: system responsive on try 2 (06:38:04), pre-launch "no ANR dialog"
  (06:38:29). APK size verified 124347441 at download.
- Screenshots (viewed):
  - home-60s (06:43): "Process system isn't responding" dialog over black —
    DESPITE the job log saying "[home-60s] no ANR dialog" at 06:43:12; the
    dialog appeared (or the dump missed it) in the ~20 s before the screencap
    completed (06:43:32). handle_anr is not fully reliable when the system
    is this frozen (a uiautomator dump also timed out at 06:37:24).
  - home-120s (06:45): "System UI isn't responding" dialog over black —
    STILL present after handle_anr tapped Wait at parsed (540,1328) at
    06:44:55 + 5 s wait. Either the tap never registered (input dispatch
    frozen) or a new dialog (different process) appeared after the tap.
  - tree-me (06:46) / tree-back (06:46): dialog gone, but a plain uniform
    dark screen — NO "…" placeholder, NO tree, NO labels, NO intro text.
    The two files are byte-identical (same sha256). The "me" tap (06:45:54)
    and back tap landed while the ANR dialog was up, so they almost
    certainly never reached the app; these shots prove nothing about the
    interaction.
- Logcat — app healthy, no crash, but burning CPU with no visible output:
  - MainActivity Displayed +18s661ms (06:42:08), `ReactNativeJS: Running
    "main"` (06:42:18), zero JS errors after start, zero FATAL for the app.
    The 4 FATAL EXCEPTION lines are all system-side and pre-app
    (com.android.phone, com.android.systemui, one more system process —
    DeadSystemException at 06:33:34–35; plus a uiautomator UiAutomation
    connect timeout at 06:37:24). ANRs: 22 "ANR in" lines, all system
    processes (phone ×18, bluetooth, media.module, systemui, system) —
    zero "ANR in top.tpgofighting.tree".
  - `SkiaTextureView: onSurfaceTextureAvailable: 1080x2400` (06:42:29) —
    the Skia surface IS created. One benign `updateAndRelease() failed...
    can safely be ignored` (RNSkia's own wording) after a one-off
    `EGLConsumer is not attached to an OpenGL ES context` (06:42:30).
    `Choreographer: Skipped 33 frames!` and `EGL_emulation:
    app_time_stats: avg=10403ms` — frames take ~10 s each on SwiftShader.
  - The app process stays at 35–58% CPU continuously (ActivityManager
    snapshots every ~30 s, 06:42–06:47) — it is doing heavy work the whole
    window, then goes silent in logcat (normal, no per-frame logging).
- Verdict: INCONCLUSIVE again, with a NEW signal vs run 3. Run 3 sat on the
  "…" gate for 2.5 min; run 4's me/back shots (~4 min after JS start) show
  NO "…" — the gate appears to have cleared, yet the screen is a blank dark
  surface with no tree. Two hypotheses cannot be separated from this run:
  (1) emulator artifact — SwiftShader software rendering + a continuously
  ANR-ing/frozen system compositor can't present the Skia canvas (the
  dialog covered the screen at both home shots); or (2) a real native bug —
  the v2 APK passes the gate but renders nothing on Android (the web
  preview renders the tree fine, but native Skia presentation is a
  different path: SkiaTextureView + SurfaceTexture). The EGLConsumer line
  is a named lead, not proof.
- Emulator route status: three runs, three different emulator-side failure
  modes (run 2: ANR dialogs; run 3: "…" gate; run 4: blank dark screen +
  dialogs). Timing tweaks have now been tried twice (30 s → 60/120 s) and
  the failure mode changed rather than resolved. The decisive check remains
  TP's real phone with the v2 APK (he has the link). If retried, the change
  should be structural, not another timing tweak — e.g. a different
  emulator profile/API, a debug build with frame-loop logging, or a
  uiautomator dump at 120 s to tell gate-stuck ("…" node present) from
  canvas-blank ("…" node absent) without relying on pixels. Do not loop
  without a new instruction.
