import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightTargetCtrl = TextEditingController();
  final _stepGoalCtrl = TextEditingController();
  final _workoutGoalCtrl = TextEditingController();

  String _gender = 'Male';
  String _fitnessLevel = 'Beginner';
  String _fitnessGoal = 'Build Muscle';

  double _bmi = 0.0;
  String _bmiStatus = '';
  List<Map<String, dynamic>> _history = [];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _fitnessGoals = ['Lose Weight', 'Build Muscle', 'Improve Stamina'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbHelper.query('profile', userId: widget.userId);
    setState(() {
      // Sort by date locally since Firestore query was simple
      data.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
      _history = data;
      if (data.isNotEmpty) {
        final last = data.first; 
        _weightCtrl.text = last['weight']?.toString() ?? '';
        _heightCtrl.text = last['height']?.toString() ?? '';
        _ageCtrl.text = last['age']?.toString() ?? '';
        _weightTargetCtrl.text = last['weight_target']?.toString() ?? '';
        _stepGoalCtrl.text = last['step_goal']?.toString() ?? '';
        _workoutGoalCtrl.text = last['workout_goal']?.toString() ?? '';
        _gender = last['gender'] ?? 'Male';
        _fitnessLevel = last['fitness_level'] ?? 'Beginner';
        _fitnessGoal = last['goal'] ?? 'Build Muscle';
        _bmi = last['bmi'] ?? 0.0;
        _bmiStatus = _bmi < 18.5 ? 'Underweight' : (_bmi > 25 ? 'Overweight' : 'Normal');
      }
    });
  }

  void _saveProfile() async {
    if (_weightCtrl.text.isEmpty || _heightCtrl.text.isEmpty) return;
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final height = double.tryParse(_heightCtrl.text) ?? 1;
    final bmi = weight / pow(height, 2);

    setState(() {
      _bmi = bmi;
      _bmiStatus = bmi < 18.5 ? 'Underweight' : (bmi > 25 ? 'Overweight' : 'Normal');
    });

    await DbHelper.insert('profile', {
      'user_id': widget.userId,
      'name': 'User',
      'age': int.tryParse(_ageCtrl.text),
      'gender': _gender,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'fitness_level': _fitnessLevel,
      'goal': _fitnessGoal,
      'weight_target': double.tryParse(_weightTargetCtrl.text),
      'step_goal': int.tryParse(_stepGoalCtrl.text),
      'workout_goal': int.tryParse(_workoutGoalCtrl.text),
      'date': DateTime.now().toIso8601String().substring(0, 10)
    });
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageCtrl,
                    decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    decoration: const InputDecoration(labelText: 'Height (m)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _fitnessLevel,
              decoration: const InputDecoration(labelText: 'Fitness Level', border: OutlineInputBorder()),
              items: _fitnessLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) => setState(() => _fitnessLevel = val!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _fitnessGoal,
              decoration: const InputDecoration(labelText: 'Fitness Goal', border: OutlineInputBorder()),
              items: _fitnessGoals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _fitnessGoal = val!),
            ),
            const SizedBox(height: 20),
            const Text('Goal Setting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _weightTargetCtrl,
              decoration: const InputDecoration(labelText: 'Weight Target (kg)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _stepGoalCtrl,
              decoration: const InputDecoration(labelText: 'Daily Step Goal', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _workoutGoalCtrl,
              decoration: const InputDecoration(labelText: 'Weekly Workout Goal', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('Save Profile & Calculate BMI'),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text('Current BMI: ${_bmi.toStringAsFixed(2)} ($_bmiStatus)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 30),
            const Text('Weight Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: _history.isEmpty 
                ? const Center(child: Text('No history data'))
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _history.reversed.toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['weight']?.toDouble() ?? 0)).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: true),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
