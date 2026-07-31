import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/core/models/topic_resource_data.dart';

void main() {
  group('TopicResourceData Tests', () {
    test('Parses null and empty strings to default empty data', () {
      final d1 = TopicResourceData.parse(null);
      expect(d1.url, '');
      expect(d1.note, '');

      final d2 = TopicResourceData.parse('   ');
      expect(d2.url, '');
      expect(d2.note, '');
    });

    test('Parses plain HTTP/HTTPS URL', () {
      final d = TopicResourceData.parse('https://youtube.com/playlist?list=123');
      expect(d.url, 'https://youtube.com/playlist?list=123');
      expect(d.note, '');
      expect(d.label, 'Open Resource');
    });

    test('Parses plain text note', () {
      final d = TopicResourceData.parse('Focus on Cayley-Hamilton Theorem');
      expect(d.url, '');
      expect(d.note, 'Focus on Cayley-Hamilton Theorem');
    });

    test('Parses legacy ||Note string', () {
      final d = TopicResourceData.parse('||Focus on Eigenvalues');
      expect(d.url, '');
      expect(d.note, 'Focus on Eigenvalues');
    });

    test('Parses full pipe encoded url|label|note string', () {
      final d = TopicResourceData.parse('https://youtube.com/playlist?list=123|Watch Playlist|Ch 1-4 Notes');
      expect(d.url, 'https://youtube.com/playlist?list=123');
      expect(d.label, 'Watch Playlist');
      expect(d.note, 'Ch 1-4 Notes');
    });

    test('Encodes url and note coexisting together', () {
      const data = TopicResourceData(
        url: 'https://youtube.com/playlist?list=123',
        label: 'Open Resource',
        note: 'Ch 1-4 Notes',
      );
      final encoded = data.encode();
      expect(encoded, 'https://youtube.com/playlist?list=123|Open Resource|Ch 1-4 Notes');

      final reParsed = TopicResourceData.parse(encoded);
      expect(reParsed.url, 'https://youtube.com/playlist?list=123');
      expect(reParsed.note, 'Ch 1-4 Notes');
    });

    test('Preserves url when updating note via copyWith', () {
      final initial = TopicResourceData.parse('https://youtube.com/playlist?list=123');
      final updated = initial.copyWith(note: 'Updated Note');

      expect(updated.url, 'https://youtube.com/playlist?list=123');
      expect(updated.note, 'Updated Note');
    });

    test('Preserves note when updating url via copyWith', () {
      final initial = TopicResourceData.parse('||Existing Note Text');
      final updated = initial.copyWith(url: 'https://youtube.com/playlist?list=456');

      expect(updated.url, 'https://youtube.com/playlist?list=456');
      expect(updated.note, 'Existing Note Text');
    });
  });
}
