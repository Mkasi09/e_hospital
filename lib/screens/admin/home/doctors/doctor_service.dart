import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorService {
  static final CollectionReference _doctorCollection =
  FirebaseFirestore.instance.collection('doctors');

  static Future<void> addDoctor({
    required String name,
    required String email,
    required String specialty,
  }) async {
    await _doctorCollection.add({
      'name': name,
      'email': email,
      'specialty': specialty,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getDoctorsStream() {
    return _doctorCollection.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> deleteDoctor(String docId) async {
    await _doctorCollection.doc(docId).delete();
  }
}
