import 'package:flutter_test/flutter_test.dart';
import 'package:screenapi/main.dart';

void main() {
  testWidgets('shows open button on startup', (tester) async {
    await tester.pumpWidget(const ScreenApiApp());

    expect(find.text('Открыть'), findsOneWidget);
  });
}
