# Google Play — NetGulf listing assets

**App:** NetGulf — Full GCC Salary & EOSB Calculator  
**Package ID (current):** `com.example.netgulf` — change to your final ID in `android/app/build.gradle.kts` before first upload.

## Quick upload checklist

| Asset | File / source | Spec |
|-------|----------------|------|
| App name | `listing_en.txt` / `listing_ar.txt` | ≤ 30 chars |
| Short description | same files | ≤ 80 chars |
| Full description | same files | ≤ 4000 chars |
| Feature graphic | [`feature-graphic.png`](feature-graphic.png) or export [`feature-graphic.svg`](feature-graphic.svg) | **1024 × 500** PNG/JPEG |
| Phone screenshots | `screenshots/phone/*.png` | Min **2**, 9:16, 320–3840 px short side |
| Privacy policy URL | `https://netgulf.app/privacy` | Must be **public HTTPS** |
| App bundle | `flutter build appbundle --release` | Signed with release keystore |

## Privacy policy (required)

1. Host [`../web/privacy.html`](../web/privacy.html) at `https://netgulf.app/privacy` (GitHub Pages, Cloudflare, or your domain).
2. Enter the same URL in Play Console → App content → Privacy policy.
3. In-app: Settings → سياسة الخصوصية (also opens in browser).

## Screenshots to capture

See [`screenshots/phone/SHOT_LIST.md`](screenshots/phone/SHOT_LIST.md).

Recommended order for Play Store:

1. Home — net salary (KSA)
2. EOSB wizard — 6-country grid
3. EOSB results — total hero + breakdown
4. GOSI detail / comparison (KSA)
5. EOSB history list
6. PDF export preview (optional)
7. Settings — privacy link visible

**Capture:** Android emulator (Pixel 6, 1080×2400) or real device → screenshot → save as `01_home.png`, etc.

```bash
flutter run --release
# or
adb exec-out screencap -p > store/play/screenshots/phone/01_home.png
```

## Data safety (Play Console form)

| Question | Answer |
|----------|--------|
| Collects data? | Yes (via Google AdMob for free users) |
| Financial info user enters | Stored **locally only**, not collected by developer |
| Data encrypted in transit | N/A for local storage; HTTPS for ads |
| Account required | No |
| Delete data | Uninstall or clear history in Settings |

## Release build

```bash
# Configure android/key.properties (see android/key.properties.example if present)
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab`.

## Store listing language

- **Default:** Arabic (Saudi Arabia) — use `listing_ar.txt`
- **Translation:** English — use `listing_en.txt`

Category suggestion: **Finance** or **Business**.
