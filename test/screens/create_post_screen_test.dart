import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/create_post_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/post.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required ApiService apiService,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: apiService),
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
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  testWidgets('CreatePostScreen renders correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const CreatePostScreen(),
      apiService: mockApiService,
    ));

    expect(find.text('Yeni Gönderi'), findsOneWidget);
    expect(find.text('Ne düşünüyorsun?'), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
  });

  testWidgets('Typing # shows hashtag suggestions',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const CreatePostScreen(),
      apiService: mockApiService,
    ));

    await tester.enterText(find.byType(TextFormField), 'Hello #');
    await tester.pump();

    expect(find.text('Popüler Etiketler'), findsOneWidget);
    expect(find.text('#motosiklet'), findsOneWidget);
  });

  testWidgets('Inserting hashtag from suggestions updates text',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const CreatePostScreen(),
      apiService: mockApiService,
    ));

    // When we type '#', the suggestion replaces it or appends.
    // In current implementation it appends to whatever is there.
    await tester.enterText(find.byType(TextFormField), '#');
    await tester.pump();

    await tester.tap(find.text('#motosiklet'));
    await tester.pump();

    // Line 130 in create_post_screen.dart: `${text.substring(0, cursorPos)}$hashtag ${text.substring(cursorPos)}`
    // text='#', cursorPos=1 -> '#' + '#motosiklet' + ' ' + '' -> '##motosiklet '
    expect(find.text('##motosiklet '), findsOneWidget);
  });

  testWidgets('Paylaş button is disabled when empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const CreatePostScreen(),
      apiService: mockApiService,
    ));

    final shareButton = tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Paylaş'));
    expect(shareButton.onPressed, isNull);
  });

  testWidgets('Paylaş button calls apiService.createPost',
      (WidgetTester tester) async {
    final mockPost = Post(
      id: 'p1',
      userId: 'u1',
      images: [],
      likes: [],
      comments: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    when(mockApiService.createPost(any, any)).thenAnswer((_) async => mockPost);

    await tester.pumpWidget(createTestWidget(
      child: const CreatePostScreen(),
      apiService: mockApiService,
    ));

    await tester.enterText(find.byType(TextFormField), 'My cool ride');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Paylaş'));
    await tester.pump();
    await tester.pumpAndSettle(); // Resolve navigation

    verify(mockApiService.createPost('My cool ride', [])).called(1);
    expect(find.text('Main Screen'), findsOneWidget);
  });
}
