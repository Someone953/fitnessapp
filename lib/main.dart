import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';
import 'meal_logger_screen.dart';
import 'planner_screen.dart';
import 'exercise_library_screen.dart';
import 'dashboard_screen.dart';
import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(const FitWellApp());
}

class FitWellApp extends StatelessWidget {
  const FitWellApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myFitLah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121417),
        primaryColor: const Color(0xFFD0FD3E),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0FD3E),
          brightness: Brightness.dark,
          primary: const Color(0xFFD0FD3E),
          surface: const Color(0xFF1C2025),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121417),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C2025),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C2025),
          selectedItemColor: Color(0xFFD0FD3E),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const AuthScreen();
    }
    return HomeScreen(userId: _user!.uid, onLogout: _logout);
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.userId, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _updateScreens();
  }

  void _updateScreens() {
    _screens = [
      DashboardScreen(
        userId: widget.userId,
        onCreateProfile: () {
          setState(() {
            _currentIndex = 1; // Navigate to Profile tab
          });
        },
        onEditProfile: () {
          setState(() {
            _currentIndex = 1; // Navigate to Profile tab
          });
        },
      ),
      ProfileScreen(userId: widget.userId),
      const ExerciseLibraryScreen(),
      PlannerScreen(userId: widget.userId),
      WorkoutScreen(userId: widget.userId),
      MealLoggerScreen(userId: widget.userId),
    ];
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'My Profile';
      case 2: return 'Exercise Library';
      case 3: return 'Workout Planner';
      case 4: return 'Workout Logs';
      case 5: return 'Meal Tracker';
      default: return 'myFitLah';
    }
  }

  String _getPageSubtitle() {
    if (_currentIndex == 2) return 'Explore our database of exercises';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    _updateScreens();
    final subtitle = _getPageSubtitle();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: subtitle.isNotEmpty ? 140 : 120,
        flexibleSpace: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0FD3E).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFFD0FD3E),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'myFitLah',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -0.5,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Text(
                            'Your Fitness Companion',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                      onPressed: widget.onLogout,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              if (_currentIndex > 1)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPageTitle(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_rounded), label: 'Meals'),
        ],
      ),
    );
  }
}
