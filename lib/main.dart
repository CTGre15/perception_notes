import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'src/app.dart';
import 'src/services/app_lock_service.dart';
import 'src/services/notes_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final repository = NotesRepository();
  final lockService = AppLockService();
  await repository.initialize();
  await lockService.initialize();

  runApp(PerceptionNotesApp(repository: repository, lockService: lockService));
}
