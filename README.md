# Digital Munshi

Offline-first bookkeeping app built with Flutter and Firebase:

- **Personal ledger** – income/expenses, smart search, filters and insights
- **Event ledgers** – shared pools, custom splits, balances and settle-up suggestions
- **Business** – products, sales, expenses and staff roles

Package id: `com.digitalmunshi.app`. Release steps are in [RELEASE.md](RELEASE.md).

## Development
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Riverpod codegen
flutter run
flutter test test
```
