import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'comments_screen.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadPosts();
    }
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

  Future<void> _handleLike(Post post) async {
    try {
      if (post.likes.contains(context.read<AuthProvider>().currentUser?.id)) {
        await _apiService.unlikePost(post.id);
      } else {
        await _apiService.likePost(post.id);
      }
      _loadPosts(); // Refresh posts after like/unlike
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Riders Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
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
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _posts.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = _posts[index];
                          final isLiked = post.likes.contains(context.read<AuthProvider>().currentUser?.id);

                          return PostCard(
                            id: post.id,
                            description: post.description ?? '',
                            images: post.images,
                            username: post.user?.username ?? 'Unknown User',
                            profilePicture: post.user?.profilePicture,
                            createdAt: post.createdAt,
                            likesCount: post.likes.length,
                            commentsCount: post.comments.length,
                            isLiked: isLiked,
                            onLike: () => _handleLike(post),
                            onComment: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommentsScreen(post: post),
                                ),
                              );
                            },
                            onShare: () {
                              // TODO: Implement share
                            },
                          );
                        },
                      ),
      ),
    );
  }
} 