import 'package:todo_list/domain/entities/task.dart';

class TaskModel {
  final String id;
  final String description;
  final bool isCompleted;

  TaskModel({
    required this.id,
    required this.description,
    required this.isCompleted,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      description: entity.description,
      isCompleted: entity.isCompleted,
    );
  }
  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      description: description,
      isCompleted: isCompleted,
    );
  }

}

