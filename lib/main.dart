import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';
import 'meal_logger_screen.dart';
import 'planner_screen.dart';
import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbHelper.init();
  runApp(const FitWellApp());
}

class FitWellApp extends StatelessWidget {
  const FitWellApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitWell - SDG 3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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
  int? _loggedInUserId;

  void _onLoginSuccess(int userId) {
    setState(() {
      _loggedInUserId = userId;
    });
  }

  void _logout() {
    setState(() {
      _loggedInUserId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedInUserId == null) {
      return AuthScreen(onLoginSuccess: _onLoginSuccess);
    }
    return HomeScreen(userId: _loggedInUserId!, onLogout: _logout);
  }
}

class HomeScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.userId, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ProfileScreen(userId: widget.userId),
      PlannerScreen(userId: widget.userId),
      WorkoutScreen(userId: widget.userId),
      MealLoggerScreen(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitWell - SDG 3'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Meals'),
        ],
      ),
    );
  }
}
