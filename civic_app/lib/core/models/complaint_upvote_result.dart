/// Authoritative result of trying to support a complaint.
///
/// [added] is false when this user had already supported the complaint. The
/// count is always the value stored by the authoritative data source.
class ComplaintUpvoteResult {
  final bool added;
  final int upvotes;

  const ComplaintUpvoteResult({required this.added, required this.upvotes});
}
