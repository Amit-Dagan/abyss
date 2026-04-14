import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      title: 'Battle Simulator',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      initialRoute: '/',
      routes: {
        '/': (context) => BattleSettingsScreen(
          viewModel: BattleSettingsViewModel(model: BattleSettingsModel()),
        ),
        '/battle': (context) =>
            BattleScreen(viewModel: BattleViewModel(model: BattleModel())),
        '/units': (context) => UnitLibraryScreen(
          viewModel: UnitLibraryViewModel(model: UnitLibraryModel()),
        ),
        '/unitEditor': (context) => UnitEditorScreen(
          viewModel: UnitEditorViewModel(model: UnitEditorModel()),
        ),
      },
    );
  }
}
