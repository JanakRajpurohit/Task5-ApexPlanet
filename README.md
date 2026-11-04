<<<<<<< HEAD
# Crave

Crave is a Flutter food-delivery app for Android, built with Dart and Material 3.
Firebase Email/Password Authentication and Cloud Firestore power the customer
and restaurant flows. The app uses Firestore client transactions; it does not
deploy Cloud Functions or require Cloud Build.

## Connect Firebase

1. Create a Firebase project in the Firebase console.
2. Install the Firebase CLI and sign in:

   ```powershell
   npm install -g firebase-tools
   firebase login
   ```

3. Install FlutterFire CLI and configure the Android app from the project root:

   ```powershell
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-firebase-project-id>
   ```

   If `flutterfire` is not recognized in PowerShell, add
   `%LOCALAPPDATA%\Pub\Cache\bin` to `PATH`, or run it with
   `dart pub global run flutterfire_cli:flutterfire configure --project=<your-firebase-project-id>`.
   Select Android and use the current application ID `com.example.crave`.
   FlutterFire replaces the placeholder values in
   `lib/firebase_options.dart` with the configuration for your Firebase app.
   Keep this file private to your project if you prefer not to commit project
   identifiers.

   To run in Chrome as well, rerun FlutterFire and select both **Android** and
   **Web**. The generated Web options require a Firebase Web app. Then run
   `flutter create .` once if the project does not yet contain a `web/` folder.

4. In Firebase Console, enable **Authentication → Sign-in method → Email/Password**
   and create a **Cloud Firestore** database.
5. Publish the included Firestore rules:

   ```powershell
   firebase deploy --only firestore:rules --project=<your-firebase-project-id>
   ```

   The rules allow reading published menu items, limit seller writes to their
   own restaurant, validate customer COD orders against current menu prices and
   inventory, and allow restaurant registration without an approval gate.

6. Fetch packages, start an Android emulator or connect a device, then run:

   ```powershell
   flutter pub get
   flutter devices
   flutter run
   ```

## Current status

- Email/password customer sign-up and sign-in use Firebase Authentication;
  customer profiles are created in the `users` collection.
- Restaurant registration creates an email/password seller account immediately
  and saves restaurant details to `sellerApplications/{uid}` and
  `restaurants/{uid}`. No approval gate is used. Verification numbers and
  uploaded files are not saved.
- The customer catalog listens to published documents in Firestore `foods`.
  Sellers can create and manage menu items from the restaurant portal; published
  items are visible in the customer catalog.
- Customers can submit Cash on Delivery orders. A Firestore transaction reads
  current menu prices, restaurant availability, and stock, then creates the
  order and updates inventory together. Orders support up to five customized
  menu lines. Firestore rules validate the order totals and inventory changes.
  Sellers manage order status directly through Firestore; changes appear in
  customer order history.
- Restaurant profiles, menu items, offers, and in-app order notifications are
  stored in Firestore. Seller analytics are calculated from Firestore orders.
- Cloud Storage uploads, Firebase Cloud Messaging push notifications, persisted
  customer address management, online payments, and customer-created reviews
  are not configured.
- The Firestore `foods` collection uses seller documents with `ownerId`,
  `restaurantId`, `name`, `category`, `price`, `stock`, `isAvailable`, and
  `isPublished`. Seller menu entries are created from the app; order writes use
  Firestore transactions and the included security rules.
- Light and dark themes with responsive account, FAQ, and location screens.

This setup does not deploy Cloud Functions, Cloud Build, or Artifact Registry.
Firestore and Firebase Authentication are subject to their Firebase plan
quotas. Since the mobile app talks directly to Firestore, use App Check and
review the security rules before a public production launch; a trusted server
backend would provide stronger protection against modified clients.

Firebase Storage and Cloud Messaging can be added later for image uploads and
push notifications.

## Run and test

The debug APK can be built with `flutter build apk --debug`; it is written to
`build/app/outputs/flutter-apk/app-debug.apk`. If Flutter reports that Android
SDK licenses need acceptance, run `flutter doctor --android-licenses` and
accept the requested licenses. If more than one device is available, pass the
desired device ID with `flutter run -d <device-id>`.

Run the test suite with `flutter test` and static analysis with `flutter analyze`.

## Project layout

```text
CraveFoodDelivery/
├── lib/
│   ├── data/catalog_repository.dart
│   ├── data/cod_order_repository.dart
│   ├── data/seller_firebase_service.dart
│   ├── services/firebase_auth_service.dart
│   ├── firebase_options.dart
│   ├── firebase_setup.dart
│   ├── models/food.dart
│   ├── models/seller_models.dart
│   ├── state/crave_store.dart
│   ├── state/seller_store.dart
│   ├── ui/crave_screens.dart
│   ├── ui/seller_screens.dart
│   ├── ui/crave_widgets.dart
│   └── main.dart
├── android/
├── firestore.rules
├── firebase.json
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

The previous native Kotlin/Compose project remains under `app/` with its root Gradle files; Flutter uses the root `pubspec.yaml`, `lib/`, and `android/` folders.
=======
# Task3-ApexPlanet
Task 3 in which i have made an resturant food app named ad Crave and in that i have connected the backend of firebase like authentication and the firestore for database 
>>>>>>> 4288f775a85d65d00a7acc6deee40e30d1b420e6
