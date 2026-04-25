import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'db_helper.dart';

class PlannerScreen extends StatefulWidget {
  final int userId;
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
    final data = await DbHelper.query('planner_containers', where: 'user_id = ?', whereArgs: [widget.userId]);
    setState(() => _containers = data);
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
                await DbHelper.insert('planner_containers', {'user_id': widget.userId, 'title': ctrl.text});
                Navigator.pop(ctx);
                _loadContainers();
              }
            },
            child: const Text('Create'),
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
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(container['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white70),
                            onPressed: () async {
                              await DbHelper.delete('planner_containers', container['id']);
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
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class BlockList extends StatefulWidget {
  final int containerId;
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
    final data = await DbHelper.query('planner_blocks', where: 'container_id = ?', whereArgs: [widget.containerId]);
    setState(() => _blocks = data);
  }

  void _addBlock() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category Block'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. Monday - Chest, Full Body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await DbHelper.insert('planner_blocks', {'container_id': widget.containerId, 'title': ctrl.text});
                Navigator.pop(ctx);
                _loadBlocks();
              }
            },
            child: const Text('Add'),
          ),
        ],
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
            title: Text(block['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
              onPressed: () async {
                await DbHelper.delete('planner_blocks', block['id']);
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
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Add Day/Category Block'),
          ),
        ),
      ],
    );
  }
}

class ExerciseMiniList extends StatefulWidget {
  final int blockId;
  const ExerciseMiniList({super.key, required this.blockId});

  @override
  State<ExerciseMiniList> createState() => _ExerciseMiniListState();
}

class _ExerciseMiniListState extends State<ExerciseMiniList> {
  List<Map<String, dynamic>> _exercises = [];
  final Set<int> _expandedIds = {}; // Track which exercises show descriptions
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final data = await DbHelper.db.query('planner_exercises', where: 'block_id = ?', whereArgs: [widget.blockId], orderBy: 'id ASC');
    setState(() => _exercises = data);
  }

  void _addExercise() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
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
                    await DbHelper.insert('planner_exercises', {
                      'block_id': widget.blockId,
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'sets': int.tryParse(setsCtrl.text) ?? 0,
                      'reps': int.tryParse(repsCtrl.text) ?? 0,
                      'image_path': imagePath ?? ''
                    });
                    Navigator.pop(ctx);
                    _loadExercises();
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
            leading: ex['image_path'].isNotEmpty 
              ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(ex['image_path']), width: 40, height: 40, fit: BoxFit.cover))
              : const Icon(Icons.fitness_center, size: 30),
            title: Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ex['sets']} sets x ${ex['reps']} reps'),
                if (isExpanded && ex['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      ex['description'], 
                      style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              onPressed: () async {
                await DbHelper.delete('planner_exercises', ex['id']);
                _loadExercises();
              },
            ),
          );
        }).toList(),
        TextButton(onPressed: _addExercise, child: const Text('+ Add Exercise')),
      ],
    );
  }
}
