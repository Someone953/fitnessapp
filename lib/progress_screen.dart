import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'db_helper.dart';

class ProgressScreen extends StatefulWidget {
  final int userId;
  const ProgressScreen({super.key, required this.userId});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> photos = [];
  List<Map<String, dynamic>> nutrition = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await DbHelper.query('progress_photo', where: 'user_id = ?', whereArgs: [widget.userId]);
    final n = await DbHelper.query('nutrition', where: 'user_id = ?', whereArgs: [widget.userId]);
    setState(() {
      photos = p;
      nutrition = n;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Nutrition Log (CRUD)
          ElevatedButton(
            onPressed: () async {
              await DbHelper.insert('nutrition', {
                'user_id': widget.userId,
                'date': DateTime.now().toIso8601String().substring(0, 10),
                'food': 'Protein Shake',
                'calories': 300,
                'protein': 25,
              });
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nutrition logged!')));
            },
            child: const Text('Log New Meal (CRUD Create)'),
          ),
          const Text('Recent Nutrition', style: TextStyle(fontSize: 18)),
          Expanded(
            child: ListView.builder(
              itemCount: nutrition.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(nutrition[i]['food']),
                subtitle: Text('${nutrition[i]['calories']} kcal • ${nutrition[i]['protein']}g protein'),
              ),
            ),
          ),
          // Camera for Progress Photos
          ElevatedButton(
            onPressed: () async {
              final XFile? image = await _picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                await DbHelper.insert('progress_photo', {
                  'user_id': widget.userId,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  'image_path': image.path,
                  'note': 'Progress photo taken',
                });
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress photo saved!')));
              }
            },
            child: const Text('Take Progress Photo (Camera Access)'),
          ),
          const Text('Progress Photos'),
          Expanded(
            child: ListView.builder(
              itemCount: photos.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text('Photo ${photos[i]['date']}'),
                leading: photos[i]['image_path'].isNotEmpty
                    ? Image.file(File(photos[i]['image_path']), width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.photo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
