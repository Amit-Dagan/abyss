import 'package:flutter/material.dart';
import 'package:mvvm_remepy/base_page.dart';
import 'package:mvvm_remepy/observer/observer.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/presentation/pages/add_task/add_task_model.dart';
import 'package:todo_list/presentation/pages/add_task/widgets/add_button.dart';

import 'add_task_view_model.dart';

class AddTaskScreen extends BasePage<AddTaskModel, AddTaskViewModel> {
  const AddTaskScreen({super.key, required super.viewModel});

  @override
  BasePageState<AddTaskModel, AddTaskViewModel, AddTaskScreen> createState() =>
      _AddTaskState();
}

class _AddTaskState
    extends BasePageState<AddTaskModel, AddTaskViewModel, AddTaskScreen> {
  @override
  // TODO: implement backgroundColor
  Color get backgroundColor => AppColors.backgroundColor;

  @override
  PreferredSizeWidget? get appBar => AppBar(
    title: Text(
      model.appBarTitle,
      style: const TextStyle(
        color: AppColors.whiteColor,
        fontWeight: FontWeight.w800,
      ),
    ),
    backgroundColor: AppColors.primaryColor,
  );

  @override
  Widget get body {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'What task do you want to add?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            controller: viewModel.controller,
            style: const TextStyle(color: AppColors.primaryColor, fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Enter your task here',
              hintStyle: TextStyle(color: AppColors.boxShadowColor),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(width: 2, color: AppColors.primaryColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 2,
                  color: AppColors.boxShadowColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),

          AddButton(
            onPressed: () {
              viewModel.addTask();
            },
            isLoading: model.status == Status.loading,
          ),
        ],
      ),
    );
  }

  @override
  void onAlert(AlertModel alertModel) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryColor,
        content: Text(alertModel.body ?? ''),
      ),
    );
  }
}
