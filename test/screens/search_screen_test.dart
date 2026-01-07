import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/search_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required ApiService apiService,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: apiService),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    when(mockApiService.buildStaticUrl(any)).thenReturn('');
  });

  testWidgets('SearchScreen shows initial message',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const SearchScreen(),
      apiService: mockApiService,
    ));

    expect(find.text('Start typing to search users'), findsOneWidget);
  });

  testWidgets('Performs search and shows results', (WidgetTester tester) async {
    final testUsers = [
      User(
        id: '1',
        username: 'coder1',
        fullName: 'Coder One',
        email: 'c1@t.com',
        role: 'user',
        followers: [],
        following: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    when(mockApiService.searchUsers('coder'))
        .thenAnswer((_) async => testUsers);

    await tester.pumpWidget(createTestWidget(
      child: const SearchScreen(),
      apiService: mockApiService,
    ));

    await tester.enterText(find.byType(TextField), 'coder');
    await tester.pump(); // Trigger onChanged

    // Search results are updated via setState
    await tester.pump(); // Handle _isLoading = true
    await tester.pump(); // Handle results

    expect(find.text('coder1'), findsOneWidget);
    expect(find.text('Coder One'), findsOneWidget);
    verify(mockApiService.searchUsers('coder')).called(1);
  });

  testWidgets('Shows "No users found" when search is empty',
      (WidgetTester tester) async {
    when(mockApiService.searchUsers('unknown'))
        .thenAnswer((_) async => <User>[]);

    await tester.pumpWidget(createTestWidget(
      child: const SearchScreen(),
      apiService: mockApiService,
    ));

    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('No users found'), findsOneWidget);
  });

  testWidgets('Shows error message on API failure',
      (WidgetTester tester) async {
    when(mockApiService.searchUsers(any)).thenThrow(Exception('Network error'));

    await tester.pumpWidget(createTestWidget(
      child: const SearchScreen(),
      apiService: mockApiService,
    ));

    await tester.enterText(find.byType(TextField), 'fail');
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Exception: Network error'), findsOneWidget);
  });
}
