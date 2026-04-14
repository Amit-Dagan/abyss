// main_model.dart
import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/task.dart';

enum MainScreenStatus { initial, loading, success, failure, empty }

class MainModel extends Model {
  MainScreenStatus status;
  List<TaskEntity> tasks;

  MainModel({this.status = MainScreenStatus.initial, this.tasks = const []}) {
    appBarTitle = 'TODO APP';
  }
}
