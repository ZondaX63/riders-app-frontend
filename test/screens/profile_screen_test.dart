import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/route.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required ApiService apiService,
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: apiService),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();

    when(mockApiService.buildStaticUrl(any)).thenReturn('');
  });

  final currentUser = User(
    id: 'user1',
    username: 'current_user',
    fullName: 'Current User',
    email: 'user1@test.com',
    followers: [],
    following: [],
    role: 'user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: {'message': 'Riding', 'customText': 'On my way'},
  );

  final testPosts = [
    {
      '_id': 'post1',
      'user': {
        '_id': 'user1',
        'username': 'current_user',
        'email': 'user1@test.com',
        'role': 'user',
        'followers': [],
        'following': [],
      },
      'description': 'Description of post 1',
      'images': [],
      'likes': [],
      'comments': [],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }
  ];

  final testRoutes = [
    RidersRoute(
      id: 'route1',
      user: currentUser,
      name: 'Ride 1',
      description: 'First ride',
      waypoints: [],
      distance: 10.5,
      duration: 3600,
      createdAt: DateTime.now(),
    ),
    RidersRoute(
      id: 'route2',
      user: currentUser,
      name: 'Ride 2',
      description: 'Second ride',
      waypoints: [],
      distance: 5.0,
      duration: 1800,
      createdAt: DateTime.now(),
    ),
  ];

  testWidgets('ProfileScreen shows correct tabs and stats',
      (WidgetTester tester) async {
    // Increase screen size to avoid off-screen issues
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    when(mockAuthProvider.currentUser).thenReturn(currentUser);
    when(mockApiService.getUserPosts('user1'))
        .thenAnswer((_) async => testPosts);
    when(mockApiService.getUserRoutes('user1'))
        .thenAnswer((_) async => testRoutes);

    await tester.pumpWidget(createTestWidget(
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      child: const ModernProfileScreen(),
    ));

    // Wait for initial load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify Stats
    expect(find.text('2'), findsOneWidget); // Rides count
    expect(find.text('15.5'), findsOneWidget); // Total distance

    // Verify Tabs
    expect(find.text('Posts'), findsOneWidget);
    // Rides text appears twice (stat label and tab label)
    expect(find.text('Rides'), findsNWidgets(2));

    // Default tab is Posts (index 0)
    expect(find.text('Description of post 1'), findsOneWidget);
    expect(find.text('Ride 1'), findsNothing);

    // Find the Rides tab button. It's usually a GestureDetector/InkWell wrapping the text.
    // We can filter for the one that is NOT the stat label.
    // Usually the tab bar is a Row of buttons.
    final ridesTab =
        find.text('Rides').last; // Usually tabs are after stats in the tree

    await tester.tap(ridesTab);
    await tester.pumpAndSettle();

    expect(find.text('Ride 1'), findsOneWidget);
    expect(find.text('Ride 2'), findsOneWidget);
    expect(find.text('10.5km'), findsOneWidget);
    expect(find.text('5.0km'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
