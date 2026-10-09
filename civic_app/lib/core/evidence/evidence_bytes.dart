import 'dart:typed_data';

/// Browser drafts store data URIs so photos survive a reload in the Hive queue.
Uint8List? evidenceDataBytes(String reference) {
  if (!reference.startsWith('data:image/')) return null;
  return UriData.parse(reference).contentAsBytes();
}

/// Use the image signature, not a picker path (a blob URL has no extension).
String evidenceFileName(Uint8List bytes, int index) {
  final extension = bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50
      ? 'png'
      : bytes.length >= 12 && bytes[0] == 0x52 && bytes[8] == 0x57
      ? 'webp'
      : 'jpg';
  return 'evidence_$index.$extension';
}
