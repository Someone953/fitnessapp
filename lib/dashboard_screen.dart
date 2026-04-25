import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight progress updated!')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal weight updated!')));
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
                TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: heightCtrl, decoration: const InputDecoration(labelText: 'Height (m)'), keyboardType: TextInputType.number)),
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
                      label: Text(goal, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || weightCtrl.text.isEmpty || heightCtrl.text.isEmpty) return;
                
                final w = double.tryParse(weightCtrl.text) ?? 0;
                final h = double.tryParse(heightCtrl.text) ?? 1;
                final bmi = w / pow(h, 2);

                await FirebaseFirestore.instance.collection('profiles').add({
                  'user_id': widget.userId,
                  'name': nameCtrl.text,
                  'age': int.tryParse(ageCtrl.text),
                  'gender': gender,
                  'weight': w,
                  'height': h,
                  'bmi': bmi,
                  'fitness_level': fitnessLevel,
                  'goals': selectedGoals,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save Profile'),
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
                const Icon(Icons.person_add, size: 80, color: Colors.teal),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to FitWell!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeader(profile),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: widget.onEditProfile,
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
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
      elevation: 2,
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
                  color: Colors.teal,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true, 
                    color: Colors.teal.withOpacity(0.15)
                  ),
                ),
              ],
              extraLinesData: ExtraLinesData(
                horizontalLines: targetWeight != null ? [
                  HorizontalLine(
                    y: (targetWeight as num).toDouble(),
                    color: Colors.redAccent.withOpacity(0.6),
                    strokeWidth: 2,
                    dashArray: [8, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
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
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  )
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < recentData.length) {
                        bool isLast = index == recentData.length - 1;
                        bool isFirst = index == 0;
                        if (!isFirst && !isLast && index % 2 != 0) return const SizedBox.shrink();

                        String dateStr = recentData[index]['date'].toString();
                        String date = dateStr.length >= 10 ? dateStr.substring(5) : dateStr;
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            date, 
                            style: TextStyle(
                              fontSize: 10, 
                              color: isLast ? Colors.teal : Colors.grey,
                              fontWeight: isLast ? FontWeight.bold : FontWeight.normal
                            )
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true, 
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                  left: BorderSide(color: Colors.grey.shade300),
                )
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y} kg', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList(),
                )
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightPromptWidget(Map<String, dynamic> profile, bool weightLoggedToday) {
    final themeColor = weightLoggedToday ? Colors.teal : Colors.orange;
    final bgColor = weightLoggedToday ? Colors.teal.shade50 : Colors.orange.shade50;
    final borderColor = weightLoggedToday ? Colors.teal.shade200 : Colors.orange.shade200;

    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight, color: themeColor),
                const SizedBox(width: 8),
                Text(
                  weightLoggedToday ? 'Current Weight Logged' : 'Weight Progress Tracker', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor)
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your latest weight: ${profile['weight']} kg. Log your weight to update your profile and chart.',
              style: TextStyle(color: themeColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightPromptCtrl,
                    decoration: InputDecoration(
                      hintText: '${profile['weight']} kg',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: themeColor)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final newWeight = double.tryParse(_weightPromptCtrl.text);
                    if (newWeight != null) {
                      await _saveWeightUpdate(newWeight, profile);
                      _weightPromptCtrl.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
                  child: const Text('Save'),
                ),
              ],
            ),
            if (!weightLoggedToday) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _saveWeightUpdate((profile['weight'] as num).toDouble(), profile),
                child: Text('Log last weight (${profile['weight']} kg) instead', style: TextStyle(color: themeColor)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${profile['name'] ?? 'User'}!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const Text(
          'Here is your fitness overview',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const Divider(height: 30),
            Text(
              'Fitness Level: ${profile['fitness_level'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(Map<String, dynamic> profile) {
    final List<dynamic> goals = profile['goals'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Current Goals',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (goals.isEmpty)
          const Text('No goals set yet.')
        else
          Wrap(
            spacing: 8,
            children: goals.map((goal) => Chip(
              label: Text(goal.toString()),
              backgroundColor: Colors.teal.shade50,
              side: BorderSide(color: Colors.teal.shade200),
            )).toList(),
          ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Icon(Icons.track_changes, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            const Text('Goal Weight: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(width: 5),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _goalWeightCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'kg',
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (val) => _updateGoalWeight(double.tryParse(val), profile),
              ),
            ),
            const SizedBox(width: 5),
            const Text('kg', style: TextStyle(fontSize: 16)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.teal),
              onPressed: () => _updateGoalWeight(double.tryParse(_goalWeightCtrl.text), profile),
              tooltip: 'Update Goal',
            )
          ],
        ),
      ],
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
