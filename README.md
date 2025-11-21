# FBLA Conference App

A modern, feature-rich conference management application built with Flutter and Firebase. This app provides a seamless experience for conference attendees to view events, manage their schedule, receive announcements, and more.

## Features

### ✨ Core Features
- **User Authentication**: Email/password authentication with Firebase Auth
- **Event Management**: Browse, search, and register for conference events
- **Personal Schedule**: View and manage registered events
- **Announcements**: Stay updated with real-time conference announcements
- **User Profiles**: Personalized user profiles with registration tracking
- **Modern UI**: Clean, professional blue and white theme

### 🎨 Design
- Modern Material Design 3 UI
- Professional blue and white color scheme
- Responsive layouts for mobile, tablet, and web
- Smooth animations and transitions
- Intuitive navigation with bottom navigation bar

### ♿ Accessibility Features
- **Dark Mode**: Reduce eye strain in low-light conditions
- **Text Size Adjustment**: Scale text from 85% to 150% for better readability
- **Reduce Motion**: Minimize animations for motion-sensitive users
- **High Contrast Mode**: Enhanced contrast for better visibility
- **Bold Text**: Make text bolder and easier to read
- All settings persist across app sessions
- See [ACCESSIBILITY_FEATURES.md](ACCESSIBILITY_FEATURES.md) for details

### 🔥 Firebase Integration
- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: Real-time database for events, users, and announcements
- **Firebase Storage**: Media storage for event images and attachments
- **Firebase Messaging**: Push notifications for important updates

## Getting Started

### Prerequisites
- Flutter SDK (3.x or higher)
- Firebase account
- iOS Simulator / Android Emulator / Chrome browser

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # For iOS  
   flutter run -d ios
   
   # For Android
   flutter run -d android
   ```

## Firebase Firestore Structure

### Sample Event
```json
{
  "title": "Opening Keynote",
  "description": "Welcome keynote address",
  "location": "Main Auditorium",
  "startTime": "2025-11-10T09:00:00Z",
  "endTime": "2025-11-10T10:30:00Z",
  "category": "Keynote",
  "speakers": ["Dr. Jane Smith"],
  "maxCapacity": 500,
  "registeredUsers": [],
  "isFeatured": true
}
```

### Sample Announcement
```json
{
  "title": "Welcome!",
  "content": "Welcome to FBLA Conference 2025!",
  "postedAt": "2025-11-06T12:00:00Z",
  "postedBy": "Conference Team",
  "isPinned": true,
  "category": "General"
}
```

## Development

For more Flutter resources:
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)

