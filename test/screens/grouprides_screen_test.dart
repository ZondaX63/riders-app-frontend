import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/grouprides_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/route.dart';
import 'package:frontend/models/group_chat.dart';
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
  });

  final testUser = User(
    id: 'u1',
    username: 'rider1',
    email: 'r1@t.com',
    role: 'user',
    followers: [],
    following: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testRoutes = [
    RidersRoute(
      id: 'r1',
      user: testUser,
      name: 'Sunday Morning Ride',
      description: 'Relaxing ride',
      waypoints: [
        RouteWaypoint(latitude: 41.0, longitude: 28.0, order: 0, name: 'Start'),
        RouteWaypoint(latitude: 41.1, longitude: 28.1, order: 1, name: 'End'),
      ],
      distance: 25.5,
      duration: 45,
      isPublic: true,
      createdAt: DateTime.now(),
    ),
  ];

  final testGroups = [
    GroupChat(
      id: 'g1',
      name: 'Weekend Warriors',
      description: 'Fast riders only',
      creator: testUser,
      members: [],
      messages: [],
      createdAt: DateTime.now(),
    ),
  ];

  testWidgets('GroupRidesScreen shows routes and groups',
      (WidgetTester tester) async {
    when(mockApiService.getPublicRoutes()).thenAnswer((_) async => testRoutes);
    when(mockApiService.getGroupChats()).thenAnswer((_) async => testGroups);

    await tester.pumpWidget(createTestWidget(
      child: const GroupRidesScreen(),
      apiService: mockApiService,
    ));

    await tester.pumpAndSettle();

    // Routes tab is default
    expect(find.text('Sunday Morning Ride'), findsOneWidget);
    expect(find.text('Relaxing ride'), findsOneWidget);

    // Switch to Gruplarım tab
    await tester.tap(find.text('Gruplarım'));
    await tester.pumpAndSettle();

    expect(find.text('Weekend Warriors'), findsOneWidget);
    expect(find.text('Fast riders only'), findsOneWidget);
  });

  testWidgets('FloatingActionButton shows options',
      (WidgetTester tester) async {
    when(mockApiService.getPublicRoutes()).thenAnswer((_) async => []);
    when(mockApiService.getGroupChats()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestWidget(
      child: const GroupRidesScreen(),
      apiService: mockApiService,
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Rota Planla'), findsOneWidget);
    expect(find.text('Grup Oluştur'), findsOneWidget);
  });
}
