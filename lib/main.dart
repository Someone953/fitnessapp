import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'profile_screen.dart';   // Member 1
import 'workout_screen.dart';  // Member 2
import 'progress_screen.dart'; // Member 3
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbHelper.init();
  await DbHelper.insertSampleData();
  runApp(const FitWellApp());
}
///inibibib
class FitWellApp extends StatelessWidget {
  const FitWellApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitWell - SDG 3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProfileScreen(),    // Member 1
    const WorkoutScreen(),    // Member 2
    const ProgressScreen(),   // Member 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitWell - SDG 3 Good Health & Well-Being'),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'Progress'),
        ],
      ),
    );
  }
}