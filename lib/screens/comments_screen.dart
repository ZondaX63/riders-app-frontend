import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment.dart' as comment_model;
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/comment_card.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;

  const CommentsScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<comment_model.Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  late ApiService _apiService;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await _apiService.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
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

  Future<void> _handleAddComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      await _apiService.createComment(widget.post.id, content);
      _commentController.clear();
      _loadComments();
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
        title: const Text('Yorumlar'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _comments.isEmpty
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
                              onPressed: _loadComments,
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : _comments.isEmpty
                        ? const Center(
                            child: Text(
                              'Henüz yorum yok. İlk yorumu sen yap!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _comments.length + (_isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _comments.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final comment = _comments[index];
                              return CommentCard(
                                comment: comment,
                                onReply: () {
                                  // TODO: Implement reply functionality
                                },
                              );
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Yorum yaz...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleAddComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 