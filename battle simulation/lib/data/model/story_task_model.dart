import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:todo_list/domain/entities/story_task.dart';

class StoryTaskModel {
  final String id;
  final String storyId;
  final String title;
  final String summary;
  final List<Map<String, dynamic>> summaryDocument;
  final String? summaryDocumentPath;
  final Timestamp? summaryUpdatedAt;
  final int? summaryDocumentVersion;
  final String status;
  final String? ownerUserId;
  final String priority;
  final int orderIndex;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const StoryTaskModel({
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

  factory StoryTaskModel.fromMap(
    String id,
    String storyId,
    Map<String, dynamic> map,
  ) {
    final String summaryPreview =
        map['summaryPreview'] as String? ?? map['summary'] as String? ?? '';
    return StoryTaskModel(
      id: id,
      storyId: storyId,
      title: map['title'] as String? ?? '',
      summary: summaryPreview,
      summaryDocument: StorySummaryDocument.fromFirestore(
        map['summaryDocument'],
        fallbackPlainText: summaryPreview,
      ),
      summaryDocumentPath: map['summaryDocumentPath'] as String?,
      summaryUpdatedAt: map['summaryUpdatedAt'] as Timestamp?,
      summaryDocumentVersion: (map['summaryDocumentVersion'] as num?)?.toInt(),
      status: map['status'] as String? ?? StoryTaskStatus.todo.firestoreValue,
      ownerUserId: map['ownerUserId'] as String?,
      priority:
          map['priority'] as String? ?? StoryPriority.medium.firestoreValue,
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  factory StoryTaskModel.fromEntity(StoryTaskEntity entity) {
    return StoryTaskModel(
      id: entity.id,
      storyId: entity.storyId,
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
      orderIndex: entity.orderIndex,
      createdAt: entity.createdAt == null
          ? null
          : Timestamp.fromDate(entity.createdAt!),
      updatedAt: entity.updatedAt == null
          ? null
          : Timestamp.fromDate(entity.updatedAt!),
    );
  }

  StoryTaskEntity toEntity() {
    return StoryTaskEntity(
      id: id,
      storyId: storyId,
      title: title,
      summary: summary,
      summaryDocument: StorySummaryDocument.clone(summaryDocument),
      summaryDocumentPath: summaryDocumentPath,
      summaryUpdatedAt: summaryUpdatedAt?.toDate(),
      summaryDocumentVersion: summaryDocumentVersion,
      status: StoryTaskStatusX.fromFirestore(status),
      ownerUserId: ownerUserId,
      priority: StoryPriorityX.fromFirestore(priority),
      orderIndex: orderIndex,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'summaryPreview': summary,
      'summary': summary,
      'summaryDocumentPath': summaryDocumentPath,
      'summaryUpdatedAt': summaryUpdatedAt,
      'summaryDocumentVersion': summaryDocumentVersion,
      'status': status,
      'ownerUserId': ownerUserId,
      'priority': priority,
      'orderIndex': orderIndex,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
