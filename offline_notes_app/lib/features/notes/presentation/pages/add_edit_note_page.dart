import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_notes_app/app_theme.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_event.dart';
import 'package:uuid/uuid.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;

  const AddEditNotePage({this.note, super.key});

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final FocusNode _bodyFocus = FocusNode();
  bool _isSaving = false;
  bool _hasChanges = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _titleController.addListener(_onChanged);
    _bodyController.addListener(_onChanged);
  }

  void _onChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _titleController.removeListener(_onChanged);
    _bodyController.removeListener(_onChanged);
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title cannot be empty'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    if (!_isEditing) {
      context.read<NotesBloc>().add(
            AddNote(
              NoteModel(
                id: const Uuid().v4(),
                title: title,
                body: body,
                updatedAt: DateTime.now(),
              ),
            ),
          );
    } else {
      context.read<NotesBloc>().add(
            UpdateNote(
              widget.note!.copyWith(
                title: title,
                body: body,
                updatedAt: DateTime.now(),
              ),
            ),
          );
    }

    Navigator.pop(context);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    // If both fields are empty (new note, nothing typed), just pop.
    if (!_isEditing && title.isEmpty && body.isEmpty) return true;
    // If content matches original, just pop.
    if (_isEditing &&
        title == (widget.note?.title ?? '') &&
        body == (widget.note?.body ?? '')) return true;
    return true; // Allow pop — unsaved changes are silently discarded.
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        _isEditing ? AppTheme.noteAccent(widget.note!.id) : AppTheme.accent;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      color: AppTheme.textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Accent dot (note colour indicator)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    // Save / Done button
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _hasChanges ? 1.0 : 0.4,
                      child: TextButton(
                        onPressed: _isSaving ? null : _save,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accent,
                                ),
                              )
                            : Text(_isEditing ? 'Done' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Title ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.25,
                  ),
                  cursorColor: accentColor,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_bodyFocus),
                ),
              ),

              // ── Divider + meta ─────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Divider(),
              ),

              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    _formatDate(widget.note!.updatedAt),
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

              // ── Body ───────────────────────────────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).requestFocus(_bodyFocus),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: TextField(
                      controller: _bodyController,
                      focusNode: _bodyFocus,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        height: 1.6,
                        letterSpacing: -0.1,
                      ),
                      cursorColor: accentColor,
                      decoration: const InputDecoration(
                        hintText: 'Start writing…',
                        hintStyle: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ·  $hour:$min $period';
  }
}
