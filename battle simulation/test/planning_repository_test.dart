import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/data/repo/planning_repo_impl/firestore_planning_repository.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:todo_list/domain/entities/story_task.dart';

void main() {
  group('FirestorePlanningRepository', () {
    test('creates and reads stories, tasks, and assignable members', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      final FirestorePlanningRepository repository =
          FirestorePlanningRepository(firestore: firestore);

      await firestore
          .collection('users')
          .doc('planner-a')
          .set(<String, dynamic>{
            'uid': 'planner-a',
            'email': 'planner@example.com',
            'displayName': 'Planner',
            'planner': true,
            'admin': false,
          });

      final StoryEntity story = StoryEntity(
        id: 'story-1',
        title: 'Stories MVP',
        summary: 'Build stories and tasks UI.',
        summaryDocument: StorySummaryDocument.fromPlainText(
          'Build stories and tasks UI.',
        ),
        summaryDocumentPath: null,
        summaryUpdatedAt: null,
        summaryDocumentVersion: null,
        status: StoryStatus.inProgress,
        ownerUserId: 'planner-a',
        priority: StoryPriority.high,
        createdAt: null,
        updatedAt: null,
      );

      await repository.createStory(story);
      await repository.createTask(
        StoryTaskEntity(
          id: 'task-1',
          storyId: story.id,
          title: 'Build list screen',
          summary: 'Build the compact row and detail route.',
          summaryDocument: StorySummaryDocument.fromPlainText(
            'Build the compact row and detail route.',
          ),
          summaryDocumentPath:
              'stories/story-1/tasks/task-1/summary.quill.json',
          summaryUpdatedAt: null,
          summaryDocumentVersion: 1,
          status: StoryTaskStatus.todo,
          ownerUserId: 'planner-a',
          priority: StoryPriority.high,
          orderIndex: 0,
          createdAt: null,
          updatedAt: null,
        ),
      );

      final List<StoryEntity> stories = await repository.getStories();
      final StoryEntity? loadedStory = await repository.getStory(story.id);
      final StoryTaskEntity? loadedTask = await repository.getTask(
        story.id,
        'task-1',
      );
      final List<StoryTaskEntity> tasks = await repository.getTasks(story.id);
      final members = await repository.getAssignableMembers();

      expect(stories, hasLength(1));
      expect(loadedStory?.title, 'Stories MVP');
      expect(loadedStory?.status, StoryStatus.inProgress);
      expect(loadedStory?.summaryDocument, isNotEmpty);
      expect(tasks, hasLength(1));
      expect(tasks.single.title, 'Build list screen');
      expect(loadedTask?.priority, StoryPriority.high);
      expect(loadedTask?.summary, 'Build the compact row and detail route.');
      expect(
        loadedTask?.summaryDocumentPath,
        'stories/story-1/tasks/task-1/summary.quill.json',
      );
      expect(members, hasLength(1));
      expect(members.single.uid, 'planner-a');
    });

    test(
      'falls back to a rich summary document for legacy plain text stories',
      () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
        final FirestorePlanningRepository repository =
            FirestorePlanningRepository(firestore: firestore);

        await firestore
            .collection('stories')
            .doc('legacy-story')
            .set(<String, dynamic>{
              'title': 'Legacy Story',
              'summary': 'Old plain text summary.',
              'status': 'backlog',
              'priority': 'medium',
            });

        final StoryEntity? loadedStory = await repository.getStory(
          'legacy-story',
        );

        expect(loadedStory, isNotNull);
        expect(loadedStory!.summary, 'Old plain text summary.');
        expect(loadedStory.summaryDocument, isNotEmpty);
        expect(
          StorySummaryDocument.toPlainText(loadedStory.summaryDocument),
          'Old plain text summary.',
        );
      },
    );

    test(
      'preserves rich list formatting in the Firestore fallback document',
      () async {
        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
        final FirestorePlanningRepository repository =
            FirestorePlanningRepository(firestore: firestore);
        final List<Map<String, dynamic>> bulletDocument =
            <Map<String, dynamic>>[
              <String, dynamic>{'insert': 'First bullet'},
              <String, dynamic>{
                'insert': '\n',
                'attributes': <String, dynamic>{'list': 'bullet'},
              },
              <String, dynamic>{'insert': 'Second bullet'},
              <String, dynamic>{
                'insert': '\n',
                'attributes': <String, dynamic>{'list': 'bullet'},
              },
            ];

        await repository.createStory(
          StoryEntity(
            id: 'story-bullets',
            title: 'Bullet Story',
            summary: 'First bullet\nSecond bullet',
            summaryDocument: bulletDocument,
            summaryDocumentPath: null,
            summaryUpdatedAt: null,
            summaryDocumentVersion: null,
            status: StoryStatus.backlog,
            ownerUserId: null,
            priority: StoryPriority.medium,
            createdAt: null,
            updatedAt: null,
          ),
        );

        final StoryEntity? loadedStory = await repository.getStory(
          'story-bullets',
        );

        expect(loadedStory, isNotNull);
        expect(loadedStory!.summaryDocument[1]['attributes'], <String, dynamic>{
          'list': 'bullet',
        });
        expect(loadedStory.summaryDocument[3]['attributes'], <String, dynamic>{
          'list': 'bullet',
        });
      },
    );
  });
}
