import 'package:flutter_test/flutter_test.dart';
import 'package:pawanmateeducation/features/splash/presentation/screens/splash_screen.dart';
import 'package:pawanmateeducation/main.dart';

void main() {
  testWidgets('Splash screen loads on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const PawanMateEducationApp());

    // Verify that the splash screen is initially present
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
