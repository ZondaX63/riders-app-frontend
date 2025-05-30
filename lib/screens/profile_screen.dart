import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bioController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int _postCount = 0;
  final ApiService _apiService = ApiService();

  String _getProfilePictureUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return '';
    }
    // Convert backslashes to forward slashes and ensure proper URL format
    final normalizedPath = profilePicture.replaceAll('\\', '/');
    // Add base URL if it's a relative path
    if (!normalizedPath.startsWith('http')) {
      // Ensure the path starts with 'uploads/'
      final path = normalizedPath.startsWith('uploads/') ? normalizedPath : 'uploads/$normalizedPath';
      return 'http://localhost:3000/$path';
    }
    return normalizedPath;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPostCount();
  }

  Future<void> _loadPostCount() async {
    try {
      final posts = await _apiService.getPosts();
      if (mounted) {
        setState(() {
          _postCount = posts.where((post) => post.userId == context.read<AuthProvider>().currentUser?.id).length;
        });
      }
    } catch (e) {
      print('Error loading post count: $e');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user data
      final user = await _apiService.getCurrentUser();
      
      // Get user's posts
      final posts = await _apiService.getPosts();
      final userPosts = posts.where((post) => post.userId == user.id).toList();
      
      if (mounted) {
        setState(() {
          _postCount = userPosts.length;
          _bioController.text = user.bio ?? '';
          _brandController.text = user.motorcycleInfo?['brand'] ?? '';
          _modelController.text = user.motorcycleInfo?['model'] ?? '';
          _yearController.text = user.motorcycleInfo?['year']?.toString() ?? '';
        });
      }
    } catch (e) {
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

  Future<void> _updateBio() async {
    if (_bioController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) throw Exception('User not found');
      
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(
        user.fullName ?? user.username,
        _bioController.text.trim(),
      );
      await _loadUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateMotorcycleInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) throw Exception('User not found');

      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(
        user.fullName ?? user.username,
        user.bio ?? '',
        {
          'brand': _brandController.text.trim(),
          'model': _modelController.text.trim(),
          'year': int.tryParse(_yearController.text.trim()) ?? 0,
        },
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Motorcycle info updated successfully')),
      );
      await _loadUserData();
    } catch (e) {
      print('Error updating motorcycle info: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        if (!mounted) return;
        final authProvider = context.read<AuthProvider>();
        await authProvider.updateProfilePicture(pickedFile.path);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profilePictureUrl = _getProfilePictureUrl(user.profilePicture);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: profilePictureUrl.isNotEmpty
                                ? NetworkImage(profilePictureUrl)
                                : null,
                            child: profilePictureUrl.isEmpty
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                color: Colors.white,
                                onPressed: _updateProfileImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user.fullName ?? user.username,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '@${user.username}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Posts', _postCount.toString()),
                        _buildStatColumn('Followers', user.followers.length.toString()),
                        _buildStatColumn('Following', user.following.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                            TextField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                hintText: 'Tell us about yourself',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateBio,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Update Bio'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            TextField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                                hintText: 'e.g., BMW, Honda, Yamaha',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                                hintText: 'e.g., S1000RR, CBR1000RR',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _yearController,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                hintText: 'e.g., 2023',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateMotorcycleInfo,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Update Motorcycle Info'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
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