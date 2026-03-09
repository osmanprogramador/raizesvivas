import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb and defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart'; // Import created options
import 'providers/auth_provider.dart';
import 'providers/content_provider.dart';
import 'providers/history_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_web_layout.dart';
import 'widgets/splash_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with conditional options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error (ignore if already init): $e');
  }

  // Configure Firestore for offline persistence
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firestore persistence init error: $e');
  }

  // Inicializa o intl para suporte a locales
  await initializeDateFormatting('pt_BR', null);

  // Set status bar to transparent with light icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness:
                  themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: themeProvider.backgroundColor,
              primaryColor: ThemeProvider.primaryGreen,
              colorScheme: ColorScheme(
                brightness: themeProvider.isDarkMode
                    ? Brightness.dark
                    : Brightness.light,
                primary: ThemeProvider.primaryGreen,
                onPrimary: Colors.white,
                secondary: ThemeProvider.primaryGreen,
                onSecondary: Colors.white,
                error: const Color(AppConstants.deleteRed),
                onError: Colors.white,
                surface: themeProvider.cardColor,
                onSurface: themeProvider.textColor,
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: themeProvider.cardColor,
                selectedItemColor: ThemeProvider.primaryGreen,
                unselectedItemColor: themeProvider.textSecondaryColor,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: ThemeProvider.primaryGreen,
                elevation: 0,
                centerTitle: false,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: Colors.white),
              ),
            ),
            // Web: full screen, Mobile: centered with max width
            builder: (context, child) {
              if (kIsWeb) {
                // Web: sem limitação de largura, full screen
                return child!;
              } else if (defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.macOS) {
                // Desktop: centralizado com largura máxima
                return Container(
                  color: themeProvider.backgroundColor,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: child,
                    ),
                  ),
                );
              }
              return child!;
            },
            home: kIsWeb ? const WebSplashWrapper() : const SplashWrapper(),
          );
        },
      ),
    );
  }
}

// Wrapper to show splash screen then navigate to main
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    // Show splash for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// Web Splash Wrapper - checks auth and redirects to admin or login
class WebSplashWrapper extends StatefulWidget {
  const WebSplashWrapper({super.key});

  @override
  State<WebSplashWrapper> createState() => _WebSplashWrapperState();
}

class _WebSplashWrapperState extends State<WebSplashWrapper> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToWeb();
    });
  }

  Future<void> _navigateToWeb() async {
    // Check login status
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkLoginStatus();

    // Small delay for splash
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      // Navigate based on auth status
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              authProvider.isAdmin
                  ? const AdminWebLayout()
                  : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkLoginStatus(); // Check saved session
      context.read<ContentProvider>().loadContents();
      context.read<HistoryProvider>().loadHistory();
    });
  }

  List<Widget> _getScreens() {
    final authProvider = context.watch<AuthProvider>();

    return [
      const HomeScreen(),
      const HistoryScreen(),
      authProvider.isAdmin ? const AdminDashboardScreen() : const LoginScreen(),
    ];
  }

  String _getBottomNavLabel(int index) {
    final authProvider = context.watch<AuthProvider>();

    if (index == 2) {
      return authProvider.isAdmin ? 'Admin' : 'Login';
    }
    return ['Início', 'Histórico'][index];
  }

  IconData _getBottomNavIcon(int index) {
    final authProvider = context.watch<AuthProvider>();

    if (index == 2) {
      return authProvider.isAdmin ? Icons.admin_panel_settings : Icons.login;
    }
    return [Icons.home, Icons.history][index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreens()[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(AppConstants.cardMedium), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: List.generate(
            3,
            (index) => BottomNavigationBarItem(
              icon: Icon(_getBottomNavIcon(index)),
              label: _getBottomNavLabel(index),
            ),
          ),
        ),
      ),
    );
  }
}
