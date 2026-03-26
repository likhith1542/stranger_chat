# Release Guide — Build, Sign & Publish STRANGER

## Step 1 — Generate a Signing Keystore

Run this **once** on your local machine. Keep the generated `.jks` file safe — if you lose it you cannot update the app on devices that have it installed.

```bash
keytool -genkey -v \
  -keystore stranger_release.jks \
  -alias stranger_key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

You will be prompted for:
- **Keystore password** — pick a strong password, save it somewhere safe
- **Key password** — can be the same as keystore password
- **Your name, organisation, city, country** — these go into the certificate (can be anything)

This creates `stranger_release.jks` in your current directory.

> ⚠️ **Never commit `stranger_release.jks` to Git.** It is listed in `.gitignore` already.

---

## Step 2 — Create `android/key.properties`

Copy the template and fill in your values:

```bash
cp android/key.properties.template android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=stranger_key
storeFile=../stranger_release.jks
```

> `storeFile` path is relative to `android/app/`. `../stranger_release.jks` means the `.jks` file sits in the `android/` folder.

Move your keystore there:

```bash
mv stranger_release.jks android/stranger_release.jks
```

> ⚠️ **`android/key.properties` is in `.gitignore` — never commit it.**

---

## Step 3 — Build Signed Release APK Locally

```bash
# Verify signing works locally first
flutter build apk --release --split-per-abi

# Your signed APKs are here:
ls build/app/outputs/flutter-apk/
# app-arm64-v8a-release.apk   ← most modern phones
# app-armeabi-v7a-release.apk ← older 32-bit phones
# app-x86_64-release.apk      ← Intel devices
```

Install on your device to verify:

```bash
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## Step 4 — Create a GitHub Repository

```bash
# Inside your project folder
git init
git add .
git commit -m "feat: initial release of STRANGER v1.0.0"

# Create repo on GitHub (via web UI or gh CLI)
gh repo create stranger_chat --public --source=. --remote=origin

# Push
git push -u origin main
```

---

## Step 5 — Add GitHub Secrets for CI Signing

The GitHub Actions workflow signs the APK in CI using secrets — so you never commit your keystore to the repo.

Go to your repo on GitHub:
**Settings → Secrets and variables → Actions → New repository secret**

Add these four secrets:

| Secret Name | Value |
|-------------|-------|
| `KEYSTORE_BASE64` | Base64-encoded keystore (see command below) |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_ALIAS` | `stranger_key` |
| `KEY_PASSWORD` | Your key password |

**How to get `KEYSTORE_BASE64`:**

```bash
# macOS / Linux
base64 -i android/stranger_release.jks | pbcopy   # copies to clipboard on Mac
base64 -i android/stranger_release.jks            # prints to terminal on Linux

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\stranger_release.jks")) | clip
```

Paste the output as the value for `KEYSTORE_BASE64`.

---

## Step 6 — Publish a Release

Once your secrets are set, publishing a new release is a single command:

```bash
# Tag the release (use semantic versioning)
git tag v1.0.0
git push origin v1.0.0
```

This triggers the GitHub Actions workflow which will:
1. Check out code
2. Set up Flutter
3. Decode your keystore from secrets
4. Build 4 signed APKs (arm64, arm32, x86_64, universal)
5. Create a GitHub Release with all APKs attached

**Watch it run:**
GitHub repo → **Actions** tab → `Build & Release` workflow

---

## Step 7 — Verify the Release

Once the workflow succeeds:

1. Go to your repo → **Releases** tab
2. You'll see `STRANGER v1.0.0` with 4 APK downloads
3. Share the release link: `https://github.com/likhith1542/stranger_chat/releases/latest`

---

## Updating the App

For future releases, bump the version in `pubspec.yaml`:

```yaml
version: 1.1.0+2   # format: versionName+versionCode
```

Then tag and push:

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.1.0"
git tag v1.1.0
git push origin main --tags
```

---

## Quick Reference

```bash
# Local debug build
flutter run

# Local release build (signed)
flutter build apk --release --split-per-abi

# Publish new version
git tag v1.x.x && git push origin v1.x.x

# Check workflow logs
gh run list
gh run view --log
```