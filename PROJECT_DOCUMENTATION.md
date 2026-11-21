# Crave Food Delivery - Project Documentation

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Project Description](#2-project-description)
3. [Technology Stack](#3-technology-stack)
4. [Application Features](#4-application-features)
5. [Application Screens](#5-application-screens)
6. [Application Architecture](#6-application-architecture)
7. [Database and Backend](#7-database-and-backend)
8. [Application Workflow](#8-application-workflow)
9. [UI/UX Design](#9-uiux-design)
10. [Testing and Validation](#10-testing-and-validation)
11. [Challenges and Solutions](#11-challenges-and-solutions)
12. [Project Outcomes](#12-project-outcomes)
13. [Future Enhancements](#13-future-enhancements)
14. [Conclusion](#14-conclusion)
15. [PowerPoint Presentation Preparation](#15-powerpoint-presentation-preparation)
16. [Screenshots and Visual References](#16-screenshots-and-visual-references)

---

## 1. Project Overview

### Project Name
**Crave**

### Introduction
Crave is a Flutter-based food delivery application that provides separate experiences for customers and restaurant partners. The project currently uses Firebase Authentication and Cloud Firestore for account roles, published menus, customer orders, restaurant management, and synchronized data.

The repository also contains a previous native Android implementation written in Kotlin and Jetpack Compose. The README identifies this implementation as remaining legacy code, while the Flutter project is the documented and current application entry for the Android build.

### Purpose
The application brings restaurant menus and ordering into one mobile interface. Customers can browse published dishes, search and filter the menu, manage favourites and addresses, place Cash on Delivery orders, and track submitted order statuses. Restaurant partners can register, manage menu items and stock, process orders, create offers, respond to reviews, and review analytics.

### Problem Statement
Customers need a simple way to find available food, place an order for a specific restaurant, and view the latest order status. Restaurants need a connected view of incoming orders, inventory, menu data, offers, and operational performance. Crave addresses this need through a role-based customer and restaurant interface backed by Firebase.

### Why the Application Is Useful
- Presents a live published menu from Firestore.
- Separates customer and restaurant account capabilities.
- Uses restaurant-scoped data so menu and order operations remain associated with the correct seller.
- Supports real COD order creation in a Firestore transaction.
- Updates stock and availability when an order is placed.
- Syncs order-status changes between the seller portal and customer order history.
- Provides in-app notifications for order events and restaurant updates.

### Target Users
- Customers who want to browse menus and place COD food orders.
- Restaurant owners who want to manage menu items, inventory, orders, offers, and restaurant information.
- Internship evaluators and developers reviewing a real Flutter/Firebase implementation.

### Main Objectives
- Implement Email/Password authentication with customer and seller roles.
- Build a customer interface for discovery, cart, checkout, and order history.
- Build a restaurant management portal.
- Synchronize catalog, orders, inventory, offers, and notifications through Firestore.
- Apply Firestore rules for role checks and order validation.
- Provide light and dark themes and responsive layouts.
- Add automated state and widget tests for core behavior.

---

## 2. Project Description

Crave starts from a splash and welcome screen. Firebase determines whether the user is signed out or signed in. A signed-in account is checked against the `users` collection for a `customer` or `seller` role.

A customer can:
- Browse published menu items.
- Search dishes by name, category, cuisine, or ingredient.
- Filter and sort the catalog.
- Open a food details page.
- Choose spice level and special instructions.
- Add items to a cart, change quantities, and save favourites.
- Maintain a local address book in the active session.
- Checkout as Cash on Delivery.
- View orders and Firestore order status updates.

A seller can:
- Register a restaurant account.
- Sign in as a seller.
- Open or close restaurant ordering.
- View dashboard metrics and recent orders.
- Accept or reject incoming orders.
- Advance accepted orders through preparation and delivery statuses.
- Add, edit, publish, draft, or delete menu items.
- Manage categories, stock, and availability.
- Create and activate offers.
- View analytics and reports.
- Respond to reviews.
- Manage business hours and scheduled closures.
- Manage profile and notification settings.

The overall workflow is role-based and data-driven: published `foods` documents feed the customer catalog; customer COD submissions create `orders` and `notifications` in a transaction; seller status updates modify the order and produce a customer-visible notification; Firestore streams keep both sides synchronized.

---

## 3. Technology Stack

| Area | Technology | Purpose |
|---|---|---|
| Primary language | Dart | Implements application logic, state, widgets, and Firebase integration |
| Mobile framework | Flutter | Builds the Android application and Material UI |
| UI framework | Flutter Material 3 | Provides widgets, theming, navigation, dialogs, cards, and responsive layouts |
| Authentication | Firebase Authentication | Email/password sign-in, sign-up, role verification, password reset, sign-out |
| Database | Cloud Firestore | Stores users, restaurants, foods, orders, offers, notifications, and reviews |
| State management | `ChangeNotifier` and `ListenableBuilder` | Updates customer and seller state from repositories and streams |
| Async data | Firestore streams and Dart futures/transactions | Performs live synchronization and transactional COD order creation |
| Android build | Gradle Kotlin DSL | Configures the Android application and Flutter Gradle plugin |
| Android package | `com.example.crave` | Application namespace and application ID |
| Java compatibility | Java 17 | Android compile and target compatibility |
| SDK constraint | Dart SDK `^3.12.0` | Declares the supported Dart language/toolchain range |
| Firebase configuration | FlutterFire-generated Dart options and Google Services | Configures Firebase for Android |
| Static analysis | `flutter_lints` | Applies recommended Dart and Flutter lint rules |
| Testing | `flutter_test` | Runs unit, state, model, and widget tests |
| Version control | Git | Tracks project source and repository history |

### Flutter Dependencies
The actual runtime dependencies in `pubspec.yaml` are:
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `flutter`

The test dependencies are:
- `flutter_test`
- `flutter_lints`

No Firebase Storage package, Firebase Messaging package, Google Sign-In package, REST HTTP client, or payment SDK is declared as an implementation dependency.

### Remaining Native Android Module
The repository also contains an older native Android module under `app/src/main`. It uses:
- Kotlin
- Jetpack Compose
- Material 3
- Navigation Compose
- AndroidX Lifecycle and ViewModel
- Kotlin Coroutines
- Coil

This module uses mock repositories and local demo data rather than Firebase. It is not the active Flutter/Firebase implementation described for the current application.

---

## 4. Application Features

### 4.1 Firebase Authentication
- **Purpose:** Support account creation and role-based entry.
- **How it works:** Firebase Email/Password Authentication creates the account. A Firestore `users/{uid}` document stores the role and profile fields.
- **User actions:** Register, sign in, reset a password, and sign out.
- **Role separation:** A customer account receives the customer shell; a seller account receives the restaurant portal.
- **No implemented Google sign-in:** The customer login displays a Google sign-in option, but its code currently shows an availability message and does not authenticate with Google.

### 4.2 Customer Discovery and Catalog
- **Purpose:** Display dishes published by restaurant accounts.
- **How it works:** `CatalogRepository` listens to Firestore `foods` documents where `isPublished` is `true`.
- **User actions:** View popular foods, browse categories, search, filter, sort, open dish details, and retry failed catalog loading.
- **Sorting:** Popular, price low to high, price high to low, and highest rated.

### 4.3 Search and Filtering
- **Purpose:** Help customers find a dish quickly.
- **How it works:** The in-memory store matches normalized text against name, category, cuisine, and ingredients.
- **User actions:** Enter text, choose categories, use recent searches, clear searches, and apply sort options.

### 4.4 Dish Details
- **Purpose:** Present dish information and customization choices.
- **How it works:** The details screen reads the selected `Food` object and adds selected quantity and customizations to the cart.
- **User actions:** View rating, reviews, veg/non-veg status, preparation range, ingredients, spice level, special instructions, and quantity.
- **Validation:** An unavailable item cannot be added to the cart.

### 4.5 Cart
- **Purpose:** Collect one restaurant's selected dishes.
- **How it works:** `CraveStore` maintains cart quantities and customization keys and calculates the item and cart totals.
- **User actions:** Increase or decrease quantity, remove an item, and proceed to checkout.
- **Constraint:** The cart rejects a dish from another restaurant and allows only one restaurant per order.

### 4.6 Favourites
- **Purpose:** Save dishes for quick viewing.
- **How it works:** Favourite IDs are stored in the in-memory store set.
- **User actions:** Toggle a heart on the dish card/details page and open the Favourites tab.
- **Limitation:** Favourites are not synchronized to Firestore or persisted between app sessions.

### 4.7 Address Management
- **Purpose:** Collect delivery details for COD checkout.
- **How it works:** Addresses are held in `CraveStore` and copied into the Firestore order document at placement.
- **User actions:** Add, edit, delete, and select addresses; choose Home, Work, or Other; set a default address.
- **Limitation:** Address-book entries are not currently synchronized to Firestore or persisted between sessions.

### 4.8 COD Checkout and Order Placement
- **Purpose:** Create a validated restaurant order and reserve stock.
- **How it works:** `CodOrderRepository.createOrder` runs a Firestore transaction, verifies the signed-in customer, restaurant status, menu availability, current prices, stock, minimum order, and delivery fields, then writes the order and stock changes together.
- **User actions:** Select a delivery address, enter instructions, review item totals, and place a COD order.
- **Payment:** Cash on Delivery only.
- **Limits:** 1–5 menu lines, up to 20 portions of an individual food item, and instructions limited to 500 characters.

### 4.9 Customer Order History
- **Purpose:** Show submitted orders and status updates.
- **How it works:** `CodOrderRepository` streams `orders` where `customerId` equals the signed-in account.
- **User actions:** Filter All, Active, Completed, and Cancelled orders and view details.
- **Status values:** The live workflow includes New, Accepted, Preparing, Ready for Pickup, Picked Up, Delivered, Rejected, and Cancelled.

### 4.10 Customer Profile and Settings
- **Purpose:** Manage local profile presentation and preferences.
- **How it works:** Profile name, email, and phone are read from Firestore and held in `CraveStore`.
- **User actions:** Edit name and phone locally through the store, set dark mode, change notification switches, select English or Hindi label preference, and view privacy/help/about information.
- **Limitation:** Editing the displayed profile through `CraveStore` does not update the Firestore `users` document in the current implementation. Language selection changes store preference only; full translation is not implemented.

### 4.11 Seller Registration
- **Purpose:** Create a restaurant owner account without an approval gate.
- **How it works:** A five-step form creates a Firebase user and writes `users`, `sellerApplications`, and `restaurants` records.
- **User actions:** Enter owner details, restaurant details, address, opening/closing times, working days, preparation time, and minimum order amount.
- **Limitation:** Logo and cover upload controls are placeholders. Document numbers and uploaded files are not saved.

### 4.12 Seller Dashboard
- **Purpose:** Provide an operational overview.
- **Metrics:** Today's orders, today's revenue, pending orders, completed orders, cancelled/rejected orders, average rating, seven-day revenue, and recent orders.
- **User actions:** Toggle the restaurant open/closed state, open notifications, view analytics, add food, manage inventory/offers, and view reviews.

### 4.13 Seller Orders
- **Purpose:** Manage incoming and active orders.
- **How it works:** Seller orders are filtered and synchronized from Firestore.
- **User actions:** Filter orders, open order details, accept/reject, set preparation time, and advance status.
- **Lifecycle:** New → Accepted → Preparing → Ready for Pickup → Picked Up → Delivered. Rejected or Cancelled are allowed terminal actions within the rules.

### 4.14 Menu Management
- **Purpose:** Create and maintain the restaurant catalog.
- **User actions:** Search menu items, filter categories and drafts, sort, publish, save drafts, edit, delete, and toggle availability.
- **Fields:** Name, direct image URL, description, category, regular price, discounted price, preparation time, stock, availability, vegetarian status, bestseller, and featured status.
- **Limitation:** Customization, ingredient, and allergen fields show a future-integration message; they are not fully persisted.

### 4.15 Inventory and Categories
- **Purpose:** Control stock and menu organization.
- **Inventory actions:** Search items, update stock, identify low-stock/out-of-stock items, and toggle availability.
- **Category actions:** Add, rename, and delete categories.
- **Synchronization:** Inventory updates and category changes are persisted to Firestore where rules permit.

### 4.16 Offers
- **Purpose:** Create promotional campaigns.
- **Offer types:** Percentage, fixed amount, buy-one-get-one, combo, and first order.
- **User actions:** Set name, description, value, minimum order, maximum discount, start date, expiry date, and active status.
- **Limitation:** The order engine does not currently apply offers to COD totals; offers are stored and displayed as campaigns.

### 4.17 Analytics
- **Purpose:** Review restaurant performance from synced orders.
- **Ranges:** Today, last 7 days, last 30 days, and custom date range.
- **Metrics:** Revenue, total orders, average order value, completed/rejected orders, restaurant rating, daily trends, and popular food quantities.
- **Limitation:** Export creates a selectable in-app summary. A downloadable file is not connected.

### 4.18 Reviews and Notifications
- **Purpose:** Let the seller view feedback and operational events.
- **Review actions:** Read reviews and add or edit a restaurant response.
- **Notification actions:** Filter categories, mark individual/all notifications as read, and open an associated order.
- **Limitation:** Push notifications are not implemented. Only in-app Firestore notifications are synchronized.

### 4.19 Seller Profile and Settings
- **Purpose:** Maintain restaurant information and preferences.
- **User actions:** Edit restaurant name, description, address, cuisine, phone, and email; manage hours and closures; open/close the restaurant; change notification preferences; sign out.
- **Limitation:** Password-change UI is present but says authentication change is not connected. Verification documents are not collected or stored.

---

## 5. Application Screens

### Customer Screens

| Screen | Purpose | Main Components | Actions and Navigation |
|---|---|---|---|
| Splash | Introduces Crave during startup | Animated progress and application branding | Replaced by Welcome after the splash timing |
| Welcome | Entry choice for new or returning users | Brand, food message, Login, Create account | Opens Login or Signup |
| Login | Authenticate customer or reach seller login | Email/password fields, password visibility, Remember Me, Forgot Password | Validates and signs in; opens seller login or signup |
| Signup | Create a customer account | Name, email, phone, password, confirm password, terms checkbox | Creates Firebase user/profile and opens main shell |
| Home | Main customer discovery view | Greeting, location/address, search, promo, categories, popular foods | Opens search, address picker, cart, or dish details |
| Search | Find and filter dishes | Search field, recent/category chips, filter/sort sheet, results | Updates query/category/sort and opens dish details |
| Cart | Review selected items | Cart items, quantity controls, totals | Change quantity/remove item and open checkout |
| Favourites | Show saved dishes | Favourite dish list | Remove via heart or open dish details |
| Profile | Customer account summary | Profile card and profile options | Opens edit profile, orders, addresses, favourites, settings, help, or logout |
| Dish Details | Display a selected dish | Image, name, rating, description, ingredients, spice choices, instructions, quantity | Toggle favourite and add selected item to cart |
| Checkout | Finalize COD order | Address, instructions, item summary, totals, COD option | Select/add address and submit COD order |
| Order Success | Confirm a submission | Order ID, estimated time, address, items, payment | Track message, view history, or return home |
| Edit Profile | Update displayed profile fields | Name, email, phone fields | Save name/phone into in-memory store |
| Saved Addresses | Manage delivery addresses | Address cards and add/edit/delete actions | Select address, set default, edit or delete |
| Address Editor | Add or change an address | Name, phone, house, street, city, state, pincode, type, default switch | Validates fields and saves the address to store |
| Location Picker | Choose delivery location | Search field, current-location placeholder, saved addresses, add address | Save or open address editor |
| Order History | View submitted orders | Status tabs and order cards | Filter orders and open details dialog |
| Settings | Manage preferences | Notification switches, dark mode, language, policy links | Update in-memory preferences and show information dialogs |
| Help & Support | Answer common questions | FAQs and support placeholder | Expand FAQs or open support-not-configured message |
| About Crave | Show application information | Brand and project description | Read-only screen |

### Seller Screens

| Screen | Purpose | Main Components | Actions and Navigation |
|---|---|---|---|
| Seller Login | Authenticate a restaurant account | Email/password, password visibility, Remember Me, reset password | Sign in, reset password, register, or return to customer login |
| Seller Registration | Create a seller and restaurant | Five-step form | Validate and submit owner, restaurant, address, hours, and business details |
| Seller Account Ready | Inform seller of immediate access | Confirmation message and sign out | Sign out |
| Restaurant Portal Loading/Error | Load seller data | Spinner, error detail, retry/sign-out controls | Retry or sign out |
| Seller Shell | Main restaurant navigation | Dashboard, Orders, Menu, Analytics, Profile tabs | Bottom navigation or NavigationRail on wide screens |
| Seller Dashboard | Operational overview | Open switch, metrics, revenue chart, recent orders, quick actions | Open notifications/profile, analytics, menu, inventory, offers, reviews |
| Seller Orders | Manage and filter orders | Status filter chips and order cards | Open details, accept/reject, advance status |
| Seller Order Details | Inspect and update an order | Customer/address/items/payment/timeline | Accept/reject, set preparation estimate, advance status |
| Seller Menu | Manage dishes | Search, category/sort controls, draft switch, item cards | Publish/edit/delete items and toggle availability |
| Seller Food Form | Create/edit a menu item | Form fields and image preview | Save draft or publish/save changes |
| Seller Inventory | Manage stock | Search and stock cards | Update stock and toggle availability |
| Menu Categories | Organize categories | Category list and add/edit/delete controls | Rename/add/delete categories |
| Seller Analytics | Review performance | Range chips, custom dates, metrics, charts, popular items | Select range and show/export report summary |
| Offers & Discounts | Manage campaigns | Offer cards, status chips, create dialog | Create offer, activate/deactivate, delete |
| Customer Reviews | Read and respond to feedback | Average rating and review cards | Add/edit seller response |
| Notifications | Review seller events | Category filters and notification cards | Mark read and open associated orders |
| Restaurant Profile | Edit restaurant details | Form fields and image placeholder | Save restaurant profile |
| Business Hours | Set operating schedule | Open switch, opening/closing times, working days, closure dates | Save hours and closures |
| Seller Profile Tab | Restaurant account navigation | Profile card and feature menu | Open details, hours, inventory, categories, offers, reviews, notifications, settings |
| Seller Settings | Manage account preferences | Password placeholder, notification switches, privacy/support, logout | Update preference switches or sign out |

---

## 6. Application Architecture

### 6.1 Project Structure

```text
lib/
├── main.dart                    # Application startup and MaterialApp configuration
├── firebase_options.dart        # FlutterFire platform configuration
├── firebase_setup.dart           # Firebase configuration status
├── data/
│   ├── catalog_repository.dart   # Published menu stream
│   ├── cod_order_repository.dart # COD order transaction and order stream
│   └── seller_firebase_service.dart
├── models/
│   ├── food.dart                 # Customer catalog/cart/order/address models
│   └── seller_models.dart        # Seller account, restaurant, order, offer, review models
├── services/
│   ├── firebase_auth_service.dart
│   └── seller_onboarding_service.dart
├── state/
│   ├── crave_store.dart          # Customer state and operations
│   └── seller_store.dart         # Seller state and real-time operations
└── ui/
    ├── crave_screens.dart
    ├── account_screens.dart
    ├── seller_screens.dart
    └── crave_widgets.dart
```

### 6.2 Important Classes

| File/Class | Responsibility |
|---|---|
| `CraveApp` | Builds light/dark themes and mounts `AuthGate` or the standalone splash |
| `AuthGate` | Watches authentication, reads the Firestore role, and chooses customer/seller UI |
| `SplashScreen` | Provides startup visual and transitions to the welcome screen |
| `FirebaseAuthService` | Wraps Firebase Authentication and user profile operations |
| `CatalogRepository` | Streams published foods from Firestore |
| `CodOrderRepository` | Streams customer orders and creates COD orders in a transaction |
| `CraveStore` | Holds cart, favourites, filters, address, profile, catalog, and customer order state |
| `MainShell` | Hosts five customer bottom-navigation tabs |
| `SellerOnboardingService` | Creates seller Firebase accounts and writes initial Firestore records |
| `SellerFirebaseService` | Loads seller data and exposes Firestore CRUD/stream operations |
| `SellerStore` | Holds seller data, metrics, real-time subscriptions, and mutation methods |
| `SellerPortal` | Loads seller state and opens the seller shell |
| `SellerShell` | Hosts the five seller navigation sections |

### 6.3 Model and State Flow
1. Widgets call methods on `CraveStore` or `SellerStore`.
2. Stores invoke repository/service methods.
3. Firebase streams and transactions return or update documents.
4. Streams call `notifyListeners()`.
5. `ListenableBuilder` rebuilds affected widgets.
6. Firestore rules verify role and document constraints.

### 6.4 Navigation
The Flutter implementation uses `Navigator` and `MaterialPageRoute` rather than a centralized named-route package. `IndexedStack` controls the customer and seller bottom navigation without recreating every tab. Seller wide screens use `NavigationRail`.

The native module, if selected, has an older Compose `NavHost` implementation with splash, welcome, login, signup, home, search, cart, favourites, profile, details, checkout, and order-success routes. It is separate from the active Flutter role-based Firebase flow.

---

## 7. Database and Backend

### Authentication Workflow
- Customer signup calls Firebase `createUserWithEmailAndPassword`.
- Firebase displays and validates account credentials.
- The app creates `users/{uid}` with `name`, `email`, `phone`, `role`, and `createdAt`.
- Customer login verifies that the Firestore role is `customer`.
- Seller login verifies that the role is `seller`.
- Password reset sends a Firebase reset email.
- Sign-out clears the Firebase authentication state.

### Firestore Collections
| Collection | Stored Data |
|---|---|
| `users` | UID, name, email, phone, role, creation time |
| `sellerApplications` | Restaurant registration data and owner data |
| `restaurants` | Restaurant profile, schedule, approval/open status, categories |
| `foods` | Menu item and inventory data |
| `orders` | Items, totals, address snapshot, status history, payment status |
| `offers` | Campaign type, value, date range, minimum order, activation |
| `notifications` | Seller/customer order events and read state |
| `reviews` | Customer review data and optional seller response |

### Data Retrieval
- The customer catalog reads published food documents as a live stream.
- Customer orders read orders associated with `customerId`.
- Seller data uses owner/seller scoped queries and live restaurant streams.
- The app maps Firestore documents into typed model objects.

### Data Synchronization
- Catalog and order documents use Firestore snapshots.
- Seller menu, orders, offers, notifications, reviews, and restaurant profile use snapshot streams.
- Stock is reduced inside the COD order transaction.
- Order status updates are written to Firestore and included in a status history list.
- Notifications are written for new orders and seller status updates.

### Security
`firestore.rules` includes:
- Sign-in checks.
- Customer/seller role checks.
- Restaurant ownership checks.
- Published-food read restrictions.
- Seller-scoped food create/update/delete rules.
- COD order field, price, stock, quantity, and minimum-order validation.
- Restricted order-status transitions.
- Notification create/read/update checks.
- Offer and review restrictions.

The included README recommends App Check and an independent security review before a public production launch because the mobile app communicates directly with Firestore.

The application does not currently deploy Cloud Functions or a separate server backend. No passwords, API keys, or private configuration values are repeated in this documentation.

---

## 8. Application Workflow

### Customer Journey
1. The app initializes Firebase and shows Firebase setup instructions if configuration is incomplete.
2. Firebase Authentication determines whether a user is signed in.
3. The app reads the user's Firestore role.
4. A customer enters the splash/welcome flow and can register or sign in.
5. The customer dashboard streams published menu items.
6. The customer searches, filters, opens dish details, and chooses options.
7. The customer adds dishes to the cart.
8. The cart enforces quantity and one-restaurant rules.
9. The checkout screen requires a saved/selected address.
10. The customer submits a COD order.
11. Firestore validates the transaction and updates stock.
12. A notification is created for the seller.
13. The customer views the order success screen and order history.
14. The seller updates the order status.
15. The customer order stream reflects the latest status.

### Seller Journey
1. The user opens Restaurant Partner login or registration.
2. Registration creates a seller role and restaurant records.
3. Seller login is accepted only when the account role is `seller`.
4. The restaurant portal loads seller data and starts real-time streams.
5. The seller views dashboard metrics and incoming notifications.
6. The seller accepts or rejects an order.
7. Accepted orders move through preparing, ready, pickup, and delivered states.
8. The seller maintains menu data and stock.
9. Published menu updates appear in the customer catalog.
10. The seller reviews analytics, offers, reviews, and business settings.

---

## 9. UI/UX Design

### Color Palette
- **Primary coral:** `#FF7043`
- **Secondary teal:** `#20645F`
- **Ink:** approximately `#302A28`
- **Light background:** cream `#FFF8F3`
- **Dark surface:** approximately `#151413` / `#211F1E`
- Additional green and red colors indicate success and error states.

### Typography
The app uses the default Flutter/Material text system with custom:
- 32 px extra-bold headline large.
- 26 px extra-bold headline medium.
- 20 px title large.
- 16 px title medium and body large.
- 14 px body medium.

### Layout
- Rounded cards, usually 20 px radius.
- 16–20 px standard page padding.
- SafeArea use for device edges.
- Bottom navigation for customer and mobile seller views.
- Seller NavigationRail for widths of at least 850 px.
- Responsive grids: seller metrics use two columns on smaller widths and three on wider widths.
- Scrollable lists and dialogs support smaller screens.

### Reusable Components
- `CraveWordmark`
- `PrimaryButton`
- `SecondaryButton`
- `FoodImage`
- `FoodCard`
- Seller metric, status, chart, quick-action, detail, info-panel, and profile-menu widgets

### Interaction Elements
- Bottom sheets for location and filters.
- Dialogs for confirmation and information.
- Choice chips and filter chips.
- Switches for availability, notifications, and dark mode.
- Badges for cart items and unread notifications.
- SnackBars and in-app error banners.
- Form validation before account and order operations.

### Theme
The app supports a Material 3 light theme and dark theme. The current selected mode is held in `CraveStore` and applies the entire app immediately.

---

## 10. Testing and Validation

### Automated Testing Completed
The current verification result is:
- `flutter test`: 24 tests passed.
- `flutter analyze`: no issues found.

The test suite covers:
- Direct image URL validation.
- Firebase setup screen rendering.
- Splash to welcome navigation.
- Customer login to restaurant-partner login navigation.
- Seller account information.
- Seller sign-out confirmation.
- Seller dashboard navigation to orders and menu.
- Checkout Cash on Delivery UI and unconfigured repository error.
- Customer search and category filtering.
- Empty store initialization.
- Cart quantity and totals.
- Address and order details.
- Favourites.
- Invalid cart quantities.
- Search history and sort behavior.
- Firestore food mapping and invalid required fields.
- Cart customizations.
- Address default/delete behavior.
- Seller lifecycle transitions.
- Seller restaurant-scoped menu operations.
- Stock availability updates.
- Customer catalog isolation from the seller store.

### Testing by Category
| Area | Status |
|---|---|
| Static analysis | Completed successfully |
| Unit tests | Completed for stores, models, repositories, and order/cart logic |
| Widget tests | Completed for representative navigation and UI behavior |
| Firebase Authentication | Implemented; live end-to-end production testing depends on a configured project and test accounts |
| Firestore data flow | Transaction and stream code implemented; live validation depends on deployed rules and project data |
| Navigation | Widget tests cover key navigation, not every screen-to-screen path |
| Form validation | Implemented in customer/seller forms and covered partly by test code |
| UI testing | Limited to selected widgets; broad visual regression testing is pending |
| Platform testing | APK/build artifacts exist; validation across device sizes and Android versions is pending |

### APK and Build Evidence
The project contains existing APK artifacts, including:
- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/apk/debug/app-debug.apk`
- `app/build/outputs/apk/debug/app-debug.apk`

These paths confirm APK build output exists, but no formal set of external-device test reports is present in the repository.

---

## 11. Challenges and Solutions

| Challenge | Cause | Implemented Solution | Result |
|---|---|---|---|
| Firebase can be missing at startup | Generated configuration may not yet be present on a platform | `firebase_setup.dart` checks configuration and displays setup guidance | App shows a setup screen instead of failing with unexplained initialization |
| Customer and seller roles share authentication | Both account types use Firebase Auth | Firestore `users/{uid}.role` controls routing and login access | Each role enters the correct application shell |
| COD orders require consistent stock and totals | Separate writes could create mismatched data | Firestore transaction reads menu/restaurant/user data and creates order, stock changes, and notification atomically | Order totals and stock updates are validated together |
| One cart could contain products from different restaurants | Cart data previously had no restaurant constraint | `CraveStore.addToCart` rejects items from a second restaurant | Cart is limited to a single restaurant |
| Invalid or unavailable menu documents could crash or leak stale data | Firestore fields may be missing or incorrectly typed | `Food.fromFirestore` validates required fields and throws `FormatException` for invalid data | Invalid catalog documents are explicitly rejected |
| Direct image links are required | Search-engine result URLs are not displayable direct images | `isDirectImageUrl` checks direct HTTP(S) image URL patterns and rejects Google Images result URLs | Forms and cards prevent malformed image entries |
| Seller data can change while the UI is open | Data may be updated externally or by the seller | Seller store starts snapshot streams and calls `notifyListeners()` | Restaurant UI updates from Firestore in real time |
| Orders need controlled status changes | Sellers must not skip lifecycle stages | Firestore rules and seller store methods restrict transitions | Status history remains in valid sequence |
| Address state needed checkout integration | Address-book persistence was not configured | Addresses are held in `CraveStore` and copied into order documents at placement | COD checkout works even though address books are not cross-session-persistent |
| Legacy native module and current Flutter module coexist | The project evolved from Jetpack Compose to Flutter | README and project structure identify Flutter as the current implementation | Future documentation avoids representing legacy mock features as Firebase features |

No development problem that cannot be verified in source or project history is presented as a fact.

---

## 12. Project Outcomes

### Developed Functionality
- Firebase customer and seller authentication.
- Role-based application routing.
- Live published menu catalog.
- Customer search, filtering, sorting, favourites, cart, address, and COD checkout.
- Firestore customer order history.
- Seller portal with dashboard, orders, menu, inventory, categories, offers, analytics, notifications, reviews, profile, and settings.
- Firestore security rules.
- Light/dark Material 3 UI.
- Automated unit and widget tests.

### Working Features
The implemented working surfaces include the customer Firebase-authenticated flow and the seller Firestore-connected portal. The exact live behavior also depends on Firebase project setup and deployed rules.

### Skills Applied
- Flutter and Dart application development.
- Material 3 UI implementation.
- State management with `ChangeNotifier`.
- Firebase Authentication integration.
- Cloud Firestore streams and transactions.
- Role-based access design.
- Android Gradle configuration.
- Form validation and error handling.
- Unit and widget testing.
- Technical documentation.

### Learned
- Connecting UI state to real-time backend streams.
- Designing separate customer and seller responsibilities.
- Using Firestore rules to protect server-side data operations.
- Designing transactional order placement with inventory updates.
- Mapping backend documents into typed application models.
- Maintaining a responsive Flutter interface.

### Current Status
Crave is a functioning Flutter/Firebase application prototype with core customer and restaurant workflows implemented. It is not a production-ready commercial service because several integrations remain placeholder or configuration-dependent.

---

## 13. Future Enhancements

The following items are proposed improvements and are not currently implemented:

1. Implement Google Sign-In.
2. Add Firebase Storage for restaurant logo, cover, and menu images.
3. Implement push notifications with Firebase Cloud Messaging.
4. Synchronize customer address books and profile changes to Firestore.
5. Persist favourites and app preferences.
6. Implement the seller password-change operation.
7. Enable complete customizations, ingredients, and allergen fields in menu documents.
8. Apply offers at checkout and validate discount values in Firestore rules.
9. Add online payment methods.
10. Add customer-created reviews and review submission.
11. Implement real support contact channels.
12. Add full localization for English and Hindi.
13. Export analytics reports as files.
14. Add current-location/geolocation services.
15. Add App Check, automated backend integration tests, and a production security review.
16. Remove or archive the older native Compose module if it is no longer part of the deliverable.

---

## 14. Conclusion

Crave demonstrates a practical food-delivery application built with Flutter and Firebase. The project combines role-based authentication, real-time Firestore catalog and order data, transactional COD checkout, and a complete restaurant management portal. It includes customer discovery, cart, favourites, address, checkout, order history, seller menu and inventory management, order processing, offers, analytics, reviews, and notifications.

The application is well suited for an internship demonstration because it shows a complete mobile-development workflow: UI implementation, state management, Firebase integration, database security rules, Android build configuration, and automated testing. Some integrations—such as Google Sign-In, Storage, Messaging, payments, persistent customer addresses, and downloadable reports—are visibly identified as future work rather than presented as complete features.

---

## 15. PowerPoint Presentation Preparation

### Slide 1: Title
- **Title:** Crave - Flutter Food Delivery Application
- **Bullets:** Customer and restaurant partner app; Flutter + Firebase
- **Visual:** App logo or launcher icon
- **Speaker notes:** Introduce the project name, technology base, and purpose.

### Slide 2: Project Introduction
- **Title:** What Is Crave?
- **Bullets:** Role-based food delivery prototype; customer and seller experiences; real-time Firebase backend
- **Visual:** Simple customer-to-seller workflow diagram
- **Speaker notes:** Explain that Crave includes both the buyer and restaurant management sides.

### Slide 3: Problem Statement
- **Title:** Problem Addressed
- **Bullets:** Customers need menu discovery and order tracking; restaurants need inventory and order management
- **Visual:** Two-column problem and solution
- **Speaker notes:** Describe the operational need for a connected menu and order system.

### Slide 4: Objectives
- **Title:** Project Objectives
- **Bullets:** Firebase authentication; customer ordering; COD; seller operations; live synchronization
- **Visual:** Checklist or four application modules
- **Speaker notes:** State the main goals implemented in the project.

### Slide 5: Technology Stack
- **Title:** Technologies Used
- **Bullets:** Dart, Flutter, Material 3, Firebase Auth, Cloud Firestore, Gradle
- **Visual:** Technology logo or architecture icons
- **Speaker notes:** Explain what each technology contributes; mention no Google Sign-In or payment SDK is implemented.

### Slide 6: Application Architecture
- **Title:** Architecture and Project Structure
- **Bullets:** UI, state stores, repositories/services, Firebase, models
- **Visual:** Layered architecture diagram
- **Speaker notes:** Explain `CraveStore`/`SellerStore` and Firestore streams.

### Slide 7: Authentication and Roles
- **Title:** Login and Registration
- **Bullets:** Email/password; customer/seller role in Firestore; seller registration; password reset
- **Visual:** Login and seller registration screenshots
- **Speaker notes:** Demonstrate role separation and the account profile document.

### Slide 8: Customer Dashboard
- **Title:** Customer Discovery Experience
- **Bullets:** Home, categories, search, sort, favorites, cart
- **Visual:** Customer home and search screenshots
- **Speaker notes:** Show how published dishes reach the customer catalog.

### Slide 9: Ordering Workflow
- **Title:** Cart and Cash on Delivery
- **Bullets:** Dish details; address; quantity; totals; transaction; stock update
- **Visual:** Details, cart, and checkout screenshots
- **Speaker notes:** Explain the Firestore transaction and COD-only payment.

### Slide 10: Seller Portal
- **Title:** Restaurant Management
- **Bullets:** Dashboard, orders, menu, inventory, categories, offers
- **Visual:** Seller dashboard screenshot
- **Speaker notes:** Demonstrate the restaurant owner's operational workflow.

### Slide 11: Backend and Security
- **Title:** Firestore and Security Rules
- **Bullets:** Collections, live streams, role checks, stock validation, order transitions
- **Visual:** Collection diagram
- **Speaker notes:** Explain direct mobile-to-Firestore integration and transaction behavior.

### Slide 12: Testing and Validation
- **Title:** Testing and Quality
- **Bullets:** 24 passing tests; static analysis no issues; unit/widget coverage
- **Visual:** Test result terminal screenshot
- **Speaker notes:** Distinguish automated testing from pending device and live-Firebase testing.

### Slide 13: Current Limitations
- **Title:** Challenges and Current Status
- **Bullets:** Address persistence pending; no Google Sign-In; no Storage/Messaging/payments; no push notifications
- **Visual:** Completed versus pending feature table
- **Speaker notes:** Be honest about prototype status and note proposed future work.

### Slide 14: Achievements
- **Title:** Results and Learning Outcomes
- **Bullets:** Customer and seller flows; live Firestore; secure rules; responsive UI
- **Visual:** Feature summary or application screens collage
- **Speaker notes:** Summarize skills developed and functionality delivered.

### Slide 15: Conclusion
- **Title:** Conclusion and Thank You
- **Bullets:** Crave is a complete Flutter/Firebase internship prototype; realistic next steps are identified
- **Visual:** App logo and thank-you message
- **Speaker notes:** Summarize the project and invite questions.

---

## 16. Screenshots and Visual References

### Existing Visual Assets
The repository contains launcher and web icons, but no application screen screenshots were found.

- Android launcher icon paths: `android/app/src/main/res/mipmap-*`
- Web icons: `web/icons/`

### APKs Available
- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/apk/debug/app-debug.apk`
- `app/build/outputs/apk/debug/app-debug.apk`

### Screenshots to Capture
Create a `screenshots/` directory in the project root and capture at least:

1. Splash and welcome screen.
2. Customer login and signup.
3. Customer home.
4. Search and filter sheet.
5. Dish details.
6. Cart.
7. Delivery address editor.
8. Checkout with COD.
9. Order success.
10. Customer order history.
11. Customer profile/settings.
12. Seller login and registration.
13. Seller dashboard.
14. Seller orders and order detail.
15. Seller menu form.
16. Inventory.
17. Analytics.
18. Offers.
19. Seller reviews.
20. Seller notifications.

These captures should be real application screens. They must not be mockups or generated fake screenshots.
