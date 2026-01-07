import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/post.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required ApiService apiService,
  required AuthProvider authProvider,
  required SocketService socketService,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: apiService),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<SocketService>.value(value: socketService),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;
  late MockSocketService mockSocketService;

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();
    mockSocketService = MockSocketService();

    // Default stubs to avoid MissingStubError
    when(mockApiService.getStories(
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
    )).thenAnswer((_) async => []);
  });

  final currentUser = User(
    id: 'user1',
    username: 'current_user',
    email: 'user1@test.com',
    followers: [],
    following: ['user2'],
    role: 'user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final otherUser = User(
    id: 'user2',
    username: 'other_user',
    email: 'user2@test.com',
    followers: [],
    following: [],
    role: 'user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final posts = [
    Post(
      id: 'post1',
      userId: 'user1',
      user: currentUser,
      description: 'My own post',
      images: [],
      likes: [],
      comments: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Post(
      id: 'post2',
      userId: 'user2',
      user: otherUser,
      description: 'Followed user post',
      images: [],
      likes: [],
      comments: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Post(
      id: 'post3',
      userId: 'user3',
      user: User(
        id: 'user3',
        username: 'unfollowed',
        email: 'u3@t.com',
        followers: [],
        following: [],
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      description: 'Unfollowed user post',
      images: [],
      likes: [],
      comments: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  testWidgets('Following tab shows own posts and followed users posts',
      (WidgetTester tester) async {
    when(mockAuthProvider.currentUser).thenReturn(currentUser);
    when(mockApiService.getPosts()).thenAnswer((_) async => posts);
    when(mockApiService.getExplorePosts()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestWidget(
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
      child: const HomeScreen(),
    ));

    await tester.pumpAndSettle();

    expect(find.text('My own post'), findsOneWidget);
    expect(find.text('Followed user post'), findsOneWidget);
    expect(find.text('Unfollowed user post'), findsNothing);
  });

  testWidgets('Explore tab shows all posts (mocked as explore posts)',
      (WidgetTester tester) async {
    when(mockAuthProvider.currentUser).thenReturn(currentUser);
    when(mockApiService.getPosts()).thenAnswer((_) async => []);
    when(mockApiService.getExplorePosts()).thenAnswer((_) async => posts);

    await tester.pumpWidget(createTestWidget(
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
      child: const HomeScreen(),
    ));

    await tester.pumpAndSettle();

    final exploreTab = find.descendant(
      of: find.byType(TabBar),
      matching: find.text('Keşfet'),
    );
    await tester.tap(exploreTab);
    await tester.pumpAndSettle();

    expect(find.text('My own post'), findsOneWidget);
    expect(find.text('Followed user post'), findsOneWidget);
    expect(find.text('Unfollowed user post'), findsOneWidget);
  });
}
