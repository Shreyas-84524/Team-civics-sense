import 'package:cloud_firestore/cloud_firestore.dart';

/// Clean pagination page result encapsulating items and continuation cursor.
class FirestorePage<T> {
  final List<T> items;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final int totalCount;

  const FirestorePage({
    required this.items,
    this.hasMore = false,
    this.lastDocument,
    this.totalCount = 0,
  });

  /// Empty page result.
  static FirestorePage<T> empty<T>() => const FirestorePage(items: []);
}
