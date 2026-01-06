import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../services/api_service.dart';
import '../widgets/profile_avatar.dart';
import 'dart:async';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late int _currentIndex;
  double _progress = 0.0;
  Timer? _timer;
  final int _storyDurationSeconds = 5;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _startStory();
    _markAsViewed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStory() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.05 / _storyDurationSeconds;
          if (_progress >= 1.0) {
            _nextStory();
          }
        });
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _startStory();
        _markAsViewed();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _startStory();
        _markAsViewed();
      });
    } else {
      setState(() {
        _progress = 0.0;
      });
    }
  }

  Future<void> _markAsViewed() async {
    try {
      final story = widget.stories[_currentIndex];
      await context.read<ApiService>().viewStory(story.id);
    } catch (e) {
      debugPrint('Error marking story as viewed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final apiService = context.read<ApiService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Media
          Center(
            child: GestureDetector(
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < width / 3) {
                  _previousStory();
                } else {
                  _nextStory();
                }
              },
              child: Image.network(
                apiService.buildStaticUrl(story.mediaUrl),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),

          // Header (Progress Bar + User Info)
          SafeArea(
            child: Column(
              children: [
                // Progress Bars
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: List.generate(widget.stories.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index < _currentIndex
                                ? 1.0
                                : (index == _currentIndex ? _progress : 0.0),
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // User Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        profilePicture: story.user.profilePicture,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        story.user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
