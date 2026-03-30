import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';

class AddTaskButton extends StatelessWidget {
  const AddTaskButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: FittedBox(
        child: FloatingActionButton(
          foregroundColor: AppColors.whiteColor,
          backgroundColor: AppColors.primaryColor,
          splashColor: AppColors.secondaryColor,
          shape: const CircleBorder(),
          onPressed: onPressed,

          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
