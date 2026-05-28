# Phone screenshots — NetGulf Play Store

Save PNG files in this folder. Play requires **at least 2** screenshots; **6–8** is ideal.

## Specs

- Aspect ratio: **9:16** (portrait)
- Size: **1080 × 1920** or **1440 × 2560** recommended
- Format: PNG or JPEG (no alpha required)
- No misleading content; show actual app UI

## Shot list

| File | Screen | Country / notes |
|------|--------|-----------------|
| `01_home_ksa.png` | Home — net salary card | 🇸🇦 KSA, sample salary 15,000 SAR |
| `02_eosb_countries.png` | EOSB wizard step 1 — 6-country grid | Any |
| `03_eosb_results_qatar.png` | EOSB results — total + breakdown | 🇶🇦 Qatar, 5 years service |
| `04_gosi_breakdown.png` | GOSI / salary breakdown | 🇸🇦 KSA |
| `05_eosb_history.png` | EOSB history — saved cards | At least 1 saved entry |
| `06_pdf_share.png` | System share sheet or PDF preview | After «تصدير PDF» |
| `07_settings_privacy.png` | Settings — privacy policy row visible | — |
| `08_uae_salary.png` | Home with UAE selected | 🇦🇪 UAE (optional) |

## Capture tips

1. Use **dark theme** for 4 shots and **light theme** for 2 for variety.
2. Hide debug banner; run `--release`.
3. Crop status bar consistently (or keep full device frame).
4. Arabic UI is the primary store listing — prefer AR screenshots for default listing.

## Emulator command (example)

```bash
flutter emulators --launch Pixel_6_API_34
flutter run --release
```

Then use device screenshot or:

```powershell
adb exec-out screencap -p > store/play/screenshots/phone/01_home_ksa.png
```
