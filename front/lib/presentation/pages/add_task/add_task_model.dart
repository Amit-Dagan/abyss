import 'package:mvvm_remepy/view_model.dart';

enum Status { initial, loading, success, failure }

class AddTaskModel extends Model {
  Status status;

  AddTaskModel({this.status = Status.initial}) {
    appBarTitle = 'ADD TASK';
  }
}
