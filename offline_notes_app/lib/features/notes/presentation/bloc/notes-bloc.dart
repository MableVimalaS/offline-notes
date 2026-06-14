import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_notes_app/features/notes/data/repositories/contract/note-respository.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-event.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-state.dart';



class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NoteRepository repository;

  NotesBloc({
    required this.repository,
  }) : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<AddNote>(_onAddNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
  }
  Future<void> _onLoadNotes(
  LoadNotes event,
  Emitter<NotesState> emit,
) async {
  emit(NotesLoading());

  try {
    final notes = await repository.getNotes();

print('Loaded notes: ${notes.length}');

    emit(NotesLoaded(notes));
  } catch (e) {
    emit(
      NotesError(e.toString()),
    );
  }
}

Future<void> _onAddNote(
  AddNote event,
  Emitter<NotesState> emit,
) async {
  await repository.addNote(
    event.note,
  );

  add(LoadNotes());
}

Future<void> _onUpdateNote(
  UpdateNote event,
  Emitter<NotesState> emit,
) async {
  await repository.updateNote(
    event.note,
  );

  add(LoadNotes());
}

Future<void> _onDeleteNote(
  DeleteNote event,
  Emitter<NotesState> emit,
) async {
  debugPrint('BLOC DELETE ${event.noteId}');

  await repository.deleteNote(
    event.noteId,
  );

  add(LoadNotes());
}
}

