import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Friend relationship status enum
enum FriendStatus {
  none,           // No relationship
  pending,        // Outgoing request sent
  incomingRequest,// Incoming request from them
  alreadyFriend,  // Already friends
  blocked,        // User is blocked
}

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _myUsername;
  Map<String, FriendStatus> _userStatuses = {}; // Track status for each user

  @override
  void initState() {
    super.initState();
    _loadMyUsername();
  }

  Future<void> _loadMyUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() => _myUsername = doc.data()?['username']);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final cleanQuery = query.toLowerCase().replaceAll('@', '').trim();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    
    // Exact match only
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: cleanQuery)
        .limit(1)
        .get();

    final results = snapshot.docs
        .where((doc) => doc.id != currentUid && doc.data()['isFrozen'] != true)
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .toList();
    
    // Check status for each result
    for (final user in results) {
      final targetUid = user['uid'] as String;
      final status = await _checkFriendStatus(currentUid, targetUid);
      _userStatuses[targetUid] = status;
    }
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }
  
  /// Check the relationship status between current user and target user
  Future<FriendStatus> _checkFriendStatus(String myUid, String targetUid) async {
    // 1. Check if blocked
    final blockCheck = await FirebaseFirestore.instance
        .collection('blocks')
        .where('blockerUid', isEqualTo: myUid)
        .where('blockedUid', isEqualTo: targetUid)
        .limit(1)
        .get();
    if (blockCheck.docs.isNotEmpty) return FriendStatus.blocked;
    
    // Check if they blocked me
    final blockedByThemCheck = await FirebaseFirestore.instance
        .collection('blocks')
        .where('blockerUid', isEqualTo: targetUid)
        .where('blockedUid', isEqualTo: myUid)
        .limit(1)
        .get();
    if (blockedByThemCheck.docs.isNotEmpty) return FriendStatus.blocked;
    
    // 2. Check if already friends
    final friendships = await FirebaseFirestore.instance
        .collection('friendships')
        .where('users', arrayContains: myUid)
        .get();
    
    final isAlreadyFriend = friendships.docs.any((doc) {
      final users = doc['users'] as List;
      return users.contains(targetUid);
    });
    if (isAlreadyFriend) return FriendStatus.alreadyFriend;
    
    // 3. Check if I sent a request to them
    final outgoingRequest = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: myUid)
        .where('to', isEqualTo: targetUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (outgoingRequest.docs.isNotEmpty) return FriendStatus.pending;
    
    // 4. Check if they sent a request to me
    final incomingRequest = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: targetUid)
        .where('to', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (incomingRequest.docs.isNotEmpty) return FriendStatus.incomingRequest;
    
    return FriendStatus.none;
  }

  Future<void> _sendFriendRequest(String targetUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get current status
      final status = _userStatuses[targetUid] ?? await _checkFriendStatus(user.uid, targetUid);
      
      if (status == FriendStatus.blocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kullanıcı engellenmiş'), backgroundColor: Colors.red),
        );
        return;
      }
      
      if (status == FriendStatus.alreadyFriend) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zaten arkadaşsınız'), backgroundColor: Colors.blue),
        );
        return;
      }
      
      if (status == FriendStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zaten istek gönderilmiş'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      // If they already sent us a request, accept it instead
      if (status == FriendStatus.incomingRequest) {
        await _acceptIncomingRequest(targetUid);
        return;
      }

      // Send new request
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'from': user.uid,
        'to': targetUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _userStatuses[targetUid] = FriendStatus.pending);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Arkadaşlık isteği gönderildi'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  /// Cancel a pending friend request that I sent
  Future<void> _cancelFriendRequest(String targetUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Find and delete my outgoing request
      final requestQuery = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: user.uid)
          .where('to', isEqualTo: targetUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      if (requestQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstek bulunamadı'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      await requestQuery.docs.first.reference.delete();
      
      setState(() => _userStatuses[targetUid] = FriendStatus.none);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ İstek iptal edildi'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  /// Accept incoming friend request when user clicks "Add" (auto-accept if they already requested)
  Future<void> _acceptIncomingRequest(String fromUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Find the incoming request
      final requestQuery = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: fromUid)
          .where('to', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      
      if (requestQuery.docs.isEmpty) return;
      
      final requestId = requestQuery.docs.first.id;
      final batch = FirebaseFirestore.instance.batch();
      
      // Delete the request
      batch.delete(FirebaseFirestore.instance.collection('friend_requests').doc(requestId));
      
      // Create friendship
      final friendshipRef = FirebaseFirestore.instance.collection('friendships').doc();
      batch.set(friendshipRef, {
        'users': [user.uid, fromUid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      setState(() => _userStatuses[fromUid] = FriendStatus.alreadyFriend);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Arkadaş olarak eklendi!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _shareUsername() {
    Share.share(
      'CountSip\'te beni ekle: @$_myUsername',
      subject: 'CountSip Arkadaşlık Daveti',
    );
  }

  Widget _buildAddButton(String targetUid) {
    final status = _userStatuses[targetUid] ?? FriendStatus.none;
    
    switch (status) {
      case FriendStatus.alreadyFriend:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                'Arkadaş',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
        
      case FriendStatus.pending:
        return GestureDetector(
          onTap: () => _cancelFriendRequest(targetUid),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  'İptal Et',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case FriendStatus.incomingRequest:
        return GestureDetector(
          onTap: () => _acceptIncomingRequest(targetUid),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Kabul Et',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case FriendStatus.blocked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 4),
              Text(
                'Engelli',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
        
      case FriendStatus.none:
      default:
        return GestureDetector(
          onTap: () => _sendFriendRequest(targetUid),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Arkadaş Ekle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.block_outlined),
            tooltip: 'Engellenen Kullanıcılar',
            onPressed: () => context.push('/blocked-users'),
          ),
        ],
      ),
      body: Column(
        children: [
          // My Username Card
          if (_myUsername != null)
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.share, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kullanıcı adını paylaş',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '@$_myUsername',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '@$_myUsername'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kopyalandı!')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Kopyala'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareUsername,
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Paylaş'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Tam kullanıcı adını gir...',
                prefixIcon: const Icon(Icons.alternate_email),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Search Results
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.length < 3
                              ? 'Kullanıcı adını tam olarak yaz'
                              : 'Kullanıcı bulunamadı',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: user['photoUrl'] != null
                                  ? NetworkImage(user['photoUrl'])
                                  : null,
                              child: user['photoUrl'] == null
                                  ? Icon(Icons.person, color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'İsimsiz',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '@${user['username']}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildAddButton(user['uid']),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
