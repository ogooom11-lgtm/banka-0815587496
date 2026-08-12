import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bank/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('BankApp renders login screen with bank branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BankApp());
    await tester.pumpAndSettle();

    // Verify bank title and login UI elements are present
    expect(find.text('Dijital Banka & Maaş Yönetimi'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Süper Admin'), findsOneWidget);
    expect(find.text('Çalışan'), findsOneWidget);
  });
}
