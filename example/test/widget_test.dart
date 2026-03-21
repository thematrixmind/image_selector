import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Choose image source'), findsOneWidget);
  });
}
