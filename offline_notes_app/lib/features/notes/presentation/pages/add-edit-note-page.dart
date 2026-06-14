import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_notes_app/features/notes/data/models/note-model.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes-event.dart';
import 'package:uuid/uuid.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;

  const AddEditNotePage({this.note, super.key});

  @override
  State<AddEditNotePage> createState() =>
      _AddEditNotePageState();

}

class _AddEditNotePageState extends State<AddEditNotePage> {
  @override
  Widget build(BuildContext context) {
          final titleController =
    TextEditingController();

final bodyController =
    TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Note'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
              ),
            ),
           ElevatedButton(
  onPressed: () {

    if (widget.note == null) {

      context.read<NotesBloc>().add(
        AddNote(
          NoteModel(
            id: const Uuid().v4(),
            title: titleController.text,
            body: bodyController.text,
            updatedAt: DateTime.now(),
          ),
        ),
      );

    } else {

      context.read<NotesBloc>().add(
        UpdateNote(
          widget.note!.copyWith(
            title: titleController.text,
            body: bodyController.text,
            updatedAt: DateTime.now(),
          ),
        ),
      );
    }

    Navigator.pop(context);
  },
  child: Text(
    widget.note == null
        ? 'Save'
        : 'Update',
  ),
)
          ],
      
        ),
        
      ),
      
    );}
}