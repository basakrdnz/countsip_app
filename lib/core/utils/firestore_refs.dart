import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed Firestore collection references to avoid raw string paths scattered
/// throughout the codebase. Use these instead of inline
/// `FirebaseFirestore.instance.collection('...')` calls.
class FirestoreRefs {
  FirestoreRefs._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Collections ────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  static CollectionReference<Map<String, dynamic>> get entries =>
      _db.collection('entries');

  static CollectionReference<Map<String, dynamic>> get friendships =>
      _db.collection('friendships');

  static CollectionReference<Map<String, dynamic>> get notifications =>
      _db.collection('notifications');

  static CollectionReference<Map<String, dynamic>> get drinkRequests =>
      _db.collection('drink_requests');

  static CollectionReference<Map<String, dynamic>> get phoneNumbers =>
      _db.collection('phoneNumbers');

  // ── Documents ──────────────────────────────────────────────────────────────

  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      users.doc(uid);

  static DocumentReference<Map<String, dynamic>> entry(String entryId) =>
      entries.doc(entryId);
}
