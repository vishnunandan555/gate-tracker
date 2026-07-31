import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/providers/resources/resources_provider.dart';

void main() {
  group('StudyResource Tests', () {
    test('StudyResource.fromJson parses valid JSON fields correctly', () {
      final json = {
        'id': 'test_res_1',
        'branches': ['CS', 'DA'],
        'subject': 'Engineering Mathematics',
        'title': 'Linear Algebra Course',
        'source': 'Community',
        'platform': 'YouTube',
        'url': 'https://youtube.com/watch?v=123',
        'lectureCount': 25,
        'type': 'Playlist',
        'description': 'Test description'
      };

      final resource = StudyResource.fromJson(json);

      expect(resource.id, 'test_res_1');
      expect(resource.branches, ['CS', 'DA']);
      expect(resource.subject, 'Engineering Mathematics');
      expect(resource.title, 'Linear Algebra Course');
      expect(resource.lectureCount, 25);
      expect(resource.url, 'https://youtube.com/watch?v=123');
    });

    test('StudyResource.fromJson handles string branch single fallback', () {
      final json = {
        'id': 'test_res_2',
        'branches': 'CS',
        'subject': 'Discrete Math',
        'title': 'Discrete Math Series',
      };

      final resource = StudyResource.fromJson(json);

      expect(resource.branches, ['CS']);
      expect(resource.subject, 'Discrete Math');
      expect(resource.lectureCount, 0);
    });
  });
}
