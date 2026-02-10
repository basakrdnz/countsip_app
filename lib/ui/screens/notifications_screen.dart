import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import '../../core/services/feed_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: Icon(AppIcons.angleLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Friend Requests Stream
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where('to', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, requestsSnapshot) {
          // 2. Friend Activity Stream (Last 24h)
          // We need friend IDs. For simplicity in UI, we fetch friendships here.
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('friendships')
                .where('users', arrayContains: user.uid)
                .snapshots(),
            builder: (context, friendshipsSnapshot) {
              if (requestsSnapshot.connectionState == ConnectionState.waiting || 
                  friendshipsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final friendIds = friendshipsSnapshot.data?.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final users = data['users'] as List;
                return users.firstWhere((id) => id != user.uid) as String;
              }).toList() ?? [];

              // If no friends and no requests, show empty
              if (friendIds.isEmpty && (requestsSnapshot.data?.docs.isEmpty ?? true)) {
                return _buildEmptyState();
              }

              // Now fetch activities from these friends (All Time)
              return StreamBuilder<QuerySnapshot>(
                stream: friendIds.isNotEmpty 
                  ? FirebaseFirestore.instance
                    .collection('entries')
                    .where('userId', whereIn: friendIds.take(10).toList())
                    .orderBy('timestamp', descending: true)
                    .limit(50) // Show last 50 entries
                    .snapshots()
                  : const Stream.empty(),
                builder: (context, activitySnapshot) {
                  final List<Map<String, dynamic>> allItems = [];

                  // Add requests as special items
                  if (requestsSnapshot.hasData) {
                    for (var doc in requestsSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      data['_type'] = 'friend_request';
                      data['_timestamp'] = data['createdAt'] ?? data['timestamp'] ?? Timestamp.now();
                      allItems.add(data);
                    }
                  }

                  // Add activities
                  if (activitySnapshot.hasData && activitySnapshot.data != null) {
                    for (var doc in activitySnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      data['_type'] = 'activity';
                      data['_timestamp'] = data['timestamp'] ?? Timestamp.now();
                      allItems.add(data);
                    }
                  }

                  // Sort by timestamp
                  allItems.sort((a, b) {
                    final tsA = a['_timestamp'] as Timestamp;
                    final tsB = b['_timestamp'] as Timestamp;
                    return tsB.compareTo(tsA);
                  });

                  if (allItems.isEmpty) {
                    return _buildEmptyState();
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        final item = allItems[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: item['_type'] == 'friend_request' 
                                  ? _NotificationItem(request: item)
                                  : _buildFeedItem(item, user.uid),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.03),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.05), width: 1),
            ),
            child: Icon(
              AppIcons.bell,
              size: 80,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Her Şey Sessiz...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary.withOpacity(0.8),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Şu an için yeni bir bildirim veya\narkadaş aktivitesi bulunmuyor. 🥂',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary.withOpacity(0.5),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item, String currentUserId) {
    final timestamp = item['timestamp'] as Timestamp?;
    final timeStr = timestamp != null ? timeago.format(timestamp.toDate(), locale: 'tr') : '';
    final cheers = List<String>.from(item['cheers'] ?? []);
    final hasCheered = cheers.contains(currentUserId);
    final drinkEmoji = item['drinkEmoji'] ?? '🍹';
    final drinkType = item['drinkType'] ?? 'İçecek';
    final portion = item['portion'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: AppDecorations.glassCard(borderRadius: 32),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Info + Drink Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    _buildUserAvatar(item['userId'], size: 48),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                        ),
                        child: Text(drinkEmoji, style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserName(item['userId']),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AppColors.textPrimary.withOpacity(0.3)),
                          const SizedBox(width: 4),
                          Text(timeStr, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.35), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Portion Chip
                if (portion.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      portion,
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          
          // Post Content: Image
          if (item['hasImage'] == true && item['imagePath'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      File(item['imagePath']), 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white.withOpacity(0.05),
                        child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Post Details: Description & Context
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drinkType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 18, 
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (item['locationName'] != null && item['locationName'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          item['locationName'], 
                          style: const TextStyle(
                            color: AppColors.primary, 
                            fontSize: 12, 
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item['note'] != null && item['note'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      item['note'], 
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.6), 
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Social Interactions Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Cheers Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    FeedService.toggleCheers(item['id'], currentUserId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasCheered ? AppColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasCheered ? AppColors.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasCheered ? Icons.celebration : Icons.celebration_outlined,
                          color: hasCheered ? AppColors.primary : AppColors.textPrimary.withOpacity(0.4),
                          size: 20,
                        ),
                        if (cheers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${cheers.length}',
                            style: TextStyle(
                              color: hasCheered ? AppColors.primary : AppColors.textPrimary.withOpacity(0.4),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Cheered by Avatars Preview
                if (cheers.isNotEmpty)
                  SizedBox(
                    height: 28,
                    child: Row(
                      children: [
                        SizedBox(
                          width: (cheers.length > 3 ? 3 : cheers.length) * 16.0 + 12.0,
                          child: Stack(
                            children: List.generate(
                              cheers.length > 3 ? 3 : cheers.length,
                              (idx) => Positioned(
                                left: idx * 16.0,
                                child: _buildUserAvatar(cheers[idx], size: 24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Şerefe!',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String userId, {double size = 40}) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final photoUrl = data?['photoUrl'];
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
          child: photoUrl != null 
            ? ClipRRect(borderRadius: BorderRadius.circular(size / 2), child: Image.network(photoUrl, fit: BoxFit.cover))
            : Icon(Icons.person, color: Colors.white24, size: size * 0.6),
        );
      },
    );
  }

  Widget _buildUserName(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        return Text(
          data?['name'] ?? 'Yükleniyor...',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> request;

  const _NotificationItem({required this.request});

  @override
  Widget build(BuildContext context) {
    final fromUid = request['from'] as String;
    final requestId = request['id'] as String;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100);
        }

        final senderData = snapshot.data?.data() as Map<String, dynamic>?;
        if (senderData == null) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.glassCard(borderRadius: 24).copyWith(
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with Border
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.5), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: senderData['photoUrl'] != null 
                      ? NetworkImage(senderData['photoUrl']) 
                      : null,
                  child: senderData['photoUrl'] == null 
                      ? Icon(AppIcons.user, color: AppColors.textTertiary, size: 24) 
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderData['name'] ?? 'İsimsiz',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 16, 
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'arkadaş olmak istiyor',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accept button (Gradient)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _acceptRequest(context, fromUid);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B09B), Color(0xFF96C93D)], // Fresh Green Gradient
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B09B).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Onayla',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Reject button (Icon only)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _rejectRequest(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white.withOpacity(0.4),
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
  }

  Widget _buildActionButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptRequest(BuildContext context, String fromUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final requestId = request['id'] as String;
      batch.delete(FirebaseFirestore.instance.collection('friend_requests').doc(requestId));
      
      final friendshipRef = FirebaseFirestore.instance.collection('friendships').doc();
      batch.set(friendshipRef, {
        'users': [user.uid, fromUid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  Future<void> _rejectRequest(BuildContext context) async {
    final requestId = request['id'] as String;
    try {
      await FirebaseFirestore.instance.collection('friend_requests').doc(requestId).delete();
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    }
  }
}
