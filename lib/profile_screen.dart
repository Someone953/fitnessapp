import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  final _nameCtrl = TextEditingController();

  String _gender = 'Male';
  String _fitnessLevel = 'Beginner';
  List<String> _selectedGoals = [];
  String? _imagePath;
  bool _isEditing = false;
  bool _isLoading = true;

  double _bmi = 0.0;
  String _bmiStatus = '';
  List<Map<String, dynamic>> _history = [];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _fitnessGoalsOptions = ['Lose Weight', 'Build Muscle', 'Improve Stamina'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('user_id', isEqualTo: widget.userId)
          .get();

      final data = querySnapshot.docs.map((doc) => doc.data()).toList();
      
      data.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      setState(() {
        _history = data;
        if (data.isNotEmpty) {
          final last = data.first;
          _nameCtrl.text = last['name']?.toString() ?? 'User';
          _weightCtrl.text = last['weight']?.toString() ?? '';
          _heightCtrl.text = last['height']?.toString() ?? '';
          _ageCtrl.text = last['age']?.toString() ?? '';
          _weightTargetCtrl.text = last['weight_target']?.toString() ?? '';
          _gender = last['gender'] ?? 'Male';
          _fitnessLevel = last['fitness_level'] ?? 'Beginner';
          _imagePath = last['profile_image']?.toString();

          if (last['goals'] != null) {
            _selectedGoals = List<String>.from(last['goals']);
          } else if (last['goal'] != null) {
            _selectedGoals = [last['goal']];
          } else {
            _selectedGoals = [];
          }

          _bmi = last['bmi']?.toDouble() ?? 0.0;
          _bmiStatus = _bmi < 18.5 ? 'Underweight' : (_bmi > 25 ? 'Overweight' : 'Normal');
          _isEditing = false;
        } else {
          _isEditing = true;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _saveProfile() async {
    if (_weightCtrl.text.isEmpty || _heightCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
       return;
    }
    
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final height = double.tryParse(_heightCtrl.text) ?? 1;
    final bmi = weight / pow(height, 2);

    setState(() {
      _bmi = bmi;
      _bmiStatus = bmi < 18.5 ? 'Underweight' : (bmi > 25 ? 'Overweight' : 'Normal');
    });

    await FirebaseFirestore.instance.collection('profiles').add({
      'user_id': widget.userId,
      'name': _nameCtrl.text,
      'age': int.tryParse(_ageCtrl.text),
      'gender': _gender,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'fitness_level': _fitnessLevel,
      'goals': _selectedGoals,
      'weight_target': double.tryParse(_weightTargetCtrl.text),
      'profile_image': _imagePath ?? '',
      'date': DateTime.now().toIso8601String().substring(0, 10)
    });
    
    _loadData();
    setState(() => _isEditing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing && _history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing) _buildEditForm() else _buildInfoView(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoView() {
    if (_history.isEmpty) return const Center(child: Text("No profile found."));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal,
                    backgroundImage: (_imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync()) 
                        ? FileImage(File(_imagePath!)) 
                        : null,
                    child: (_imagePath == null || _imagePath!.isEmpty || !File(_imagePath!).existsSync())
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(_nameCtrl.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _infoRow(Icons.cake, 'Age', _ageCtrl.text),
            _infoRow(Icons.wc, 'Gender', _gender),
            _infoRow(Icons.monitor_weight, 'Weight', '${_weightCtrl.text} kg'),
            _infoRow(Icons.height, 'Height', '${_heightCtrl.text} m'),
            _infoRow(Icons.speed, 'Fitness Level', _fitnessLevel),
            _infoRow(Icons.track_changes, 'Weight Target', '${_weightTargetCtrl.text} kg'),
            const SizedBox(height: 10),
            const Text('Fitness Goals:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              children: _selectedGoals.map((g) => Chip(label: Text(g), backgroundColor: Colors.teal.shade50)).toList(),
            ),
            const Divider(height: 30),
            Center(
              child: Text(
                'Current BMI: ${_bmi.toStringAsFixed(2)} ($_bmiStatus)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 15),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Edit User Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (_imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync()) 
                    ? FileImage(File(_imagePath!)) 
                    : null,
                child: (_imagePath == null || _imagePath!.isEmpty || !File(_imagePath!).existsSync())
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Profile Name', border: OutlineInputBorder()),
        ),
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
        const SizedBox(height: 20),
        const Text('Weight Target (kg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _weightTargetCtrl,
          decoration: const InputDecoration(labelText: 'Weight Target (kg)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 15),
        const Text('Fitness Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Wrap(
          spacing: 8.0,
          children: _fitnessGoalsOptions.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return FilterChip(
              label: Text(goal),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedGoals.add(goal);
                  } else {
                    _selectedGoals.remove(goal);
                  }
                });
              },
              selectedColor: Colors.teal.shade200,
              checkmarkColor: Colors.teal,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (_history.isNotEmpty)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text('Cancel'),
                ),
              ),
            if (_history.isNotEmpty) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
