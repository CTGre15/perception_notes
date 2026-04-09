import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/person_models.dart';

class NotesRepository {
  static const MethodChannel _storageChannel = MethodChannel(
    'perception_notes/storage',
  );

  Database? _database;
  Directory? _appDirectory;

  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    _appDirectory = directory;
    final databasePath = p.join(directory.path, 'perception_notes.db');
    _database = await openDatabase(
      databasePath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE people (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            nicknames TEXT NOT NULL DEFAULT '',
            school TEXT NOT NULL DEFAULT '',
            course TEXT NOT NULL DEFAULT '',
            birthday TEXT,
            age INTEGER,
            details TEXT NOT NULL DEFAULT '',
            profile_photo_path TEXT,
            custom_fields TEXT NOT NULL DEFAULT '[]',
            is_pinned INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY(person_id) REFERENCES people(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(person_id) REFERENCES people(id) ON DELETE CASCADE
          )
        ''');
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE people ADD COLUMN profile_photo_path TEXT",
          );
          await db.execute(
            "ALTER TABLE people ADD COLUMN custom_fields TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE people ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "ALTER TABLE notes ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0",
          );
        }
      },
    );
  }

  Database get _db => _database!;
  Directory get _storageRoot => _appDirectory!;

  Future<List<PersonSummary>> fetchPeople() async {
    final peopleRows = await _db.query(
      'people',
      orderBy: 'is_pinned DESC, updated_at DESC, name COLLATE NOCASE ASC',
    );
    return peopleRows.map(PersonSummary.fromMap).toList();
  }

  Future<PersonDetails?> fetchPersonDetails(int personId) async {
    final people = await _db.query(
      'people',
      where: 'id = ?',
      whereArgs: [personId],
      limit: 1,
    );

    if (people.isEmpty) {
      return null;
    }

    final person = PersonRecord.fromMap(people.first);
    final notesRows = await _db.query(
      'notes',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'is_pinned DESC, created_at DESC',
    );
    final photoRows = await _db.query(
      'photos',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'created_at ASC',
    );

    return PersonDetails(
      person: person,
      notes: notesRows.map(NoteEntry.fromMap).toList(),
      photos: photoRows.map(PhotoAttachment.fromMap).toList(),
      primaryPhotoPath: person.profilePhotoPath,
    );
  }

  Future<int> insertPerson(PersonRecord person) {
    return _db.insert('people', person.toMap(includeId: false));
  }

  Future<void> updatePerson(PersonRecord person) async {
    await _db.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<void> togglePersonPinned(int personId, bool isPinned) async {
    await _db.update(
      'people',
      {
        'is_pinned': isPinned ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [personId],
    );
  }

  Future<void> addNote({required int personId, required String content}) async {
    final now = DateTime.now();
    await _db.insert('notes', {
      'person_id': personId,
      'content': content,
      'is_pinned': 0,
      'created_at': now.toIso8601String(),
    });
    await _touchPerson(personId, now);
  }

  Future<void> toggleNotePinned(NoteEntry note, bool isPinned) async {
    await _db.update(
      'notes',
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [note.id],
    );
    await _touchPerson(note.personId, DateTime.now());
  }

  Future<void> deleteNote(int noteId) async {
    final rows = await _db.query(
      'notes',
      columns: ['person_id'],
      where: 'id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    await _db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
    if (rows.isNotEmpty) {
      await _touchPerson(rows.first['person_id'] as int, DateTime.now());
    }
  }

  Future<void> addPhoto(int personId, String sourcePath) async {
    final destinationPath = await _copyIntoAppStorage(
      sourcePath: sourcePath,
      folderName: 'photos',
      filePrefix: 'person_$personId',
    );
    if (destinationPath == null) {
      return;
    }

    final now = DateTime.now();
    await _db.insert('photos', {
      'person_id': personId,
      'path': destinationPath,
      'created_at': now.toIso8601String(),
    });
    await _touchPerson(personId, now);
  }

  Future<void> deletePhoto(PhotoAttachment photo) async {
    await _db.delete('photos', where: 'id = ?', whereArgs: [photo.id]);
    final file = File(photo.path);
    if (file.existsSync()) {
      await file.delete();
    }
    await _touchPerson(photo.personId, DateTime.now());
  }

  Future<void> setProfilePhoto(int personId, String sourcePath) async {
    final rows = await _db.query(
      'people',
      columns: ['profile_photo_path'],
      where: 'id = ?',
      whereArgs: [personId],
      limit: 1,
    );

    final destinationPath = await _copyIntoAppStorage(
      sourcePath: sourcePath,
      folderName: 'profile_photos',
      filePrefix: 'profile_$personId',
    );
    if (destinationPath == null) {
      return;
    }

    final now = DateTime.now();
    await _db.update(
      'people',
      {
        'profile_photo_path': destinationPath,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [personId],
    );

    final oldPath = rows.isEmpty
        ? null
        : rows.first['profile_photo_path'] as String?;
    if (oldPath != null && oldPath.isNotEmpty && oldPath != destinationPath) {
      final oldFile = File(oldPath);
      if (oldFile.existsSync()) {
        await oldFile.delete();
      }
    }
  }

  Future<void> clearProfilePhoto(int personId) async {
    final rows = await _db.query(
      'people',
      columns: ['profile_photo_path'],
      where: 'id = ?',
      whereArgs: [personId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }

    final oldPath = rows.first['profile_photo_path'] as String?;
    await _db.update(
      'people',
      {
        'profile_photo_path': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [personId],
    );

    if (oldPath != null && oldPath.isNotEmpty) {
      final file = File(oldPath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Future<GlobalSearchResult> searchEverything(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const GlobalSearchResult(people: [], notes: []);
    }

    final people = await fetchPeople();
    final matchedPeople = people.where((person) {
      final text = [
        person.name,
        person.nicknames,
        person.school,
        person.course,
        ...person.customFields.map((field) => '${field.label} ${field.value}'),
      ].join(' ').toLowerCase();
      return text.contains(normalized);
    }).toList();

    final peopleRows = await _db.query('people');
    final peopleMap = {
      for (final row in peopleRows)
        row['id'] as int: PersonSummary.fromMap(row),
    };
    final noteRows = await _db.query(
      'notes',
      orderBy: 'is_pinned DESC, created_at DESC',
    );
    final matchedNotes = noteRows
        .map(NoteEntry.fromMap)
        .where((note) => note.content.toLowerCase().contains(normalized))
        .map(
          (note) => MatchedNote(note: note, person: peopleMap[note.personId]!),
        )
        .toList();

    return GlobalSearchResult(people: matchedPeople, notes: matchedNotes);
  }

  Future<String?> exportBackup() async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = 'perception_notes_backup_$timestamp.json';
    String? savePath;
    final payload = await _buildBackupPayload();
    final bytes = Uint8List.fromList(utf8.encode(payload));
    debugPrint('[backup] json payload byte length: ${bytes.length}');

    if (Platform.isAndroid) {
      debugPrint('[backup] using Android create-document export for $fileName');
      try {
        final savedUri = await _storageChannel.invokeMethod<String>(
          'saveBackupBytes',
          {'fileName': fileName, 'bytes': bytes},
        );
        debugPrint('[backup] native export success uri: $savedUri');
        return savedUri;
      } on PlatformException catch (error) {
        debugPrint(
          '[backup] native export failed code=${error.code} message=${error.message} details=${error.details}',
        );
        rethrow;
      }
    }

    final directoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose where to save the backup',
    );
    debugPrint('[backup] picked directory: $directoryPath');
    if (directoryPath == null) {
      debugPrint('[backup] export cancelled before directory selection');
      return null;
    }

    savePath = p.join(directoryPath, fileName);
    debugPrint('[backup] writing file directly to path: $savePath');
    final file = File(savePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(payload, flush: true);
    debugPrint('[backup] direct file export success: $savePath');
    return savePath;
  }

  Future<StorageSummary> getStorageSummary() async {
    final dbFile = File(p.join(_storageRoot.path, 'perception_notes.db'));
    final databaseBytes = dbFile.existsSync() ? await dbFile.length() : 0;
    final imageBytes =
        await _directorySize(Directory(p.join(_storageRoot.path, 'photos'))) +
        await _directorySize(
          Directory(p.join(_storageRoot.path, 'profile_photos')),
        ) +
        await _directorySize(
          Directory(p.join(_storageRoot.path, 'restored_assets')),
        );
    final backupBytes = await _directorySize(
      Directory(p.join(_storageRoot.path, 'backups')),
    );
    return StorageSummary(
      totalBytes: databaseBytes + imageBytes + backupBytes,
      databaseBytes: databaseBytes,
      imageBytes: imageBytes,
      backupBytes: backupBytes,
    );
  }

  Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) {
      return false;
    }

    final file = File(path);
    if (!file.existsSync()) {
      return false;
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      debugPrint('[backup] import failed: decoded payload is not a map');
      return false;
    }

    final assetMap = <String, String>{};
    final assetEntries = (decoded['assets'] as List?) ?? const [];
    debugPrint('[backup] import asset count: ${assetEntries.length}');
    for (final item in assetEntries) {
      final map = Map<String, dynamic>.from(item as Map);
      final originalPath = map['originalPath']?.toString() ?? '';
      final baseName = map['baseName']?.toString() ?? 'asset.bin';
      final bytes = base64Decode(map['bytes']?.toString() ?? '');
      final restoredPath = p.join(
        _storageRoot.path,
        'restored_assets',
        '${DateTime.now().millisecondsSinceEpoch}_$baseName',
      );
      final restoredFile = File(restoredPath);
      restoredFile.parent.createSync(recursive: true);
      await restoredFile.writeAsBytes(bytes, flush: true);
      assetMap[originalPath] = restoredPath;
    }

    await _db.transaction((txn) async {
      await txn.delete('photos');
      await txn.delete('notes');
      await txn.delete('people');

      for (final raw in (decoded['people'] as List?) ?? const []) {
        final row = Map<String, Object?>.from(raw as Map);
        final original = row['profile_photo_path'] as String?;
        row['profile_photo_path'] = assetMap[original] ?? original;
        await txn.insert('people', row);
      }
      for (final raw in (decoded['notes'] as List?) ?? const []) {
        await txn.insert('notes', Map<String, Object?>.from(raw as Map));
      }
      for (final raw in (decoded['photos'] as List?) ?? const []) {
        final row = Map<String, Object?>.from(raw as Map);
        final original = row['path'] as String?;
        row['path'] = assetMap[original] ?? original;
        await txn.insert('photos', row);
      }
    });

    return true;
  }

  Future<void> deletePerson(int personId) async {
    final details = await fetchPersonDetails(personId);
    await _db.delete('people', where: 'id = ?', whereArgs: [personId]);
    if (details == null) {
      return;
    }

    final profilePath = details.person.profilePhotoPath;
    if (profilePath != null && profilePath.isNotEmpty) {
      final profileFile = File(profilePath);
      if (profileFile.existsSync()) {
        await profileFile.delete();
      }
    }

    for (final photo in details.photos) {
      final file = File(photo.path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Future<void> _touchPerson(int personId, DateTime time) async {
    await _db.update(
      'people',
      {'updated_at': time.toIso8601String()},
      where: 'id = ?',
      whereArgs: [personId],
    );
  }

  Future<String?> importPhotoFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  Future<String?> _copyIntoAppStorage({
    required String sourcePath,
    required String folderName,
    required String filePrefix,
  }) async {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      return null;
    }

    final directory = Directory(p.join(_storageRoot.path, folderName));
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final extension = p.extension(sourcePath);
    final destinationPath = p.join(
      directory.path,
      '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await file.copy(destinationPath);
    return destinationPath;
  }

  Future<int> _directorySize(Directory directory) async {
    if (!directory.existsSync()) {
      return 0;
    }

    var total = 0;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<String> _buildBackupPayload() async {
    final people = await _db.query('people');
    final notes = await _db.query('notes');
    final photos = await _db.query('photos');
    final assets = <Map<String, String>>[];

    Future<void> addAsset(String? path) async {
      if (path == null || path.isEmpty) {
        return;
      }
      final file = File(path);
      if (!file.existsSync()) {
        debugPrint('[backup] skipping missing asset path: $path');
        return;
      }
      final bytes = await file.readAsBytes();
      assets.add({
        'originalPath': path,
        'baseName': p.basename(path),
        'bytes': base64Encode(bytes),
      });
      debugPrint('[backup] bundled asset path=$path bytes=${bytes.length}');
    }

    debugPrint(
      '[backup] building payload people=${people.length} notes=${notes.length} photos=${photos.length}',
    );

    for (final row in people) {
      await addAsset(row['profile_photo_path'] as String?);
    }
    for (final row in photos) {
      await addAsset(row['path'] as String?);
    }

    debugPrint('[backup] final bundled asset count: ${assets.length}');
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'people': people,
      'notes': notes,
      'photos': photos,
      'assets': assets,
    });
  }
}
