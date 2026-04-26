import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onCreateProfile;
  final VoidCallback onEditProfile;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.onCreateProfile,
    required this.onEditProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _weightPromptCtrl = TextEditingController();
  final _goalWeightCtrl = TextEditingController();
  
  double _todayCalories = 0;
  double _todayProtein = 0;
  double _todayCarbs = 0;
  double _todayFats = 0;
  int _todayWorkouts = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
  }

  Future<void> _loadTodayStats() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    // Load nutrition
    final nutritionSnapshot = await FirebaseFirestore.instance
        .collection('nutrition')
        .where('user_id', isEqualTo: widget.userId)
        .where('date', isEqualTo: today)
        .get();
        
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (var doc in nutritionSnapshot.docs) {
      final d = doc.data();
      cal += (d['calories'] as num? ?? 0).toDouble();
      pro += (d['protein'] as num? ?? 0).toDouble();
      carb += (d['carbs'] as num? ?? 0).toDouble();
      fat += (d['fats'] as num? ?? 0).toDouble();
    }
    
    // Load workouts
    final workoutSnapshot = await FirebaseFirestore.instance
        .collection('workout_logs')
        .where('user_id', isEqualTo: widget.userId)
        .where('date', isEqualTo: today)
        .get();

    if (mounted) {
      setState(() {
        _todayCalories = cal;
        _todayProtein = pro;
        _todayCarbs = carb;
        _todayFats = fat;
        _todayWorkouts = workoutSnapshot.docs.length;
      });
    }
  }

  Future<void> _saveWeightUpdate(double weight, Map<String, dynamic> profile) async {
    final weightNum = weight.toDouble();
    final heightNum = (profile['height'] as num).toDouble();
    final bmi = weightNum / pow(heightNum, 2);
    
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final existingDocs = await FirebaseFirestore.instance
        .collection('profiles')
        .where('user_id', isEqualTo: widget.userId)
        .where('date', isEqualTo: today)
        .get();

    if (existingDocs.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(existingDocs.docs.first.id)
          .update({
        'weight': weightNum,
        'bmi': bmi,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      final newProfileData = Map<String, dynamic>.from(profile);
      newProfileData.remove('id');
      
      await FirebaseFirestore.instance.collection('profiles').add({
        ...newProfileData,
        'weight': weightNum,
        'bmi': bmi,
        'date': today,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Weight progress updated!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFD0FD3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateGoalWeight(double? target, Map<String, dynamic> lastProfile) async {
    if (target == null) return;
    
    final query = await FirebaseFirestore.instance
        .collection('profiles')
        .where('user_id', isEqualTo: widget.userId)
        .where('date', isEqualTo: lastProfile['date'])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({'weight_target': target});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Goal weight updated!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFD0FD3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showCreateProfilePopUp(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    String gender = 'Male';
    String fitnessLevel = 'Beginner';
    List<String> selectedGoals = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Create Your Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Profile Name')),
                TextField(
                  controller: ageCtrl, 
                  decoration: const InputDecoration(labelText: 'Age'), 
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl, 
                        decoration: const InputDecoration(labelText: 'Weight (kg)'), 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      )
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: heightCtrl, 
                        decoration: const InputDecoration(labelText: 'Height (m)'), 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      )
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setModalState(() => gender = val!),
                ),
                DropdownButtonFormField<String>(
                  value: fitnessLevel,
                  decoration: const InputDecoration(labelText: 'Fitness Level'),
                  items: ['Beginner', 'Intermediate', 'Advanced'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (val) => setModalState(() => fitnessLevel = val!),
                ),
                const SizedBox(height: 15),
                const Text('Fitness Goals:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['Lose Weight', 'Build Muscle', 'Improve Stamina'].map((goal) {
                    final isSelected = selectedGoals.contains(goal);
                    return FilterChip(
                      label: Text(goal, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                      selected: isSelected,
                      selectedColor: const Color(0xFFD0FD3E),
                      checkmarkColor: Colors.black,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) selectedGoals.add(goal);
                          else selectedGoals.remove(goal);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || weightCtrl.text.isEmpty || heightCtrl.text.isEmpty) return;
                
                final age = int.tryParse(ageCtrl.text);
                if (age == null && ageCtrl.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Age must be a whole number')));
                  return;
                }

                final w = double.tryParse(weightCtrl.text);
                final h = double.tryParse(heightCtrl.text);
                if (w == null || h == null) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight and Height must be numbers')));
                   return;
                }
                
                final weight = double.parse(w.toStringAsFixed(2));
                final height = double.parse(h.toStringAsFixed(2));
                final bmi = weight / pow(height, 2);

                await FirebaseFirestore.instance.collection('profiles').add({
                  'user_id': widget.userId,
                  'name': nameCtrl.text,
                  'age': age,
                  'gender': gender,
                  'weight': weight,
                  'height': height,
                  'bmi': bmi,
                  'fitness_level': fitnessLevel,
                  'goals': selectedGoals,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0FD3E),
                foregroundColor: Colors.black,
              ),
              child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('profiles')
          .where('user_id', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 80, color: Color(0xFFD0FD3E)),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to myFitLah!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please create your profile to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => _showCreateProfilePopUp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0FD3E),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Create Profile'),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();
        
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          
          final dateCompare = (dataB['date'] as String).compareTo(dataA['date'] as String);
          if (dateCompare != 0) return dateCompare;
          
          final tsA = dataA['timestamp'] as Timestamp?;
          final tsB = dataB['timestamp'] as Timestamp?;
          if (tsA != null && tsB != null) return tsB.compareTo(tsA);
          
          return 0;
        });

        final profile = docs.first.data() as Map<String, dynamic>;
        final profileImage = profile['profile_image'] as String?;

        if (_goalWeightCtrl.text.isEmpty && profile['weight_target'] != null) {
          _goalWeightCtrl.text = profile['weight_target'].toString();
        }
        
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final weightLoggedToday = profile['date'] == today;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFD0FD3E).withOpacity(0.2),
                      backgroundImage: (profileImage != null && profileImage.isNotEmpty && File(profileImage).existsSync())
                          ? FileImage(File(profileImage))
                          : null,
                      child: (profileImage == null || profileImage.isEmpty || !File(profileImage).existsSync())
                          ? const Icon(Icons.person, size: 40, color: Color(0xFFD0FD3E))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Check your STATS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD0FD3E),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildHeader(profile),
              const SizedBox(height: 20),
              _buildTodaySummary(),
              const SizedBox(height: 20),
              _buildStatsCard(profile),
              const SizedBox(height: 20),
              _buildGoalsSection(profile),
              const SizedBox(height: 20),
              const Text('Weight Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildWeightGraph(docs, profile['weight_target']),
              const SizedBox(height: 20),
              _buildWeightPromptWidget(profile, weightLoggedToday),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeightGraph(List<QueryDocumentSnapshot> docs, dynamic targetWeight) {
    if (docs.isEmpty) return const SizedBox.shrink();
    
    // Sort oldest to newest (ascending) for the line chart
    final data = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    data.sort((a, b) {
      final dateCompare = (a['date'] as String).compareTo(b['date'] as String);
      if (dateCompare != 0) return dateCompare;
      
      final tsA = a['timestamp'] as Timestamp?;
      final tsB = b['timestamp'] as Timestamp?;
      if (tsA != null && tsB != null) return tsA.compareTo(tsB);
      if (tsA == null && tsB != null) return -1;
      if (tsA != null && tsB == null) return 1;
      
      return 0;
    });

    final recentData = data.length > 10 ? data.sublist(data.length - 10) : data;

    return Card(
      elevation: 0,
      color: const Color(0xFF1C2025),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: recentData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['weight'] as num).toDouble())).toList(),
                  isCurved: true,
                  color: const Color(0xFFD0FD3E),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true, 
                    color: const Color(0xFFD0FD3E).withOpacity(0.1)
                  ),
                ),
              ],
              extraLinesData: ExtraLinesData(
                horizontalLines: targetWeight != null ? [
                  HorizontalLine(
                    y: (targetWeight as num).toDouble(),
                    color: Colors.white.withOpacity(0.4),
                    strokeWidth: 1,
                    dashArray: [8, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      labelResolver: (line) => 'Goal: ${line.y}kg',
                    ),
                  ),
                ] : [],
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, 
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  )
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < recentData.length) {
                        String dateStr = recentData[index]['date'].toString();
                        String date = dateStr.length >= 10 ? dateStr.substring(5) : dateStr;
                        return Text(date, style: const TextStyle(fontSize: 9, color: Colors.grey));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightPromptWidget(Map<String, dynamic> profile, bool weightLoggedToday) {
    final themeColor = const Color(0xFFD0FD3E);
    final bgColor = const Color(0xFF1C2025);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight, color: themeColor),
              const SizedBox(width: 8),
              Text(
                weightLoggedToday ? 'Weight Logged' : 'Log Daily Weight', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep track of your progress. Your current goal is ${profile['weight_target'] ?? 'not set'} kg.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightPromptCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter weight (kg)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final rawWeight = double.tryParse(_weightPromptCtrl.text);
                  if (rawWeight != null) {
                    final weight = double.parse(rawWeight.toStringAsFixed(2));
                    await _saveWeightUpdate(weight, profile);
                    _weightPromptCtrl.clear();
                  } else if (_weightPromptCtrl.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight must be a number')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${profile['name'] ?? 'User'}!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const Text(
          'Your fitness journey looks good!',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2025),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn('Weight', '${profile['weight']} kg'),
              _statColumn('Height', '${profile['height']} m'),
              _statColumn('BMI', profile['bmi']?.toStringAsFixed(1) ?? '0.0'),
            ],
          ),
          const Divider(height: 30, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, color: Color(0xFFD0FD3E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Fitness Level: ${profile['fitness_level'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(Map<String, dynamic> profile) {
    final List<dynamic> goals = profile['goals'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Goals Tracker',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        if (goals.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals.map((goal) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD0FD3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD0FD3E).withOpacity(0.3)),
              ),
              child: Text(
                goal.toString(),
                style: const TextStyle(color: Color(0xFFD0FD3E), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFFD0FD3E), size: 20),
              const SizedBox(width: 12),
              const Text('Target Weight', style: TextStyle(color: Colors.white70)),
              const Spacer(),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _goalWeightCtrl,
                  style: const TextStyle(color: Color(0xFFD0FD3E), fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '---',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (val) {
                    final raw = double.tryParse(val);
                    if (raw != null) {
                      _updateGoalWeight(double.parse(raw.toStringAsFixed(2)), profile);
                    }
                  },
                ),
              ),
              const Text('kg', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0FD3E).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFFD0FD3E), size: 18),
                onPressed: _loadTodayStats,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('Cals', _todayCalories, 'kcal'),
              _summaryItem('Pro', _todayProtein, 'g'),
              _summaryItem('Workouts', _todayWorkouts.toDouble(), 'Done', isInt: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, String unit, {bool isInt = false}) {
    return Column(
      children: [
        Text(
          isInt ? value.toInt().toString() : value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD0FD3E)),
        ),
        Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
