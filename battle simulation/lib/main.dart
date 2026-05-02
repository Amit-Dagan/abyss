import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mvvm_remepy/base_page.dart';
import 'package:todo_list/firebase_options.dart';
import 'package:todo_list/presentation/pages/battle/battle_model.dart';
import 'package:todo_list/presentation/pages/battle/battle_screen.dart';
import 'package:todo_list/presentation/pages/battle/battle_view_model.dart';
import 'package:todo_list/presentation/pages/battle_settings/battle_settings_model.dart';
import 'package:todo_list/presentation/pages/battle_settings/battle_settings_screen.dart';
import 'package:todo_list/presentation/pages/battle_settings/battle_settings_view_model.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_model.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_screen.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_view_model.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_model.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_screen.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_view_model.dart';
import 'package:todo_list/presentation/pages/stories/stories_screen.dart';
import 'package:todo_list/presentation/pages/stories/story_detail_screen.dart';
import 'package:todo_list/presentation/pages/stories/task_detail_screen.dart';
import 'package:todo_list/presentation/pages/workspace/workspace_home_screen.dart';
import 'package:todo_list/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abyss Studio',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        final String routeName = settings.name ?? '/';
        switch (routeName) {
          case '/':
            return MaterialPageRoute<void>(
              builder: (_) => const WorkspaceHomeScreen(),
              settings: settings,
            );
          case '/simulators':
            return MaterialPageRoute<void>(
              builder: (_) => BattleSettingsScreen(
                viewModel: BattleSettingsViewModel(
                  model: BattleSettingsModel(),
                ),
              ),
              settings: settings,
            );
          case '/battle':
            return MaterialPageRoute<void>(
              builder: (_) => BattleScreen(
                viewModel: BattleViewModel(model: BattleModel()),
              ),
              settings: settings,
            );
          case '/units':
            return MaterialPageRoute<void>(
              builder: (_) => UnitLibraryScreen(
                viewModel: UnitLibraryViewModel(model: UnitLibraryModel()),
              ),
              settings: settings,
            );
          case '/unitEditor':
            return MaterialPageRoute<void>(
              builder: (_) => UnitEditorScreen(
                viewModel: UnitEditorViewModel(model: UnitEditorModel()),
              ),
              settings: settings,
            );
          case '/stories':
            return MaterialPageRoute<void>(
              builder: (_) => const StoriesScreen(),
              settings: settings,
            );
          case '/stories/new':
            return MaterialPageRoute<void>(
              builder: (_) => const StoryDetailScreen(storyId: null),
              settings: settings,
            );
        }

        final RegExpMatch? taskRouteMatch = RegExp(
          r'^/stories/([^/]+)/tasks/([^/]+)$',
        ).firstMatch(routeName);
        if (taskRouteMatch != null) {
          final String storyId = Uri.decodeComponent(taskRouteMatch.group(1)!);
          final String taskId = Uri.decodeComponent(taskRouteMatch.group(2)!);
          return MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(storyId: storyId, taskId: taskId),
            settings: settings,
          );
        }

        if (routeName.startsWith('/stories/')) {
          final String storyId = Uri.decodeComponent(
            routeName.substring('/stories/'.length),
          );
          return MaterialPageRoute<void>(
            builder: (_) => StoryDetailScreen(storyId: storyId),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => const WorkspaceHomeScreen(),
          settings: settings,
        );
      },
    );
  }
}
