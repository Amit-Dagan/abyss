import 'package:todo_list/domain/entities/task.dart';

abstract class TaskRepository {
  Future<void> addTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String taskId); 
  Future<List<TaskEntity>> getAllTasks();
  Future<void> toggleTask(String taskId);
}