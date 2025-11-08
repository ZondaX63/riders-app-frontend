import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'base_api_service.dart';
import '../models/post.dart';
import '../models/comment.dart' as comment_model;

/// Post API Service
/// 
/// SRP: Sadece post işlemlerinden sorumlu
/// - Get Posts
/// - Create Post
/// - Like/Unlike Post
/// - Comments
class PostApiService extends BaseApiService {
  Future<List<Post>> getPosts() async {
    try {
      final response = await dio.get('$baseUrl/posts');

      if (!response.data['success']) {
        throw Exception('Failed to get posts');
      }

      final posts = (response.data['data']['posts'] as List)
          .map((post) => Post.fromJson(post))
          .toList();

      return posts;
    } on DioException catch (e) {
      log('DioException in getPosts: ${e.message}');
      throw Exception('Failed to get posts');
    }
  }

  Future<Post> createPost(String? content, List<String> images) async {
    try {
      final token = await getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (content != null && content.isNotEmpty) {
        request.fields['description'] = content;  // Backend 'description' bekliyor
      }

      // Web ve mobile için farklı yaklaşımlar
      for (var imagePath in images) {
        if (kIsWeb) {
          // Web için: XFile'dan bytes okuyarak ekle
          final xFile = XFile(imagePath);
          final bytes = await xFile.readAsBytes();
          final filename = xFile.name.isNotEmpty ? xFile.name : 'image.jpg';
          
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: filename,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
          // Mobile/Desktop için: dosya yolundan ekle
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              imagePath,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('Failed to create post');
      }

      final responseJson = Map<String, dynamic>.from(
        await dio.get('$baseUrl/posts').then((r) => r.data),
      );

      return Post.fromJson(responseJson['data']['posts'][0]);
    } catch (e) {
      log('Exception in createPost: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await dio.post('$baseUrl/posts/$postId/like');
    } on DioException catch (e) {
      log('DioException in likePost: ${e.message}');
      throw Exception('Failed to like post');
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      await dio.delete('$baseUrl/posts/$postId/like');
    } on DioException catch (e) {
      log('DioException in unlikePost: ${e.message}');
      throw Exception('Failed to unlike post');
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      await dio.post(
        '$baseUrl/posts/$postId/comments',
        data: {'content': content},
      );
    } on DioException catch (e) {
      log('DioException in addComment: ${e.message}');
      throw Exception('Failed to add comment');
    }
  }

  Future<List<comment_model.Comment>> getComments(String postId) async {
    try {
      final response = await dio.get('$baseUrl/posts/$postId/comments');

      if (!response.data['success']) {
        throw Exception('Failed to get comments');
      }

      final comments = (response.data['data']['comments'] as List)
          .map((comment) => comment_model.Comment.fromJson(comment))
          .toList();

      return comments;
    } on DioException catch (e) {
      log('DioException in getComments: ${e.message}');
      throw Exception('Failed to get comments');
    }
  }

  Future<void> createComment(String postId, String content) async {
    try {
      await dio.post(
        '$baseUrl/posts/$postId/comments',
        data: {'content': content},
      );
    } on DioException catch (e) {
      log('DioException in createComment: ${e.message}');
      throw Exception('Failed to create comment');
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await dio.delete('$baseUrl/posts/$postId/comments/$commentId');
    } on DioException catch (e) {
      log('DioException in deleteComment: ${e.message}');
      throw Exception('Failed to delete comment');
    }
  }
}
