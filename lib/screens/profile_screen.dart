import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import '../models/route.dart';
import '../widgets/user_status_dialog.dart';

class ModernProfileScreen extends StatefulWidget {
  const ModernProfileScreen({super.key});

  @override
  State<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen> {
  late final ApiService _apiService;
  bool _isLoading = false;
  String? _error;
  int _routeCount = 0;
  double _totalDistance = 0.0;
  List<Post> _userPosts = [];
  List<RidersRoute> _userRoutes = [];
  int _selectedTab = 0; // 0: Posts, 1: Rides, 2: Achievements

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _loadUserData();
  }

  String _buildAvatarUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) return '';
    return _apiService.buildStaticUrl(profilePicture);
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final current =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (current == null) return;

      final postMaps = await _apiService.getUserPosts(current.id);
      final userPosts = postMaps.map((m) => Post.fromJson(m)).toList();

      final List<RidersRoute> routes =
          await _apiService.getUserRoutes(current.id);

      double totalDistance = 0.0;
      for (var route in routes) {
        totalDistance += route.distance;
      }

      if (!mounted) return;
      setState(() {
        _userPosts = userPosts;
        _userRoutes = routes;
        _routeCount = routes.length;
        _totalDistance = totalDistance;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85);
    if (pickedFile == null) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .updateProfilePicture(pickedFile.path);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil resmi güncellendi')));
      await _loadUserData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avatarUrl = _buildAvatarUrl(user.profilePicture);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.username),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppTheme.lightGrey,
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? const Icon(Icons.person, size: 36)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _updateProfileImage,
                                child: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.primaryOrange,
                                  child: Icon(Icons.camera_alt,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName ?? user.username,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    user.bio?.isNotEmpty == true
                                        ? user.bio!
                                        : '',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => const UserStatusDialog(),
                          );
                          if (result == true && mounted) {
                            // Status updated successfully
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Durum güncellendi')),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppTheme.primaryOrange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryOrange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (user.status?['message'] != null &&
                                              user.status!['message']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? user.status!['message']
                                          : 'Durumunu Paylaş',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (user.status?['customText'] != null &&
                                              user.status!['customText']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? user.status!['customText']
                                          : 'Şu an ne yapıyorsun?',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen()));
                              },
                              style: TextButton.styleFrom(
                                  backgroundColor: AppTheme.lightGrey,
                                  shape: const StadiumBorder(),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12)),
                              child: const Text('Profili Düzenle'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        _StatCard(value: '$_routeCount', label: 'Rides'),
                        const SizedBox(width: 8),
                        _StatCard(
                            value: '${user.followers.length}',
                            label: 'Followers'),
                        const SizedBox(width: 8),
                        _StatCard(
                            value: _totalDistance.toStringAsFixed(1),
                            label: 'Distance'),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    // Motorcycle Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MotorcycleCard(
                        title:
                            '${user.motorcycleInfo?['brand'] ?? 'Motorcycle'} ${user.motorcycleInfo?['model'] ?? ''}'
                                .trim(),
                        year: user.motorcycleInfo?['year']?.toString(),
                        description: user.bio?.isNotEmpty == true
                            ? user.bio!
                            : 'Sürüşlerim için kullandığım motosiklet.',
                        motorcyclePhoto: user.motorcycleInfo?['photo'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tabs
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1)))),
                      child: Row(children: [
                        _TabButton(
                            text: 'Posts',
                            selected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0)),
                        _TabButton(
                            text: 'Rides',
                            selected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1)),
                        _TabButton(
                            text: 'Achievements',
                            selected: _selectedTab == 2,
                            onTap: () => setState(() => _selectedTab = 2)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _selectedTab == 0
                          ? _PostsGrid(posts: _userPosts)
                          : _selectedTab == 1
                              ? _RidesList(
                                  routes: _userRoutes,
                                  onDelete: (id) async {
                                    try {
                                      await _apiService.deleteRoute(id);
                                      await _loadUserData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text('Rota silindi')));
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('Hata: $e')));
                                      }
                                    }
                                  },
                                )
                              : const _AchievementsPlaceholder(),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _MotorcycleCard extends StatelessWidget {
  final String title;
  final String? year;
  final String description;
  final String? motorcyclePhoto;

  const _MotorcycleCard({
    required this.title,
    this.year,
    required this.description,
    this.motorcyclePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (motorcyclePhoto != null && motorcyclePhoto!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  motorcyclePhoto!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.darkGrey,
                      child: const Center(
                        child: Icon(Icons.two_wheeler,
                            size: 64, color: Colors.white24),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.darkGrey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.two_wheeler,
                          size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'Motor fotoğrafı eklenmemiş',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (year != null && year!.isNotEmpty)
                            Text(year!,
                                style: const TextStyle(color: Colors.white70)),
                          Text(description,
                              style: const TextStyle(color: Colors.white70)),
                        ]),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.black,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Teknik Bilgiler'),
                            content:
                                const Text('Özellikler yakında eklenecek.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Kapat'))
                            ],
                          ),
                        );
                      },
                      child: const Text('View Specs'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryOrange : Colors.transparent;
    final textColor = selected ? Colors.white : Colors.white70;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(bottom: 10, top: 14),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: color, width: 3))),
          child: Text(text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _PostsGrid extends StatelessWidget {
  final List<Post> posts;
  const _PostsGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(
          child: Text('Henüz paylaşım yok',
              style: TextStyle(color: Colors.white70)));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final image = post.images.isNotEmpty ? post.images.first : null;
        final title = post.description?.split('\n').first ?? 'Paylaşım';
        return ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image != null
                      ? Image.network(image, fit: BoxFit.cover)
                      : Container(
                          color: AppTheme.lightGrey,
                          child:
                              const Icon(Icons.image, color: Colors.white54)),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                    post.createdAt.toLocal().toIso8601String().substring(0, 10),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementsPlaceholder extends StatelessWidget {
  const _AchievementsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: const Text('Başarımlar yakında',
          style: TextStyle(color: Colors.white70)),
    );
  }
}

class _RidesList extends StatelessWidget {
  final List<RidersRoute> routes;
  final Function(String) onDelete;

  const _RidesList({required this.routes, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const Center(
          child: Text('Henüz sürüş kaydı yok',
              style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Card(
          color: AppTheme.lightGrey,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.two_wheeler, color: AppTheme.primaryOrange),
                Text(
                  '${route.distance.toStringAsFixed(1)}km',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
            title: Text(route.name.isNotEmpty ? route.name : 'İsimsiz Sürüş',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${route.waypoints.length} durak • ${route.createdAt.toLocal().toIso8601String().substring(0, 10)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sürüşü Sil'),
                    content: const Text(
                        'Bu sürüş kaydını silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('İptal')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDelete(route.id);
                        },
                        child: const Text('Sil',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
