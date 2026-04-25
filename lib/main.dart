import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';
import 'meal_logger_screen.dart';
import 'planner_screen.dart';
import 'exercise_library_screen.dart';
import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ProfileScreen(userId: widget.userId),
      const ExerciseLibraryScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Meals'),
        ],
      ),
    );
  }
}
