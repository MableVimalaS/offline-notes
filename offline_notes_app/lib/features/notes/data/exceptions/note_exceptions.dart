class HiveInitializationException implements Exception {
  final String message;
  const HiveInitializationException(this.message);

  @override
  String toString() => 'HiveInitializationException: $message';
}

class NoteNotFoundException implements Exception {
  final String noteId;
  const NoteNotFoundException(this.noteId);

  @override
  String toString() => 'Note not found: $noteId';
}

class SyncFailedException implements Exception {
  final String message;
  final Object? cause;
  const SyncFailedException(this.message, {this.cause});

  @override
  String toString() => 'SyncFailedException: $message';
}
