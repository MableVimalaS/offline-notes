import 'package:offline_notes_app/features/notes/data/enum/notes-enum.dart';

class NoteModel {
  final String id;
  final String title;
  final String body;

  final DateTime updatedAt;
  final DateTime? lastSyncedAt;

  final SyncStatus syncStatus;
  final bool isDeleted;

  const NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pending,
    this.isDeleted = false,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'updatedAt': updatedAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'isDeleted': isDeleted,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      updatedAt: DateTime.parse(json['updatedAt']),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'])
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}