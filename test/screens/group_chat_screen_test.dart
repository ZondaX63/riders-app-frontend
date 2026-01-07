import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/group_chat_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/group_chat_api_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/group_chat.dart';
import '../helpers/mocks.mocks.dart';

class MockGroupChatApiService extends Mock implements GroupChatApiService {
  @override
  Future<void> addMember(String? groupId, String? userId) =>
      super.noSuchMethod(Invocation.method(#addMember, [groupId, userId]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value());
}

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
  late MockGroupChatApiService mockGroupChatApiService;

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();
    mockSocketService = MockSocketService();
    mockGroupChatApiService = MockGroupChatApiService();

    when(mockSocketService.groupMessageReceivedStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockApiService.groupChats).thenReturn(mockGroupChatApiService);
  });

  final testUser = User(
    id: 'user1',
    username: 'Test User',
    email: 'test@test.com',
    profilePicture: 'pic.jpg',
    followers: [],
    following: [],
    role: 'user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final groupDataMember = {
    '_id': 'group1',
    'name': 'Test Group',
    'description': 'Desc',
    'members': [
      {
        'user': {
          '_id': 'user1',
          'username': 'Test User',
          'email': 'test@test.com',
          'followers': [],
          'following': [],
          'role': 'user'
        },
        'role': 'member',
        'joinedAt': DateTime.now().toIso8601String()
      }
    ],
    'isPrivate': false,
    'messages': [],
    'creator': {
      '_id': 'creator_id',
      'username': 'Creator',
      'email': 'creator@test.com',
      'followers': [],
      'following': [],
      'role': 'user'
    },
    'rideStatus': 'planned',
    'createdAt': DateTime.now().toIso8601String()
  };

  final groupDataNonMember = {
    '_id': 'group1',
    'name': 'Test Group',
    'description': 'Desc',
    'members': [],
    'isPrivate': false,
    'messages': [],
    'creator': {
      '_id': 'creator_id',
      'username': 'Creator',
      'email': 'creator@test.com',
      'followers': [],
      'following': [],
      'role': 'user'
    },
    'rideStatus': 'planned',
    'createdAt': DateTime.now().toIso8601String()
  };

  testWidgets('Should show "Join Group" button when user is NOT a member',
      (WidgetTester tester) async {
    when(mockAuthProvider.currentUser).thenReturn(testUser);
    when(mockApiService.getGroupChat('group1'))
        .thenAnswer((_) async => GroupChat.fromJson(groupDataNonMember));

    await tester.pumpWidget(createTestWidget(
      child: const GroupChatScreen(groupId: 'group1', groupName: 'Test Group'),
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Gruba Katıl'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Should show Message Input when user IS a member',
      (WidgetTester tester) async {
    when(mockAuthProvider.currentUser).thenReturn(testUser);
    when(mockApiService.getGroupChat('group1'))
        .thenAnswer((_) async => GroupChat.fromJson(groupDataMember));
    when(mockApiService.getGroupMessages('group1'))
        .thenAnswer((_) async => <GroupMessage>[]);
    when(mockSocketService.joinGroup('group1')).thenReturn(null);

    await tester.pumpWidget(createTestWidget(
      child: const GroupChatScreen(groupId: 'group1', groupName: 'Test Group'),
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Gruba Katıl'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    verify(mockSocketService.joinGroup('group1')).called(1);
  });

  testWidgets('Tapping Join Group calls API and refreshes',
      (WidgetTester tester) async {
    when(mockAuthProvider.currentUser).thenReturn(testUser);

    var callCount = 0;
    when(mockApiService.getGroupChat('group1')).thenAnswer((_) async {
      callCount++;
      return callCount == 1
          ? GroupChat.fromJson(groupDataNonMember)
          : GroupChat.fromJson(groupDataMember);
    });

    when(mockApiService.addGroupMember('group1', 'user1'))
        .thenAnswer((_) async {});

    when(mockApiService.getGroupMessages('group1'))
        .thenAnswer((_) async => <GroupMessage>[]);

    when(mockSocketService.joinGroup('group1')).thenReturn(null);

    await tester.pumpWidget(createTestWidget(
      child: const GroupChatScreen(groupId: 'group1', groupName: 'Test Group'),
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
    ));

    await tester.pumpAndSettle();

    // Init: Not member
    final joinBtn = find.text('Gruba Katıl');
    expect(joinBtn, findsOneWidget);

    // Act: Join
    await tester.tap(joinBtn);
    await tester.pump(); // Start join logic

    // Allow async gaps to complete
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify
    verify(mockApiService.addGroupMember('group1', 'user1')).called(1);

    // Should now behave like member (load messages, show input)
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Allows searching and inviting members',
      (WidgetTester tester) async {
    when(mockAuthProvider.currentUser).thenReturn(testUser);

    // User is a member
    when(mockApiService.getGroupChat('group1'))
        .thenAnswer((_) async => GroupChat.fromJson(groupDataMember));
    when(mockApiService.getGroupMessages('group1'))
        .thenAnswer((_) async => <GroupMessage>[]);
    when(mockSocketService.joinGroup('group1')).thenReturn(null);
    when(mockSocketService.groupMessageReceivedStream)
        .thenAnswer((_) => Stream.empty());

    // Setup Search Mock
    final searchedUser = User(
        id: 'u2',
        username: 'target_user',
        email: 't@t.com',
        role: 'user',
        followers: [],
        following: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now());
    when(mockApiService.searchUsers('target'))
        .thenAnswer((_) async => [searchedUser]);

    // Setup Add Member Mock
    when(mockGroupChatApiService.addMember('group1', 'u2'))
        .thenAnswer((_) async {});

    await tester.pumpWidget(createTestWidget(
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
      child: const GroupChatScreen(groupId: 'group1', groupName: 'Test Group'),
    ));
    await tester.pumpAndSettle();

    // 1. Open Invite Dialog
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    expect(find.text('Üye Davet Et'), findsOneWidget);

    // 2. Search
    final searchField = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(searchField, 'target');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump(); // Start search
    await tester.pump(const Duration(milliseconds: 100)); // Maybe a delay?
    await tester.pumpAndSettle();

    expect(find.text('target_user'), findsOneWidget);

    // 3. Invite
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pump();

    verify(mockGroupChatApiService.addMember('group1', 'u2')).called(1);
    expect(find.text('target_user davet edildi'), findsOneWidget);
  });
}
