# Perception Notes

Perception Notes is a local-first Flutter app for keeping private notes about people in your life. It lets you create person profiles, save dated notes, attach photos, search across saved information, and lock the app with a PIN. Everything is stored on-device with SQLite.

## Features

- Add a new person with core details like name, nicknames, birthday, age, school, course, and free-form notes.
- Add dynamic custom fields such as `Location`, `Instagram`, `Facebook`, or anything else you want.
- Attach a real profile picture or use a generated placeholder avatar when no photo is set.
- Save dated notes per person.
- Pin people and notes so they stay near the top.
- Search from the home screen across people, custom attributes, and notes.
- Search inside an individual profile for matching attributes and notes.
- Lock the app with a local PIN.
- Export and import a portable JSON backup that includes saved database content and bundled image assets.
- View storage usage inside Settings.

## Privacy And Storage

- Data is stored locally in SQLite.
- App lock PIN data is stored locally using secure storage.
- Photos are copied into the app's local storage area.
- No account, server sync, or cloud backend is required.

## Stack

- Flutter
- SQLite via `sqflite`
- `flutter_secure_storage` for app lock
- `file_picker` for choosing images and backup files
- `path_provider` and `path` for local file handling

## Project Structure

- [lib/main.dart](C:\Users\ADMIN\Documents\Own projects\Person notes\perception_notes\lib\main.dart): app entry point
- [lib/src/app.dart](C:\Users\ADMIN\Documents\Own projects\Person notes\perception_notes\lib\src\app.dart): app shell and home screen
- [lib/src/screens/person_editor_screen.dart](C:\Users\ADMIN\Documents\Own projects\Person notes\perception_notes\lib\src\screens\person_editor_screen.dart): create and edit people
- [lib/src/screens/person_detail_screen.dart](C:\Users\ADMIN\Documents\Own projects\Person notes\perception_notes\lib\src\screens\person_detail_screen.dart): person profile, notes, photos, profile picture
- [lib/src/screens/settings_screen.dart](C:\Users\ADMIN\Documents\Own projects\Person notes\perception_notes\lib\src\screens\settings_screen.dart): privacy, storage, backup, and about
- [lib/src/services/notes_repository.dart](C:\Users\ADMIN\Documents\Own projects\Person notes\perception_notes\lib\src\services\notes_repository.dart): SQLite and local file operations
- [lib/src/services/app_lock_service.dart](C:\Users\ADMIN\Documents\Own projects\Person notes\perception_notes\lib\src\services\app_lock_service.dart): PIN lock logic

## Getting Started

### Requirements

- Flutter SDK
- Dart SDK
- Android Studio, VS Code, or another Flutter-capable editor
- An emulator or physical device

### Install Dependencies

```bash
flutter pub get
```

### Run The App

```bash
flutter run
```

### Analyze

```bash
flutter analyze
```

### Test

```bash
flutter test
```

## Backup Format

The app currently uses a portable JSON backup format.

Each backup includes:

- people records
- notes
- photo attachment records
- bundled image file bytes
- profile picture references

This makes the backup more portable than copying only the raw SQLite database file.

## Known Notes

- Backup export/import is designed to stay local to the device.
- On Android, backup export relies on native file save handling because direct writes to arbitrary public folders can fail under scoped storage.
- Existing databases are migrated forward automatically when new columns are added.

## Developer

Built for `entropious`, a Filipino full stack developer.

