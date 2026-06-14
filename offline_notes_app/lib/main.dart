import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_notes_app/features/notes/data/local/add-note.dart';
import 'package:offline_notes_app/features/notes/data/models/note-model.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/pages/notes-page.dart';
import 'package:offline_notes_app/features/notes/services/hive-service.dart';
import 'package:offline_notes_app/features/notes/data/repositories/implementation/note-repository-imple.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  final localDataSource =
    NoteLocalDataSourceImpl();

final repository =
    NoteRepositoryImpl(
  localDataSource: localDataSource,
);

  runApp(
     BlocProvider(
    create: (_) => NotesBloc(
      repository: repository,
    ),
    child: const MyApp(),
  ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
       debugShowCheckedModeBanner: false,
     home: const NotesPage(),
    );
  }
}