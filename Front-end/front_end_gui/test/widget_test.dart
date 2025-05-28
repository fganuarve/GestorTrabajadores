import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_end_gui/main.dart';

void main() {
  testWidgets('Login screen has email and password fields', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(initialRoute: '/'));

    // Verify that login screen is shown
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    expect(find.text('¿No tienes una cuenta? Regístrate'), findsOneWidget);
  });

  testWidgets('Can navigate to register screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialRoute: '/'));
    
    // Tap the register button
    await tester.tap(find.text('¿No tienes una cuenta? Regístrate'));
    await tester.pumpAndSettle();
    
    // Verify that register screen is shown
    expect(find.text('Registro de Trabajador'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(6)); // All form fields
  });
}
