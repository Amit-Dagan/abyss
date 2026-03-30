import 'package:mvvm_remepy/observer/observer.dart';
import 'package:mvvm_remepy/view_model.dart';

import '../../../domain/repo/task_repo.dart';
import '../../../service_locator.dart';
import 'main_model.dart';

class MainViewModel extends ViewModel<MainModel> {

  final TaskRepository _taskRepository = sl<TaskRepository>();

  MainViewModel({required super.model});

  void refreshTasks() {
    _taskRepository
        .getAllTasks()
        .then((tasks) {
      if (tasks.isEmpty) {
        model.status = MainScreenStatus.empty;
      } else {
        model.status = MainScreenStatus.success;
        model.tasks = tasks;

      }
    })
        .catchError((error) {
          model.status = MainScreenStatus.failure;
    });
    notify();
  }
  void deleteTask(String taskId) async {
    await _taskRepository.deleteTask(taskId);
    refreshTasks();
  }
  void toggleTaskCompletion(String taskId) async {
    _taskRepository.toggleTask(taskId);
    refreshTasks();
  }
  void initialize() {
    model.status = MainScreenStatus.initial;
    notify();
    refreshTasks();
  }

  @override void onViewLoaded(data) {
    super.onViewLoaded(data);
    initialize();
  }

  void onAddTaskButtonClick() {
    notifyNavigate(NavigateModel(routeName: '/addTask'));
  }
}