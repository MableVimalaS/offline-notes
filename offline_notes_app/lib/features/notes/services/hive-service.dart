import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String notesBox = 'notes_box';
  static const String syncQueueBox = 'sync_queue_box';

  static Future<void> init() async {
    await Hive.initFlutter();
//     final box = Hive.box(HiveService.notesBox);

// print('Box length: ${box.length}');
// print(box.values.toList());

    await Hive.openBox<Map>(notesBox);

    await Hive.openBox<Map>(syncQueueBox);
  }
}