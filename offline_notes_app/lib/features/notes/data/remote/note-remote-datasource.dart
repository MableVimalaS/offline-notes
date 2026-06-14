import 'dart:async';

import 'package:offline_notes_app/features/notes/data/models/note-model.dart';


class NoteRemoteDataSource {
  Future<void> createNote(
    NoteModel note,
  ) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    print(
      'Server: Created ${note.id}',
    );
  }

  Future<void> updateNote(
    NoteModel note,
  ) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    print(
      'Server: Updated ${note.id}',
    );
  }

  Future<void> deleteNote(
    String noteId,
  ) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    print(
      'Server: Deleted $noteId',
    );
  }
}