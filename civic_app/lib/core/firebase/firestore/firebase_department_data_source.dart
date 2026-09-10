import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Govt UI/models/department_model.dart';
import '../errors/firestore_error_handler.dart';
import '../firebase_constants.dart';
import '../mappers/department_firestore_mapper.dart';

/// Remote Firestore Data Source for reading Municipal Department catalogs.
class FirebaseDepartmentDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseDepartmentDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _departmentsRef =>
      _db.collection(FirestoreCollections.departments);

  /// Retrieves the list of active municipal departments.
  Future<List<GovtDepartmentModel>> getDepartments() async {
    try {
      final snapshot = await _departmentsRef.where('active', isEqualTo: true).get();
      if (snapshot.docs.isEmpty) {
        return GovtDepartmentModel.defaultDepartments;
      }

      return snapshot.docs
          .map((doc) => DepartmentFirestoreMapper.departmentFromFirestore(
                documentId: doc.id,
                data: doc.data(),
              ))
          .toList();
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Fetches a specific department by ID.
  Future<GovtDepartmentModel?> getDepartmentById(String id) async {
    try {
      final doc = await _departmentsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        try {
          return GovtDepartmentModel.defaultDepartments.firstWhere((d) => d.id == id);
        } catch (_) {
          return null;
        }
      }
      return DepartmentFirestoreMapper.departmentFromFirestore(
        documentId: doc.id,
        data: doc.data()!,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }
}
