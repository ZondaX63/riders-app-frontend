import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ApiService _apiService;
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
  }

  String _getProfilePictureUrl(String? profilePicture) =>
      _apiService.buildStaticUrl(profilePicture ?? '');

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _apiService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            _searchUsers(value);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Start typing to search users'
                            : 'No users found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final profilePictureUrl =
                            _getProfilePictureUrl(user.profilePicture);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profilePictureUrl.isNotEmpty
                                ? NetworkImage(profilePictureUrl)
                                : null,
                            child: profilePictureUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(user.username),
                          subtitle: Text(user.fullName ?? user.username),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfileScreen(userId: user.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
