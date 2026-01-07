import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/chat_detail_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/models/chat.dart';
import 'package:frontend/models/message.dart';
import 'package:frontend/models/user.dart';
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

  final currentUser = User(
    id: 'u1',
    username: 'me',
    email: 'm@t.com',
    role: 'user',
    followers: [],
    following: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final otherUser = User(
    id: 'u2',
    username: 'other',
    fullName: 'Other User',
    email: 'o@t.com',
    role: 'user',
    followers: [],
    following: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testChat = Chat(
    id: 'c1',
    participants: [currentUser, otherUser],
    otherUser: otherUser,
    lastMessageAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();
    when(mockAuthProvider.currentUser).thenReturn(currentUser);
  });

  testWidgets('ChatDetailScreen loads and shows messages',
      (WidgetTester tester) async {
    final messages = [
      Message(
        id: 'm1',
        chatId: 'c1',
        sender: otherUser,
        content: 'Hi!',
        type: MessageType.text,
        readBy: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Message(
        id: 'm2',
        chatId: 'c1',
        sender: currentUser,
        content: 'Hello!',
        type: MessageType.text,
        readBy: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    when(mockApiService.getChatMessages('c1'))
        .thenAnswer((_) async => messages);
    when(mockApiService.markChatAsRead('c1')).thenAnswer((_) async {});

    await tester.pumpWidget(createTestWidget(
      child: ChatDetailScreen(chat: testChat),
      apiService: mockApiService,
      authProvider: mockAuthProvider,
    ));

    await tester.pump(); // Loading
    await tester.pump(); // Results

    expect(find.text('Hi!'), findsOneWidget);
    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('Other User'), findsOneWidget);
  });

  testWidgets('Sending a message calls API and updates UI',
      (WidgetTester tester) async {
    when(mockApiService.getChatMessages('c1')).thenAnswer((_) async => []);
    when(mockApiService.markChatAsRead('c1')).thenAnswer((_) async {});

    final newMessage = Message(
      id: 'm3',
      chatId: 'c1',
      sender: currentUser,
      content: 'New msg',
      type: MessageType.text,
      readBy: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(mockApiService.sendMessage('c1', 'New msg', MessageType.text))
        .thenAnswer((_) async => newMessage);

    await tester.pumpWidget(createTestWidget(
      child: ChatDetailScreen(chat: testChat),
      apiService: mockApiService,
      authProvider: mockAuthProvider,
    ));

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New msg');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    verify(mockApiService.sendMessage('c1', 'New msg', MessageType.text))
        .called(1);
    expect(find.text('New msg'), findsOneWidget);
  });
}
