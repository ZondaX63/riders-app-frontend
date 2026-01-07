import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/screens/explore_screen_new.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/location_service.dart';
import 'package:frontend/providers/map_pin_provider.dart';
import 'package:frontend/models/user.dart';
import '../helpers/mocks.mocks.dart';

Widget createTestWidget({
  required Widget child,
  required ApiService apiService,
  required AuthProvider authProvider,
  required SocketService socketService,
  required LocationService locationService,
  required MapPinProvider mapPinProvider,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: apiService),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<SocketService>.value(value: socketService),
      Provider<LocationService>.value(value: locationService),
      ChangeNotifierProvider<MapPinProvider>.value(value: mapPinProvider),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;
  late MockSocketService mockSocketService;
  late MockLocationService mockLocationService;
  late MockMapPinProvider mockMapPinProvider;

  final testUser = User(
    id: 'u1',
    username: 'me',
    email: 'm@t.com',
    role: 'user',
    followers: [],
    following: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();
    mockSocketService = MockSocketService();
    mockLocationService = MockLocationService();
    mockMapPinProvider = MockMapPinProvider();

    when(mockAuthProvider.currentUser).thenReturn(testUser);
    when(mockApiService.searchUsers(any)).thenAnswer((_) async => []);
    when(mockApiService.getPublicRoutes()).thenAnswer((_) async => []);
    when(mockApiService.getGroupChats()).thenAnswer((_) async => []);
    when(mockApiService.buildStaticUrl(any)).thenReturn('');

    when(mockMapPinProvider.nearbyPins).thenReturn([]);
    when(mockMapPinProvider.isLoadingNearby).thenReturn(false);
    when(mockMapPinProvider.nearbyError).thenReturn(null);

    // Mocks for RidersMapScreen
    when(mockLocationService.hasPermission()).thenAnswer((_) async => true);
    when(mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => Position(
              latitude: 41.0,
              longitude: 28.0,
              timestamp: DateTime.now(),
              accuracy: 0.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            ));
    when(mockLocationService.getNearbyUsers(
      latitude: anyNamed('latitude'),
      longitude: anyNamed('longitude'),
      radius: anyNamed('radius'),
    )).thenAnswer((_) async => [
          {
            'user': {
              'id': 'u2',
              'username': 'rider2',
              'fullName': 'Rider Two',
              'profilePicture': 'p2.jpg',
            },
            'latitude': 41.01,
            'longitude': 28.01,
            'statusMessage': 'On the road',
          }
        ]);

    when(mockSocketService.locationUpdateStream)
        .thenAnswer((_) => const Stream.empty());
  });

  testWidgets('ExploreScreen renders all tabs', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const ExploreScreen(),
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
      locationService: mockLocationService,
      mapPinProvider: mockMapPinProvider,
    ));

    expect(find.text('Keşfet'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('Harita'), findsOneWidget);
    expect(find.text('Noktalar'), findsOneWidget);
    expect(find.text('Grup Sürüşleri'), findsOneWidget);
  });

  testWidgets('ExploreScreen can switch tabs', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: const ExploreScreen(),
      apiService: mockApiService,
      authProvider: mockAuthProvider,
      socketService: mockSocketService,
      locationService: mockLocationService,
      mapPinProvider: mockMapPinProvider,
    ));

    // Initially on "Ara" (RidersExploreTab)
    expect(find.byIcon(Icons.search), findsWidgets);

    // Switch to "Harita"
    await tester.tap(find.text('Harita'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // In RidersMapScreen, we should see the rider count or map elements
    // Using a more generic check first
    expect(find.text('1 motosikletçi'), findsOneWidget);

    // Switch to "Noktalar"
    await tester.tap(find.text('Noktalar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);

    // Switch to "Grup Sürüşleri"
    await tester.tap(find.text('Grup Sürüşleri'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Rotalar'), findsOneWidget);
  });
}
