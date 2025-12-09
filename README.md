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

## iOS Setup (macOS only)

### 1. Install Xcode
- Install Xcode from the Mac App Store
- Open Xcode and accept the license agreement
- Install Xcode command line tools:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 2. Install CocoaPods
```bash
sudo gem install cocoapods
```

### 3. Setup iOS Device (Physical Device)
- Connect your iPhone/iPad via USB cable
- Trust the computer on your iOS device
- In Xcode, go to Settings > Accounts and sign in with your Apple ID
- Open `ios/Runner.xcworkspace` in Xcode
- Select your device in the device dropdown
- Select "Runner" target and go to "Signing & Capabilities"
- Select your team and ensure automatic signing is enabled

### 4. Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

## Running the App

### Android

#### 1. Connect Android Device
- Connect your phone via USB cable
- Accept USB debugging prompt on phone

#### 2. Verify Device Connection
```bash
flutter devices
```
you should see andoid device as one of the device...

#### 3. Install Dependencies
```bash
flutter pub get
```

#### 4. Run on Device
```bash
flutter run
```

#### 5. Select Your Device
- When prompted, select your Android device from the list
- Wait for build and installation (first build takes 3-5 minutes)
- if not asking you probably using the android device as default

### iOS

#### 1. Connect iOS Device
- Connect your iPhone/iPad via USB cable
- Unlock your device and trust the computer

#### 2. Verify Device Connection
```bash
flutter devices
```
You should see your iOS device in the list

#### 3. Install Dependencies (if not done already)
```bash
flutter pub get
```

#### 4. Run on Device
```bash
flutter run
```

#### 5. Select Your Device
- When prompted, select your iOS device from the list
- First build takes 5-10 minutes
- If you see a code signing error, open the project in Xcode and configure signing

## Building Release Versions (Optional)

### Android APK
To build a release APK:
```bash
flutter build apk
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### iOS IPA
To build for iOS (requires Apple Developer account):
```bash
flutter build ios --release
```

Then archive and export from Xcode, or use:
```bash
flutter build ipa
```

IPA will be at: `build/ios/ipa/`

## How Caching Works

1. Open app with internet ON
2. Browse all pages you want offline
3. Turn internet OFF
4. Cached content loads from local storage
