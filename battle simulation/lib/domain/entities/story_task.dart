import 'package:todo_list/domain/entities/story.dart';

enum StoryTaskStatus { todo, inProgress, done }

extension StoryTaskStatusX on StoryTaskStatus {
  String get firestoreValue => switch (this) {
    StoryTaskStatus.todo => 'todo',
    StoryTaskStatus.inProgress => 'in_progress',
    StoryTaskStatus.done => 'done',
  };

  String get label => switch (this) {
    StoryTaskStatus.todo => 'Todo',
    StoryTaskStatus.inProgress => 'In Progress',
    StoryTaskStatus.done => 'Done',
  };

  static StoryTaskStatus fromFirestore(String? value) => switch (value) {
    'in_progress' => StoryTaskStatus.inProgress,
    'done' => StoryTaskStatus.done,
    _ => StoryTaskStatus.todo,
  };
}

class StoryTaskEntity {
  final String id;
  final String storyId;
  final String title;
  final String summary;
  final List<Map<String, dynamic>> summaryDocument;
  final String? summaryDocumentPath;
  final DateTime? summaryUpdatedAt;
  final int? summaryDocumentVersion;
  final StoryTaskStatus status;
  final String? ownerUserId;
  final StoryPriority priority;
  final int orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoryTaskEntity({
    required this.id,
    required this.storyId,
    required this.title,
    required this.summary,
    required this.summaryDocument,
    required this.summaryDocumentPath,
    required this.summaryUpdatedAt,
    required this.summaryDocumentVersion,
    required this.status,
    required this.ownerUserId,
    required this.priority,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  StoryTaskEntity copyWith({
    String? id,
    String? storyId,
    String? title,
    String? summary,
    List<Map<String, dynamic>>? summaryDocument,
    Object? summaryDocumentPath = _sentinel,
    Object? summaryUpdatedAt = _sentinel,
    Object? summaryDocumentVersion = _sentinel,
    StoryTaskStatus? status,
    Object? ownerUserId = _sentinel,
    StoryPriority? priority,
    int? orderIndex,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return StoryTaskEntity(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      summaryDocument: summaryDocument ?? this.summaryDocument,
      summaryDocumentPath: identical(summaryDocumentPath, _sentinel)
          ? this.summaryDocumentPath
          : summaryDocumentPath as String?,
      summaryUpdatedAt: identical(summaryUpdatedAt, _sentinel)
          ? this.summaryUpdatedAt
          : summaryUpdatedAt as DateTime?,
      summaryDocumentVersion: identical(summaryDocumentVersion, _sentinel)
          ? this.summaryDocumentVersion
          : summaryDocumentVersion as int?,
      status: status ?? this.status,
      ownerUserId: identical(ownerUserId, _sentinel)
          ? this.ownerUserId
          : ownerUserId as String?,
      priority: priority ?? this.priority,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: identical(createdAt, _sentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _sentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  static const Object _sentinel = Object();
}
