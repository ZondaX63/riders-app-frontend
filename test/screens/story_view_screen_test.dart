import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/story_view_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/story.dart';
import 'package:frontend/models/user.dart';
import '../helpers/mocks.mocks.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }

  // Necessary overrides to satisfy Mockito
  @override
  var headers = _MockHttpHeaders();
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    // Transparent 1x1 GIF
    final List<int> completion = [
      0x47,
      0x49,
      0x46,
      0x38,
      0x39,
      0x61,
      0x01,
      0x00,
      0x01,
      0x00,
      0x80,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xff,
      0xff,
      0xff,
      0x21,
      0xf9,
      0x04,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x2c,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x01,
      0x00,
      0x00,
      0x02,
      0x02,
      0x44,
      0x01,
      0x00,
      0x3b
    ];
    return Stream.value(completion).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

void main() {
  late MockApiService mockApiService;

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  setUp(() {
    mockApiService = MockApiService();
    // Default stub for viewStory
    when(mockApiService.viewStory(any)).thenAnswer((_) async {});
    // Stub for image loading - just return path as is for test
    when(mockApiService.buildStaticUrl(any))
        .thenAnswer((i) => i.positionalArguments.first as String);
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

  final testStory = Story(
    id: 'story1',
    user: testUser,
    mediaUrl: 'http://localhost/image.png',
    mediaType: 'image',
    duration: 24, // long duration to avoid immediate close?
    views: [],
    createdAt: DateTime.now(),
  );

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('StoryViewScreen renders story content',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      StoryViewScreen(stories: [testStory]),
    ));

    expect(find.byType(Image), findsNWidgets(2));
    expect(find.text('Test User'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('StoryViewScreen calls viewStory API on init',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      StoryViewScreen(stories: [testStory]),
    ));

    verify(mockApiService.viewStory(testStory.id)).called(1);
  });

  testWidgets('StoryViewScreen pops when stories finish',
      (WidgetTester tester) async {
    // Shorter duration story for this test
    final shortStory = Story(
      id: 'story2',
      user: testUser,
      mediaUrl: 'http://localhost/image2.png',
      mediaType: 'image',
      duration: 3, // 3 seconds
      views: [],
      createdAt: DateTime.now(),
    );

    // Use a Navigator to verify pop
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => StoryViewScreen(stories: [shortStory])),
                );
              },
              child: const Text('Open Story'),
            );
          },
        ),
      ),
    ));

    // Open screen
    await tester.tap(find.text('Open Story'));
    await tester.pump(); // Start nav
    await tester
        .pump(const Duration(milliseconds: 300)); // Complete nav animation

    expect(find.byType(StoryViewScreen), findsOneWidget);

    // Fast forward time to finish story
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Should be back to main screen
    expect(find.byType(StoryViewScreen), findsNothing);
    expect(find.text('Open Story'), findsOneWidget);
  });
}
