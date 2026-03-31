# Trip Notes App - Windsurf Instructions

## Project Overview

**Trip Notes App** is a Flutter mobile application for managing ride/drive requests. It allows users to:
- Create and manage ride notes (chuyến xe/ghi chú)
- Accept rides as a driver
- Track ride status (pending, ongoing, completed)
- Receive real-time push notifications for new rides
- View ride history and manage activities

**Tech Stack:**
- **Framework:** Flutter 3.11.1+
- **State Management:** flutter_bloc (BLoC pattern)
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Messaging, Functions)
- **Maps:** Google Maps Flutter + Goong API (Vietnam map service)
- **Authentication:** Firebase Phone Auth (OTP)
- **Push Notifications:** Firebase Cloud Messaging (FCM)

---

## Project Structure

```
lib/
├── core/
│   └── services/
│       └── notification_service.dart    # FCM setup, local notifications, force update check
├── data/
│   ├── models/
│   │   ├── ride_model.dart              # Ride data model
│   │   └── user_model.dart              # User data model
│   └── repositories/
│       ├── auth_repository.dart         # Auth operations (OTP, FCM token, avatar upload)
│       └── ride_repository.dart         # CRUD operations for rides
├── presentation/
│   ├── bloc/
│   │   ├── auth_bloc.dart               # Auth state management
│   │   ├── auth_event.dart              # Auth events
│   │   └── auth_state.dart              # Auth states
│   ├── screens/
│   │   ├── home_screen.dart             # Main screen with bottom nav
│   │   ├── login_screen.dart            # Phone login with claymorphism UI
│   │   ├── otp_screen.dart              # OTP verification
│   │   ├── register_info_screen.dart    # New user profile setup
│   │   ├── ride_detail_screen.dart      # Ride details & actions
│   │   ├── map_picker_screen.dart       # Map location picker
│   │   └── tabs/
│   │       ├── home_tab.dart            # Pending rides list
│   │       ├── activity_tab.dart        # Ongoing rides + ride management
│   │       ├── notification_tab.dart    # Filtered ride notifications
│   │       └── profile_tab.dart         # User profile & logout
│   └── widgets/
│       ├── clay_container.dart          # Reusable claymorphism container
│       ├── create_ride_dialog.dart      # Create/edit ride form
│       ├── ride_card.dart               # Ride card component
│       └── ride_detail_bottom_sheet.dart # Ride preview bottom sheet
├── firebase_options.dart                # Firebase configuration (Android/iOS)
└── main.dart                            # App entry point
```

---

## Architecture Pattern

### BLoC (Business Logic Component)
The app uses `flutter_bloc` for state management:

**Auth Flow:**
1. `LoginScreen` → `SendOtpEvent` → `AuthBloc` → Firebase Phone Auth
2. `OtpScreen` → `VerifyOtpEvent` → Check if new user
3. New user → `RegisterInfoScreen` → `UpdateUserInfoEvent` → Save to Firestore
4. Existing user → `HomeScreen`

**Repository Pattern:**
- `AuthRepository`: Handles Firebase Auth, Firestore user storage, FCM tokens, avatar upload
- `RideRepository`: Handles ride CRUD, queries, status updates

### Data Models

**RideModel** (`data/models/ride_model.dart`):
```dart
- id, customerPhone, pickupPoint, destinationPoint
- dateTime, price, distance, status (pending/ongoing/completed/cancelled)
- type (one_way/round_trip)
- driverId, driverName, driverPhone (assigned driver)
- pickupLat, pickupLng, destLat, destLng (coordinates)
- creatorId, creatorName, creatorPhone (who created the ride)
- createdAt
```

**UserModel** (`data/models/user_model.dart`):
```dart
- uid, displayName, email, phoneNumber, photoUrl, createdAt
```

---

## Key Features Implementation

### 1. Phone Authentication (OTP)
- Uses `intl_phone_field` for VN phone input
- `firebase_auth` for OTP verification
- New users must complete `RegisterInfoScreen` before accessing app

### 2. Push Notifications (FCM)
**Client Side** (`notification_service.dart`):
- Subscribes to `new_rides` topic
- Handles foreground, background, and terminated states
- Tapping notification navigates to ride detail

**Server Side** (`functions/index.js`):
- `sendNotificationOnNewRide`: Broadcasts to all drivers when new ride created
- `sendNotificationToCreator`: Notifies creator when driver accepts their ride

