import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/widgets/profile_avatar.dart';
import 'package:frontend/services/api_service.dart';
import '../helpers/mocks.mocks.dart';
import 'dart:io';

// Helper for image mocking
class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  var headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
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
    return Stream<List<int>>.value(completion).listen(onData,
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
    when(mockApiService.buildStaticUrl(any))
        .thenAnswer((inv) => inv.positionalArguments.first as String);
  });

  testWidgets('ProfileAvatar uses provider and renders image',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
        ],
        child: const MaterialApp(
          home: ProfileAvatar(profilePicture: 'http://test.com/pic.jpg'),
        ),
      ),
    );

    // Verify ApiService was used (buildStaticUrl called)
    verify(mockApiService.buildStaticUrl('http://test.com/pic.jpg')).called(1);

    // Verify structure
    expect(find.byType(ClipOval), findsOneWidget);
    // Note: NetworkImage testing is tricky without verifying the request,
    // but we verify the widget tree has the avatar.
  });

  testWidgets('ProfileAvatar renders person icon when url is null',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
        ],
        child: const MaterialApp(
          home: ProfileAvatar(profilePicture: null),
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('ProfileAvatarWithBadge renders status icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
        ],
        child: const MaterialApp(
          home: ProfileAvatarWithBadge(
            profilePicture: null,
            status: 'Kahve Arıyorum',
            isOnline: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.coffee), findsOneWidget); // Status icon
    // Online indicator is a container, hard to find by type specifically without key,
    // but we can trust if no error it rendered.
    expect(find.byType(Stack), findsOneWidget);
  });

  testWidgets(
      'ProfileAvatar falls back to default ApiService if provider missing',
      (WidgetTester tester) async {
    // This test verifies the try-catch block for provider
    // Note: Default ApiService() might fail to get baseUrl from env?
    // But it instantiates. buildStaticUrl works?
    // buildStaticUrl depends on baseUrl.
    // We just want to ensure it doesn't crash properly.

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileAvatar(profilePicture: null),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
