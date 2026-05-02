import 'package:uuid/uuid.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:todo_list/domain/entities/story_task.dart';
import 'package:todo_list/domain/repo/planning_repository.dart';
import 'package:todo_list/domain/repo/story_summary_document_repository.dart';

class StorySaveResult {
  final bool summaryDocumentUploaded;
  final Object? summaryUploadError;

  const StorySaveResult({
    required this.summaryDocumentUploaded,
    this.summaryUploadError,
  });
}

class TaskSaveResult {
  final bool summaryDocumentUploaded;
  final Object? summaryUploadError;

  const TaskSaveResult({
    required this.summaryDocumentUploaded,
    this.summaryUploadError,
  });
}

class PlanningActionService {
  final PlanningRepository _repository;
  final StorySummaryDocumentRepository _summaryDocumentRepository;
  final Uuid _uuid;

  PlanningActionService({
    required PlanningRepository repository,
    required StorySummaryDocumentRepository summaryDocumentRepository,
    Uuid? uuid,
  }) : _repository = repository,
       _summaryDocumentRepository = summaryDocumentRepository,
       _uuid = uuid ?? const Uuid();

  String createId(String prefix) => '$prefix-${_uuid.v4()}';

  Future<StorySaveResult> createStory(StoryEntity story) async {
    final StoryEntity metadataDraft = _withSummaryPreview(story);
    await _repository.createStory(metadataDraft);
    return _tryUploadSummaryDocument(metadataDraft);
  }

  Future<StorySaveResult> updateStory(StoryEntity story) async {
    final StoryEntity metadataDraft = _withSummaryPreview(story);
    await _repository.updateStory(metadataDraft);
    return _tryUploadSummaryDocument(metadataDraft);
  }

  Future<StorySaveResult> _tryUploadSummaryDocument(StoryEntity story) async {
    try {
      final StorySummarySaveResult saveResult = await _summaryDocumentRepository
          .saveSummaryDocument(
            storyId: story.id,
            document: story.summaryDocument,
          );
      await _repository.updateStory(
        story.copyWith(
          summaryDocumentPath: saveResult.path,
          summaryUpdatedAt: saveResult.updatedAt,
          summaryDocumentVersion: saveResult.version,
        ),
      );
      return const StorySaveResult(summaryDocumentUploaded: true);
    } catch (error) {
      return StorySaveResult(
        summaryDocumentUploaded: false,
        summaryUploadError: error,
      );
    }
  }

  Future<void> updateStoryMetadata(StoryEntity story) {
    return _repository.updateStory(story);
  }

  Future<void> updateStorySummaryMetadata({
    required StoryEntity story,
    required StorySummarySaveResult saveResult,
  }) {
    return _repository.updateStory(
      story.copyWith(
        summaryDocumentPath: saveResult.path,
        summaryUpdatedAt: saveResult.updatedAt,
        summaryDocumentVersion: saveResult.version,
      ),
    );
  }

  Future<void> setStoryStatus(String storyId, StoryStatus status) async {
    final StoryEntity? story = await _repository.getStory(storyId);
    if (story == null) {
      return;
    }
    await _repository.updateStory(story.copyWith(status: status));
  }

  Future<void> createTask(StoryTaskEntity task) {
    return _repository.createTask(_withTaskSummaryPreview(task));
  }

  Future<void> updateTask(StoryTaskEntity task) {
    return _repository.updateTask(_withTaskSummaryPreview(task));
  }

  Future<TaskSaveResult> createRichTask(StoryTaskEntity task) async {
    final StoryTaskEntity metadataDraft = _withTaskSummaryPreview(task);
    await _repository.createTask(metadataDraft);
    return _tryUploadTaskSummaryDocument(metadataDraft);
  }

  Future<TaskSaveResult> updateRichTask(StoryTaskEntity task) async {
    final StoryTaskEntity metadataDraft = _withTaskSummaryPreview(task);
    await _repository.updateTask(metadataDraft);
    return _tryUploadTaskSummaryDocument(metadataDraft);
  }

  Future<TaskSaveResult> _tryUploadTaskSummaryDocument(
    StoryTaskEntity task,
  ) async {
    try {
      final StorySummarySaveResult saveResult = await _summaryDocumentRepository
          .saveTaskSummaryDocument(
            storyId: task.storyId,
            taskId: task.id,
            document: task.summaryDocument,
          );
      await _repository.updateTask(
        task.copyWith(
          summaryDocumentPath: saveResult.path,
          summaryUpdatedAt: saveResult.updatedAt,
          summaryDocumentVersion: saveResult.version,
        ),
      );
      return const TaskSaveResult(summaryDocumentUploaded: true);
    } catch (error) {
      return TaskSaveResult(
        summaryDocumentUploaded: false,
        summaryUploadError: error,
      );
    }
  }

  StoryEntity _withSummaryPreview(StoryEntity story) {
    final String preview = StorySummaryDocument.toPlainText(
      story.summaryDocument,
    );
    return story.copyWith(summary: preview);
  }

  StoryTaskEntity _withTaskSummaryPreview(StoryTaskEntity task) {
    final String preview = StorySummaryDocument.toPlainText(
      task.summaryDocument,
    );
    return task.copyWith(summary: preview);
  }
}
