import 'package:offline_notes_app/features/notes/data/enum/operation_enum.dart';

class SyncOperation {
  final String noteId;
  final OperationType operationType;
  final DateTime createdAt;

  const SyncOperation({
    required this.noteId,
    required this.operationType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'operationType': operationType.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      noteId: json['noteId'] as String,
      operationType: OperationType.values.firstWhere(
        (e) => e.name == json['operationType'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
