import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/main.dart';
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
}
