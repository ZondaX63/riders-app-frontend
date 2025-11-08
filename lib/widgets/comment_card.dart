import 'package:flutter/material.dart';
import '../models/comment.dart' as comment_model;

class CommentCard extends StatelessWidget {
  final comment_model.Comment comment;
  final VoidCallback onReply;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: comment.user?.profilePicture != null
                      ? NetworkImage(comment.user!.profilePicture!)
                      : null,
          child: comment.user?.profilePicture == null
            ? Text(_avatarText())
            : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user?.username ?? 'Bilinmeyen Kullanıcı',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: onReply,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                _formatDate(comment.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  String _avatarText() {
    final u = comment.user;
    final name = u?.username;
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }
} 
