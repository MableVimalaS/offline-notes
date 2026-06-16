import 'package:equatable/equatable.dart';
import 'package:offline_notes_app/features/notes/data/enum/notes_enum.dart';

class NoteModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;
  final String? serverTitle;
  final String? serverBody;
  final DateTime? serverUpdatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pending,
    this.isDeleted = false,
    this.serverTitle,
    this.serverBody,
    this.serverUpdatedAt,
  });
static const _keep = Object();
  NoteModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    Object? serverTitle = _keep,
    Object? serverBody = _keep,
    Object? serverUpdatedAt = _keep,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      serverTitle: serverTitle == _keep ? this.serverTitle : serverTitle as String?,
      serverBody: serverBody == _keep ? this.serverBody : serverBody as String?,
      serverUpdatedAt: serverUpdatedAt == _keep ? this.serverUpdatedAt : serverUpdatedAt as DateTime?,
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
      'serverTitle': serverTitle,
      'serverBody': serverBody,
      'serverUpdatedAt': serverUpdatedAt?.toIso8601String(),
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      isDeleted: json['isDeleted'] as bool? ?? false,
      serverTitle: json['serverTitle'] as String?,
      serverBody: json['serverBody'] as String?,
      serverUpdatedAt: json['serverUpdatedAt'] != null
          ? DateTime.parse(json['serverUpdatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        updatedAt,
        lastSyncedAt,
        syncStatus,
        isDeleted,
        serverTitle,
        serverBody,
        serverUpdatedAt,
      ];

  void operator [](String other) {}
}
