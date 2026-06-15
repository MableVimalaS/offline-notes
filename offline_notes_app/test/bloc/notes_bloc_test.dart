import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes_app/features/notes/data/models/data_sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/data/repositories/contract/note_repository.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_event.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_state.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

final _note = NoteModel(
  id: 'test-id',
  title: 'Test Note',
  body: 'Test body',
  updatedAt: DateTime(2024),
);

void main() {
  late MockNoteRepository repository;

  setUp(() {
    repository = MockNoteRepository();
    registerFallbackValue(_note);
  });

  group('NotesBloc', () {
    group('LoadNotes', () {
      blocTest<NotesBloc, NotesState>(
        'emits [NotesLoading, NotesLoaded] with notes sorted by updatedAt desc',
        build: () {
          final older = NoteModel(
            id: 'older',
            title: 'Older',
            body: '',
            updatedAt: DateTime(2024, 1, 1),
          );
          final newer = NoteModel(
            id: 'newer',
            title: 'Newer',
            body: '',
            updatedAt: DateTime(2024, 6, 1),
          );
          when(() => repository.getNotes())
              .thenAnswer((_) async => [older, newer]);
          return NotesBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const LoadNotes()),
        expect: () {
          final older = NoteModel(
            id: 'older',
            title: 'Older',
            body: '',
            updatedAt: DateTime(2024, 1, 1),
          );
          final newer = NoteModel(
            id: 'newer',
            title: 'Newer',
            body: '',
            updatedAt: DateTime(2024, 6, 1),
          );
          return [
            const NotesLoading(),
            NotesLoaded([newer, older]),
          ];
        },
      );

      blocTest<NotesBloc, NotesState>(
        'emits [NotesLoading, NotesLoaded([])] when repository returns empty list',
        build: () {
          when(() => repository.getNotes()).thenAnswer((_) async => []);
          return NotesBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const LoadNotes()),
        expect: () => [const NotesLoading(), const NotesLoaded([])],
      );

      blocTest<NotesBloc, NotesState>(
        'emits [NotesLoading, NotesError] when repository throws',
        build: () {
          when(() => repository.getNotes())
              .thenThrow(Exception('DB failure'));
          return NotesBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const LoadNotes()),
        expect: () => [
          const NotesLoading(),
          isA<NotesError>(),
        ],
      );
    });

    group('AddNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls repository.addNote then reloads',
        build: () {
          when(() => repository.addNote(any())).thenAnswer((_) async {});
          when(() => repository.getNotes()).thenAnswer((_) async => [_note]);
          return NotesBloc(repository: repository);
        },
        act: (bloc) => bloc.add(AddNote(_note)),
        verify: (_) {
          verify(() => repository.addNote(_note)).called(1);
          verify(() => repository.getNotes()).called(1);
        },
      );
    });

    group('UpdateNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls repository.updateNote then reloads',
        build: () {
          when(() => repository.updateNote(any())).thenAnswer((_) async {});
          when(() => repository.getNotes()).thenAnswer((_) async => [_note]);
          return NotesBloc(repository: repository);
        },
        act: (bloc) => bloc.add(UpdateNote(_note)),
        verify: (_) {
          verify(() => repository.updateNote(_note)).called(1);
          verify(() => repository.getNotes()).called(1);
        },
      );
    });

    group('DeleteNote', () {
      blocTest<NotesBloc, NotesState>(
        'calls repository.deleteNote then reloads',
        build: () {
          when(() => repository.deleteNote(any())).thenAnswer((_) async {});
          when(() => repository.getNotes()).thenAnswer((_) async => []);
          return NotesBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const DeleteNote('test-id')),
        verify: (_) {
          verify(() => repository.deleteNote('test-id')).called(1);
          verify(() => repository.getNotes()).called(1);
        },
      );
    });
  });
}
