import 'package:get_it/get_it.dart';
import 'package:todo_list/data/repo/battle_repo_impl/local_battle_catalog_repository.dart';
import 'package:todo_list/data/repo/task_repo_impl/shared_prefrence_impl.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';
import 'package:todo_list/domain/repo/task_repo.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerSingleton<BattleCatalogRepository>(
    const LocalBattleCatalogRepository(),
  );
  //sl.registerSingleton<TaskRepository>(MockTaskRepositoryImpl());
  sl.registerSingleton<TaskRepository>(SharedPreferenceImpl());
}
