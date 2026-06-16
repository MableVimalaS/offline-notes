import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_notes_app/app_theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:offline_notes_app/features/notes/data/enum/notes_enum.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_event.dart';
import 'package:offline_notes_app/features/notes/presentation/bloc/notes_state.dart';
import 'package:offline_notes_app/features/notes/presentation/pages/add_edit_note_page.dart';
import 'package:offline_notes_app/features/notes/services/connectivity_service.dart';
import 'package:offline_notes_app/features/notes/services/sync_service.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _isSyncing = false;
  String _searchQuery = '';
  late final StreamSubscription<bool> _connectivitySub;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _syncAnimController;

  @override
  void initState() {
    super.initState();
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    context.read<NotesBloc>().add(const LoadNotes());
    _connectivitySub =
        ConnectivityService().connectionStream.listen((online) async {
      setState(() => _isOnline = online);
      if (online) await _runSync();
    });
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _searchController.dispose();
    _syncAnimController.dispose();
    super.dispose();
  }

  Future<void> _runSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    _syncAnimController.repeat();
    try {
      await SyncService().sync();
    } finally {
      if (mounted) {
        _syncAnimController.stop();
        _syncAnimController.reset();
        setState(() => _isSyncing = false);
        context.read<NotesBloc>().add(const LoadNotes());
      }
    }
  }

  void _openNote({NoteModel? note}) {
    if(note != null && note.syncStatus == SyncStatus.conflict) {
     _showConflictDialog(note);
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => AddEditNotePage(note: note),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _deleteNote(NoteModel note) {
    context.read<NotesBloc>().add(DeleteNote(note.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Note deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => context.read<NotesBloc>().add(AddNote(note)),
          ),
        ),
      );
  }

  void _showNoteOptions(NoteModel note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteOptionsSheet(
        note: note,
        onEdit: () {
          Navigator.pop(context);
          _openNote(note: note);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteNote(note);
        },
      ),
    );
  }

  List<NoteModel> _filtered(List<NoteModel> notes) {
    if (_searchQuery.isEmpty) return notes;
    final q = _searchQuery.toLowerCase();
    return notes
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNote(),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'New Note',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          final noteCount = state is NotesLoaded ? state.notes.length : 0;
          final visible =
              state is NotesLoaded ? _filtered(state.notes) : <NoteModel>[];

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // ── Header ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _Header(
                    noteCount: noteCount,
                    isOnline: _isOnline,
                    isSyncing: _isSyncing,
                    syncAnimController: _syncAnimController,
                    onSync: _runSync,
                  ),
                ),

                // ── Search bar ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── States ───────────────────────────────────────────────
                if (state is NotesLoading)
                  const _ShimmerGrid()
                else if (state is NotesError)
                  SliverFillRemaining(child: _ErrorView(message: state.message))
                else if (state is NotesLoaded && visible.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyView(isFiltering: _searchQuery.isNotEmpty),
                  )
                else if (state is NotesLoaded)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => _NoteCard(
                          note: visible[index],
                          onTap: () => _openNote(note: visible[index]),
                          onLongPress: () => _showNoteOptions(visible[index]),
                        )
                            .animate(delay: Duration(milliseconds: index * 60))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOut),
                        childCount: visible.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 164,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
 void _showConflictDialog(NoteModel note) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text(
          'Conflict Detected',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This note was edited on the server while you were offline.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _conflictVersion(
              label: 'Your Version',
              title: note.title,
              body: note.body,
            ),
            const SizedBox(height: 12),
            _conflictVersion(
              label: 'Server Version',
              title: note.serverTitle ?? '',
              body: note.serverBody ?? '',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotesBloc>().add(
                    ResolveConflict(noteId: note.id, keepLocal: false),
                  );
            },
            child: const Text(
              'Use Server Version',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotesBloc>().add(
                    ResolveConflict(noteId: note.id, keepLocal: true),
                  );
            },
            child: const Text('Keep Mine'),
          ),
        ],
      ),
    );
  }

  Widget _conflictVersion({
    required String label,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int noteCount;
  final bool isOnline;
  final bool isSyncing;
  final AnimationController syncAnimController;
  final VoidCallback onSync;

  const _Header({
    required this.noteCount,
    required this.isOnline,
    required this.isSyncing,
    required this.syncAnimController,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Notes',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  noteCount == 0
                      ? 'No notes yet'
                      : '$noteCount note${noteCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Connectivity + sync row
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  key: ValueKey(isOnline),
                  color: isOnline
                      ? const Color(0xFF30D158)
                      : AppTheme.textTertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              RotationTransition(
                turns: syncAnimController,
                child: IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 22),
                  onPressed: isSyncing ? null : onSync,
                  color: isSyncing ? AppTheme.accent : AppTheme.textSecondary,
                  tooltip: 'Sync',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search notes…',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.search_rounded, size: 20, color: AppTheme.textTertiary),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.noteAccent(note.id);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured accent stripe
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (note.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          _timeAgo(note.updatedAt),
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        if (note.syncStatus == SyncStatus.pending) ...[
                          const Spacer(),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.pendingDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      if(note.syncStatus == SyncStatus.conflict) ...[
                          const Spacer(),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year % 100}';
  }
}

class _EmptyView extends StatelessWidget {
  final bool isFiltering;

  const _EmptyView({required this.isFiltering});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/animations/Empty.json',
                fit: BoxFit.contain,
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 28),
            Text(
              isFiltering ? 'No matches found' : 'No notes yet',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 400.ms)
                .slideY(begin: 0.15, end: 0, delay: 600.ms, duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? 'Try a different search term'
                  : 'Tap New Note to write your first one',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            )
                .animate()
                .fadeIn(delay: 750.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  context.read<NotesBloc>().add(const LoadNotes()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteOptionsSheet extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteOptionsSheet({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.noteAccent(note.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + note title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _SheetAction(
            icon: Icons.edit_outlined,
            label: 'Edit note',
            iconColor: AppTheme.textPrimary,
            textColor: AppTheme.textPrimary,
            onTap: onEdit,
          ),
          const Divider(indent: 56),
          _SheetAction(
            icon: Icons.delete_outline_rounded,
            label: 'Delete note',
            iconColor: AppTheme.error,
            textColor: AppTheme.error,
            onTap: onDelete,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shimmer loading ───────────────────────────────────────────────────────────
// Shown while notes are being read from Hive on first load.
// Matches the exact same grid layout as the real note cards.

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Shimmer.fromColors(
            baseColor: AppTheme.surface,
            highlightColor: AppTheme.surfaceVariant,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          childCount: 6,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 164,
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
