import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/base_api_service.dart';

class TestApiService extends BaseApiService {}

void main() {
  group('BaseApiService URL Logic', () {
    final service = TestApiService();

    test('Should return empty string for empty path', () {
      expect(service.buildStaticUrl(''), '');
    });

    test('Should strip localhost and use prod url', () {
      const input = 'http://localhost:5000/uploads/profile.jpg';
      const expected =
          'https://riders-app-backend.onrender.com/uploads/profile.jpg';
      expect(service.buildStaticUrl(input), expected);
    });

    test('Should clean absolute server paths', () {
      const input = '/opt/render/project/src/uploads/media-123.jpg';
      const expected =
          'https://riders-app-backend.onrender.com/uploads/media-123.jpg';
      expect(service.buildStaticUrl(input), expected);
    });

    test('Should handle simple relative paths', () {
      const input = 'profile.jpg';
      const expected =
          'https://riders-app-backend.onrender.com/uploads/profile.jpg';
      expect(service.buildStaticUrl(input), expected);
    });

    test('Should handle paths with windows backslashes', () {
      const input = 'uploads\\image.png';
      const expected =
          'https://riders-app-backend.onrender.com/uploads/image.png';
      expect(service.buildStaticUrl(input), expected);
    });

    test('Should respect existing external http links if not localhost', () {
      const input = 'https://google.com/image.png';
      expect(service.buildStaticUrl(input), input);
    });
  });
}
