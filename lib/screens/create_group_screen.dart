import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../providers/auth_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isPrivate = false;
  bool _isLoading = false;

  // Member selection
  List<User> _searchResults = [];
  final List<User> _selectedUsers = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await context.read<ApiService>().searchUsers(query);
      if (mounted) {
        final currentUserId = context.read<AuthProvider>().currentUser?.id;
        setState(() {
          _searchResults = (results as List)
              .map((data) => User.fromJson(data))
              .where((u) => u.id != currentUserId)
              .where(
                  (u) => !_selectedUsers.any((selected) => selected.id == u.id))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Create Group
      final groupData = await context.read<ApiService>().createGroupChat(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            isPrivate: _isPrivate,
          );

      final groupId = groupData['_id'] ?? groupData['id'];

      // 2. Add Members
      if (_selectedUsers.isNotEmpty) {
        final api = context.read<ApiService>();
        // Add members sequentially or parallel
        // Assuming addMember API exists and takes groupId, userId
        for (var user in _selectedUsers) {
          try {
            await api.groupChats.addMember(groupId, user.id);
          } catch (e) {
            debugPrint('Error adding user ${user.username}: $e');
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Grup Oluştur'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Oluştur',
                    style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Info
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Grup Adı',
                  filled: true,
                  fillColor: AppTheme.darkGrey,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v?.isEmpty == true ? 'Grup adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  filled: true,
                  fillColor: AppTheme.darkGrey,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Gizli Grup'),
                subtitle: const Text('Sadece davet edilenler katılabilir'),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
                activeColor: AppTheme.primaryOrange,
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(height: 32),

              // Member Selection
              const Text('Üye Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Selected Users Chips
              if (_selectedUsers.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedUsers
                      .map((user) => Chip(
                            avatar: ProfileAvatar(
                                profilePicture: user.profilePicture,
                                radius: 10),
                            label: Text(user.username),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedUsers.remove(user);
                              });
                            },
                            backgroundColor:
                                AppTheme.primaryOrange.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.white),
                          ))
                      .toList(),
                ),

              const SizedBox(height: 12),

              // Search Input
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.darkGrey,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
              ),

              const SizedBox(height: 12),

              // Search Results
              if (_searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: ProfileAvatar(
                            profilePicture: user.profilePicture, radius: 16),
                        title: Text(user.username),
                        subtitle: Text(user.fullName ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppTheme.primaryOrange),
                          onPressed: () {
                            setState(() {
                              _selectedUsers.add(user);
                              _searchResults.removeAt(index);
                              _searchController.clear();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
