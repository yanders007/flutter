# Anderson CVE

> Mobile Android vulnerability scanner — identifies web technologies and maps them to public CVEs.

Built with **Flutter / Dart**. Architecture: 100% client-side, zero persistence.

---

## Architecture

```
URL Input
   │
   ▼
Step A — Passive HTTP Analysis       (package: http + html)
   │   • HTTP response headers
   │   • HTML <meta name="generator">
   │   • DOM <script>/<link> src URL regex
   │
   ▼
Step B — Dynamic JS Evaluation       (flutter_inappwebview headless)
   │   • Incognito mode, no cache, no storage
   │   • Evaluates window.jQuery, window.React, window.Vue …
   │   • WebView destroyed immediately after extraction
   │
   ▼
Step C — CVE Lookup                  (NIST NVD API v2.0)
   │   • One HTTP query per detected technology
   │   • CVSS v3.1 score + severity classification
   │
   ▼
In-Memory Report
   │   • Lives in RAM only (Riverpod StateNotifier)
   │   • Purged on back navigation (PopScope → dispose → GC)
   └──► Never written to SharedPreferences, SQLite, or disk cache
```

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── models/
│   │   └── scan_result.dart          # ScanResult, DetectedTech, CveItem
│   ├── services/
│   │   ├── static_scanner_service.dart   # Step A
│   │   ├── dynamic_scanner_service.dart  # Step B
│   │   └── nvd_api_service.dart          # Step C
│   └── providers/
│       └── scan_provider.dart        # Riverpod orchestrator
├── features/
│   ├── home/home_screen.dart
│   ├── scan/scan_screen.dart
│   └── report/report_screen.dart
└── shared/
    └── theme/app_theme.dart
```

---

## Local Development

### Prerequisites

- Flutter ≥ 3.16 ([install](https://docs.flutter.dev/get-started/install))
- Android Studio / SDK (API 21+)
- Java 17

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

### Build debug APK

```bash
flutter build apk --debug
```

---

## GitHub Actions CI/CD

The workflow at `.github/workflows/build_apk.yml` runs automatically.

### Jobs

| Job | Trigger | Output |
|-----|---------|--------|
| `test` | Every push / PR | Lint + unit tests |
| `build_debug` | Push to `main`/`develop`, PRs | Debug APK (artifact) |
| `build_release` | Push to `main` or tag | Signed release APKs + AAB |
| `release` | Version tag `v*.*.*` | GitHub Release with APKs |

### Required Secrets

Add these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded Android keystore (`.jks`) |
| `KEY_STORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias inside the keystore |
| `KEY_PASSWORD` | Key password |
| `NIST_NVD_API_KEY` | *(Optional)* NIST NVD API key for higher rate limits |

### Generate a keystore (first time)

```bash
keytool -genkey -v \
  -keystore anderson-cve-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias anderson-cve \
  -storepass YOUR_STORE_PASS \
  -keypass YOUR_KEY_PASS \
  -dname "CN=Anderson CVE, OU=Mobile, O=Anderson, L=Paris, ST=IDF, C=FR"

# Encode for GitHub secret
base64 -i anderson-cve-release.jks | pbcopy   # macOS
base64 android-release.jks > keystore.b64     # Linux
```

### Trigger a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the full release pipeline and creates a GitHub Release with signed APKs.

---

## NIST NVD API

CVE data is sourced from the [NIST National Vulnerability Database API v2.0](https://nvd.nist.gov/developers/vulnerabilities).

- **Without API key**: ~5 requests / 30 seconds
- **With API key** (free registration): 50 requests / 30 seconds

Register at: https://nvd.nist.gov/developers/request-an-api-key

---

## Privacy & Security

- **Zero disk writes** — No data is written to SharedPreferences, SQLite, Hive, or any file.
- **Headless WebView** uses `incognito: true`, `cacheEnabled: false`, `domStorageEnabled: false`.
- WebView is explicitly destroyed (`clearCache()` + `dispose()`) after each scan.
- Riverpod `autoDispose` providers release all references on navigation pop.
- Dart GC reclaims all scan session memory after `dispose()`.

---

## License

MIT
