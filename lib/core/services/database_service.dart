import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateTestCode() {
    // Generate a 6 digit random code
    final random = Random();
    int code = random.nextInt(900000) + 100000;
    return code.toString();
  }

  Future<String> createTest(String testName, int durationMinutes, List<Map<String, dynamic>> questions, {bool hasNegativeMarking = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to create a test');

    final code = _generateTestCode();
    
    await _db.collection('tests').doc(code).set({
      'testId': code,
      'teacherId': user.uid,
      'teacherName': user.displayName ?? 'Teacher',
      'testName': testName,
      'durationMinutes': durationMinutes,
      'questions': questions,
      'hasNegativeMarking': hasNegativeMarking,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    return code;
  }

  Future<void> updateTest(String code, String testName, int durationMinutes, List<Map<String, dynamic>> questions, {bool hasNegativeMarking = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to update a test');

    await _db.collection('tests').doc(code).update({
      'testName': testName,
      'durationMinutes': durationMinutes,
      'questions': questions,
      'hasNegativeMarking': hasNegativeMarking,
    });
  }

  Future<Map<String, dynamic>?> getTest(String code) async {
    final doc = await _db.collection('tests').doc(code).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> submitResult(
    String code,
    String studentName,
    int score,
    int total, {
    int? maxScore,
    String? testName,
    List<dynamic>? questions,
    Map<int, String>? selectedAnswers,
  }) async {
    final user = _auth.currentUser;

    // Convert integer keys to string keys for Firestore compatibility
    Map<String, String>? firestoreAnswers;
    if (selectedAnswers != null) {
      firestoreAnswers = selectedAnswers.map((key, value) => MapEntry(key.toString(), value));
    }

    await _db.collection('results').add({
      'testId': code,
      if (testName != null) 'testName': testName,
      if (user != null) 'studentId': user.uid,
      if (user?.email != null) 'studentEmail': user!.email,
      'studentName': studentName,
      'score': score,
      'total': total,
      if (maxScore != null) 'maxScore': maxScore,
      if (questions != null) 'questions': questions,
      if (firestoreAnswers != null) 'selectedAnswers': firestoreAnswers,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasStudentAlreadyAttempted(String code, String studentName) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userQuery = await _db.collection('results')
          .where('testId', isEqualTo: code)
          .where('studentId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) return true;
    }

    final query = await _db.collection('results')
        .where('testId', isEqualTo: code)
        .where('studentName', isEqualTo: studentName)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Stream<QuerySnapshot> getTeacherTests() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');
    
    return _db.collection('tests')
      .where('teacherId', isEqualTo: user.uid)
      .snapshots();
  }

  Future<void> deleteTest(String code) async {
    // Delete the test
    await _db.collection('tests').doc(code).delete();
    // Delete associated results (optional, but good practice)
    final results = await _db.collection('results').where('testId', isEqualTo: code).get();
    for (var doc in results.docs) {
      await doc.reference.delete();
    }
  }

  Stream<QuerySnapshot> getTestResults(String code) {
    return _db.collection('results')
      .where('testId', isEqualTo: code)
      .snapshots();
  }

  Stream<QuerySnapshot> getCurrentStudentResults() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    return _db.collection('results')
      .where('studentId', isEqualTo: user.uid)
      .snapshots();
  }

  Future<void> toggleTestStatus(String code, bool isActive) async {
    await _db.collection('tests').doc(code).update({
      'isActive': isActive,
    });
  }
}
