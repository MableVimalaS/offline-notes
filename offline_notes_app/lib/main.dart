import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_notes_app/app_theme.dart';
import 'package:offline_notes_app/features/notes/data/exceptions/note_exceptions.dart';
import 'package:offline_notes_app/features/notes/data/local/add_note.dart';
import 'package:offline_notes_app/features/notes/data/repositories/implementation/note_repository_impl.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/pages/notes_page.dart';
import 'package:offline_notes_app/features/notes/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await _runApplication();
}

Future<void> _runApplication() async {
  try {
    await HiveService.init();

    final localDataSource = NoteLocalDataSourceImpl();
    final repository = NoteRepositoryImpl(localDataSource: localDataSource);

    runApp(
      BlocProvider(
        create: (_) => NotesBloc(repository: repository),
        child: const MyApp(),
      ),
    );
  } on HiveInitializationException catch (error) {
    runApp(StartupErrorApp(message: error.message, onRetry: _runApplication));
  } catch (error) {
    runApp(
      StartupErrorApp(
        message: 'Unable to start Offline Notes: $error',
        onRetry: _runApplication,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const NotesPage(),
    );
  }
}

class StartupErrorApp extends StatefulWidget {
  final String message;
  final Future<void> Function() onRetry;

  const StartupErrorApp({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await widget.onRetry();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isRetrying ? null : _retry,
                  icon: _isRetrying
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
