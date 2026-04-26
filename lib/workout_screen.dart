import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkoutScreen extends StatefulWidget {
  final String userId;
  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<Map<String, dynamic>> _loggedWorkouts = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLoggedWorkouts();
  }

  Future<void> _loadLoggedWorkouts() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('workout_logs')
        .where('user_id', isEqualTo: widget.userId)
        .where('date', isEqualTo: dateStr)
        .get();

    setState(() {
      _loggedWorkouts = querySnapshot.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id;
        return map;
      }).toList();
      _isLoading = false;
    });
  }

  void _showLogWorkoutDialog() async {
    // 1. Fetch planners to choose a routine
    final plannerSnapshot = await FirebaseFirestore.instance
        .collection('planner_containers')
        .where('user_id', isEqualTo: widget.userId)
        .get();

    if (plannerSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a routine in the Planner first!')),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Routine to Log'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: plannerSnapshot.docs.length,
            itemBuilder: (context, index) {
              final routine = plannerSnapshot.docs[index];
              return ListTile(
                title: Text(routine['title'] ?? 'Routine'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBlockSelectionDialog(routine.id);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBlockSelectionDialog(String routineId) async {
    final blockSnapshot = await FirebaseFirestore.instance
        .collection('planner_blocks')
        .where('container_id', isEqualTo: routineId)
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Workout Day/Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: blockSnapshot.docs.length,
            itemBuilder: (context, index) {
              final block = blockSnapshot.docs[index];
              return ListTile(
                title: Text(block['title'] ?? 'Workout'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showExerciseSelectionDialog(block.id);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showExerciseSelectionDialog(String blockId) async {
    final exerciseSnapshot = await FirebaseFirestore.instance
        .collection('planner_exercises')
        .where('block_id', isEqualTo: blockId)
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Exercise'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: exerciseSnapshot.docs.length,
            itemBuilder: (context, index) {
              final ex = exerciseSnapshot.docs[index];
              return ListTile(
                title: Text(ex['name'] ?? 'Exercise'),
                subtitle: Text('Planned: ${ex['sets']} sets x ${ex['reps']} reps'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLogForm(ex.data(), ex.id);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLogForm(Map<String, dynamic> exData, String exId, [Map<String, dynamic>? existingLog]) {
    final setsCtrl = TextEditingController(text: existingLog?['sets']?.toString() ?? exData['sets'].toString());
    final repsCtrl = TextEditingController(text: existingLog?['reps']?.toString() ?? exData['reps'].toString());
    final weightCtrl = TextEditingController(text: existingLog?['weight']?.toString() ?? '');
    DateTime logDate = existingLog != null ? DateTime.parse(existingLog['date']) : _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Log: ${exData['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  title: Text("Date: ${DateFormat('yyyy-MM-dd').format(logDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: logDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setModalState(() => logDate = picked);
                    }
                  },
                ),
                TextField(controller: setsCtrl, decoration: const InputDecoration(labelText: 'Sets Done'), keyboardType: TextInputType.number),
                TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'Reps Done'), keyboardType: TextInputType.number),
                TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'user_id': widget.userId,
                      'exercise_id': exId,
                      'exercise_name': exData['name'],
                      'sets': int.tryParse(setsCtrl.text) ?? 0,
                      'reps': int.tryParse(repsCtrl.text) ?? 0,
                      'weight': double.tryParse(weightCtrl.text) ?? 0.0,
                      'date': DateFormat('yyyy-MM-dd').format(logDate),
                      'timestamp': FieldValue.serverTimestamp(),
                    };

                    if (existingLog == null) {
                      await FirebaseFirestore.instance.collection('workout_logs').add(data);
                    } else {
                      await FirebaseFirestore.instance.collection('workout_logs').doc(existingLog['id']).update(data);
                    }
                    Navigator.pop(ctx);
                    _loadLoggedWorkouts();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Workout log saved!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFFD0FD3E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        )
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Save Log'),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Logs for: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color(0xFFD0FD3E)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadLoggedWorkouts();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loggedWorkouts.isEmpty
                    ? const Center(child: Text('No workouts logged for this date.'))
                    : ListView.builder(
                        itemCount: _loggedWorkouts.length,
                        itemBuilder: (ctx, i) {
                          final log = _loggedWorkouts[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(log['exercise_name'] ?? 'Exercise', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${log['sets']} sets x ${log['reps']} reps @ ${(log['weight'] as num? ?? 0).toStringAsFixed(2)} kg'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('workout_logs').doc(log['id']).delete();
                                  _loadLoggedWorkouts();
                                },
                              ),
                              onTap: () async {
                                // Re-fetch exercise data to allow editing
                                final exDoc = await FirebaseFirestore.instance.collection('planner_exercises').doc(log['exercise_id']).get();
                                if (exDoc.exists) {
                                  _showLogForm(exDoc.data()!, exDoc.id, log);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogWorkoutDialog,
        label: const Text('Log Workout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
        backgroundColor: const Color(0xFFD0FD3E),
      ),
    );
  }
}
