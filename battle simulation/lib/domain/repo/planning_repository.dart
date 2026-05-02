import 'package:todo_list/domain/entities/planner_member.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_task.dart';

abstract class PlanningRepository {
  Future<List<StoryEntity>> getStories();
  Future<StoryEntity?> getStory(String storyId);
  Future<StoryTaskEntity?> getTask(String storyId, String taskId);
  Future<List<StoryTaskEntity>> getTasks(String storyId);
  Future<List<PlannerMemberEntity>> getAssignableMembers();
  Future<void> createStory(StoryEntity story);
  Future<void> updateStory(StoryEntity story);
  Future<void> createTask(StoryTaskEntity task);
  Future<void> updateTask(StoryTaskEntity task);
}
