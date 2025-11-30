# CYBER-GUARDIAN XMD — Build on Termux

What this repository contains:
- build.sh — Termux-friendly script that installs prerequisites, creates a Cordova project named "CYBER-GUARDIAN", and builds a debug APK.
- config.xml — Cordova config for app id and name.
- www/index.html — Minimal app UI.

Quick steps to build on Termux (summary)
1. Open Termux and grant storage permission:
   - termux-setup-storage
2. Copy the files (build.sh, config.xml, www/) into a folder in Termux (for example: ~/cyber-build)
3. In Termux:
   - cd ~/cyber-build
   - chmod +x build.sh
   - ./build.sh
4. After a successful build the debug APK will be copied to:
   - ~/CYBER-GUARDIAN-XMD-debug.apk
   Install it on-device or copy it out.

Important notes and troubleshooting
- Android command-line tools: The script attempts to download the official Android command-line tools. If that download fails, manually download "Command line tools only" (Linux) from:
  https://developer.android.com/studio#command-tools
  Place the zip in the folder and re-run the script, or manually extract to:
  $HOME/Android/Sdk/cmdline-tools/latest
- SDK components: The script installs platform-tools, a recent platform (android-33), and build-tools. If your device or the SDK versions differ, adjust the build-tools/platform versions in build.sh.
- Signing: The produced APK is a debug build and is signed with Cordova/Gradle debug key. For a release you must generate a keystore and sign+align the release APK.
- Performance: Building on-device is CPU and memory intensive; it can take many minutes to finish on low-end devices.
- If Cordova or the gradle-related build fails with Java or SDK errors, ensure:
  - openjdk-17 is installed (pkg install openjdk-17)
  - ANDROID_SDK_ROOT is set and sdkmanager has installed required components
  - PATH includes ${ANDROID_SDK_ROOT}/platform-tools and the cmdline-tools bin

Where the APK will be:
- platforms/android/app/build/outputs/apk/debug/app-debug.apk
- plus a copy at ~/CYBER-GUARDIAN-XMD-debug.apk after a successful run.

If you want me to:
- Push these files into your GitHub repo `pokuahdoe-rgb/CYBER-GUARDIAN-` (I will need explicit permission and confirmation), or
- Modify the app UI/permissions (e.g., camera, location, termux:api integration),
tell me what you want changed and whether to commit/push.
