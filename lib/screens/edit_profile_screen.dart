import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _motorcycleBrandController;
  late TextEditingController _motorcycleModelController;
  late TextEditingController _motorcycleYearController;
  late TabController _tabController;

  bool _saving = false;
  XFile? _selectedProfileImage;
  String? _currentProfilePicture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _motorcycleBrandController =
        TextEditingController(text: user?.motorcycleInfo?['brand'] ?? '');
    _motorcycleModelController =
        TextEditingController(text: user?.motorcycleInfo?['model'] ?? '');
    _motorcycleYearController = TextEditingController(
        text: user?.motorcycleInfo?['year']?.toString() ?? '');
    _currentProfilePicture = user?.profilePicture;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _motorcycleBrandController.dispose();
    _motorcycleModelController.dispose();
    _motorcycleYearController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedProfileImage = pickedFile;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final apiService = ApiService();

      // Prepare motorcycle info
      Map<String, dynamic>? motorcycleInfo;
      if (_motorcycleBrandController.text.trim().isNotEmpty ||
          _motorcycleModelController.text.trim().isNotEmpty ||
          _motorcycleYearController.text.trim().isNotEmpty) {
        motorcycleInfo = {
          'brand': _motorcycleBrandController.text.trim(),
          'model': _motorcycleModelController.text.trim(),
          'year': _motorcycleYearController.text.trim().isNotEmpty
              ? int.tryParse(_motorcycleYearController.text.trim())
              : null,
        };
      }

      // Update profile picture if selected
      if (_selectedProfileImage != null) {
        await apiService.updateProfilePicture(_selectedProfileImage!.path);
      }

      // Update profile with all info
      await apiService.updateProfile(
        _fullNameController.text.trim(),
        _bioController.text.trim(),
        motorcycleInfo,
      );

      // Reload auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(text: 'Genel'),
            Tab(text: 'Motor'),
            Tab(text: 'Fotoğraf'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Kaydet',
                    style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold),
                  ),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // General Tab
            _buildGeneralTab(),
            // Motorcycle Tab
            _buildMotorcycleTab(),
            // Photo Tab
            _buildPhotoTab(user),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Kişisel Bilgiler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Ad Soyad *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Ad Soyad boş olamaz';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: 'Hakkında',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Kendinizden kısaca bahsedin...',
            prefixIcon: const Icon(Icons.info_outline),
          ),
          maxLines: 4,
          maxLength: 200,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'İpucu',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '• Profilinizi daha çekici hale getirmek için hakkınızda kısmını doldurun\n'
          '• Motor bilgilerinizi ekleyerek diğer sürücülerle ortak noktalar yakalayın\n'
          '• Profil fotoğrafı ekleyerek hesabınızı kişiselleştirin',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildMotorcycleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Motor Bilgileri',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Motorunuzun detaylarını paylaşın',
          style: TextStyle(fontSize: 14, color: Colors.white60),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _motorcycleBrandController,
          decoration: InputDecoration(
            labelText: 'Marka',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Örn: Honda, Yamaha, Kawasaki',
            prefixIcon: const Icon(Icons.two_wheeler),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _motorcycleModelController,
          decoration: InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Örn: CBR 1000RR, R1, Ninja',
            prefixIcon: const Icon(Icons.label),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _motorcycleYearController,
          decoration: InputDecoration(
            labelText: 'Model Yılı',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Örn: 2023',
            prefixIcon: const Icon(Icons.calendar_today),
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v != null && v.trim().isNotEmpty) {
              final year = int.tryParse(v.trim());
              if (year == null ||
                  year < 1900 ||
                  year > DateTime.now().year + 1) {
                return 'Geçerli bir yıl girin';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.primaryOrange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Motor bilgileriniz profilinizde görünecek ve diğer sürücüler sizi daha kolay bulabilecek',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTab(dynamic user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Profil Fotoğrafı',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Center(
          child: Stack(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryOrange, width: 3),
                ),
                child: ClipOval(
                  child: _selectedProfileImage != null
                      ? Image.network(
                          _selectedProfileImage!.path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.darkGrey,
                              child: const Icon(Icons.person, size: 60),
                            );
                          },
                        )
                      : (_currentProfilePicture != null &&
                              _currentProfilePicture!.isNotEmpty
                          ? Image.network(
                              _currentProfilePicture!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.darkGrey,
                                  child: const Icon(Icons.person, size: 60),
                                );
                              },
                            )
                          : Container(
                              color: AppTheme.darkGrey,
                              child: const Icon(Icons.person, size: 60),
                            )),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _pickProfileImage,
          icon: const Icon(Icons.photo_library),
          label: const Text('Galeriden Seç'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_selectedProfileImage != null) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedProfileImage = null;
              });
            },
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text('Seçimi İptal Et',
                style: TextStyle(color: Colors.red)),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Öneriler',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '• Yüzünüzün net göründüğü bir fotoğraf kullanın\n'
          '• Kare formatında fotoğraflar daha iyi görünür\n'
          '• İyi ışıklandırılmış fotoğraflar tercih edin',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}
