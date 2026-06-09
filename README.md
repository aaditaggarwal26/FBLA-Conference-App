# FBLA Conference App

A mobile app for managing and navigating conference events. Built with Flutter for iOS and Android.

It covers everything an attendee needs during a conference: finding their way around the venue in AR, keeping up with events, messaging other attendees, trading pins, and practicing for competitive events.

---

## Features

**AR Navigation**

Point your camera at the venue and walk toward any pinned location. A compass overlay renders event pins in real space using live GPS and device heading data. Works best outdoors or in large open venues.

**Event Management**

Browse events by category, register for sessions, and scan QR codes at check-in. The app includes a full conference schedule with speaker info and session details that can be imported directly.

**School Dashboard**

School chapters get their own dashboard where admins can post announcements, manage members, broadcast messages, and view registration info for their chapter.

**Practice Tests**

Timed quizzes with scoring history and stats across competitive event categories. Questions cover the standard objective test format with answer explanations.

**Pin Trading**

Create custom pins, scan other attendees' QR codes to trade, and build a collection. Each pin has its own detail view with trade history.

**Messaging**

Real-time direct messaging between attendees. Chapter admins can send broadcast messages to their whole school group.

**LinkedIn Integration**

Share event participation and achievements to LinkedIn without leaving the app. Requires a LinkedIn Developer app configured with the correct redirect URI.

**Siri Shortcuts**

Trigger navigation or check your schedule using Siri. Shortcut donations are handled automatically as you use the app.

**Accessibility**

Adjustable text size (85-150%), dark mode, high contrast, reduced motion, and bold text. All preferences are saved across sessions.

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore, Storage, Cloud Messaging) |
| AR | Device camera + Flutter Compass + Geolocator |
| Calendar | table_calendar |
| QR Scanning | mobile_scanner |
| Environment | flutter_dotenv |

---

## Getting Started

### Prerequisites

- Flutter 3.x ([install guide](https://docs.flutter.dev/get-started/install))
- Xcode 15+ (for iOS builds)
- CocoaPods: `sudo gem install cocoapods`
- A Firebase project with Firestore, Auth, and Storage enabled

### 1. Clone and install

```bash
git clone https://github.com/aaditaggarwal26/FBLA-Conference-App.git
cd FBLA-Conference-App
flutter pub get
```

### 2. Set up environment variables

```bash
cp .env.example .env
```

Fill in your values:

```
OPENROUTER_API_KEY=your_key_here
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
```

### 3. Add Firebase config files

Download these from your Firebase project console and place them at:

- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

Both are gitignored and not included in the repo.

### 4. Install iOS dependencies

```bash
cd ios && pod install && cd ..
```

### 5. Run

```bash
flutter run -d ios        # iOS device or simulator
flutter run -d android    # Android device or emulator
```

```bash
flutter devices           # list available targets
```

### Build for release

```bash
flutter build ios --release
flutter build apk --release
```

---

## Project Layout

```
lib/
├── main.dart
├── firebase_options.dart
├── theme/                  # colors and text styles
├── models/                 # Firestore data models
├── services/               # business logic (AR, auth, school, LinkedIn, Siri)
├── screens/
│   ├── ar_navigation/      # camera + compass AR screen
│   ├── auth/               # login, register, forgot password
│   ├── events/             # event browser, QR scanner, detail view
│   ├── home/               # main feed with announcements and events
│   ├── messages/           # direct messaging and conversations
│   ├── pins/               # pin trading and collection
│   ├── practice_tests/     # quiz mode and scoring
│   ├── profile/            # user profile and settings
│   └── school/             # school dashboard, calendar, admin tools
├── widgets/                # shared UI components
└── data/                   # static event and schedule data
```

---

## Notes

- AR navigation needs a physical device. The camera and GPS sensors don't work in simulators.
- LinkedIn OAuth requires a verified LinkedIn Developer app with the correct callback URL.
- Firestore security rules are in `firestore.rules`. Review them before deploying.
- Never commit your `.env` file. It is gitignored by default.
