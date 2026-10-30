# Android test APK

The Android test build is produced by the repository's Android test APK workflow:
https://github.com/betraykuroro99-ai/BALLxRONKE/actions/workflows/android-apk.yml

First verified APK build: https://github.com/betraykuroro99-ai/BALLxRONKE/actions/runs/40985470994

Open a successful run and download the BALLxRONKE-android-test artifact.
Extract the ZIP and open BALLxRONKE-android-test.apk on your Android phone.
If Android prompts, allow installation from the browser/file manager used to
open this APK, then launch BALLxRONKE. The archive also contains the SHA-256
checksum, source commit, engine version and Android package metadata.

This is a debug-signed test APK, built with Godot 4.6.3, not a Play Store release.
It includes ARM32 and ARM64 runtimes and uses the Compatibility renderer. The
workflow keeps a cached debug key for test updates; no production signing key
or password is committed. Build artifacts expire after 30 days. Pushes affecting
the Godot project automatically rebuild; Run workflow can rebuild manually.

## First phone check

1. Open the app and start a run. Check the blue theme, character art, menu text
   and arena fit on your display, including the camera cutout.
2. Move with the left touch stick while aiming with a second finger. Release
   each finger separately, then try dash and a fully charged Surge.
3. Pause with Android Back. Change effects or the FPS cap in Settings and resume.
4. Switch apps or lock/unlock the phone. The run should remain paused on return.
5. Reach an upgrade, both guardian encounters and the results screen. Check that
   warning lanes match shots and guardian phase changes remain readable.
6. Bank shards, return to camp and reopen the last report. Close/reopen the app
   and confirm your settings and banked progress remain.
7. Play a full run at 60 FPS. If the device struggles, try 30 FPS with extra
   effects and damage numbers disabled. Report the phone model, Android version,
   chosen cap and the wave where slowdowns occur.

A signed archive and passing headless checks do not establish on-device startup,
audio, touch feel or actual FPS. These still need a physical-phone test. No
Windows or Linux executable is built by this workflow.
