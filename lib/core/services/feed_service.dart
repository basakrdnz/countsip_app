import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FeedService {
  /// Maximum number of user IDs in a single whereIn query (Firestore limit is 30).
  static const int _whereInLimit = 10;

  /// Maximum feed entries returned per snapshot.
  static const int _feedLimit = 50;

  static Stream<List<Map<String, dynamic>>> getSocialFeed() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    try {
      // 1. Get friend IDs.
      final friendshipDocs = await FirebaseFirestore.instance
          .collection('friendships')
          .where('users', arrayContains: user.uid)
          .get();

      final friendIds = friendshipDocs.docs.map((doc) {
        final users = doc.data()['users'] as List;
        return users.firstWhere((id) => id != user.uid) as String;
      }).toList();

      // Include self; cap at Firestore whereIn limit.
      final allInterestedIds =
          [user.uid, ...friendIds].take(_whereInLimit).toList();

      // 2. Stream entries for those IDs, capped at _feedLimit.
      yield* FirebaseFirestore.instance
          .collection('entries')
          .where('userId', whereIn: allInterestedIds)
          .orderBy('timestamp', descending: true)
          .limit(_feedLimit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList());
    } catch (e, st) {
      debugPrint('FeedService.getSocialFeed error: $e\n$st');
      yield [];
    }
  }

  static Future<void> toggleCheers(String entryId, String userId) async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('entries').doc(entryId);
      final doc = await ref.get();
      if (!doc.exists) return;

      final cheers = List<String>.from(doc.data()?['cheers'] ?? []);
      if (cheers.contains(userId)) {
        await ref.update({'cheers': FieldValue.arrayRemove([userId])});
      } else {
        await ref.update({'cheers': FieldValue.arrayUnion([userId])});
      }
    } catch (e) {
      debugPrint('FeedService.toggleCheers error: $e');
    }
  }
}
