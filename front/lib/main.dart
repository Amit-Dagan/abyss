import 'package:flutter/material.dart';
import 'package:todo_list/presentation/pages/add_task/add_task_model.dart';
import 'package:todo_list/presentation/pages/add_task/add_task_screen.dart';
import 'package:todo_list/presentation/pages/add_task/add_task_view_model.dart';
import 'package:todo_list/presentation/pages/main/main_model.dart';
import 'package:todo_list/presentation/pages/main/main_screen.dart';
import 'package:todo_list/presentation/pages/main/main_view_model.dart';
import 'package:todo_list/service_locator.dart';

void main() {
  initializeDependencies();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Define named routes
      initialRoute: '/',
      routes: {
        '/': (context) => MainScreen(viewModel: MainViewModel(model: MainModel())),
        '/addTask': (context) => AddTaskScreen(viewModel: AddTaskViewModel(model: AddTaskModel()),),
      },
    );
  }
}

