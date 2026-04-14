import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/data/model/task_model.dart';
import 'package:todo_list/domain/entities/task.dart';
import 'package:todo_list/domain/repo/task_repo.dart';

class SharedPreferenceImpl implements TaskRepository {
  static const String taskKey = 'tasks_';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  @override
  Future<void> addTask(TaskEntity task) async {
    final prefs = await _prefs;

    await prefs.setString(
      taskKey + task.id,
      json.encode(TaskModel.fromEntity(task).toMap()),
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final prefs = await _prefs;
    await prefs.remove(taskKey + taskId);
  }

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    final prefs = await _prefs;

    final keys = prefs.getKeys().where((k) => k.startsWith(taskKey));

    return keys.map((key) {
      final jsonString = prefs.getString(key)!;
      final taskMap = json.decode(jsonString);
      final taskModel = TaskModel.fromMap(taskMap);
      return taskModel.toEntity();
    }).toList();
  }

  @override
  Future<void> toggleTask(String taskId) async {
    final prefs = await _prefs;
    final key = taskKey + taskId;

    final jsonString = prefs.getString(key);
    if (jsonString == null) return;

    final taskMap = json.decode(jsonString);
    final taskModel = TaskModel.fromMap(taskMap);

    final updatedTaskModel = TaskModel(
      id: taskModel.id,
      description: taskModel.description,
      isCompleted: !taskModel.isCompleted,
    );

    await prefs.setString(key, json.encode(updatedTaskModel.toMap()));
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final prefs = await _prefs;

    await prefs.setString(
      taskKey + task.id,
      json.encode(TaskModel.fromEntity(task).toMap()),
    );
  }
}
