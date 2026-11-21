# Crave Food Delivery - User Guide

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Requirements](#2-system-requirements)
3. [Installation Guide](#3-installation-guide)
4. [Getting Started](#4-getting-started)
5. [Registration Guide](#5-registration-guide)
6. [Login Guide](#6-login-guide)
7. [Customer Dashboard Guide](#7-customer-dashboard-guide)
8. [Complete Customer Feature Guide](#8-complete-customer-feature-guide)
9. [Restaurant Partner Guide](#9-restaurant-partner-guide)
10. [Navigation Guide](#10-navigation-guide)
11. [Troubleshooting](#11-troubleshooting)
12. [Frequently Asked Questions](#12-frequently-asked-questions)
13. [Tips for Users](#13-tips-for-users)
14. [Support and Limitations](#14-support-and-limitations)

---

## 1. Introduction

Crave is a Flutter food delivery application for Android with two types of accounts:

- **Customer:** Browses published food items, uses a cart, places Cash on Delivery orders, and tracks order status.
- **Restaurant partner:** Registers a restaurant and manages menu items, stock, orders, offers, analytics, reviews, notifications, and business information.

### Who Should Use It
- Customers who want to search a live published menu and submit COD orders.
- Restaurant owners who want to operate the included seller portal.
- A user with internet access and a configured Firebase project.

### What Users Can Accomplish
Customers can search dishes, choose categories and sorting options, save favourites, maintain delivery addresses, place COD orders, and view submitted orders.

Restaurant partners can add and publish menu items, update stock, accept or reject orders, track preparation and delivery stages, create offers, view restaurant analytics, and respond to reviews.

---

## 2. System Requirements

| Requirement | Current Project Information |
|---|---|
| Platform | Android |
| Minimum Android SDK | 24 (Android 7.0), based on the native module configuration |
| Main application framework | Flutter |
| Internet | Required for Firebase Authentication, Firestore, and live menu/order data |
| Firebase | Authentication and Cloud Firestore must be enabled |
| Device storage | Enough space for an APK and normal app cache |
| Permissions | The Android manifest requests Internet |
| APK | Debug APK output may exist in build folders |
| Supported IDE for source | Android Studio or VS Code with Flutter/Dart tools |

For source builds, Flutter and the Android SDK must be installed and configured. The Flutter project does not require a separate REST API server or Cloud Functions.

---

## 3. Installation Guide

### 3.1 Obtain the Application
This project contains at least these APK build-output locations:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/apk/debug/app-debug.apk`
- `app/build/outputs/apk/debug/app-debug.apk`

Only install an APK you built or received through a trusted source.

If no APK exists in your current copy:
1. Open a terminal in the project root.
2. Run `flutter pub get`.
3. Connect a device or start an emulator.
4. Run `flutter run`.
5. For an APK, run `flutter build apk --debug`.

The common Flutter debug APK location is `build/app/outputs/flutter-apk/app-debug.apk`.

### 3.2 Install on Android
1. Copy the APK to the Android device.
2. Open the APK with a file manager.
3. If prompted, allow installation from the selected source.
4. Tap **Install**.
5. After installation, tap **Open**.

The exact security prompt depends on the Android version and installer.

### 3.3 Firebase Setup
Before the app can operate with live accounts and data:
1. Create or select a Firebase project.
2. Enable Firebase Authentication → Email/Password.
3. Create a Cloud Firestore database.
4. Configure the Android app with FlutterFire.
5. Deploy the included Firestore rules.

If Firebase is not configured, the app shows setup instructions rather than the normal welcome screen.

### 3.4 First Open
1. Allow the app to start.
2. Wait for the splash screen.
3. Open the welcome screen.
4. Choose **Login** or **Create an account**.

---

## 4. Getting Started

1. Open Crave.
2. On first launch, wait through the splash screen.
3. Choose a customer or restaurant path.
4. Create an account or sign in.
5. Use the role-appropriate interface.

Customer accounts reach the customer tabs. Seller accounts reach the restaurant portal.

---

## 5. Registration Guide

### 5.1 Customer Registration
1. On the Welcome screen, tap **Create an account**.
2. Enter your full name.
3. Enter a valid email address.
4. Enter a valid phone number.
5. Enter a password of at least six characters.
6. Re-enter the password.
7. Accept the Terms & Conditions checkbox.
8. Tap **Create Account**.
9. After successful account creation, the app opens the customer interface.

The app creates a Firebase customer account and a Firestore user profile.

### 5.2 Restaurant Registration
1. Open customer **Login**.
2. Tap **Login as Restaurant Partner**.
3. Tap **Register your restaurant**.
4. Complete each of the five steps:
   - Owner information.
   - Restaurant information.
   - Restaurant address.
   - Business information.
   - Final confirmation.
5. Enter:
   - Owner name, email, phone, and password.
   - Restaurant name, description, contact, and cuisine.
   - Country, state, city, area, address, PIN code, and optional landmark.
   - Opening time, closing time, working days, preparation time, and minimum order amount.
6. Confirm that the business details are accurate.
7. Tap **Submit registration**.

The account is created immediately. Restaurant approval/review is not required.

**Not available during registration:** document uploads and restaurant logo/cover uploads.

---

## 6. Login Guide

### 6.1 Customer Login
1. Open Crave.
2. Tap **Login** on the Welcome screen.
3. Enter an email address.
4. Enter a password.
5. Optional: select **Remember me**.
6. Tap **Login**.

The app verifies the account is registered as a customer.

### 6.2 Seller Login
1. Open customer Login.
2. Tap **Login as Restaurant Partner**.
3. Enter the seller email and password.
4. Optional: select **Remember me**.
5. Tap **Login**.

The app verifies the Firestore account role is `seller`.

### 6.3 Password Visibility
Tap the eye icon beside a password field to show or hide the password.

### 6.4 Forgot Password
1. Enter the email address.
2. Tap **Forgot password?**.
3. Firebase sends a password-reset email if the account exists.

Check the spam folder if the email does not appear.

### 6.5 Remember Me
The login screen contains a Remember Me checkbox. It is a visible UI control; persistent session behavior is controlled by Firebase Authentication state.

### 6.6 Google Sign-In
Google sign-in is **not implemented**. If it is shown, tapping its button displays a message that Google authentication is not connected.

### 6.7 Common Login Errors
- Invalid email format.
- Password shorter than six characters.
- Wrong credentials.
- Signing in with a seller account from the customer login screen.
- Signing in with a customer account from the restaurant login screen.
- Internet or Firebase connection problems.
- Missing Firebase setup or unpublished Firestore rules.

---

## 7. Customer Dashboard Guide

The customer dashboard has five bottom tabs:

### Home
- Shows the greeting and customer name.
- Shows the selected delivery city.
- Opens address selection.
- Opens search.
- Shows categories and popular/published foods.
- Shows cart item count.

### Search
- Searches names, categories, cuisines, and ingredients.
- Uses recent searches and category chips.
- Opens category filters and sorting.
- Displays no-results information when needed.

### Cart
- Lists cart items and customizations.
- Shows quantity and item totals.
- Opens checkout when items exist.

### Favourites
- Displays saved dishes.
- Opens favourite dishes for details.

### Profile
- Shows name, email, and phone.
- Opens edit profile, order history, addresses, favourites, settings, help, and logout.

---

## 8. Complete Customer Feature Guide

### 8.1 Browse the Menu
1. Open **Home**.
2. Scroll through categories.
3. Tap a category to filter the popular-food section.
4. Tap **See all** or the search field to open all results.

Only menu items marked published in Firestore are shown.

### 8.2 Search for Food
1. Open **Search**.
2. Enter a food name or category.
3. Review matching dishes.
4. Tap a dish to open details.

Use the tune icon to filter:
- Category.
- Popular.
- Price low to high.
- Price high to low.
- Highest rated.

### 8.3 Open Dish Details
1. Tap a dish card.
2. Review image, price, rating, review count, ingredients, vegetarian status, and preparation time.
3. Select Mild, Medium, or Hot spice.
4. Enter optional special instructions.
5. Use the quantity minus/plus controls.

If the item is unavailable, the Add to Cart button is disabled.

### 8.4 Add a Dish to the Cart
1. On dish details, choose quantity and options.
2. Tap **Add to Cart**.
3. Wait for the confirmation message.
4. Open the Cart tab.

The cart allows items from only one restaurant. If you try to add an item from another restaurant, use a separate order.

### 8.5 Change the Cart
1. Open **Cart**.
2. Use minus to reduce quantity.
3. Use plus to increase quantity.
4. Tap the remove/trash control to remove an item.
5. Review subtotal and total.

### 8.6 Save Favourites
1. Open a dish or dish card.
2. Tap the heart icon.
3. Open **Favourites** to review saved items.
4. Tap the heart again to remove a favourite.

Favourites are not restored after a new app session.

### 8.7 Edit Customer Profile
1. Open **Profile**.
2. Tap **Edit Profile**.
3. Enter a name.
4. Enter or verify the email.
5. Enter a phone number.
6. Tap **Save Changes**.

Profile display updates locally. The current implementation does not fully synchronize customer profile edits to Firestore.

### 8.8 Add or Change an Address
1. Open **Saved Addresses** from Profile.
2. Tap **Add address**.
3. Enter:
   - Full name.
   - Phone number.
   - House/flat.
   - Street.
   - City.
   - State.
   - Six-digit PIN code.
   - Address type: Home, Work, or Other.
4. Optional: set it as the default.
5. Tap **Save Address**.

To edit or delete:
1. Open the address card menu.
2. Choose **Edit**, **Set as default**, or **Delete**.
3. Confirm deletion if prompted.

The address book is maintained in the active app session and is not yet cross-session Firestore storage.

### 8.9 Select a Location
1. Tap the delivery location row on Home.
2. Browse saved addresses.
3. Tap an address or open the add-address action.
4. Current-location lookup is not connected.

### 8.10 Place a COD Order
1. Add at least one available dish.
2. Open **Cart**.
3. Tap **Proceed to Checkout**.
4. If no address exists, tap **Add** and create one.
5. Review the selected address.
6. Enter optional delivery instructions.
7. Review the order summary.
8. Confirm that **Cash on Delivery** is selected.
9. Tap **Place COD order**.

The app then:
- Verifies signed-in customer status.
- Verifies the restaurant is open.
- Checks current price and stock.
- Checks the minimum order amount.
- Creates the order.
- Reduces stock.
- Creates an in-app seller notification.

Online payment is not supported.

### 8.11 Track an Order
1. Open **Profile**.
2. Tap **My Orders**.
3. Filter All, Active, Completed, or Cancelled.
4. Review status and item details.

Seller status changes appear in order history. Possible statuses include New, Accepted, Preparing, Ready for Pickup, Picked Up, Delivered, Rejected, and Cancelled.

### 8.12 Change Settings
1. Open **Profile** → **Settings**.
2. Use switches for order notifications, offers/updates, and dark mode.
3. Tap **Language** to choose English or Hindi.

The language control currently stores a preference; full content translation is not implemented.

### 8.13 Help and About
- Open **Help & Support** for FAQs.
- Tap **Contact Support** to see that support contact details are not configured.
- Open **About Crave** for app information.

### 8.14 Sign Out
1. Open **Profile**.
2. Tap **Logout**.
3. Confirm **Log out**.

---

## 9. Restaurant Partner Guide

### 9.1 Seller Dashboard
After seller login, the dashboard shows:
- Restaurant open/closed state.
- Today's orders.
- Today's revenue.
- Pending orders.
- Completed and cancelled/rejected counts.
- Average rating.
- Seven-day revenue chart.
- Recent orders.
- Quick actions.

Use the switch to open or close the restaurant.

### 9.2 Manage Orders
1. Open the **Orders** tab.
2. Choose All or a status filter.
3. Tap an order card to open details.
4. For a New order:
   - Tap **Accept** or **Reject**.
   - If rejecting, choose a reason and optional explanation.
5. After acceptance, set preparation time from 5 to 180 minutes.
6. Advance Accepted to Preparing.
7. Advance Preparing to Ready for Pickup.
8. Advance Ready for Pickup to Picked Up.
9. Advance Picked Up to Delivered.

Cancellation/rejection behavior is constrained by Firestore rules.

### 9.3 Add a Menu Item
1. Open **Menu** or use **Add new food** from Dashboard.
2. Tap the add form button.
3. Enter name and description.
4. Enter a direct image URL if available.
5. Choose category.
6. Enter regular price and optional discounted price.
7. Enter preparation time and stock.
8. Set availability, vegetarian status, bestseller, and featured status.
9. Tap **Save as draft** or **Publish item**.

The discounted price must be positive and lower than the regular price.

### 9.4 Edit or Delete a Menu Item
1. Open **Menu**.
2. Tap the edit icon on a menu card.
3. Change the fields.
4. Tap **Save changes** or **Save as draft**.
5. To delete, tap the trash icon and confirm.

Published items with `isPublished` true appear in the customer catalog.

### 9.5 Manage Inventory
1. Open **Inventory** from Profile or Dashboard.
2. Search by item name.
3. Tap the edit stock icon.
4. Enter zero or a positive stock number.
5. Tap **Save**.

Stock of five or fewer is marked low. Zero stock is marked out of stock.

### 9.6 Manage Categories
1. Open **Menu** → category icon or **Profile** → **Menu categories**.
2. Tap plus to add a category.
3. Use the edit icon to rename a category.
4. Use the delete icon to remove a category.
5. Confirm the deletion.

At least one category must remain.

### 9.7 Create an Offer
1. Open **Offers and discounts**.
2. Tap **Create offer** or the plus icon.
3. Enter name and description.
4. Select an offer type.
5. Enter discount value, minimum order, and maximum discount.
6. Set start and expiry dates.
7. Create the offer.

The offer is stored in Firestore, but checkout totals do not currently apply offer discounts.

### 9.8 View Analytics
1. Open **Analytics**.
2. Select Today, Last 7 days, or Last 30 days.
3. Optional: select **Custom dates**.
4. Review revenue, order totals, average value, completed/rejected orders, rating, charts, and popular dishes.
5. Tap the download icon to view a selectable report summary.

The app does not create a downloadable file.

### 9.9 Respond to Reviews
1. Open **Customer reviews**.
2. Read the rating and customer text.
3. Tap **Respond** or **Edit response**.
4. Enter the reply and tap **Save response**.

You cannot edit or delete customer review text itself.

### 9.10 Manage Notifications
1. Open Notifications from Dashboard or Profile.
2. Use category filters.
3. Tap a notification to mark it read.
4. If it belongs to an order, open the order.
5. Use **Mark all read** as needed.

Push notifications are not configured.

### 9.11 Update Restaurant Profile
1. Open **Profile** → **Restaurant details**.
2. Update name, description, phone, email, address, or cuisine.
3. Tap **Save restaurant profile**.

Restaurant logo/cover storage is not connected.

### 9.12 Set Business Hours
1. Open **Profile** → **Business hours**.
2. Set open/closed state.
3. Choose opening and closing times.
4. Select working days.
5. Optional: add scheduled closures.
6. Tap **Save business hours**.

---

## 10. Navigation Guide

### Customer
- The bottom bar contains Home, Search, Cart, Favourites, and Profile.
- Profile options open dedicated screens and return using the back button.
- Checkout opens from Cart and is replaced by the success screen after placement.
- Dish cards open a new details screen.
- Dialogs and bottom sheets close with Done, Cancel, Back, or the close gesture.

### Seller
- Mobile uses bottom navigation: Dashboard, Orders, Menu, Analytics, Profile.
- Wide screens use a left NavigationRail.
- Profile entries open secondary screens.
- Order cards open an order detail screen.
- Add/edit forms open as full pages or dialogs.

---

## 11. Troubleshooting

| Problem | Possible Cause | Solution |
|---|---|---|
| App shows Firebase setup screen | FlutterFire configuration is missing | Run FlutterFire configuration and restart |
| Cannot sign in | Wrong credentials or account role | Recheck email/password and use the correct customer/seller login |
| Restaurant account cannot access portal | Account role is customer | Register or sign in with a seller account |
| Menu is empty | No published foods or Firestore rules/data missing | Confirm seller published items and deployed rules |
| Could not load menu | Firestore connection or permissions | Retry, verify internet, Firebase setup, and rules |
| Item unavailable | Stock zero or availability false | Ask the seller to update stock/availability |
| Cannot add item to cart | Item is unavailable or belongs to another restaurant | Remove the unavailable item or use a separate order |
| Cannot place COD order | Address missing or restaurant closed | Add/select address and confirm restaurant is open |
| Minimum order error | Cart total below restaurant minimum | Add more items until the minimum is reached |
| Seller notification missing | Firestore notification write or rules issue | Verify rules and internet connection |
| Password reset email missing | Typo or spam folder | Recheck address and check spam |
| Google sign-in not working | Not implemented | Use Email/Password |
| Address missing after restart | Address book is session-only | Re-enter the address |
| Review cannot be submitted | Customer-created reviews are not implemented | Read/reply to existing seller reviews only if present |

---

## 12. Frequently Asked Questions

**Is the app available for iOS?**  
The repository is configured for Flutter, but the documented and verified target is Android.

**Does Crave support online payments?**  
No. Checkout uses Cash on Delivery only.

**Can I cancel an active order?**  
The app relies on the restaurant to reject a new order or cancel an order in an allowed preparation stage. Customers cannot directly cancel from the current code.

**Can I change a delivery address after placing an order?**  
No. The delivery address is saved in the order document as a snapshot. Create a new order for a different address.

**Are order statuses updated automatically?**  
The app streams Firestore order updates, so a seller status change should appear in customer order history when connected.

**Can I add my own menu image?**  
The app supports direct image URLs. It does not upload local files through Firebase Storage.

**Can I create a seller account immediately?**  
Yes. Seller registration is implemented without an approval gate.

**Can I use Google sign-in?**  
No. Google sign-in is only shown as placeholder UI.

**Are favourites saved permanently?**  
No. They are stored in memory and are not synchronized to Firestore.

**Does the app know my current location?**  
No. The current-location option is not connected.

**Does the app send push notifications?**  
No. In-app Firestore notifications are implemented.

**Can the seller export analytics?**  
The app shows a selectable report summary. File export is not implemented.

---

## 13. Tips for Users

- Check the restaurant open status before placing an order.
- Verify the delivery address and phone number before checkout.
- Review stock-sensitive items carefully.
- Keep the app open or connected to internet for live order updates.
- Use clear, direct image URLs for menu items.
- Keep menu preparation estimates realistic.
- Mark unavailable items or zero stock promptly.
- Use order status transitions carefully because they follow a fixed lifecycle.
- Check notification categories to distinguish new orders from reviews and inventory changes.
- Sign out from a shared device.

---

## 14. Support and Limitations

### Known Limitations
- Google Sign-In is not implemented.
- Customer profile edits do not fully synchronize to Firestore.
- Address-book entries are not persistent across sessions.
- Favourites are not stored in Firestore.
- Password change for sellers is not connected.
- Firebase Storage and image uploads are not connected.
- Firebase Cloud Messaging push notifications are not configured.
- Online payments are not implemented.
- Customer-created reviews are not implemented.
- Seller offers are stored but do not change checkout totals.
- Analytics export does not download a file.
- Full English/Hindi localization is not implemented.
- Contact details for support are not configured.
- Current-location lookup is not connected.
- Document and verification uploads are not collected.
- No formal production backend is deployed.

### Support
The app does not have configured support contact details. For project setup issues, refer to `README.md` and verify Firebase configuration, Firestore rules, and Flutter installation.

### Security
Do not share account passwords or private Firebase configuration data. For production use, App Check and a complete security review are recommended before the application is made publicly available.
