import 'dart:typed_data';

import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_task.dart';

class StorySummarySaveResult {
  final String path;
  final DateTime updatedAt;
  final int version;

  const StorySummarySaveResult({
    required this.path,
    required this.updatedAt,
    required this.version,
  });
}

abstract class StorySummaryDocumentRepository {
  static const int currentVersion = 1;

  static String pathForStoryId(String storyId) {
    return 'stories/$storyId/summary.quill.json';
  }

  static String pathForTaskId(String storyId, String taskId) {
    return 'stories/$storyId/tasks/$taskId/summary.quill.json';
  }

  Future<List<Map<String, dynamic>>> loadSummaryDocument(StoryEntity story);

  Future<List<Map<String, dynamic>>> loadTaskSummaryDocument(
    StoryTaskEntity task,
  );

  Future<StorySummarySaveResult> saveSummaryDocument({
    required String storyId,
    required List<Map<String, dynamic>> document,
  });

  Future<StorySummarySaveResult> saveTaskSummaryDocument({
    required String storyId,
    required String taskId,
    required List<Map<String, dynamic>> document,
  });

  Future<List<Map<String, dynamic>>> importDocx(Uint8List bytes);

  Future<Uint8List> exportDocx({
    required String storyTitle,
    required List<Map<String, dynamic>> document,
  });
}
