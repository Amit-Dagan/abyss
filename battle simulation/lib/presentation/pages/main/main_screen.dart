import 'package:flutter/material.dart';
import 'package:mvvm_remepy/base_page.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/presentation/pages/main/widgets/add_task_button.dart';
import 'package:todo_list/presentation/pages/main/widgets/get_started.dart';
import 'package:todo_list/presentation/pages/main/widgets/task_widget.dart';

import 'main_model.dart';
import 'main_view_model.dart';

class MainScreen extends BasePage<MainModel, MainViewModel> {
  const MainScreen({super.key, required super.viewModel});

  @override
  BasePageState<MainModel, MainViewModel, MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState
    extends BasePageState<MainModel, MainViewModel, MainScreen> {
  @override
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
  Widget? get floatingActionButton => AddTaskButton(
    onPressed: () async {
      viewModel.onAddTaskButtonClick();
    },
  );

  @override
  Widget get body {
    switch (model.status) {
      case MainScreenStatus.initial:
      case MainScreenStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );

      case MainScreenStatus.success:
        final allTasks = model.tasks;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: allTasks.length,
          itemBuilder: (context, index) {
            final task = allTasks[index];
            return Dismissible(
              key: ValueKey(task.id),
              onDismissed: (_) => viewModel.deleteTask(task.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TaskWidget(
                  task: task,
                  onToggle: (_) => viewModel.toggleTaskCompletion(task.id),
                ),
              ),
            );
          },
        );

      case MainScreenStatus.empty:
        return Center(child: GetStarted());

      case MainScreenStatus.failure:
        return Center(child: Text('An error occurred'));
    }
  }
}
