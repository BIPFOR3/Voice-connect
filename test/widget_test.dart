import 'package:flutter_test/flutter_test.dart';
import 'package:voice_connect/main.dart';

void main() {
  testWidgets('App loads and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Mis Grabaciones'), findsOneWidget);
  });
}
