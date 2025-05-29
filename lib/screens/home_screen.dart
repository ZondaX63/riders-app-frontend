import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _apiService.getPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MotoSocial'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _isLoading && _posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPosts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _posts.isEmpty
                    ? const Center(
                        child: Text(
                          'No posts yet. Be the first to share!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: post.user?.profilePicture != null
                                        ? NetworkImage(post.user!.profilePicture!)
                                        : null,
                                    child: post.user?.profilePicture == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(post.user?.fullName ?? 'Unknown User'),
                                  subtitle: Text('@${post.user?.username ?? 'unknown'}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      // TODO: Show post options
                                    },
                                  ),
                                ),
                                if (post.content != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(post.content!),
                                  ),
                                if (post.images.isNotEmpty)
                                  SizedBox(
                                    height: 300,
                                    child: PageView.builder(
                                      itemCount: post.images.length,
                                      itemBuilder: (context, imageIndex) {
                                        return Image.network(
                                          post.images[imageIndex],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading image: $error');
                                            return const Center(
                                              child: Icon(Icons.error),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              post.likes.contains(context.read<AuthProvider>().currentUser?.id)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: post.likes.contains(context.read<AuthProvider>().currentUser?.id)
                                                  ? Colors.red
                                                  : null,
                                            ),
                                            onPressed: () {
                                              // TODO: Implement like functionality
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.comment_outlined),
                                            onPressed: () {
                                              // TODO: Implement comment functionality
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.share_outlined),
                                            onPressed: () {
                                              // TODO: Implement share functionality
                                            },
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.bookmark_border),
                                        onPressed: () {
                                          // TODO: Implement save functionality
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (post.likes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '${post.likes.length} likes',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (post.comments.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'View all ${post.comments.length} comments',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${post.comments.first.user.username}: ${post.comments.first.content}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
} 