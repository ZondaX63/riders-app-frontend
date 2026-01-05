import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/logger_config.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/profile_screen.dart'; // Contains ModernProfileScreen
import 'screens/chat_list_screen.dart';
import 'widgets/modern_bottom_nav.dart';
import 'theme/app_theme.dart';
import 'screens/grouprides_screen.dart';
import 'screens/app_settings_screen.dart';
import 'screens/explore_screen_new.dart';
import 'providers/map_pin_provider.dart';
import 'services/socket_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configure logging
  LoggerConfig.configure();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const CreatePostScreen(),
    const ChatListScreen(),
    const ModernProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<ApiService>(),
            context.read<StorageService>(),
            widget.prefs,
          ),
        ),
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, SocketService>(
          create: (context) => SocketService(context.read<ApiService>()),
          update: (context, api, auth, socket) {
            socket ??= SocketService(api);
            socket.updateAuth(auth);
            return socket;
          },
        ),
        ChangeNotifierProxyProvider3<ApiService, SocketService, AuthProvider, MapPinProvider>(
          create: (context) => MapPinProvider(
            apiService: context.read<ApiService>(),
            socketService: context.read<SocketService>(),
            currentUserId: context.read<AuthProvider>().currentUser?.id,
          ),
          update: (context, api, socket, auth, provider) {
            provider ??= MapPinProvider(
              apiService: api,
              socketService: socket,
              currentUserId: auth.currentUser?.id,
            );
            provider.updateDependencies(
              socketService: socket,
              currentUserId: auth.currentUser?.id,
            );
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'MotoSocial',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/group-rides': (context) => const GroupRidesScreen(),
          '/settings': (context) => const AppSettingsScreen(),
          '/search': (context) => const SearchScreen(),
          '/main': (context) => Scaffold(
                body: _screens[_selectedIndex],
                bottomNavigationBar: ModernBottomNav(
                  currentIndex: _selectedIndex,
                  onTabSelected: (i) {
                    setState(() => _selectedIndex = i);
                  },
                  onCreate: () {
                    setState(() => _selectedIndex = 2);
                  },
                ),
              ),
        },
      ),
    );
  }
}
