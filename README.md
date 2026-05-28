# NetGulf

**Full GCC Salary & EOSB Calculator** — net salary, GOSI / GPSSA / DEWS, and end-of-service benefits for all six GCC countries (offline-first).

## Getting Started

```bash
flutter pub get
flutter run
flutter test
```

## Play Store release

Listing copy, feature graphic, screenshot guide, and privacy hosting:

- [`store/play/README.md`](store/play/README.md)
- [`store/play/listing_en.txt`](store/play/listing_en.txt) / [`listing_ar.txt`](store/play/listing_ar.txt)
- Privacy URL for Play Console: **https://netgulf.app/privacy** (host [`store/web/privacy.html`](store/web/privacy.html))

```bash
flutter build appbundle --release
```

Before publishing, change `applicationId` from `com.example.netgulf` to your production package name.
