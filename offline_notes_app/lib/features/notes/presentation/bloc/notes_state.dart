import 'package:equatable/equatable.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';

abstract class NotesState extends Equatable {
  const NotesState();
}

class NotesInitial extends NotesState {
  const NotesInitial();

  @override
  List<Object?> get props => [];
}

class NotesLoading extends NotesState {
  const NotesLoading();

  @override
  List<Object?> get props => [];
}

class NotesLoaded extends NotesState {
  final List<NoteModel> notes;

  const NotesLoaded(this.notes);

  @override
  List<Object?> get props => [notes];
}

class NotesError extends NotesState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object?> get props => [message];
}
