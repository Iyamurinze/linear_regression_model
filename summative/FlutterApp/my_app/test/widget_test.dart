import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('App renders prediction page', (WidgetTester tester) async {
    await tester.pumpWidget(const CropYieldApp());
    expect(find.text('Crop Yield Predictor'), findsOneWidget);
    expect(find.text('Predict'), findsOneWidget);
  });
}
