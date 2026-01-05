import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  String? _error;
  static const int maxImages = 10;
  static const int maxCharacters = 2000;
  
  // New features
  TabController? _tabController;
  String? _selectedLocation;
  final List<String> _popularHashtags = [
    '#motosiklet', '#motorcycle', '#bikelife', '#rider', 
    '#motorcu', '#ride', '#touring', '#adventure'
  ];
  bool _showHashtagSuggestions = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _contentController.addListener(() {
      setState(() {
        // Check if user is typing a hashtag
        final text = _contentController.text;
        final cursorPos = _contentController.selection.baseOffset;
        if (cursorPos > 0 && text.substring(cursorPos - 1, cursorPos) == '#') {
          _showHashtagSuggestions = true;
        } else {
          _showHashtagSuggestions = false;
        }
      });
    });
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('En fazla $maxImages resim yükleyebilirsiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(pickedFile);
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final remainingSlots = maxImages - _selectedImages.length;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('En fazla $maxImages resim yükleyebilirsiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        // Add only up to the remaining slots
        _selectedImages.addAll(pickedFiles.take(remainingSlots));
      });
      
      if (pickedFiles.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$remainingSlots resim eklendi. Maksimum $maxImages resim yükleyebilirsiniz.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _insertHashtag(String hashtag) {
    final text = _contentController.text;
    final cursorPos = _contentController.selection.baseOffset;
    final newText = text.substring(0, cursorPos) + hashtag + ' ' + text.substring(cursorPos);
    _contentController.text = newText;
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: cursorPos + hashtag.length + 1),
    );
    setState(() {
      _showHashtagSuggestions = false;
    });
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konum Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('İstanbul, Türkiye'),
                onTap: () {
                  setState(() {
                    _selectedLocation = 'İstanbul, Türkiye';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Ankara, Türkiye'),
                onTap: () {
                  setState(() {
                    _selectedLocation = 'Ankara, Türkiye';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('İzmir, Türkiye'),
                onTap: () {
                  setState(() {
                    _selectedLocation = 'İzmir, Türkiye';
                  });
                  Navigator.pop(context);
                },
              ),
              if (_selectedLocation != null)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Konumu Kaldır'),
                  onTap: () {
                    setState(() {
                      _selectedLocation = null;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir içerik veya resim ekleyin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final imagePaths = _selectedImages.map((file) {
        if (kIsWeb) {
          return file.path; // Web'de path blob URL olacak
        } else {
          return file.path;
        }
      }).toList();
      
      await apiService.createPost(
        _contentController.text.trim(),
        imagePaths,
      );
      
      if (mounted) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderi başarıyla paylaşıldı'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      print('Error creating post: $e'); // Debug log
      setState(() {
        if (e.toString().contains('Description is required')) {
          _error = 'Lütfen bir içerik girin';
        } else {
          _error = e.toString();
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gönderi paylaşılırken bir hata oluştu: $_error'),
          backgroundColor: Colors.red,
        ),
      );
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100];
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final characterCount = _contentController.text.length;
    final isOverLimit = characterCount > maxCharacters;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Yeni Gönderi'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : null,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Düzenle'),
            Tab(icon: Icon(Icons.visibility), text: 'Önizleme'),
          ],
        ),
        actions: [
          // Location button
          IconButton(
            icon: Icon(
              _selectedLocation != null ? Icons.location_on : Icons.location_on_outlined,
              color: _selectedLocation != null ? Theme.of(context).primaryColor : null,
            ),
            onPressed: _showLocationPicker,
            tooltip: 'Konum Ekle',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditTab(context, textColor, cardColor, backgroundColor, characterCount, isOverLimit),
          _buildPreviewTab(context, textColor, cardColor),
        ],
      ),
    );
  }

  Widget _buildEditTab(BuildContext context, Color textColor, Color cardColor, Color? backgroundColor, int characterCount, bool isOverLimit) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                  // Content Field with character counter
                  TextFormField(
                    controller: _contentController,
                    maxLines: 5,
                    maxLength: maxCharacters,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Ne düşünüyorsun?',
                      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      hintText: 'Düşüncelerini, deneyimlerini veya fotoğraflarını paylaş...',
                      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: cardColor,
                      counterText: '', // Hide default counter
                    ),
                  ),
                  
                  // Character counter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_selectedLocation != null)
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                _selectedLocation!,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        Text(
                          '$characterCount/$maxCharacters',
                          style: TextStyle(
                            color: isOverLimit ? Colors.red : textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Hashtag suggestions
                  if (_showHashtagSuggestions) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: textColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Popüler Etiketler',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularHashtags.map((tag) {
                              return InkWell(
                                onTap: () => _insertHashtag(tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Image Preview
                  if (_selectedImages.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seçilen Resimler',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_selectedImages.length}/$maxImages',
                          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<Uint8List>(
                                    future: _selectedImages[index].readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Add Image Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Tek Resim'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: textColor.withValues(alpha: 0.15)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickMultipleImages,
                          icon: const Icon(Icons.collections_outlined),
                          label: const Text('Çoklu Seçim'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: textColor.withValues(alpha: 0.15)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${_selectedImages.length}/$maxImages resim seçildi',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Error Message
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            // Share Button at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading || (_contentController.text.trim().isEmpty && _selectedImages.isEmpty)
                      ? null
                      : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Paylaş', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildPreviewTab(BuildContext context, Color textColor, Color cardColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preview Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sen',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Şimdi',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            if (_selectedLocation != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                              Text(
                                _selectedLocation!,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_contentController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _contentController.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ],
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<Uint8List>(
                            future: _selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                width: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPreviewAction(Icons.thumb_up_outlined, '0', textColor),
                  _buildPreviewAction(Icons.comment_outlined, '0', textColor),
                  _buildPreviewAction(Icons.share_outlined, '0', textColor),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.blue.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bu önizleme gönderinizin nasıl görüneceğini gösterir. Paylaşmak için "Düzenle" sekmesine dönün.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewAction(IconData icon, String count, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: textColor.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 



