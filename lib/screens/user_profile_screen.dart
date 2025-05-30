import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'chat_detail_screen.dart';
import '../providers/auth_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = true;
  String? _error;
  bool _isFollowing = false;

  String _getProfilePictureUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    // Replace backslashes with forward slashes
    final normalizedPath = path.replaceAll('\\', '/');
    // If the path doesn't start with http, prepend the base URL
    if (!normalizedPath.startsWith('http')) {
      return 'http://localhost:3000/$normalizedPath';
    }
    return normalizedPath;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkFollowStatus();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _apiService.getUser(widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser != null && _user != null) {
        setState(() {
          _isFollowing = _user!.followers.contains(currentUser.id);
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isFollowing) {
        await _apiService.unfollowUser(_user!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_user!.username} takibi bırakıldı'),
            backgroundColor: Colors.grey[800],
          ),
        );
      } else {
        await _apiService.followUser(_user!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_user!.username} takip ediliyor'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadUserData();
      await _checkFollowStatus();
      await Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startChat() async {
    if (_user == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chat = await _apiService.getOrCreateChat(_user!.id);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('User not found'),
        ),
      );
    }

    final profilePictureUrl = _getProfilePictureUrl(_user!.profilePicture);

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.username),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: _isLoading ? null : _startChat,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profilePictureUrl.isNotEmpty
                    ? NetworkImage(profilePictureUrl)
                    : null,
                child: profilePictureUrl.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _user!.fullName ?? _user!.username,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '@${_user!.username}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_user!.bio != null && _user!.bio!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_user!.bio!),
                    ],
                  ),
                ),
              ),
            if (_user!.motorcycleInfo != null &&
                (_user!.motorcycleInfo!['brand'] != null ||
                    _user!.motorcycleInfo!['model'] != null ||
                    _user!.motorcycleInfo!['year'] != null))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motorcycle Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (_user!.motorcycleInfo!['brand'] != null)
                        Text('Brand: ${_user!.motorcycleInfo!['brand']}'),
                      if (_user!.motorcycleInfo!['model'] != null)
                        Text('Model: ${_user!.motorcycleInfo!['model']}'),
                      if (_user!.motorcycleInfo!['year'] != null)
                        Text('Year: ${_user!.motorcycleInfo!['year']}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', '0'),
                _buildStatColumn('Followers', _user!.followers.length.toString()),
                _buildStatColumn('Following', _user!.following.length.toString()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _toggleFollow,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isFollowing ? 'Unfollow' : 'Follow'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startChat,
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
} 