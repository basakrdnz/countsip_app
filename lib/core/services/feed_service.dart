import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedService {
  static Stream<List<Map<String, dynamic>>> getSocialFeed() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    // 1. Get friend IDs
    final friendshipDocs = await FirebaseFirestore.instance
        .collection('friendships')
        .where('users', arrayContains: user.uid)
        .get();

    final friendIds = friendshipDocs.docs.map((doc) {
      final users = doc.data()['users'] as List;
      return users.firstWhere((id) => id != user.uid) as String;
    }).toList();

    // Include self
    final allInterestedIds = [user.uid, ...friendIds];

    // 2. Fetch all entries for all these IDs

    // Firestore 'whereIn' is limited to 10-30 items depending on version. 
    // For a simple implementation, we'll fetch in batches if needed, 
    // but for now we'll assume a reasonable number of friends.
    // If friends > 10, we'll need a more complex query strategy.
    
    // Using snapshots to keep it reactive
    yield* FirebaseFirestore.instance
        .collection('entries')
        .where('userId', whereIn: allInterestedIds.take(10).toList())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<void> toggleCheers(String entryId, String userId) async {
    final ref = FirebaseFirestore.instance.collection('entries').doc(entryId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final cheers = List<String>.from(doc.data()?['cheers'] ?? []);
    if (cheers.contains(userId)) {
      await ref.update({'cheers': FieldValue.arrayRemove([userId])});
    } else {
      await ref.update({'cheers': FieldValue.arrayUnion([userId])});
    }
  }
}
