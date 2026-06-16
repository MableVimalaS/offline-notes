import 'package:equatable/equatable.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();
}

class LoadNotes extends NotesEvent {
  const LoadNotes();

  @override
  List<Object?> get props => [];
}

class AddNote extends NotesEvent {
  final NoteModel note;

  const AddNote(this.note);

  @override
  List<Object?> get props => [note];
}

class UpdateNote extends NotesEvent {
  final NoteModel note;

  const UpdateNote(this.note);

  @override
  List<Object?> get props => [note];
}

class DeleteNote extends NotesEvent {
  final String noteId;

  const DeleteNote(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

class ResolveConflict extends NotesEvent {
  final String noteId;
  final bool keepLocal;

  const ResolveConflict({required this.noteId, required this.keepLocal});

  @override
  List<Object?> get props => [noteId, keepLocal];
}