### 3. Location & Maps
- **Map Picker**: `MapPickerScreen` with Google Maps, geocoding
- **Place Search**: Goong API for Vietnamese address autocomplete
- **Distance Calculation**: Goong DistanceMatrix API
- **Current Location**: `geolocator` for GPS position

### 4. Location Tracking (ActivityTab)
- Real-time GPS tracking for ongoing rides
- Auto-completes ride when driver reaches destination (500m radius)
- For round trips: tracks arrival at destination and return to pickup

### 5. Claymorphism UI Design
- Consistent design system using `ClayContainer` widget
- Colors: Primary Indigo `#4F46E5`, Background `#F2F9F8`, Card `#FFE0B2`
- Soft shadows, rounded corners (border radius 20)

---

## Firebase Configuration

**Project:** `trip-notes-app-0001`

**Required Collections:**
```
users/{uid}
  - uid, displayName, email, phoneNumber, photoUrl, fcmToken, createdAt, updatedAt

rides/{rideId}
  - All RideModel fields
```

**Security Rules:** Set appropriate Firestore rules for production.

---

## Environment Setup

### Prerequisites
1. Flutter SDK 3.11.1 or higher
2. Firebase CLI installed and logged in
3. Android Studio / Xcode for emulators

### Installation
```bash
# Install dependencies
flutter pub get

# Firebase setup (if needed)
flutterfire configure

# Run app
flutter run
```

### Required API Keys
1. **Goong API Key** (in `create_ride_dialog.dart`):
   - Currently hardcoded: `DTG9XzXVm1lZi9NhVAXtrBREelukL5MhZI9eJvqg`
   - Get your own at: https://goong.io/

2. **Google Maps API Key** (Android/iOS native config):
   - Add to `android/app/src/main/AndroidManifest.xml`
   - Add to `ios/Runner/AppDelegate.swift`

---

## Common Development Tasks

### Adding a New Screen
1. Create file in `presentation/screens/`
2. Add route navigation in appropriate screen
3. Use `ClayContainer` for consistent UI
4. Access repositories via `RepositoryProvider.of<Repository>(context)`

### Adding a New Ride Feature
1. Update `RideModel` if new fields needed
2. Add method to `RideRepository`
3. Update UI in relevant screens/tabs
4. Update Firebase Functions if notifications needed

### Modifying Notifications
1. **Client**: Update `notification_service.dart`
2. **Server**: Update `functions/index.js` and deploy:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

### Styling Guidelines
- Primary color: `Color(0xFF4F46E5)` (Indigo)
- Card background: `Color(0xFFFFE0B2)`
- Page background: `Color(0xFFF2F9F8)`
- Text: Use Google Fonts Inter
- Always use `ClayContainer` for cards/containers

---

## Testing Checklist

- [ ] Phone login with valid VN number
- [ ] OTP verification
- [ ] New user registration flow
- [ ] Create ride with all fields
- [ ] Accept ride as driver
- [ ] Cancel ride
- [ ] Complete ride (auto/manual)
- [ ] Push notification received
- [ ] Map picker location selection
- [ ] Contact picker for phone number
- [ ] Avatar upload
- [ ] Logout and re-login

---

## Deployment Notes

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Firebase Functions
```bash
cd functions
firebase deploy --only functions
```

---

## Troubleshooting

**Build Issues:**
- Run `flutter clean` and `flutter pub get`
- Check `firebase_options.dart` is up to date

**Maps not working:**
- Verify API keys are valid
- Check location permissions granted

**Notifications not received:**
- Check FCM token is saved to Firestore
- Verify topic subscription in `notification_service.dart`
- Check Firebase Functions logs

**Goong API errors:**
- Verify API key has sufficient quota
- Check network connectivity

---

## Dependencies (pubspec.yaml)

**Key Packages:**
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
- `flutter_bloc`, `equatable` - State management
- `google_maps_flutter`, `geolocator`, `geocoding` - Maps & location
- `flutter_local_notifications` - Local notifications
- `intl_phone_field`, `pinput` - Phone/OTP UI
- `dio` - HTTP client for Goong API
- `intl` - Date/number formatting
- `image_picker`, `flutter_contacts` - Media & contacts
- `google_fonts` - Typography
- `url_launcher` - Phone calls & maps

---

## Version History

- **v1.0.0+1** - Initial release with full ride management, notifications, and claymorphism UI

---

## Contact & Support

For issues related to:
- **Flutter app**: Check Flutter logs and widget tree
- **Firebase**: Check Firebase Console logs
- **Goong API**: Check Goong dashboard for quota/usage
