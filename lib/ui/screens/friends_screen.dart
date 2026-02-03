import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Arkadaşlar', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: () => context.push('/add-friend'),
            icon: Icon(AppIcons.addUser, size: 22),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.buttonPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.buttonPrimary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: [
            _buildFriendsTabLabel(),
            _buildRequestsTabLabel(),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsListTab(),
          _RequestsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTabLabel() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Tab(text: 'Arkadaşlarım');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friendships')
          .where('users', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Arkadaşlarım'),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTabLabel() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Tab(text: 'İstekler');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('to', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('İstekler'),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FriendsListTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Giriş yapmalısın'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friendships')
          .where('users', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final friendships = snapshot.data?.docs ?? [];

        if (friendships.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.users, size: 80, color: Colors.white10),
                const SizedBox(height: 16),
                Text(
                  'Henüz arkadaşın yok',
                  style: TextStyle(fontSize: 18, color: Colors.white24),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/add-friend'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.addUser, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Arkadaş Ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: friendships.length,
          itemBuilder: (context, index) {
            final friendship = friendships[index].data() as Map<String, dynamic>;
            final friendUid = (friendship['users'] as List)
                .firstWhere((uid) => uid != user.uid);
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox(height: 70);
                }

                final friendData = userSnapshot.data?.data() as Map<String, dynamic>?;
                if (friendData == null) return const SizedBox();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.glassCard(borderRadius: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: friendData['photoUrl'] != null
                            ? NetworkImage(friendData['photoUrl'])
                            : null,
                        child: friendData['photoUrl'] == null
                            ? Icon(AppIcons.user, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(
                                friendData['name'] ?? 'İsimsiz',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '@${friendData['username'] ?? ''}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(AppIcons.menuDotsVertical, color: Colors.grey.shade400, size: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'block') {
                            _showBlockDialog(context, friendUid, friendData['name'] ?? 'Bu kullanıcı', friendships[index].id);
                          } else if (value == 'remove') {
                            _showRemoveFriendDialog(context, friendData['name'] ?? 'Bu kullanıcı', friendships[index].id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(AppIcons.userRemoveIcon, color: Colors.orange, size: 20),
                                const SizedBox(width: 12),
                                const Text('Arkadaşlıktan Çıkar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'block',
                            child: Row(
                              children: [
                                Icon(AppIcons.ban, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                const Text('Engelle'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  
  void _showBlockDialog(BuildContext context, String friendUid, String friendName, String friendshipId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(AppIcons.ban, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Kullanıcıyı Engelle', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '$friendName adlı kullanıcıyı engellemek istediğine emin misin?\n\n'
          'Engeeldiğinde:\n'
          '• Arkadaşlığınız sonlanacak\n'
          '• Seni bulamayacak\n'
          '• Sana istek gönderemeyecek',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _blockUser(context, friendUid, friendshipId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Engelle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _blockUser(BuildContext context, String targetUid, String friendshipId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Add to blocks collection
      final blockRef = FirebaseFirestore.instance.collection('blocks').doc();
      batch.set(blockRef, {
        'blockerUid': user.uid,
        'blockedUid': targetUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // 2. Delete friendship
      batch.delete(FirebaseFirestore.instance.collection('friendships').doc(friendshipId));
      
      // 3. Delete any pending requests between them
      final outgoingRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: user.uid)
          .where('to', isEqualTo: targetUid)
          .get();
      for (final doc in outgoingRequests.docs) {
        batch.delete(doc.reference);
      }
      
      final incomingRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: targetUid)
          .where('to', isEqualTo: user.uid)
          .get();
      for (final doc in incomingRequests.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Kullanıcı engellendi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _showRemoveFriendDialog(BuildContext context, String friendName, String friendshipId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Arkadaşlıktan Çıkar', style: TextStyle(color: Colors.white)),
        content: Text('$friendName adlı kullanıcıyı arkadaş listenden çıkarmak istediğine emin misin?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeFriend(context, friendshipId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Çıkar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeFriend(BuildContext context, String friendshipId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friendships')
          .doc(friendshipId)
          .delete();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Arkadaşlıktan çıkarıldı'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Giriş yapmalısın'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('to', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.envelope, size: 80, color: Colors.white10),
                const SizedBox(height: 16),
                Text(
                  'Bekleyen istek yok',
                  style: TextStyle(fontSize: 18, color: Colors.white24),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final fromUid = request['from'] as String;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox(height: 90);
                }

                final senderData = userSnapshot.data?.data() as Map<String, dynamic>?;
                if (senderData == null) return const SizedBox();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.glassCard(borderRadius: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: senderData['photoUrl'] != null
                                ? NetworkImage(senderData['photoUrl'])
                                : null,
                            child: senderData['photoUrl'] == null
                                ? Icon(AppIcons.user, color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  senderData['name'] ?? 'İsimsiz',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '@${senderData['username'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
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
                            child: OutlinedButton(
                              onPressed: () => _rejectRequest(context, request.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Reddet'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _acceptRequest(context, request.id, fromUid),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Kabul Et', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _acceptRequest(BuildContext context, String requestId, String fromUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // Delete request
    batch.delete(FirebaseFirestore.instance.collection('friend_requests').doc(requestId));

    // Create friendship
    final friendshipRef = FirebaseFirestore.instance.collection('friendships').doc();
    batch.set(friendshipRef, {
      'users': [user.uid, fromUid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Arkadaş eklendi!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _rejectRequest(BuildContext context, String requestId) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(requestId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İstek reddedildi'), backgroundColor: Colors.orange),
    );
  }
}
