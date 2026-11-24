# Releasing Digital Munshi

- Package id (Android) / bundle id (iOS): **`com.digitalmunshi.app`**: permanent once uploaded.
- Firebase project: `sprint14-d3ab2` (existing accounts and data are shared).
- Version name: `version:` in `pubspec.yaml`. Version code: `--build-number`
  (CI uses the workflow run number).

## 1. One-time setup

### Firebase (required before the first release)
> **Temporary dev workaround in place:** `google-services.json` currently maps
> `com.digitalmunshi.app` to the OLD Android app's Firebase id so the app can
> run during development. CI refuses to build a release until the real config
> below replaces it.

The app id changed, so the new app must be registered in Firebase:
1. Firebase console → Project settings → **Add app** → Android, package
   `com.digitalmunshi.app`. Add the upload key's SHA-1/SHA-256 (below).
2. Download `google-services.json` and replace `android/app/google-services.json`.
   (Builds fail with "No matching client found for package name" until you do.)
3. For iOS: add an iOS app with bundle id `com.digitalmunshi.app` and place
   `GoogleService-Info.plist` in `ios/Runner/`.

Upload key fingerprints:
- SHA-1: `B6:01:19:95:19:10:76:C2:F4:4C:52:0D:A7:E4:4E:55:61:C6:49:EE`
- SHA-256: `CC:42:60:2E:98:D3:77:92:67:82:EF:B4:6F:44:53:56:9A:23:83:65:3C:01:EB:32:95:DD:19:CE:A4:A3:57:64`

After the first upload, also add the **Play App Signing** key's SHA-1/SHA-256
(Play Console → Test and release → App integrity) to the Firebase Android app.

### Upload key (already generated)
- Keystore: `android/app/upload-keystore.jks` (alias `upload`)
- Passwords: `android/key.properties`

Both are git-ignored. **Back them up somewhere safe (e.g. a password manager)**.
With Play App Signing a lost upload key can be reset, but it takes days.

### GitHub secrets (for CI builds)
Settings → Secrets and variables → Actions → replace the old values:
| Secret | Value |
| --- | --- |
| `KEYSTORE_BASE64` | output of `base64 -w0 android/app/upload-keystore.jks` (Git Bash) |
| `KEYSTORE_PASSWORD` | `storePassword` from `android/key.properties` |
| `KEY_ALIAS` | `upload` |
| `KEY_PASSWORD` | `keyPassword` from `android/key.properties` |

Delete the old `PLAY_STORE_CONFIG_JSON` secret (old Play account).

### Play Console (new account)
1. Create the app "Digital Munshi" (Finance, free, no ads) and turn on Play App Signing.
2. Main store listing: copy the texts from `distribution/store_listing/listing-en-US.md`;
   upload `icon_512.png`, `feature_graphic.png` and 2–8 phone screenshots.
3. Privacy policy: host `distribution/PRIVACY_POLICY.md` publicly and add the URL.
4. App content: Data safety (see below), ads = no, target audience 18+, content rating.
5. New personal developer accounts must run a **closed test (12+ testers for 14 days)**
   before production access is granted.

Data safety answers: collects name, email address, photos (optional profile
picture), financial info (user-entered records) and device IDs (push token);
used for app functionality and account management; encrypted in transit; not
sold or shared with third parties; users can request deletion.

## 2. Every release
1. Bump `version:` in `pubspec.yaml` and edit `distribution/whatsnew/whatsnew-en-US`
   (max 500 characters).
2. Merge to `master` (or run the workflow manually). CI analyzes, tests and
   attaches a signed `app-release.aab`, `app-release.apk` and `mapping.txt` to
   a GitHub release.
3. Play Console → create a release on the track you want → upload the `.aab`,
   paste the release notes, upload `mapping.txt` (de-obfuscated crash reports).

Local build instead of CI: `flutter build appbundle --release --build-number=<N>`
(uses `android/key.properties`; without it the build is signed with the debug
key, which Play rejects).

## Brand assets
Sources: `assets/images/logo.svg` and `tool/brand/*.svg`. After editing:
```
flutter test tool/brand/render_brand_test.dart
python tool/brand/feature_graphic.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Must fix before going live
- `lib/clients/notifications/notification_server_key.dart` embeds a Firebase
  service-account private key that anyone can extract from the app. Revoke it
  in Google Cloud Console (IAM → Service accounts → Keys) and send pushes from
  a Cloud Function instead.
- Google Play requires in-app **account deletion** (plus a web page explaining
  how to request it) for apps with sign-up. Not implemented yet.
