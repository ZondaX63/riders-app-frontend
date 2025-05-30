import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  String? _error;
  static const int maxImages = 5;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
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
          content: Text('Gönderi paylaşılırken bir hata oluştu: ${_error}'),
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gönderi Paylaş'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : null,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Content Field
                  TextFormField(
                    controller: _contentController,
                    maxLines: 5,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Ne düşünüyorsun?',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      hintText: 'Düşüncelerini, deneyimlerini veya fotoğraflarını paylaş...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      filled: true,
                      fillColor: cardColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Preview
                  if (_selectedImages.isNotEmpty) ...[
                    Text(
                      'Seçilen Resimler (${_selectedImages.length}/$maxImages)',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                                    color: Colors.black.withOpacity(0.5),
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

                  // Add Image Button
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('Resim Ekle (${_selectedImages.length}/$maxImages)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : null,
                      foregroundColor: textColor,
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPost,
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
                      : const Text(
                          'Paylaş',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 