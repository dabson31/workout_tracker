# Workout Tracker

A simple Flutter app to track your workouts, log exercises, watch your progress, and set goals - all stored locally on your phone.

> **This is a beta release.** Things may break as it may be unstable. Feedback is welcome!

## Features

- Calendar heatmap of your workout days
- Log exercises with weight, reps, and sets
- Track progress and personal records (PRs) over time
- Set and track goals (exercise or bodyweight)
- Bodyweight logging
- Everything stays on your device - no account, no cloud (yet)

## Install (Android)

1. Go to the [Releases](../../releases) page
2. Download the latest `.apk` file (or the version of your choice)
3. Open it on your phone
4. If prompted, allow installs from this source (settings will pop up automatically)
5. Tap install - done

## Run from source (for devs)

```bash
git clone <this-repo-url> (https://github.com/dabson31/workout_tracker.git)
cd workout_tracker
flutter pub get
flutter run
```

## Build your own APK

```bash
flutter build apk --release
```
The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Feedback

Feedback is welcome!