import 'dart:typed_data';

import 'package:todo_list/data/repo/planning_repo_impl/story_summary_document_converter.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:todo_list/domain/entities/story_task.dart';
import 'package:todo_list/domain/repo/story_summary_document_repository.dart';

class LocalStorySummaryDocumentRepository
    implements StorySummaryDocumentRepository {
  final StorySummaryDocumentConverter _converter;
  final Map<String, List<Map<String, dynamic>>> _documents =
      <String, List<Map<String, dynamic>>>{};

  LocalStorySummaryDocumentRepository({
    StorySummaryDocumentConverter? converter,
  }) : _converter = converter ?? const StorySummaryDocumentConverter();

  @override
  Future<List<Map<String, dynamic>>> loadSummaryDocument(
    StoryEntity story,
  ) async {
    final List<Map<String, dynamic>>? stored =
        _documents[StorySummaryDocumentRepository.pathForStoryId(story.id)];
    if (stored != null) {
      return StorySummaryDocument.clone(stored);
    }
    if (story.summaryDocument.isNotEmpty) {
      return StorySummaryDocument.clone(story.summaryDocument);
    }
    return StorySummaryDocument.fromPlainText(story.summary);
  }

  @override
  Future<List<Map<String, dynamic>>> loadTaskSummaryDocument(
    StoryTaskEntity task,
  ) async {
    final List<Map<String, dynamic>>? stored =
        _documents[StorySummaryDocumentRepository.pathForTaskId(
          task.storyId,
          task.id,
        )];
    if (stored != null) {
      return StorySummaryDocument.clone(stored);
    }
    if (task.summaryDocument.isNotEmpty) {
      return StorySummaryDocument.clone(task.summaryDocument);
    }
    return StorySummaryDocument.fromPlainText(task.summary);
  }

  @override
  Future<StorySummarySaveResult> saveSummaryDocument({
    required String storyId,
    required List<Map<String, dynamic>> document,
  }) async {
    final String path = StorySummaryDocumentRepository.pathForStoryId(storyId);
    final DateTime updatedAt = DateTime.now();
    _documents[path] = StorySummaryDocument.clone(document);
    return StorySummarySaveResult(
      path: path,
      updatedAt: updatedAt,
      version: StorySummaryDocumentRepository.currentVersion,
    );
  }

  @override
  Future<StorySummarySaveResult> saveTaskSummaryDocument({
    required String storyId,
    required String taskId,
    required List<Map<String, dynamic>> document,
  }) async {
    final String path = StorySummaryDocumentRepository.pathForTaskId(
      storyId,
      taskId,
    );
    final DateTime updatedAt = DateTime.now();
    _documents[path] = StorySummaryDocument.clone(document);
    return StorySummarySaveResult(
      path: path,
      updatedAt: updatedAt,
      version: StorySummaryDocumentRepository.currentVersion,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> importDocx(Uint8List bytes) {
    return _converter.importDocx(bytes);
  }

  @override
  Future<Uint8List> exportDocx({
    required String storyTitle,
    required List<Map<String, dynamic>> document,
  }) {
    return _converter.exportDocx(storyTitle: storyTitle, document: document);
  }
}
