import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:offline_notes_app/features/notes/data/repositories/contract/note_repository.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_event.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_state.dart';

final _log = Logger();

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NoteRepository repository;

  NotesBloc({required this.repository}) : super(const NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<AddNote>(_onAddNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<ResolveConflict>(_onResolveConflict);
  }

  Future<void> _onLoadNotes(
    LoadNotes event,
    Emitter<NotesState> emit,
  ) async {
    emit(const NotesLoading());
    try {
      final notes = await repository.getNotes();
      // Sort most-recently-updated first.
      final sorted = [...notes]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _log.d('Loaded ${sorted.length} notes');
      emit(NotesLoaded(sorted));
    } on Exception catch (e) {
      _log.e('Failed to load notes', error: e);
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onAddNote(
    AddNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await repository.addNote(event.note);
    } on Exception catch (e) {
      _log.e('Failed to add note', error: e);
    }
    add(const LoadNotes());
  }

  Future<void> _onUpdateNote(
    UpdateNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await repository.updateNote(event.note);
    } on Exception catch (e) {
      _log.e('Failed to update note', error: e);
    }
    add(const LoadNotes());
  }

  Future<void> _onDeleteNote(
    DeleteNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await repository.deleteNote(event.noteId);
    } on Exception catch (e) {
      _log.e('Failed to delete note ${event.noteId}', error: e);
    }
    add(const LoadNotes());
  }
Future<void> _onResolveConflict(
    ResolveConflict event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await repository.resolveConflict(
        event.noteId,
        keepLocal: event.keepLocal,
      );
    } on Exception catch (e) {
      _log.e('Failed to resolve conflict', error: e);
    }
    add(const LoadNotes());
  }
}