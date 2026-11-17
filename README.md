# tree-expo-apk-test

Test-only repo. Runs the tree-expo APK (`top.tpgofighting.tree`, Expo SDK 58)
on a GitHub-hosted Android emulator (API 34, Pixel 6) and captures screenshots:

- `tree-home.png` — app home after launch (tree should be grown, 4 labels visible)
- `tree-me.png` — after tapping the "me" label (bottom-right)
- `tree-back.png` — after tapping the back arrow (bottom-left)
- `logcat.txt` — device log for crash diagnosis

The APK is downloaded from https://tpgofighting.top/preview/tree-expo/app.apk
at run time and is **not** committed here. Triggered on push or manually
(`workflow_dispatch`).
