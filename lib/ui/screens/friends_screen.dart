import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
                    color: AppColors.primary,
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
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFEE5A6F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.addUser, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'Arkadaş Ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
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

        return RefreshIndicator(
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
          color: AppColors.primary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                    decoration: AppDecorations.glassCard(borderRadius: 24),
                    child: Row(
                      children: [
                        // Avatar with matching style
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: friendData['photoUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(friendData['photoUrl'], fit: BoxFit.cover),
                                )
                              : Icon(AppIcons.user, color: AppColors.primary.withOpacity(0.6), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  friendData['name'] ?? 'İsimsiz',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  '@${friendData['username'] ?? ''}',
                                  style: TextStyle(
                                    color: AppColors.textTertiary.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(AppIcons.menuDotsVertical, color: AppColors.textTertiary.withOpacity(0.5), size: 18),
                          color: AppColors.surface, // Dark background
                          elevation: 8,
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
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
                              height: 44,
                              child: Row(
                                children: [
                                  Icon(AppIcons.userRemoveIcon, color: Colors.orange.withOpacity(0.8), size: 18),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Arkadaşlıktan Çıkar',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              height: 44,
                              child: Row(
                                children: [
                                  Icon(AppIcons.ban, color: AppColors.error.withOpacity(0.8), size: 18),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Engelle',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
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
          ),
        );
      },
    );
  }
  
  void _showBlockDialog(BuildContext context, String friendUid, String friendName, String friendshipId) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: AppColors.background.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kullanıcıyı Engelle',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$friendName adlı kullanıcıyı engellemek istediğine emin misin? Bu işlem sonunda arkadaşlığınız sonlanır.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'VAZGEÇ',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _blockUser(context, friendUid, friendshipId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'ENGELLE',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: AppColors.background.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_remove_rounded,
                  color: Colors.orange.withOpacity(0.8),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Arkadaşlıktan Çıkar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$friendName adlı kullanıcıyı arkadaş listenden çıkarmak istediğine emin misin?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'VAZGEÇ',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _removeFriend(context, friendshipId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'ÇIKAR',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

        return RefreshIndicator(
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
          color: AppColors.primary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                    decoration: AppDecorations.glassCard(borderRadius: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Avatar with matching style
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: senderData['photoUrl'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(senderData['photoUrl'], fit: BoxFit.cover),
                                    )
                                  : Icon(AppIcons.user, color: AppColors.primary.withOpacity(0.6), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderData['name'] ?? 'İsimsiz',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  Text(
                                    '@${senderData['username'] ?? ''}',
                                    style: TextStyle(
                                      color: AppColors.textTertiary.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _rejectRequest(context, request.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    'Reddet',
                                    style: TextStyle(
                                      color: AppColors.error.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _acceptRequest(context, request.id, fromUid),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, Color(0xFFEE5A6F)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Kabul Et',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
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
          ),
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
