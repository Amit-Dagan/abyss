import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/data/model/planner_member_model.dart';
import 'package:todo_list/data/model/story_model.dart';
import 'package:todo_list/data/model/story_task_model.dart';
import 'package:todo_list/domain/entities/planner_member.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_task.dart';
import 'package:todo_list/domain/repo/planning_repository.dart';

class FirestorePlanningRepository implements PlanningRepository {
  final FirebaseFirestore _firestore;

  FirestorePlanningRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _storiesCollection =>
      _firestore.collection('stories');

  CollectionReference<Map<String, dynamic>> _tasksCollection(String storyId) =>
      _storiesCollection.doc(storyId).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<void> createStory(StoryEntity story) async {
    final StoryModel model = StoryModel.fromEntity(story);
    final Map<String, dynamic> map = model.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _storiesCollection.doc(story.id).set(map);
  }

  @override
  Future<void> createTask(StoryTaskEntity task) async {
    final StoryTaskModel model = StoryTaskModel.fromEntity(task);
    final Map<String, dynamic> map = model.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _tasksCollection(task.storyId).doc(task.id).set(map);
    await _storiesCollection.doc(task.storyId).set(<String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<PlannerMemberEntity>> getAssignableMembers() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _usersCollection
        .get();
    final List<PlannerMemberEntity> members = snapshot.docs
        .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data();
          return (data['planner'] as bool? ?? false) ||
              (data['admin'] as bool? ?? false);
        })
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              PlannerMemberModel.fromMap(doc.data()).toEntity(),
        )
        .toList(growable: false);
    members.sort(
      (PlannerMemberEntity a, PlannerMemberEntity b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return members;
  }

  @override
  Future<StoryEntity?> getStory(String storyId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _storiesCollection.doc(storyId).get();
    final Map<String, dynamic>? data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return StoryModel.fromMap(snapshot.id, data).toEntity();
  }

  @override
  Future<StoryTaskEntity?> getTask(String storyId, String taskId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _tasksCollection(storyId).doc(taskId).get();
    final Map<String, dynamic>? data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return StoryTaskModel.fromMap(snapshot.id, storyId, data).toEntity();
  }

  @override
  Future<List<StoryEntity>> getStories() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _storiesCollection.orderBy('updatedAt', descending: true).get();
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              StoryModel.fromMap(doc.id, doc.data()).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Future<List<StoryTaskEntity>> getTasks(String storyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _tasksCollection(
      storyId,
    ).orderBy('orderIndex').get();
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              StoryTaskModel.fromMap(doc.id, storyId, doc.data()).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Future<void> updateStory(StoryEntity story) async {
    final StoryModel model = StoryModel.fromEntity(story);
    final Map<String, dynamic> map = model.toMap()
      ..remove('createdAt')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _storiesCollection.doc(story.id).set(map, SetOptions(merge: true));
  }

  @override
  Future<void> updateTask(StoryTaskEntity task) async {
    final StoryTaskModel model = StoryTaskModel.fromEntity(task);
    final Map<String, dynamic> map = model.toMap()
      ..remove('createdAt')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _tasksCollection(
      task.storyId,
    ).doc(task.id).set(map, SetOptions(merge: true));
    await _storiesCollection.doc(task.storyId).set(<String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
