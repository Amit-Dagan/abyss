import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/entities/task.dart';
class TaskWidget extends StatelessWidget {
  const TaskWidget({super.key, required this.task, required this.onToggle});

  final TaskEntity task;
  final ValueChanged<bool?> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? AppColors.primaryColor : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: AppColors.boxShadowColor, blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDone ? AppColors.whiteColor : AppColors.primaryColor,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
              child: Text(task.description),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Checkbox(
              side: BorderSide(
                color: AppColors.primaryColor,
                width: 2,
              ),
              activeColor: AppColors.primaryColor,
              key: ValueKey(isDone),
              value: isDone,
              onChanged: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}
