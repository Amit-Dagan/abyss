import 'package:get_it/get_it.dart';
import 'package:todo_list/data/repo/task_repo_impl/mock_impl.dart';
import 'package:todo_list/data/repo/task_repo_impl/shared_prefrence_impl.dart';
import 'package:todo_list/domain/repo/task_repo.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  //sl.registerSingleton<TaskRepository>(MockTaskRepositoryImpl());
  sl.registerSingleton<TaskRepository>(SharedPreferenceImpl());

}
