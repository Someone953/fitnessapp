import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  List<dynamic> _exercises = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    try {
      final response = await http.get(Uri.parse('https://wger.de/api/v2/exercise/?language=2&status=2'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _exercises = data['results'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load exercises. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error connecting to API: $e';
        _isLoading = false;
      });
    }
  }

  String _stripHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return 'No description available';
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(_error, textAlign: TextAlign.center),
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _exercises.length,
                  itemBuilder: (ctx, i) {
                    final ex = _exercises[i];
                    if (ex == null) return const SizedBox.shrink();
                    
                    final String name = ex['name']?.toString() ?? 'Unknown Exercise';
                    final String description = _stripHtml(ex['description']?.toString());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.fitness_center, color: Colors.white),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              description,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
