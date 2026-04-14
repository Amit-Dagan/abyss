import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:todo_list/data/repo/battle_repo_impl/firestore_battle_catalog_repository.dart';
import 'package:todo_list/data/repo/battle_repo_impl/local_battle_catalog_repository.dart';
import 'package:todo_list/data/repo/task_repo_impl/shared_prefrence_impl.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';
import 'package:todo_list/domain/repo/task_repo.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final BattleCatalogRepository battleCatalogRepository = kIsWeb
      ? FirestoreBattleCatalogRepository()
      : LocalBattleCatalogRepository();
  sl.registerSingleton<BattleCatalogRepository>(battleCatalogRepository);
  //sl.registerSingleton<TaskRepository>(MockTaskRepositoryImpl());
  sl.registerSingleton<TaskRepository>(SharedPreferenceImpl());

  final EditorSessionService sessionService = kIsWeb
      ? EditorSessionService.firebase(
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
          catalogRepository:
              battleCatalogRepository as FirestoreBattleCatalogRepository,
        )
      : EditorSessionService.local();
  sl.registerSingleton<EditorSessionService>(sessionService);
  await sessionService.initialize();
}
