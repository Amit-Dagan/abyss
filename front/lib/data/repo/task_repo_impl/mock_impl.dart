import 'package:todo_list/domain/entities/task.dart';
import 'package:todo_list/domain/repo/task_repo.dart';

// class SharedPreferencesTaskRepository implements TaskRepository {

// }

class MockTaskRepositoryImpl implements TaskRepository {

  TaskEntity task1 = TaskEntity(id: '0', description: 'Sample Task', isCompleted: false);
  TaskEntity task2 = TaskEntity(id: '1', description: 'Completed Task', isCompleted: true); 
  List<TaskEntity> _tasks = [];
  MockTaskRepositoryImpl() {
    _tasks = [task1, task2];
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    _tasks.add(task);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    return _tasks;
  }

  @override
  Future<void> toggleTask(String taskId) async {
    for (var t in _tasks) {
      if (t.id == taskId) {
        t.isCompleted = !t.isCompleted;
      }
    }
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    for (var t in _tasks) {
      if (t.id == task.id) {
        _tasks[_tasks.indexOf(t)] = task;
        break;
      }
    }
  }
}
