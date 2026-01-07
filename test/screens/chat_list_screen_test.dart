import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/chat.dart';
import 'package:frontend/models/message.dart';
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

  final testUser2 = User(
    id: 'user2',
    username: 'johndoe',
    fullName: 'John Doe',
    email: 'j@t.com',
    role: 'user',
    followers: [],
    following: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testChats = <Chat>[
    Chat(
      id: 'chat1',
      participants: [User.empty(), testUser2],
      otherUser: testUser2,
      lastMessage: Message(
        id: 'm1',
        chatId: 'chat1',
        sender: testUser2,
        content: 'Hello there!',
        type: MessageType.text,
        readBy: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  testWidgets('ChatListScreen shows chats correctly',
      (WidgetTester tester) async {
    when(mockApiService.getChats()).thenAnswer((_) async => testChats);

    await tester.pumpWidget(createTestWidget(
      child: const ChatListScreen(),
      apiService: mockApiService,
    ));

    await tester.pump(); // Start loading
    await tester.pump(); // Finish loading

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Hello there!'), findsOneWidget);
    expect(find.text('1'),
        findsOneWidget); // Unread count logic: if readBy is empty, returns 1
  });

  testWidgets('Shows empty message when no chats', (WidgetTester tester) async {
    when(mockApiService.getChats()).thenAnswer((_) async => <Chat>[]);

    await tester.pumpWidget(createTestWidget(
      child: const ChatListScreen(),
      apiService: mockApiService,
    ));

    await tester.pump();
    await tester.pump();

    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('Shows error and retry button on failure',
      (WidgetTester tester) async {
    when(mockApiService.getChats()).thenThrow(Exception('Failed to load'));

    await tester.pumpWidget(createTestWidget(
      child: const ChatListScreen(),
      apiService: mockApiService,
    ));

    await tester.pump();
    await tester.pump();

    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Test retry
    when(mockApiService.getChats()).thenAnswer((_) async => testChats);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('John Doe'), findsOneWidget);
  });
}
