import 'package:hive_flutter/hive_flutter.dart';
import 'package:offline_notes_app/features/notes/data/exceptions/note_exceptions.dart';

class HiveService {
  static const String notesBox = 'notes_box';
  static const String syncQueueBox = 'sync_queue_box';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox<Map>(notesBox);
      await Hive.openBox<Map>(syncQueueBox);
    } catch (e) {
      throw HiveInitializationException(
        'Failed to initialize local storage: $e',
      );
    }
  }
}
