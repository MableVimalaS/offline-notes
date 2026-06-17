import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';

const _baseUrl = 'https://function-bun-production-b979.up.railway.app';
final _log = Logger();

class NoteRemoteDataSource {
  Future<void> createNote(NoteModel note) async {
    http.Response response = await http.post(
      Uri.parse('$_baseUrl/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(note.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create note ${response.statusCode}');
    } else {
      _log.d('Server: Created ${note.id}');
    }
  }

  Future<void> updateNote(NoteModel note) async {
    http.Response response = await http.put(
      Uri.parse('$_baseUrl/notes/${note.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(note.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update note ${response.statusCode}');
    } else {
      _log.d('Server: Updated ${note.id}');
    }
  }

  Future<void> deleteNote(String noteId) async {
    http.Response response = await http.delete(
      Uri.parse('$_baseUrl/notes/$noteId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete note ${response.statusCode}');
    } else {
      _log.d('Server: Deleted $noteId');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    http.Response response = await http.get(Uri.parse('$_baseUrl/notes'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load notes ${response.statusCode}');
    }
  }
}
