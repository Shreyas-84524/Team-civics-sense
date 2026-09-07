/// Source medium through which photo evidence was attached.
enum EvidenceSource {
  camera,
  gallery,
}

extension EvidenceSourceExt on EvidenceSource {
  String get label {
    switch (this) {
      case EvidenceSource.camera:
        return 'Camera';
      case EvidenceSource.gallery:
        return 'Gallery';
    }
  }

  String get iconName {
    switch (this) {
      case EvidenceSource.camera:
        return 'camera_alt';
      case EvidenceSource.gallery:
        return 'photo_library';
    }
  }
}

/// Model representing a photo evidence attached to a civic complaint draft.
class EvidenceItem {
  final String id;
  final String filePath;
  final String fileName;
  final EvidenceSource source;
  final DateTime capturedAt;
  final String? previewThumbnail;

  const EvidenceItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.source,
    required this.capturedAt,
    this.previewThumbnail,
  });

  /// Formatted creation time string for UI badges.
  String get formattedTime {
    final hour = capturedAt.hour.toString().padLeft(2, '0');
    final minute = capturedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  EvidenceItem copyWith({
    String? id,
    String? filePath,
    String? fileName,
    EvidenceSource? source,
    DateTime? capturedAt,
    String? previewThumbnail,
  }) {
    return EvidenceItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
      previewThumbnail: previewThumbnail ?? this.previewThumbnail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath;

  @override
  int get hashCode => id.hashCode ^ filePath.hashCode;
}
