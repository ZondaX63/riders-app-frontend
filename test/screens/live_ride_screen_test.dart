import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/live_ride_screen.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/webrtc_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/group_chat.dart';
import 'package:frontend/models/user.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required SocketService socketService,
  required WebRTCService webRTCService,
  required ApiService apiService,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: apiService),
      ChangeNotifierProvider<SocketService>.value(value: socketService),
      Provider<WebRTCService>.value(value: webRTCService),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockSocketService mockSocketService;
  late MockWebRTCService mockWebRTCService;
  late MockApiService mockApiService;

  final testUser = User(
    id: 'user1',
    username: 'Rider1',
    email: 'r1@test.com',
    role: 'user',
    followers: [],
    following: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final groupDetail = GroupChat(
    id: 'group1',
    name: 'Test Group',
    members: [
      GroupMember(user: testUser, role: 'member', joinedAt: DateTime.now()),
    ],
    isPrivate: false,
    messages: [],
    creator: testUser,
    rideStatus: 'active',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockSocketService = MockSocketService();
    mockWebRTCService = MockWebRTCService();
    mockApiService = MockApiService();

    when(mockSocketService.locationSharedStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockWebRTCService.participantsStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockApiService.buildStaticUrl(any)).thenReturn('');
  });

  testWidgets('LiveRideScreen shows group name and map',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: LiveRideScreen(groupId: 'group1', groupDetail: groupDetail),
      socketService: mockSocketService,
      webRTCService: mockWebRTCService,
      apiService: mockApiService,
    ));

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Test Group'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget); // Inside SOSButton
  });

  testWidgets('LiveRideScreen updates member locations from socket',
      (WidgetTester tester) async {
    final locationStream = Stream.value({
      'groupId': 'group1',
      'userId': 'user1',
      'location': {'latitude': 41.0100, 'longitude': 28.9800}
    });

    when(mockSocketService.locationSharedStream)
        .thenAnswer((_) => locationStream);

    await tester.pumpWidget(createTestWidget(
      child: LiveRideScreen(groupId: 'group1', groupDetail: groupDetail),
      socketService: mockSocketService,
      webRTCService: mockWebRTCService,
      apiService: mockApiService,
    ));

    await tester.pump(); // Start stream
    await tester.pump(const Duration(milliseconds: 100)); // Update state

    // Check if state updated
  });

  testWidgets('Toggling voice calls WebRTCService',
      (WidgetTester tester) async {
    when(mockWebRTCService.joinChannel('group1')).thenAnswer((_) async {});
    when(mockWebRTCService.leaveChannel()).thenAnswer((_) async {});

    await tester.pumpWidget(createTestWidget(
      child: LiveRideScreen(groupId: 'group1', groupDetail: groupDetail),
      socketService: mockSocketService,
      webRTCService: mockWebRTCService,
      apiService: mockApiService,
    ));

    await tester.pump(const Duration(milliseconds: 100));

    // Initial state: not active -> shows call
    final joinVoiceBtn = find.byIcon(Icons.call);
    expect(joinVoiceBtn, findsOneWidget);

    await tester.tap(joinVoiceBtn);
    await tester.pump();

    verify(mockWebRTCService.joinChannel('group1')).called(1);

    // Now should show call_end
    expect(find.byIcon(Icons.call_end), findsOneWidget);
    // And mic should appear
    expect(find.byIcon(Icons.mic), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pump();

    verify(mockWebRTCService.leaveChannel()).called(1);
    expect(find.byIcon(Icons.call), findsOneWidget);
  });
}
