import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';

class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.onPressed, required this.isLoading});
  final VoidCallback onPressed;
  final bool isLoading;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 65,
            child: FloatingActionButton(
              onPressed: isLoading ? null : onPressed,
              backgroundColor: AppColors.primaryColor,
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.whiteColor,
                    )
                  : const Text(
                      'ADD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.whiteColor,
                      ),
                    ),
        
            ),
          ),
        ),
      ],
    );
  }
}
