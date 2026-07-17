import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sampah_online/firebase_options.dart';
import 'package:sampah_online/welcome_screen.dart';
import 'package:sampah_online/services/auth_service.dart';
import 'package:sampah_online/services/notification_service.dart';
import 'package:sampah_online/screens/login_screen.dart';
import 'package:sampah_online/screens/register_screen.dart';
import 'package:sampah_online/screens/user/user_home.dart';
import 'package:sampah_online/screens/driver/driver_home.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting(
    'id_ID',
    null,
  ).then((_) => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthService _authService;
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _initializeSecondaryServices();
  }

  Future<void> _initializeSecondaryServices() async {
    try {
      await Future.wait([
        FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        ),
        NotificationService().init(authService: _authService),
      ]);
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _error = null;
      });
    } catch (e) {
      debugPrint("Inisialisasi background bermasalah: $e");
      if (mounted) {
        setState(() => _isReady = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _authService)],
      child: MaterialApp(
        title: 'GoTrash',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: WelcomeScreen(isReady: _isReady, initError: _error),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/user': (context) => const UserHome(),
          '/driver': (context) => const DriverHomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
