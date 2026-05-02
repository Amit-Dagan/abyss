import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';

class StoryModel {
  final String id;
  final String title;
  final String summary;
  final List<Map<String, dynamic>> summaryDocument;
  final String? summaryDocumentPath;
  final Timestamp? summaryUpdatedAt;
  final int? summaryDocumentVersion;
  final String status;
  final String? ownerUserId;
  final String priority;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const StoryModel({
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

  factory StoryModel.fromMap(String id, Map<String, dynamic> map) {
    final String summaryPreview =
        map['summaryPreview'] as String? ?? map['summary'] as String? ?? '';
    return StoryModel(
      id: id,
      title: map['title'] as String? ?? '',
      summary: summaryPreview,
      summaryDocument: StorySummaryDocument.fromFirestore(
        map['summaryDocument'],
        fallbackPlainText: summaryPreview,
      ),
      summaryDocumentPath: map['summaryDocumentPath'] as String?,
      summaryUpdatedAt: map['summaryUpdatedAt'] as Timestamp?,
      summaryDocumentVersion: (map['summaryDocumentVersion'] as num?)?.toInt(),
      status: map['status'] as String? ?? StoryStatus.backlog.firestoreValue,
      ownerUserId: map['ownerUserId'] as String?,
      priority:
          map['priority'] as String? ?? StoryPriority.medium.firestoreValue,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  factory StoryModel.fromEntity(StoryEntity entity) {
    return StoryModel(
      id: entity.id,
      title: entity.title,
      summary: entity.summary,
      summaryDocument: StorySummaryDocument.clone(entity.summaryDocument),
      summaryDocumentPath: entity.summaryDocumentPath,
      summaryUpdatedAt: entity.summaryUpdatedAt == null
          ? null
          : Timestamp.fromDate(entity.summaryUpdatedAt!),
      summaryDocumentVersion: entity.summaryDocumentVersion,
      status: entity.status.firestoreValue,
      ownerUserId: entity.ownerUserId,
      priority: entity.priority.firestoreValue,
      createdAt: entity.createdAt == null
          ? null
          : Timestamp.fromDate(entity.createdAt!),
      updatedAt: entity.updatedAt == null
          ? null
          : Timestamp.fromDate(entity.updatedAt!),
    );
  }

  StoryEntity toEntity() {
    return StoryEntity(
      id: id,
      title: title,
      summary: summary,
      summaryDocument: StorySummaryDocument.clone(summaryDocument),
      summaryDocumentPath: summaryDocumentPath,
      summaryUpdatedAt: summaryUpdatedAt?.toDate(),
      summaryDocumentVersion: summaryDocumentVersion,
      status: StoryStatusX.fromFirestore(status),
      ownerUserId: ownerUserId,
      priority: StoryPriorityX.fromFirestore(priority),
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'summaryPreview': summary,
      'summary': summary,
      'summaryDocument': StorySummaryDocument.clone(summaryDocument),
      'summaryDocumentPath': summaryDocumentPath,
      'summaryUpdatedAt': summaryUpdatedAt,
      'summaryDocumentVersion': summaryDocumentVersion,
      'status': status,
      'ownerUserId': ownerUserId,
      'priority': priority,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
