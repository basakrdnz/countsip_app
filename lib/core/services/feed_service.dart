import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FeedService {
  /// Maximum number of user IDs in a single whereIn query (Firestore limit is 30).
  static const int _whereInLimit = 10;

  /// Maximum feed entries returned per snapshot.
  static const int _feedLimit = 50;

  /// In-memory cache for the current user's friend IDs.
  /// Cleared whenever a new user signs in.
  static List<String>? _cachedFriendIds;
  static String? _cachedForUserId;

  static Stream<List<Map<String, dynamic>>> getSocialFeed() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    try {
      // 1. Get friend IDs — use in-memory cache to avoid redundant Firestore reads.
      if (_cachedFriendIds == null || _cachedForUserId != user.uid) {
        final friendshipDocs = await FirebaseFirestore.instance
            .collection('friendships')
            .where('users', arrayContains: user.uid)
            .get();

        _cachedFriendIds = friendshipDocs.docs.map((doc) {
          final users = doc.data()['users'] as List;
          return users.firstWhere((id) => id != user.uid) as String;
        }).toList();
        _cachedForUserId = user.uid;
      }

      // Include self; cap at Firestore whereIn limit.
      final allInterestedIds =
          [user.uid, ..._cachedFriendIds!].take(_whereInLimit).toList();

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

  /// Invalidates the in-memory friend ID cache (call on sign-out or friendship change).
  static void invalidateFriendCache() {
    _cachedFriendIds = null;
    _cachedForUserId = null;
  }

  /// Toggles a "cheers" reaction without reading the document first.
  ///
  /// Uses [FieldValue.arrayUnion] / [FieldValue.arrayRemove] directly,
  /// avoiding an unnecessary round-trip read.
  static Future<void> toggleCheers(
    String entryId,
    String userId, {
    required bool currentlyLiked,
  }) async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('entries').doc(entryId);
      if (currentlyLiked) {
        await ref.update({'cheers': FieldValue.arrayRemove([userId])});
      } else {
        await ref.update({'cheers': FieldValue.arrayUnion([userId])});
      }
    } catch (e) {
      debugPrint('FeedService.toggleCheers error: $e');
    }
  }
}
