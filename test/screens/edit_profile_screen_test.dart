import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/edit_profile_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required AuthProvider authProvider,
  required ApiService apiService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      Provider<ApiService>.value(value: apiService),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockApiService mockApiService;

  final testUser = User(
    id: 'u1',
    username: 'rider1',
    fullName: 'Rider One',
    bio: 'Initial Bio',
    email: 'r1@t.com',
    role: 'user',
    motorcycleInfo: {
      'brand': 'Honda',
      'model': 'CBR',
      'year': 2022,
    },
    followers: [],
    following: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockApiService = MockApiService();

    when(mockAuthProvider.currentUser).thenReturn(testUser);
  });

  testWidgets('EditProfileScreen shows initial data',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const EditProfileScreen(),
      authProvider: mockAuthProvider,
      apiService: mockApiService,
    ));

    expect(find.text('Rider One'), findsOneWidget);
    expect(find.text('Initial Bio'), findsOneWidget);

    // Switch to Motor tab
    await tester.tap(find.text('Motor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Check values in TextFormFields
    final hondaFinder = find.widgetWithText(TextFormField, 'Marka');
    expect(hondaFinder, findsOneWidget);
    final cbrFinder = find.widgetWithText(TextFormField, 'Model');
    expect(cbrFinder, findsOneWidget);

    // Verify controller values if needed, but text finder should work if settled
    expect(find.text('Honda'), findsWidgets);
    expect(find.text('CBR'), findsWidgets);
  });

  testWidgets('Save button calls updateProfile', (WidgetTester tester) async {
    when(mockApiService.updateProfile(any, any, any))
        .thenAnswer((_) async => testUser);
    when(mockAuthProvider.checkAuthStatus()).thenAnswer((_) async => true);

    await tester.pumpWidget(createTestWidget(
      child: const EditProfileScreen(),
      authProvider: mockAuthProvider,
      apiService: mockApiService,
    ));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Ad Soyad *'), 'New Name');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Hakkında'), 'New Bio');

    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    await tester.pumpAndSettle();

    verify(mockApiService.updateProfile('New Name', 'New Bio', any)).called(1);
    verify(mockAuthProvider.checkAuthStatus()).called(1);
  });
}
