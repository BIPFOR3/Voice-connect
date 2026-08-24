import 'package:flutter_test/flutter_test.dart';
import 'package:clase_uno/main.dart';

void main() {
  testWidgets('App loads and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Clase uno'), findsOneWidget);
    expect(find.text('Hello World!'), findsOneWidget);
  });
}
