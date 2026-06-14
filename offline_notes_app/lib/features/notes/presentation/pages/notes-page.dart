import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-event.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-state.dart';
import 'package:offline_notes_app/features/notes/presentation/pages/add-edit-note-page.dart';
import 'package:offline_notes_app/features/notes/services/connective-service.dart';
import 'package:offline_notes_app/features/notes/services/sync-service.dart';



class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool isOnline = true;

late StreamSubscription<bool>
    connectivitySubscription;

 @override
void initState() {
  super.initState();

  context.read<NotesBloc>().add(
    LoadNotes(),
  );

  connectivitySubscription =
      ConnectivityService()
          .connectionStream
          .listen((online) async {

    setState(() {
      isOnline = online;
    });

    if (online) {
      await SyncService().sync();

      if (mounted) {
        context.read<NotesBloc>().add(
          LoadNotes(),
        );
      }
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Icon(
              isOnline
                  ? Icons.cloud_done
                  : Icons.cloud_off,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final syncService = SyncService();

              await syncService.sync();

              if (mounted) {
                context.read<NotesBloc>().add(
                      LoadNotes(),
                    );
              }
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditNotePage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is NotesLoaded) {
            if (state.notes.isEmpty) {
              return const Center(
                child: Text('No Notes Yet'),
              );
            }

            return ListView.builder(
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(note.title),

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(note.body),

                        const SizedBox(height: 6),

                        Chip(
                          label: Text(
                            note.syncStatus.name,
                          ),
                        ),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditNotePage(
                                  note: note,
                                ),
                              ),
                            );
                          },
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            context
                                .read<NotesBloc>()
                                .add(
                                  DeleteNote(
                                    note.id,
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          if (state is NotesError) {
            return Center(
              child: Text(
                state.message,
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}