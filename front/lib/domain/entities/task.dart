class TaskEntity {
  final String id;
  final String description;
  bool isCompleted;

  TaskEntity({
    required this.id,
    required this.description,
    required this.isCompleted,
  });
}