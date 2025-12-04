# Cached WebView - Setup Guide

## Clone Repository

```bash
git clone <repository-url>
cd cached_webview
```

## Prerequisites Setup

### 1. Enable USB Debugging on Android Device
- Go to Settings > About Phone
- Tap "Build Number" 7 times to enable Developer Options
- Go to Settings > Developer Options
- Enable "USB Debugging"

### 2. Install Android Command Line Tools
```bash
sudo apt install google-android-cmdline-tools-11.0-installer -y
```

### 3. Accept Android SDK Licenses
```bash
yes | flutter doctor --android-licenses
```

### 4. Fix Android SDK Permissions
```bash
sudo chmod -R 777 /usr/lib/android-sdk
```

### 5. Create aapt Symlink
```bash
sudo ln -sf /usr/lib/android-sdk/build-tools/35.0.0/aapt /usr/bin/aapt
```

## Running the App

### 1. Connect Android Device
- Connect your phone via USB cable
- Accept USB debugging prompt on phone

### 2. Verify Device Connection
```bash
flutter devices
```
you should see andoid device as one of the device...

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run on Device
```bash
flutter run
```

### 5. Select Your Device
- When prompted, select your Android device from the list
- Wait for build and installation (first build takes 3-5 minutes)
- if not asking you probably using the android device as default

## Building APK (Optional)

To build a release APK:
```bash
flutter build apk
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## How Caching Works

1. Open app with internet ON
2. Browse all pages you want offline
3. Turn internet OFF
4. Cached content loads from local storage
