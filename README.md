# Get Top Marks With Shiksha Setu (v1.0.0)

Bilingual (Hindi + English) Flutter app with Search, Chapter-wise Assignments, Voice Input, Bookmarks,
Downloadable PDFs and Offline Mode.

## Quick Start

1. **Install Flutter** (stable). Verify:
   ```bash
   flutter --version
   ```

2. **Get packages:**
   ```bash
   flutter pub get
   ```

3. **Set the app icon** (optional):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. **Run debug:**
   ```bash
   flutter run
   ```

## Build Signed AAB & APK

> Android requires a keystore (JKS). Keep it secret and back it up.

### 1) Create a keystore (JKS)

**Windows (PowerShell):**
```powershell
keytool -genkey -v -keystore shiksha-setu-key.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

**macOS/Linux:**
```bash
keytool -genkey -v -keystore shiksha-setu-key.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

This will ask for a password and details. Remember the alias and passwords.

Move the file to `android/app/shiksha-setu-key.jks`.

### 2) Create signing config

Create `android/key.properties` with:

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=shiksha-setu-key.jks
```

Then edit `android/app/build.gradle` and ensure it reads `key.properties` and uses `signingConfigs.release` for `buildTypes.release`.

Minimal snippet (if missing) to add inside `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
        }
    }
}
```

### 3) Build AAB (Play Console upload)
```bash
flutter build appbundle --release
```
Find the file at:
```
build/app/outputs/bundle/release/app-release.aab
```

### 4) Build APK (for sideload/testing)
```bash
flutter build apk --release
```
Output:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Offline PDFs

This template ships a `assets/pdfs/placeholder.pdf`. The app copies PDFs to the device documents directory for offline use.
Replace with your real PDFs and update paths if needed.

## Bilingual (Hindi + English)

The UI labels are kept simple and dual-language where helpful. For full localization, you can add `intl` ARB files later.

## Structure
```
lib/
  main.dart
assets/
  data/subjects.json
  icons/icon.png
  pdfs/placeholder.pdf
```

## Color & Design

- Seed color: `#2F7CF6` (motivational, study-friendly)
- Rounded cards, soft shadows, Material 3

## Rename App (optional)
Change name in `pubspec.yaml` and Android `android/app/src/main/AndroidManifest.xml` (`application android:label`).

---

**Made for: Get Top Marks With Shiksha Setu (v1.0.0)**
