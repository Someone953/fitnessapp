import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'notification_service.dart';

class PlannerScreen extends StatefulWidget {
  final String userId;
  const PlannerScreen({super.key, required this.userId});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  List<Map<String, dynamic>> _containers = [];

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('planner_containers')
        .where('user_id', isEqualTo: widget.userId)
        .get();
    
    final containers = querySnapshot.docs.map((doc) {
      final map = doc.data();
      map['id'] = doc.id;
      return map;
    }).toList();

    setState(() {
      _containers = containers;
    });

    _rescheduleNotifications(containers);
  }

  Future<void> _rescheduleNotifications(List<Map<String, dynamic>> containers) async {
    final ns = NotificationService();
    await ns.cancelAll();

    final Map<String, int> dayMap = {
      'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
      'Friday': 5, 'Saturday': 6, 'Sunday': 7
    };

    int notificationId = 0;
    for (var container in containers) {
      final blocksSnapshot = await FirebaseFirestore.instance
          .collection('planner_blocks')
          .where('container_id', isEqualTo: container['id'])
          .get();

      for (var blockDoc in blocksSnapshot.docs) {
        final title = blockDoc.data()['title'] as String? ?? '';
        for (var day in dayMap.keys) {
          if (title.contains(day)) {
            await ns.scheduleWeeklyNotification(
              id: notificationId++,
              title: 'Workout Time!',
              body: 'Time for your scheduled workout: $title',
              dayOfWeek: dayMap[day]!,
              hour: 8, // Default to 8 AM
              minute: 0,
            );
          }
        }
      }
    }
  }

  void _addContainer() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Workout Routine'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. Weekly Split, Summer Shred')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('planner_containers').add({
                  'user_id': widget.userId,
                  'name': ctrl.text, // Using 'name' as title or vice versa
                  'title': ctrl.text
                });
                Navigator.pop(ctx);
                _loadContainers();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Routine created!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFD0FD3E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editContainer(String id, String currentTitle) {
    final ctrl = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Workout Routine Name'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. Weekly Split')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('planner_containers').doc(id).update({
                  'title': ctrl.text,
                  'name': ctrl.text
                });
                Navigator.pop(ctx);
                _loadContainers();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Routine updated!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFD0FD3E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _containers.isEmpty 
        ? const Center(child: Text('No routines yet. Click + to start planning!'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _containers.length,
            itemBuilder: (ctx, i) {
              final container = _containers[i];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD0FD3E),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(container['title'] ?? 'Routine', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black87, size: 20),
                            onPressed: () => _editContainer(container['id'], container['title'] ?? ''),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.black87, size: 20),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('planner_containers').doc(container['id']).delete();
                              _loadContainers();
                            },
                          ),
                        ],
                      ),
                    ),
                    BlockList(containerId: container['id']),
                  ],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContainer,
        backgroundColor: const Color(0xFFD0FD3E),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class BlockList extends StatefulWidget {
  final String containerId;
  const BlockList({super.key, required this.containerId});

  @override
  State<BlockList> createState() => _BlockListState();
}

class _BlockListState extends State<BlockList> {
  List<Map<String, dynamic>> _blocks = [];

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  Future<void> _loadBlocks() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('planner_blocks')
        .where('container_id', isEqualTo: widget.containerId)
        .get();
    
    setState(() {
      _blocks = querySnapshot.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id;
        return map;
      }).toList();
    });
  }

  void _addBlock() {
    String selectedDay = 'Monday';
    final muscleCtrl = TextEditingController();
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Workout Day'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Day of the Week'),
                  items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setModalState(() => selectedDay = val!),
                ),
                TextField(controller: muscleCtrl, decoration: const InputDecoration(labelText: 'Muscle Group (e.g. Chest)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (muscleCtrl.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('planner_blocks').add({
                    'container_id': widget.containerId,
                    'title': '$selectedDay - ${muscleCtrl.text}'
                  });
                  
                  Navigator.pop(ctx);
                  _loadBlocks();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Workout day added!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFFD0FD3E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      )
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._blocks.map((block) => Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(block['title'] ?? 'Category', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('planner_blocks').doc(block['id']).delete();
                _loadBlocks();
              },
            ),
            children: [
              ExerciseMiniList(blockId: block['id']),
            ],
          ),
        )).toList(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton.icon(
            onPressed: _addBlock,
            icon: const Icon(Icons.add_box_outlined, color: Color(0xFFD0FD3E)),
            label: const Text('Add Day/Category Block', style: TextStyle(color: Color(0xFFD0FD3E))),
          ),
        ),
      ],
    );
  }
}

class ExerciseMiniList extends StatefulWidget {
  final String blockId;
  const ExerciseMiniList({super.key, required this.blockId});

  @override
  State<ExerciseMiniList> createState() => _ExerciseMiniListState();
}

class _ExerciseMiniListState extends State<ExerciseMiniList> {
  List<Map<String, dynamic>> _exercises = [];
  final Set<String> _expandedIds = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('planner_exercises')
        .where('block_id', isEqualTo: widget.blockId)
        .get();
    
    setState(() {
      _exercises = querySnapshot.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id;
        return map;
      }).toList();
    });
  }

  void _addExercise() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    String? imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Exercise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exercise Name')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: setsCtrl, decoration: const InputDecoration(labelText: 'Sets'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'Reps'), keyboardType: TextInputType.number)),
                  ],
                ),
                TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Planned Weight (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 10),
                if (imagePath != null) Image.file(File(imagePath!), height: 80, fit: BoxFit.cover),
                TextButton.icon(
                  onPressed: () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setModalState(() => imagePath = img.path);
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Add Image'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    
                    final sets = int.tryParse(setsCtrl.text);
                    final reps = int.tryParse(repsCtrl.text);
                    final weight = double.tryParse(weightCtrl.text);
                    
                    if ((sets == null && setsCtrl.text.isNotEmpty) || (reps == null && repsCtrl.text.isNotEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sets and Reps must be whole numbers')));
                      return;
                    }

                    await FirebaseFirestore.instance.collection('planner_exercises').add({
                      'block_id': widget.blockId,
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'sets': sets ?? 0,
                      'reps': reps ?? 0,
                      'planned_weight': weight ?? 0.0,
                      'image_path': imagePath ?? ''
                    });
                    Navigator.pop(ctx);
                    _loadExercises();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Exercise added!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFFD0FD3E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        )
                      );
                    }
                  },
                  child: const Text('Save Exercise'),
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
    return Column(
      children: [
        ..._exercises.map((ex) {
          final isExpanded = _expandedIds.contains(ex['id']);
          final String name = ex['name'] ?? 'Exercise';
          final String description = ex['description'] ?? '';
          final String imagePath = ex['image_path'] ?? '';
          
          return ListTile(
            dense: true,
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(ex['id']);
                } else {
                  _expandedIds.add(ex['id']);
                }
              });
            },
            leading: imagePath.isNotEmpty && File(imagePath).existsSync()
              ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(imagePath), width: 40, height: 40, fit: BoxFit.cover))
              : const Icon(Icons.fitness_center, size: 30),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ex['sets'] ?? 0} sets x ${ex['reps'] ?? 0} reps @ ${(ex['planned_weight'] as num? ?? 0).toStringAsFixed(1)} kg'),
                if (isExpanded && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      description,
                      style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('planner_exercises').doc(ex['id']).delete();
                _loadExercises();
              },
            ),
          );
        }).toList(),
        TextButton(
          onPressed: _addExercise, 
          child: const Text('+ Add Exercise', style: TextStyle(color: Color(0xFFD0FD3E)))
        ),
      ],
    );
  }
}
