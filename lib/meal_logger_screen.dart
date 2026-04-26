import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealLoggerScreen extends StatefulWidget {
  final String userId;
  const MealLoggerScreen({super.key, required this.userId});

  @override
  State<MealLoggerScreen> createState() => _MealLoggerScreenState();
}

class _MealLoggerScreenState extends State<MealLoggerScreen> {
  List<Map<String, dynamic>> _meals = [];
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFats = 0;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final querySnapshot = await FirebaseFirestore.instance
        .collection('nutrition')
        .where('user_id', isEqualTo: widget.userId)
        .where('date', isEqualTo: today)
        .get();
    
    final data = querySnapshot.docs.map((doc) {
      final map = doc.data();
      map['id'] = doc.id;
      return map;
    }).toList();
    
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (var m in data) {
      cal += (m['calories'] as num? ?? 0).toDouble();
      pro += (m['protein'] as num? ?? 0).toDouble();
      carb += (m['carbs'] as num? ?? 0).toDouble();
      fat += (m['fats'] as num? ?? 0).toDouble();
    }

    setState(() {
      _meals = data;
      _totalCalories = cal;
      _totalProtein = pro;
      _totalCarbs = carb;
      _totalFats = fat;
    });
  }

  void _showMealForm([Map<String, dynamic>? meal]) {
    final foodCtrl = TextEditingController(text: meal?['food'] ?? '');
    final calCtrl = TextEditingController(text: meal?['calories']?.toString() ?? '');
    final proCtrl = TextEditingController(text: meal?['protein']?.toString() ?? '');
    final carbCtrl = TextEditingController(text: meal?['carbs']?.toString() ?? '');
    final fatCtrl = TextEditingController(text: meal?['fats']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(meal == null ? 'Log New Meal' : 'Edit Meal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(controller: foodCtrl, decoration: const InputDecoration(labelText: 'Food Name')),
              TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Calories (kcal)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: proCtrl, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: carbCtrl, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: fatCtrl, decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final data = {
                    'user_id': widget.userId,
                    'food': foodCtrl.text,
                    'calories': double.tryParse(calCtrl.text) ?? 0.0,
                    'protein': double.tryParse(proCtrl.text) ?? 0.0,
                    'carbs': double.tryParse(carbCtrl.text) ?? 0.0,
                    'fats': double.tryParse(fatCtrl.text) ?? 0.0,
                    'date': meal?['date'] ?? DateTime.now().toIso8601String().substring(0, 10),
                  };

                  if (meal == null) {
                    await FirebaseFirestore.instance.collection('nutrition').add(data);
                  } else {
                    await FirebaseFirestore.instance.collection('nutrition').doc(meal['id']).update(data);
                  }
                  Navigator.pop(ctx);
                  _loadMeals();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Meal log saved!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFFD0FD3E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      )
                    );
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Save Meal'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2025),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Column(
              children: [
                const Text("Today's Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Cals', _totalCalories, 'kcal'),
                    _summaryItem('Pro', _totalProtein, 'g'),
                    _summaryItem('Carb', _totalCarbs, 'g'),
                    _summaryItem('Fat', _totalFats, 'g'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _meals.isEmpty
                ? const Center(child: Text('No meals logged today.'))
                : ListView.builder(
                    itemCount: _meals.length,
                    itemBuilder: (ctx, i) {
                      final m = _meals[i];
                      return ListTile(
                        title: Text(m['food'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${(m['calories'] as num? ?? 0).toStringAsFixed(2)} kcal | P: ${(m['protein'] as num? ?? 0).toStringAsFixed(2)}g C: ${(m['carbs'] as num? ?? 0).toStringAsFixed(2)}g F: ${(m['fats'] as num? ?? 0).toStringAsFixed(2)}g'),
                        onTap: () => _showMealForm(m),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('nutrition').doc(m['id']).delete();
                            _loadMeals();
                          },
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showMealForm(),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Log New Meal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0FD3E),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, String unit) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD0FD3E))),
        Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
