#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

echo "=== CYBER-GUARDIAN XMD build script for Termux ==="
echo "This will install packages, Cordova, Android command-line tools (if allowed), create the project and build a debug APK."
echo

# Basic packages
pkg update -y
pkg upgrade -y
pkg install -y git nodejs openjdk-17 wget unzip zip proot

# Ensure npm global installs go under $HOME/.npm-global to avoid permission issues
export NPM_CONFIG_PREFIX=${HOME}/.npm-global
export PATH=${NPM_CONFIG_PREFIX}/bin:$PATH
mkdir -p "${NPM_CONFIG_PREFIX}"

# Install Cordova
echo "Installing Cordova (may take a while)..."
npm install -g cordova@11.0.0

# Set Java environment
if command -v javac >/dev/null 2>&1; then
  JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")
  export JAVA_HOME
  echo "Detected JAVA_HOME=${JAVA_HOME}"
else
  echo "Warning: javac not found after installing openjdk-17. Continuing but build may fail."
fi

# Android SDK root
export ANDROID_SDK_ROOT=${HOME}/Android/Sdk
export PATH=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}
mkdir -p "${ANDROID_SDK_ROOT}"

# Download Android command-line tools if not present
if [ ! -d "${ANDROID_SDK_ROOT}/cmdline-tools/latest" ]; then
  echo
  echo "Android command-line tools not found. I can attempt to download them now (~70MB)."
  read -p "Download and install Android command-line tools now? [Y/n] " answer
  answer=${answer:-Y}
  if [[ "${answer}" =~ ^[Yy]$ ]]; then
    cd "${HOME}"
    TMPZIP="${HOME}/cmdline-tools.zip"
    echo "Downloading command-line tools..."
    # Try a latest known Google link. If it fails, you'll need to download manually and put the zip at ${TMPZIP}
    if ! wget -O "${TMPZIP}" "https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"; then
      echo "Auto-download failed. Please download the Command line tools for Linux from:"
      echo "  https://developer.android.com/studio#command-tools"
      echo "Place the ZIP at ${TMPZIP} and re-run this script."
      exit 1
    fi
    mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
    unzip -q "${TMPZIP}" -d "${ANDROID_SDK_ROOT}/cmdline-tools/tmp"
    # Move contents into "latest" folder
    mv "${ANDROID_SDK_ROOT}/cmdline-tools/tmp/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
    rm -f "${TMPZIP}"
    echo "Command-line tools installed to ${ANDROID_SDK_ROOT}/cmdline-tools/latest"
  else
    echo "You chose not to download command-line tools. The script will continue but building will likely fail. To build, install Android command-line tools and Android SDK components (platform-tools, build-tools, platforms)."
  fi
fi

# Install Android SDK components via sdkmanager
if [ -x "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "Installing Android SDK platform-tools, build-tools and platform (API 33) ..."
  yes | "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" "platform-tools" "platforms;android-33" "build-tools;33.0.2"
  # Accept licenses
  yes | "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager" --licenses || true
else
  echo "sdkmanager not found. Make sure Android command-line tools are installed in ${ANDROID_SDK_ROOT}/cmdline-tools/latest and sdkmanager is executable."
fi

# Create Cordova project
PROJECT_DIR="${HOME}/CYBER-GUARDIAN"
if [ -d "${PROJECT_DIR}" ]; then
  echo "Project directory ${PROJECT_DIR} already exists. Reusing it."
else
  echo "Creating Cordova project..."
  cordova create "${PROJECT_DIR}" com.cyberguardian.xmd "CYBER-GUARDIAN XMD"
fi

cd "${PROJECT_DIR}"

# Replace www/index.html and config.xml if present in the same folder as this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/config.xml" ]; then
  echo "Using provided config.xml"
  cp "${SCRIPT_DIR}/config.xml" "${PROJECT_DIR}/config.xml"
fi
if [ -d "${SCRIPT_DIR}/www" ]; then
  echo "Copying provided www/"
  rm -rf "${PROJECT_DIR}/www"
  cp -r "${SCRIPT_DIR}/www" "${PROJECT_DIR}/www"
fi

# Add Android platform (lock to a cordova-android version that works with modern SDKs)
echo "Adding Android platform..."
cordova platform rm android 2>/dev/null || true
cordova platform add android@10.1.2

# Build debug APK
echo
echo "Building debug APK (this can take several minutes)..."
cordova build android --debug

# Locate the debug APK
APK_PATH=$(find "${PROJECT_DIR}" -type f -path "*/platforms/android/app/build/outputs/apk/debug/*-debug.apk" | head -n 1 || true)
if [ -z "${APK_PATH}" ]; then
  echo "Could not find APK in expected build output location. Search results:"
  find "${PROJECT_DIR}" -type f -name "*-debug.apk" || true
  echo "Build may have failed. Check the output above."
  exit 1
fi

DEST="${HOME}/CYBER-GUARDIAN-XMD-debug.apk"
cp "${APK_PATH}" "${DEST}"
echo
echo "=== Build complete ==="
echo "Debug APK copied to: ${DEST}"
echo "You can install it with: pm install -r ${DEST} (run in Termux with appropriate permissions or copy the APK to your file manager and install)"
echo
echo "Notes:"
echo "- This APK is a debug build. For release builds you must sign with your own keystore and align the APK."
echo "- If the build fails because of missing sdkcomponents, ensure ANDROID_SDK_ROOT is set to ${ANDROID_SDK_ROOT} and that sdkmanager installed platform-tools, platforms;android-33 and build-tools;33.0.2"