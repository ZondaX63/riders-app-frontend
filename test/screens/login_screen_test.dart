import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/login_screen.dart';
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
        '/register': (context) => const Scaffold(body: Text('Register Screen')),
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

  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const LoginScreen(),
      authProvider: mockAuthProvider,
    ));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Validates empty email and password',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const LoginScreen(),
      authProvider: mockAuthProvider,
    ));

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    verifyNever(mockAuthProvider.login(any, any));
  });

  testWidgets('Calls login with correct credentials',
      (WidgetTester tester) async {
    when(mockAuthProvider.login('test@test.com', 'password123'))
        .thenAnswer((_) async {});

    await tester.pumpWidget(createTestWidget(
      child: const LoginScreen(),
      authProvider: mockAuthProvider,
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.text('Login'));
    await tester.pump();

    verify(mockAuthProvider.login('test@test.com', 'password123')).called(1);
  });

  testWidgets('Shows error message on login failure',
      (WidgetTester tester) async {
    when(mockAuthProvider.login(any, any))
        .thenThrow(Exception('Invalid credentials'));

    await tester.pumpWidget(createTestWidget(
      child: const LoginScreen(),
      authProvider: mockAuthProvider,
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(); // Handle setState in finally block

    expect(find.text('Exception: Invalid credentials'), findsOneWidget);
  });

  testWidgets('Navigates to register screen', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const LoginScreen(),
      authProvider: mockAuthProvider,
    ));

    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle();

    expect(find.text('Register Screen'), findsOneWidget);
  });
}
