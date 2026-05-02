import 'package:todo_list/domain/entities/planner_member.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:todo_list/domain/entities/story_task.dart';
import 'package:todo_list/domain/repo/planning_repository.dart';

class LocalPlanningRepository implements PlanningRepository {
  final List<StoryEntity> _stories = <StoryEntity>[
    StoryEntity(
      id: 'story-battle-foundation',
      title: 'Battle Prototype Foundation',
      summary:
          'Keep the battle simulator stable as the first playable pillar while the broader city and abyss loops are still being designed.',
      summaryDocument: StorySummaryDocument.fromPlainText(
        'Keep the battle simulator stable as the first playable pillar while the broader city and abyss loops are still being designed.',
      ),
      summaryDocumentPath: 'stories/story-battle-foundation/summary.quill.json',
      summaryUpdatedAt: null,
      summaryDocumentVersion: 1,
      status: StoryStatus.inProgress,
      ownerUserId: 'local-user',
      priority: StoryPriority.high,
      createdAt: null,
      updatedAt: null,
    ),
  ];

  final List<StoryTaskEntity> _tasks = <StoryTaskEntity>[
    StoryTaskEntity(
      id: 'task-battle-scope',
      storyId: 'story-battle-foundation',
      title: 'Review battle MVP scope against current prototype',
      summary: '',
      summaryDocument: StorySummaryDocument.fromPlainText(''),
      summaryDocumentPath:
          'stories/story-battle-foundation/tasks/task-battle-scope/summary.quill.json',
      summaryUpdatedAt: null,
      summaryDocumentVersion: 1,
      status: StoryTaskStatus.inProgress,
      ownerUserId: 'local-user',
      priority: StoryPriority.high,
      orderIndex: 0,
      createdAt: null,
      updatedAt: null,
    ),
    StoryTaskEntity(
      id: 'task-battle-docs',
      storyId: 'story-battle-foundation',
      title: 'Keep battle docs aligned with shipped simulator behavior',
      summary: '',
      summaryDocument: StorySummaryDocument.fromPlainText(''),
      summaryDocumentPath:
          'stories/story-battle-foundation/tasks/task-battle-docs/summary.quill.json',
      summaryUpdatedAt: null,
      summaryDocumentVersion: 1,
      status: StoryTaskStatus.todo,
      ownerUserId: 'local-user',
      priority: StoryPriority.medium,
      orderIndex: 1,
      createdAt: null,
      updatedAt: null,
    ),
  ];

  final List<PlannerMemberEntity> _members = const <PlannerMemberEntity>[
    PlannerMemberEntity(
      uid: 'local-user',
      email: 'local@abyss.dev',
      displayName: 'Local Planner',
    ),
  ];

  @override
  Future<void> createStory(StoryEntity story) async {
    _stories.add(story);
  }

  @override
  Future<void> createTask(StoryTaskEntity task) async {
    _tasks.add(task);
  }

  @override
  Future<List<PlannerMemberEntity>> getAssignableMembers() async {
    return List<PlannerMemberEntity>.from(_members);
  }

  @override
  Future<StoryEntity?> getStory(String storyId) async {
    for (final StoryEntity story in _stories) {
      if (story.id == storyId) {
        return story;
      }
    }
    return null;
  }

  @override
  Future<List<StoryEntity>> getStories() async {
    final List<StoryEntity> sorted = List<StoryEntity>.from(_stories);
    sorted.sort((StoryEntity a, StoryEntity b) {
      final int priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sorted;
  }

  @override
  Future<StoryTaskEntity?> getTask(String storyId, String taskId) async {
    for (final StoryTaskEntity task in _tasks) {
      if (task.storyId == storyId && task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  @override
  Future<List<StoryTaskEntity>> getTasks(String storyId) async {
    final List<StoryTaskEntity> result = _tasks
        .where((StoryTaskEntity task) => task.storyId == storyId)
        .toList(growable: false);
    result.sort(
      (StoryTaskEntity a, StoryTaskEntity b) =>
          a.orderIndex.compareTo(b.orderIndex),
    );
    return result;
  }

  @override
  Future<void> updateStory(StoryEntity story) async {
    final int index = _stories.indexWhere(
      (StoryEntity item) => item.id == story.id,
    );
    if (index == -1) {
      _stories.add(story);
      return;
    }
    _stories[index] = story;
  }

  @override
  Future<void> updateTask(StoryTaskEntity task) async {
    final int index = _tasks.indexWhere(
      (StoryTaskEntity item) => item.id == task.id,
    );
    if (index == -1) {
      _tasks.add(task);
      return;
    }
    _tasks[index] = task;
  }
}
