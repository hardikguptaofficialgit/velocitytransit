# Velocity Transit

Velocity Transit is a Flutter-based transit experience focused on nearby bus discovery, live tracking, route visualization, and simulation-driven operations insights.

## Project Overview

This app combines:

- Real passenger location using device GPS
- Simulated bus movement for demo and prototype workflows
- Real map tiles rendered with `flutter_map`
- Road-snapped transit paths fetched from a routing service
- Nearby bus, route playback, alerts, favorites, and planning flows

## Tech Stack

- Flutter
- Dart
- Riverpod
- `flutter_map`
- `geolocator`
- `http`
- `latlong2`

## Key Features

- Live map with nearby buses
- Passenger GPS location tracking
- Simulated buses moving along route geometry
- Route lines aligned to actual road paths when routing is available
- Trip playback screen
- Heatmap and demand visualization
- Alerts and favorites support

## Requirements

Before installing the app, make sure you have:

- Flutter SDK `3.11.x` or compatible
- Dart SDK matching the Flutter version
- Android Studio or VS Code with Flutter support
- Android SDK for Android builds
- Xcode for iOS builds on macOS

Check your environment with:

```bash
flutter doctor
```

## Getting Started

Clone the repository:

```bash
git clone <your-repository-url>
cd VelocityTransit
```

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Launch the app:

```bash
flutter run
```

## App Installation

### Install on Android device

1. Enable Developer Options on your Android phone.
2. Enable USB debugging.
3. Connect the device with USB.
4. Confirm the device is detected:

```bash
flutter devices
```

5. Install and run the app:

```bash
flutter run
```

To generate a release APK:

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Install on Android emulator

1. Open Android Studio.
2. Start an emulator from Device Manager.
3. Run:

```bash
flutter run
```

### Install on iPhone or iOS simulator

On macOS with Xcode installed:

```bash
flutter run
```

To build an iOS release:

```bash
flutter build ios --release
```

## Permissions

The app uses location permissions for passenger GPS tracking.

Android:

- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`
- `INTERNET`

iOS:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

## How Live Tracking Works

- Passenger location is fetched from the device GPS.
- Bus positions are simulated inside the app.
- Nearby route networks are generated around the passenger area.
- Route shapes are requested from a road-routing service so lines follow real roads where available.
- If routing is temporarily unavailable, the app falls back to generated route geometry so the experience still works.

## Development Notes

- Bus locations are currently simulated for product demonstration.
- Passenger location is real and device-based.
- The project is suitable for replacing simulated bus data later with backend or fleet feeds.

## Useful Commands

Install packages:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Analyze the code:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build release APK:

```bash
flutter build apk --release
```


## Admin Panel

- **URL:** https://velocityappx.vercel.app/
- **Email:** hardikgupta8792@gmail.com
- **Password:** hardik91

---
## Project Structure

```text
lib/
  core/
    data/
    providers/
    router/
    services/
    theme/
    widgets/
  features/
    home/
    live_tracking/
    splash/
    trip_playback/
```

## Future Improvements

- Replace simulated bus positions with backend fleet feeds
- Add GTFS or city transport integration
- Improve nearest-stop and nearest-bus ranking
- Add offline caching for route geometry
- Add authentication and user-specific commute preferences

## License

This project is currently private and not licensed for public redistribution unless explicitly stated otherwise.
