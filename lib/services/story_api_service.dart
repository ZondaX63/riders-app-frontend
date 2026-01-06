import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import '../models/story.dart';
import '../models/user.dart';
import 'base_api_service.dart';

class StoryApiService extends BaseApiService {
  Future<List<Story>> getStories({int limit = 20, int offset = 0}) async {
    final response = await dio.get(
      '$baseUrl/stories',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final List<dynamic> storiesJson = response.data['data']['stories'];
    return storiesJson.map((json) => Story.fromJson(json)).toList();
  }

  Future<Story> createStory({
    required String mediaPath,
    required String mediaType, // 'image' or 'video'
    int duration = 24,
  }) async {
    String fileName = mediaPath.split('/').last;

    FormData formData = FormData.fromMap({
      'media': await MultipartFile.fromFile(
        mediaPath,
        filename: fileName,
        contentType: mediaType == 'image'
            ? MediaType('image', 'jpeg')
            : MediaType('video', 'mp4'),
      ),
      'mediaType': mediaType,
      'duration': duration,
    });

    final response = await dio.post(
      '$baseUrl/stories',
      data: formData,
    );

    return Story.fromJson(response.data['data']['story']);
  }

  Future<void> viewStory(String storyId) async {
    await dio.post('$baseUrl/stories/$storyId/view');
  }

  Future<List<User>> getStoryViews(String storyId,
      {int limit = 20, int offset = 0}) async {
    final response = await dio.get(
      '$baseUrl/stories/$storyId/views',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final List<dynamic> viewsJson = response.data['data']['views'];
    return viewsJson.map((json) => User.fromJson(json)).toList();
  }
}
