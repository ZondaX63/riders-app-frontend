import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      routes: {
        '/main': (context) => const Scaffold(body: Text('Main Screen')),
      },
      home: child,
    ),
  );
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  testWidgets('RegisterScreen renders all fields', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const RegisterScreen(),
      authProvider: mockAuthProvider,
    ));

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    // Find the button specifically to avoid conflict with AppBar title
    expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
  });

  testWidgets('Validates password match', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const RegisterScreen(),
      authProvider: mockAuthProvider,
    ));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'different');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Calls register with correct data', (WidgetTester tester) async {
    when(mockAuthProvider.register('user1', 't@t.com', 'pass123', 'Full Name'))
        .thenAnswer((_) async {});

    await tester.pumpWidget(createTestWidget(
      child: const RegisterScreen(),
      authProvider: mockAuthProvider,
    ));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'user1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Full Name');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 't@t.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'pass123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'pass123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();

    verify(mockAuthProvider.register(
            'user1', 't@t.com', 'pass123', 'Full Name'))
        .called(1);
  });
}
