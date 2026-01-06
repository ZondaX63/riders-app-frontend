import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/story.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'profile_avatar.dart';
import '../screens/story_view_screen.dart';
import 'package:image_picker/image_picker.dart';

class StoriesList extends StatefulWidget {
  const StoriesList({super.key});

  @override
  State<StoriesList> createState() => _StoriesListState();
}

class _StoriesListState extends State<StoriesList> {
  Map<String, List<Story>> _groupedStories = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final stories = await context.read<ApiService>().getStories();

      // Group stories by user ID
      final Map<String, List<Story>> grouped = {};
      for (var story in stories) {
        final userId = story.user.id;
        if (!grouped.containsKey(userId)) {
          grouped[userId] = [];
        }
        grouped[userId]!.add(story);
      }

      if (mounted) {
        setState(() {
          _groupedStories = grouped;
        });
      }
    } catch (e) {
      debugPrint('Error loading stories: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createStory() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      try {
        await context.read<ApiService>().createStory(
              mediaPath: image.path,
              mediaType: 'image',
            );
        _loadStories(); // Reload list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hikaye paylaşıldı')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final userIds = _groupedStories.keys.toList();

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: userIds.length + 1, // +1 for "Add Story" button
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton(currentUser);
          }
          final userId = userIds[index - 1];
          final userStories = _groupedStories[userId]!;
          return _buildStoryGroupItem(userStories);
        },
      ),
    );
  }

  Widget _buildAddStoryButton(User? user) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[800]!,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: ProfileAvatar(
                  profilePicture: user?.profilePicture,
                  radius: 32,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _createStory,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hikayen',
            style: TextStyle(fontSize: 12, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryGroupItem(List<Story> stories) {
    if (stories.isEmpty) return const SizedBox.shrink();

    final user = stories.first.user;
    final currentUser = context.read<AuthProvider>().currentUser;
    final isViewed = currentUser != null &&
        stories.every((s) => s.views.contains(currentUser.id));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewScreen(stories: stories),
          ),
        ).then((_) => _loadStories()); // Refresh viewed status
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isViewed ? Colors.grey[700]! : AppTheme.primaryOrange,
                  width: 2,
                ),
              ),
              child: ProfileAvatar(
                profilePicture: user.profilePicture,
                radius: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.username,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
