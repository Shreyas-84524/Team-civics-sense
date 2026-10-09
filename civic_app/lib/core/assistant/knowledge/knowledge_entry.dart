/// Data model representing a canonical CivicFix knowledge entry.
class KnowledgeEntry {
  /// Unique identifier for this knowledge entry (e.g., 'overview_platform', 'dept_maintenance_roads').
  final String id;

  /// Human-readable title of the topic.
  final String title;

  /// High-level topic category (e.g., 'overview', 'lifecycle', 'departments', 'wards', 'roles', 'faq').
  final String topic;

  /// Target audience: 'citizen', 'government', or 'all'.
  final String audience;

  /// Search tags and keywords associated with this entry.
  final List<String> tags;

  /// Authoritative, canonical explanation and facts for this topic.
  final String canonicalContent;

  /// Related knowledge entry IDs.
  final List<String> relatedTopics;

  /// Reference source verifying this knowledge (e.g., 'Brain.md', 'departments.ts').
  final String sourceReference;

  const KnowledgeEntry({
    required this.id,
    required this.title,
    required this.topic,
    this.audience = 'all',
    required this.tags,
    required this.canonicalContent,
    this.relatedTopics = const [],
    required this.sourceReference,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'audience': audience,
        'tags': tags,
        'canonicalContent': canonicalContent,
        'relatedTopics': relatedTopics,
        'sourceReference': sourceReference,
      };
}
