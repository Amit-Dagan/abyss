import 'package:flutter/cupertino.dart';
import 'package:mvvm_remepy/observer/observer.dart';
import 'package:mvvm_remepy/view_model.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/task.dart';
import '../../../domain/repo/task_repo.dart';
import '../../../service_locator.dart';
import 'add_task_model.dart';

class AddTaskViewModel extends ViewModel<AddTaskModel>{
  AddTaskViewModel({required super.model});
  final TaskRepository _taskRepository = sl<TaskRepository>();
  final uuid = Uuid();
  final TextEditingController _controller = TextEditingController();

  TextEditingController get controller => _controller;

  Future<void> addTask() async {
    String taskTitle = _controller.text.trim();
    if (taskTitle.isEmpty) {
      notifyAlert(
        AlertModel(
          title: 'Error',
          body: 'Please enter a task description',
        ),
      );
      return;
    }
    try {
      final task = TaskEntity(
        description: taskTitle,
        isCompleted: false,
        id: uuid.v4(),
      );
      await _taskRepository.addTask(task);
      model.status = Status.success;
      notifyNavigate(NavigateModel(routeName: '/'));
      notify();
    } catch (e) {
      model.status = Status.failure;
      notifyAlert(
        AlertModel(
          title: 'Error',
          body: 'Please try again later',
        ),
      );
    }
  }

}