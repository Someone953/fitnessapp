import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  double _bmi = 0.0;
  String _bmiStatus = '';
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await DbHelper.query('profile');
    setState(() => _history = data);
  }

  String? _validate(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (double.tryParse(value) == null) return 'Number only';
    return null;
  }

  void _calculateBMI() {  // Practical 3
    if (_weightCtrl.text.isEmpty || _heightCtrl.text.isEmpty) return;
    final weight = double.parse(_weightCtrl.text);
    final height = double.parse(_heightCtrl.text);
    final bmi = weight / pow(height, 2);

    setState(() {
      _bmi = bmi;
      _bmiStatus = bmi < 18.5 ? 'Underweight' : (bmi > 25 ? 'Overweight' : 'Normal');
    });

    // CRUD Create (Practical 9)
    DbHelper.insert('profile', {
      'name': 'User',
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'goal': 'Build Muscle',
      'date': DateTime.now().toIso8601String().substring(0, 10)
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile & BMI Calculator', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          TextField(
            controller: _weightCtrl,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _heightCtrl,
            decoration: const InputDecoration(labelText: 'Height (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _calculateBMI, child: const Text('Calculate BMI')),
          Text('BMI: ${_bmi.toStringAsFixed(2)} $_bmiStatus'),
          const SizedBox(height: 20),
          const Text('Weight Progress (Line Chart)'),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: _history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['bmi'] ?? 0)).toList(),
                    isCurved: true,
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}