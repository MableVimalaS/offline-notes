import 'package:hive/hive.dart';
import 'package:offline_notes_app/features/notes/services/hive-service.dart';


final notesBox =
    Hive.box<Map>(HiveService.notesBox);

// await notesBox.put(
//   'test',
//   {
//     'title': 'First Note',
//     'body': 'Hello Hive',
//   },
// );

// print(notesBox.get('test'));