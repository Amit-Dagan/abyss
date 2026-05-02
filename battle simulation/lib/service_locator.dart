import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:todo_list/data/repo/battle_repo_impl/firestore_battle_catalog_repository.dart';
import 'package:todo_list/data/repo/battle_repo_impl/local_battle_catalog_repository.dart';
import 'package:todo_list/data/repo/planning_repo_impl/firebase_story_summary_document_repository.dart';
import 'package:todo_list/data/repo/planning_repo_impl/firestore_planning_repository.dart';
import 'package:todo_list/data/repo/planning_repo_impl/local_planning_repository.dart';
import 'package:todo_list/data/repo/planning_repo_impl/local_story_summary_document_repository.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';
import 'package:todo_list/domain/repo/planning_repository.dart';
import 'package:todo_list/domain/repo/story_summary_document_repository.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';
import 'package:todo_list/domain/services/planning_action_service.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final BattleCatalogRepository battleCatalogRepository = kIsWeb
      ? FirestoreBattleCatalogRepository()
      : LocalBattleCatalogRepository();
  sl.registerSingleton<BattleCatalogRepository>(battleCatalogRepository);

  final PlanningRepository planningRepository = kIsWeb
      ? FirestorePlanningRepository()
      : LocalPlanningRepository();
  sl.registerSingleton<PlanningRepository>(planningRepository);
  final StorySummaryDocumentRepository summaryDocumentRepository = kIsWeb
      ? FirebaseStorySummaryDocumentRepository(
          storage: FirebaseStorage.instanceFor(
            bucket: 'gs://abyss-f0953.firebasestorage.app',
          ),
        )
      : LocalStorySummaryDocumentRepository();
  sl.registerSingleton<StorySummaryDocumentRepository>(
    summaryDocumentRepository,
  );
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

  sl.registerSingleton<PlanningActionService>(
    PlanningActionService(
      repository: planningRepository,
      summaryDocumentRepository: summaryDocumentRepository,
    ),
  );
}
