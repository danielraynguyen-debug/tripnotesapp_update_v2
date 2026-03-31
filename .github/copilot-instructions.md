# Copilot Workspace Instructions for Trip Notes App

## Principles
- **Follow Clean Architecture**: See PLAN.md for directory and responsibility breakdown.
- **Flutter + Firebase**: Use standard Flutter build/test commands. Backend logic (notifications, sensitive actions) must go through Cloud Functions (see FIREBASE_CLOUD_FUNCTIONS_GUIDE.md).
- **Bloc State Management**: All stateful logic should use Bloc (see lib/presentation/bloc/).
- **UI/UX**: Follow claymorphism, color, and typography guidelines in PROJECT_UI_UX_DOCUMENTATION.md. All UI must be Vietnamese-localized.
- **Privacy**: Never expose sensitive user data (e.g., phone numbers) in UI or logs unless user is authenticated and authorized (see lib/presentation/screens/ride_detail_screen.dart).
- **Notifications**: All push notifications use FCM v1 and are triggered by backend (see FCM_V1_SETUP_GUIDE.md, functions/index.js).

## Key Files & Docs
- [PLAN.md](../PLAN.md): Architecture, file responsibilities, features, roadmap.
- [PROJECT_UI_UX_DOCUMENTATION.md](../PROJECT_UI_UX_DOCUMENTATION.md): UI/UX, navigation, design system.
- [FIREBASE_SETUP.md](../FIREBASE_SETUP.md), [FCM_V1_SETUP_GUIDE.md](../FCM_V1_SETUP_GUIDE.md), [FIREBASE_CLOUD_FUNCTIONS_GUIDE.md](../FIREBASE_CLOUD_FUNCTIONS_GUIDE.md): Firebase, FCM, backend setup.
- [functions/index.js](../functions/index.js): Cloud Functions for notifications.

## Build & Run
- Use standard Flutter commands:
  - `flutter pub get`
  - `flutter run`
  - `flutter test`
- For backend:
  - `npm install` in `functions/`
  - `firebase deploy --only functions`

## Anti-patterns
- Do **not** embed sensitive keys or tokens in client code.
- Do **not** bypass backend for notifications or sensitive actions.
- Do **not** hardcode UI text; always localize.
- Do **not** duplicate documentation—link to the files above.

## Example Prompts
- "Add a new notification type for ride cancellation, following backend notification pattern."
- "Refactor ride creation to support a new field, updating both UI and backend."
- "Update the UI to match the latest claymorphism design in PROJECT_UI_UX_DOCUMENTATION.md."

---
For advanced agent customization, consider applyTo patterns for frontend (lib/presentation/), backend (functions/), and tests (test/). See PLAN.md for boundaries.