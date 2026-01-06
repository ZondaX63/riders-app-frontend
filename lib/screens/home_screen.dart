import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_list.dart'; // Import StoriesList
import 'notifications_screen.dart';
import 'chat_list_screen.dart';
import 'comments_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Post> _posts = [];
  List<Post> _followingPosts = [];
  List<Post> _explorePosts = [];
  bool _isLoading = false;
  String? _error;
  late ApiService _apiService;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
        });
        if (_currentTab == 0 && _followingPosts.isEmpty) {
          _loadFollowingPosts();
        } else if (_currentTab == 1 && _explorePosts.isEmpty) {
          _loadExplorePosts();
        }
      }
    });
    _apiService = context.read<ApiService>();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    if (_currentTab == 0) {
      await _loadFollowingPosts();
    } else {
      await _loadExplorePosts();
    }
  }

  Future<void> _loadFollowingPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _apiService.getPosts();
      final following =
          context.read<AuthProvider>().currentUser?.following ?? [];

      // Filter posts ONLY from followed users (excluding current user)
      final filteredPosts = posts.where((post) {
        return following.contains(post.user?.id);
      }).toList();

      if (mounted) {
        setState(() {
          _followingPosts = filteredPosts;
          _posts = filteredPosts;
        });
      }
    } catch (e) {
      print('Error loading following posts: $e');
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

  Future<void> _loadExplorePosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _apiService.getExplorePosts();

      if (mounted) {
        setState(() {
          _explorePosts = posts.cast<Post>();
          _posts = _explorePosts;
        });
      }
    } catch (e) {
      print('Error loading explore posts: $e');
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
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Takip Edilenler'),
            Tab(text: 'Keşfet'),
          ],
        ),
      ),
      body: Column(
        children: [
          const StoriesList(), // Add StoriesList here
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Following Tab
                RefreshIndicator(
                  onRefresh: _loadFollowingPosts,
                  child: _buildPostsList(
                    emptyMessage: _currentTab == 0
                        ? 'Henüz takip ettiğiniz kişilerden gönderi yok.\nYeni kişileri takip edin!'
                        : 'Henüz gönderi yok',
                  ),
                ),
                // Explore Tab
                RefreshIndicator(
                  onRefresh: _loadExplorePosts,
                  child: _buildPostsList(
                    emptyMessage:
                        'Henüz keşfedilecek gönderi yok.\nİlk paylaşımı siz yapın!',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList({required String emptyMessage}) {
    return _isLoading && _posts.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _posts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color:
                          Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPosts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              )
            : _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentTab == 0
                              ? Icons.people_outline
                              : Icons.explore_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                      final isLiked = post.likes.contains(
                          context.read<AuthProvider>().currentUser?.id);

                      return PostCard(
                        id: post.id,
                        description: post.description ?? '',
                        images: post.images,
                        username: post.user?.username ?? 'Unknown User',
                        profilePicture: post.user?.profilePicture,
                        userId: post.user?.id,
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
                          // Share functionality
                        },
                        onProfileTap: post.user?.id != null &&
                                post.user!.id !=
                                    context.read<AuthProvider>().currentUser?.id
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => UserProfileScreen(
                                        userId: post.user!.id),
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  );
  }
}
