/// Represents the structured data stored within a syllabus topic's `resourceUrl` column.
///
/// Encodes as `url|label|note` inside the single TEXT column in SQLite,
/// ensuring both Resource Links and Study Notes can coexist without overwriting each other,
/// while maintaining full cloud synchronization.
class TopicResourceData {
  final String url;
  final String label;
  final String note;

  const TopicResourceData({
    this.url = '',
    this.label = 'Open Resource',
    this.note = '',
  });

  /// Parse a raw string stored in database into structured [TopicResourceData].
  factory TopicResourceData.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const TopicResourceData();
    }

    final trimmed = raw.trim();

    // Direct check for leading || (note with empty URL)
    if (trimmed.startsWith('||')) {
      return TopicResourceData(note: trimmed.substring(2).trim());
    }

    // Case 1: Structured pipe format `url|label|note`
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      final url = parts[0].trim();
      final label = parts.length > 1 && parts[1].trim().isNotEmpty
          ? parts[1].trim()
          : 'Open Resource';
      final note = parts.length > 2 ? parts.sublist(2).join('|').trim() : '';
      return TopicResourceData(url: url, label: label, note: note);
    }

    // Case 2: Plain URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return TopicResourceData(url: trimmed);
    }

    // Case 3: Plain Note Text
    return TopicResourceData(note: trimmed);
  }

  /// Encode structured data back into string for database storage.
  String? encode() {
    final cleanUrl = url.trim();
    final cleanLabel = label.trim().isEmpty ? 'Open Resource' : label.trim();
    final cleanNote = note.trim();

    if (cleanUrl.isEmpty && cleanNote.isEmpty) {
      return null;
    }

    if (cleanNote.isEmpty && (cleanLabel == 'Open Resource' || cleanLabel.isEmpty)) {
      return cleanUrl;
    }

    if (cleanUrl.isEmpty) {
      return '||$cleanNote';
    }

    return '$cleanUrl|$cleanLabel|$cleanNote';
  }

  TopicResourceData copyWith({
    String? url,
    String? label,
    String? note,
  }) {
    return TopicResourceData(
      url: url ?? this.url,
      label: label ?? this.label,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicResourceData &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          label == other.label &&
          note == other.note;

  @override
  int get hashCode => url.hashCode ^ label.hashCode ^ note.hashCode;
}
