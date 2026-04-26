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
  bool _isFetchingMore = false;
  String? _nextPageUrl = 'https://wger.de/api/v2/exerciseinfo/?language=2&status=2';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises({bool isMore = false}) async {
    if (_nextPageUrl == null && isMore) return;

    setState(() {
      if (isMore) {
        _isFetchingMore = true;
      } else {
        _isLoading = true;
        _exercises = [];
      }
    });

    try {
      final response = await http.get(Uri.parse(_nextPageUrl ?? ''));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _exercises.addAll(data['results'] ?? []);
          _nextPageUrl = data['next'];
          _isLoading = false;
          _isFetchingMore = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load exercises. Status: ${response.statusCode}';
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error connecting to API: $e';
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  String _stripHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return 'No description available';
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String result = htmlString.replaceAll(exp, '');
    return result.replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&');
  }

  void _showExerciseDetails(Map<String, dynamic> ex, String name, String description, String? imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1C2025),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.fitness_center, size: 80, color: Color(0xFFD0FD3E)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFD0FD3E)),
                    ),
                    const SizedBox(height: 8),
                    if (ex['category'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0FD3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ex['category']['name'],
                          style: const TextStyle(color: Color(0xFFD0FD3E), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Instructions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0FD3E),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(_error, textAlign: TextAlign.center),
                ))
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final ex = _exercises[i];
                            String name = 'Unknown Exercise';
                            String description = 'No description available';
                            String? imageUrl;

                            final translations = ex['translations'] as List<dynamic>?;
                            if (translations != null && translations.isNotEmpty) {
                              final translation = translations.firstWhere(
                                (t) => t['language'] == 2,
                                orElse: () => translations[0],
                              );
                              name = translation['name']?.toString() ?? name;
                              description = _stripHtml(translation['description']?.toString());
                            }

                            final images = ex['images'] as List<dynamic>?;
                            if (images != null && images.isNotEmpty) {
                              final mainImage = images.firstWhere(
                                (img) => img['is_main'] == true,
                                orElse: () => images[0],
                              );
                              imageUrl = mainImage['image'];
                            }

                            final category = ex['category']?['name'] ?? 'General';

                            return InkWell(
                              onTap: () => _showExerciseDetails(ex, name, description, imageUrl),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        child: imageUrl != null
                                            ? Image.network(imageUrl, fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) => 
                                                const Icon(Icons.fitness_center, size: 50, color: Color(0xFFD0FD3E)))
                                            : const Icon(Icons.fitness_center, size: 50, color: Color(0xFFD0FD3E)),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD0FD3E).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(color: Color(0xFFD0FD3E), fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _exercises.length,
                        ),
                      ),
                    ),
                    if (_nextPageUrl != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _isFetchingMore
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0FD3E)))
                              : ElevatedButton(
                                  onPressed: () => _fetchExercises(isMore: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD0FD3E),
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Load More', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
