import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Firestore
  static FirebaseFirestore get firestore => _firestore;

  static CollectionReference get usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  static CollectionReference get roomsCollection =>
      _firestore.collection(AppConstants.roomsCollection);

  static CollectionReference get classesCollection =>
      _firestore.collection(AppConstants.classesCollection);

  static CollectionReference get reservationsCollection =>
      _firestore.collection(AppConstants.reservationsCollection);

  static CollectionReference get packsCollection =>
      _firestore.collection(AppConstants.packsCollection);

  static CollectionReference get purchasesCollection =>
      _firestore.collection(AppConstants.purchasesCollection);

  static CollectionReference get reportsCollection =>
      _firestore.collection(AppConstants.reportsCollection);

  // Auth
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  // Messaging
  static FirebaseMessaging get messaging => _messaging;

  // Storage
  static FirebaseStorage get storage => _storage;

  // Helper methods
  static Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists ? doc.data() : null;
    } on firebase_core.FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error getting document');
    }
  }

  static Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(data);
    } on firebase_core.FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error setting document');
    }
  }

  static Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } on firebase_core.FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error updating document');
    }
  }

  static Future<void> deleteDocument(
    String collection,
    String documentId,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } on firebase_core.FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error deleting document');
    }
  }

  static Stream<QuerySnapshot> getCollectionStream(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) {
    Query query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  static Future<QuerySnapshot> getCollection(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return await query.get();
    } on firebase_core.FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error getting collection');
    }
  }

  // Transaction helper
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction) updateFunction,
  ) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } on firebase_core.FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error running transaction');
    }
  }

  // Batch helper
  static WriteBatch getBatch() => _firestore.batch();

  static Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } on firebase_core.FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Error committing batch');
    }
  }
}
