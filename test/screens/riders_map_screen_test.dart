import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/riders_map_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required ApiService apiService,
  required SocketService socketService,
  required LocationService locationService,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: apiService),
      ChangeNotifierProvider<SocketService>.value(value: socketService),
      Provider<LocationService>.value(value: locationService),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiService mockApiService;
  late MockSocketService mockSocketService;
  late MockLocationService mockLocationService;

  setUp(() {
    mockApiService = MockApiService();
    mockSocketService = MockSocketService();
    mockLocationService = MockLocationService();

    // Default mocks
    when(mockLocationService.hasPermission()).thenAnswer((_) async => true);
    when(mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => Position(
              latitude: 41.0082,
              longitude: 28.9784,
              timestamp: DateTime.now(),
              accuracy: 10,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            ));
    when(mockLocationService.getNearbyUsers(
      latitude: anyNamed('latitude'),
      longitude: anyNamed('longitude'),
      radius: anyNamed('radius'),
    )).thenAnswer((_) async => []);
    when(mockSocketService.locationUpdateStream)
        .thenAnswer((_) => const Stream.empty());

    // Fix MissingStubError
    when(mockApiService.buildStaticUrl(any)).thenReturn('');
  });

  testWidgets('RidersMapScreen loads and shows nearby riders count',
      (WidgetTester tester) async {
    // Set screen size to avoid overflow in tests if possible
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    final nearbyRiders = [
      {
        'user': {
          'id': 'u1',
          'username': 'rider1',
          'fullName': 'Rider One',
          'profilePicture': 'p1.jpg',
        },
        'latitude': 41.0100,
        'longitude': 28.9800,
        'statusMessage': 'Available',
      }
    ];

    when(mockLocationService.getNearbyUsers(
      latitude: anyNamed('latitude'),
      longitude: anyNamed('longitude'),
      radius: anyNamed('radius'),
    )).thenAnswer((_) async => nearbyRiders);

    await tester.pumpWidget(createTestWidget(
      apiService: mockApiService,
      socketService: mockSocketService,
      locationService: mockLocationService,
      child: const RidersMapScreen(),
    ));

    // Initial load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Check if it shows "1 motosikletçi"
    expect(find.text('1 motosikletçi'), findsOneWidget);

    // Check if rider username is visible on map
    expect(find.text('rider1'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
