import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/main.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_keyword_glossary.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_card.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_model.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_screen.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_view_model.dart';
import 'package:todo_list/service_locator.dart';

void main() {
  setUp(() async {
    await sl.reset();
    await initializeDependencies();
  });

  testWidgets('battle settings screen loads first', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('BATTLE SETTINGS'), findsOneWidget);
    expect(find.text('Start Battle'), findsOneWidget);
  });

  testWidgets('battle unit card keyword can open a tooltip', (
    WidgetTester tester,
  ) async {
    final BattleUnitDefinitionEntity definition = BattleUnitDefinitionEntity(
      id: 'tooltip_unit',
      name: 'Tooltip Unit',
      iconKey: 'beast',
      attack: 2,
      health: 5,
      onHitEffects: const <BattleOnHitEffectEntity>[
        BattleOnHitEffectEntity(type: BattleOnHitEffectType.poison, amount: 1),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260,
                  child: BattleUnitCard(
                    definition: definition,
                    onKeywordTap: (String key) {
                      final BattleKeywordGlossaryEntry entry =
                          BattleKeywordGlossary.lookup(key)!;
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: Text(entry.title),
                            content: Text(entry.description),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Poison').first);
    await tester.pumpAndSettle();

    expect(find.text('Poison'), findsWidgets);
    expect(
      find.textContaining('Poison deals increasing damage in cleanup'),
      findsOneWidget,
    );
  });

  testWidgets('unit library hides editor controls in read-only mode', (
    WidgetTester tester,
  ) async {
    sl.unregister<EditorSessionService>();
    sl.registerSingleton<EditorSessionService>(
      EditorSessionService.local(canEditUnits: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UnitLibraryScreen(
          viewModel: UnitLibraryViewModel(model: UnitLibraryModel()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Create Unit'), findsNothing);
  });
}
