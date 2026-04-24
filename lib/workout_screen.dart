import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db_helper.dart';

class WorkoutScreen extends StatefulWidget {
  final String userId;
  const WorkoutScreen({super.key, required this.userId});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<Map<String, dynamic>> _workouts = [];
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final data = await DbHelper.query('workout', userId: widget.userId);
    setState(() {
      data.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
      _workouts = data;
    });
  }

  void _addWorkout() async {
    await DbHelper.insert('workout', {
      'user_id': widget.userId,
      'title': _titleCtrl.text.isEmpty ? 'New Workout' : _titleCtrl.text,
      'sets': 4,
      'reps': 10,
      'date': DateTime.now().toIso8601String().substring(0, 10)
    });
    _titleCtrl.clear();
    _loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Workout Title')),
          ElevatedButton(onPressed: _addWorkout, child: const Text('Create Workout (CRUD)')),
          Expanded(
            child: ListView.builder(
              itemCount: _workouts.length,
              itemBuilder: (ctx, i) {
                final w = _workouts[i];
                return ListTile(
                  title: Text(w['title']),
                  subtitle: Text('${w['sets']} sets × ${w['reps']} reps'),
                  trailing: IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('QR Code'),
                        content: QrImageView(data: 'workout:${w['id']}', size: 200),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
            child: const Text('Scan QR to Join Workout'),
          ),
        ],
      ),
    );
  }
}

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) Navigator.pop(context);
        },
      ),
    );
  }
}
