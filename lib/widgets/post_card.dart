import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String id;
  final String description;
  final List<String> images;
  final String username;
  final String? profilePicture;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.id,
    required this.description,
    required this.images,
    required this.username,
    this.profilePicture,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  Widget _buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: images.length == 1
            ? AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  images[0],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  },
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: images.length == 2 ? 2 : 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: profilePicture != null
                  ? NetworkImage(profilePicture!)
                  : null,
              child: profilePicture == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(username),
            subtitle: Text(
              _formatDate(createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(description),
            ),
          _buildImageGrid(images),
          ButtonBar(
            alignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : null,
                ),
                onPressed: onLike,
              ),
              Text('$likesCount'),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: onComment,
              ),
              Text('$commentsCount'),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d';
    } else {
      return 'şimdi';
    }
  }
}
