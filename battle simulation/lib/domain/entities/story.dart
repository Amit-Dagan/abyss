enum StoryStatus { backlog, inProgress, review, done }

extension StoryStatusX on StoryStatus {
  String get firestoreValue => switch (this) {
    StoryStatus.backlog => 'backlog',
    StoryStatus.inProgress => 'in_progress',
    StoryStatus.review => 'review',
    StoryStatus.done => 'done',
  };

  String get label => switch (this) {
    StoryStatus.backlog => 'Backlog',
    StoryStatus.inProgress => 'In Progress',
    StoryStatus.review => 'Review',
    StoryStatus.done => 'Done',
  };

  static StoryStatus fromFirestore(String? value) => switch (value) {
    'in_progress' => StoryStatus.inProgress,
    'review' => StoryStatus.review,
    'done' => StoryStatus.done,
    _ => StoryStatus.backlog,
  };
}

enum StoryPriority { low, medium, high, critical }

extension StoryPriorityX on StoryPriority {
  String get firestoreValue => switch (this) {
    StoryPriority.low => 'low',
    StoryPriority.medium => 'medium',
    StoryPriority.high => 'high',
    StoryPriority.critical => 'critical',
  };

  String get label => switch (this) {
    StoryPriority.low => 'Low',
    StoryPriority.medium => 'Medium',
    StoryPriority.high => 'High',
    StoryPriority.critical => 'Critical',
  };

  static StoryPriority fromFirestore(String? value) => switch (value) {
    'low' => StoryPriority.low,
    'high' => StoryPriority.high,
    'critical' => StoryPriority.critical,
    _ => StoryPriority.medium,
  };
}

class StoryEntity {
  final String id;
  final String title;
  final String summary;
  final List<Map<String, dynamic>> summaryDocument;
  final String? summaryDocumentPath;
  final DateTime? summaryUpdatedAt;
  final int? summaryDocumentVersion;
  final StoryStatus status;
  final String? ownerUserId;
  final StoryPriority priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoryEntity({
    required this.id,
    required this.title,
    required this.summary,
    required this.summaryDocument,
    required this.summaryDocumentPath,
    required this.summaryUpdatedAt,
    required this.summaryDocumentVersion,
    required this.status,
    required this.ownerUserId,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  StoryEntity copyWith({
    String? id,
    String? title,
    String? summary,
    List<Map<String, dynamic>>? summaryDocument,
    Object? summaryDocumentPath = _sentinel,
    Object? summaryUpdatedAt = _sentinel,
    Object? summaryDocumentVersion = _sentinel,
    StoryStatus? status,
    Object? ownerUserId = _sentinel,
    StoryPriority? priority,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return StoryEntity(
      id: id ?? this.id,
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
