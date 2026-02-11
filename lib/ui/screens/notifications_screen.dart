import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
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
          if (requestsSnapshot.hasError) {
            debugPrint('Friend requests stream error: ${requestsSnapshot.error}');
          }
          // 2. Friend Activity Stream (Last 24h)
          // We need friend IDs. For simplicity in UI, we fetch friendships here.
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('friendships')
                .where('users', arrayContains: user.uid)
                .snapshots(),
            builder: (context, friendshipsSnapshot) {
              if (friendshipsSnapshot.hasError) {
                debugPrint('Friendships stream error: ${friendshipsSnapshot.error}');
              }
              if (requestsSnapshot.connectionState == ConnectionState.waiting || 
                  friendshipsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final relevantUserIds = friendshipsSnapshot.data?.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final users = data['users'] as List;
                return users.firstWhere((id) => id != user.uid) as String;
              }).toList() ?? [];
              
              // Her zaman kullanıcının kendi ID'sini de ekle (Kendi paylaşımlarını görmesi için)
              if (!relevantUserIds.contains(user.uid)) {
                relevantUserIds.insert(0, user.uid);
              }

              // If no friends and no requests, show empty
              if (relevantUserIds.isEmpty && (requestsSnapshot.data?.docs.isEmpty ?? true)) {
                return _buildEmptyState();
              }

              // Now fetch activities (All Time)
              return StreamBuilder<QuerySnapshot>(
                stream: relevantUserIds.isNotEmpty 
                  ? FirebaseFirestore.instance
                    .collection('entries')
                    .where('userId', whereIn: relevantUserIds.take(10).toList())
                    .orderBy('timestamp', descending: true)
                    .limit(50) // Show last 50 entries
                    .snapshots()
                  : const Stream.empty(),
                builder: (context, activitySnapshot) {
                  if (activitySnapshot.hasError) {
                    debugPrint('Activity stream error: ${activitySnapshot.error}');
                  }
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

                  return RefreshIndicator(
                    onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
                    color: AppColors.primary,
                    child: AnimationLimiter(
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
          if (item['hasImage'] == true && (item['imageUrl'] != null || item['imagePath'] != null))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: item['imageUrl'] != null
                      ? CachedNetworkImage(
                          imageUrl: item['imageUrl'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white.withOpacity(0.05),
                            child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
                          ),
                        )
                      : Image.file(
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
                // Cheers Button (Modernized)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    FeedService.toggleCheers(item['id'], currentUserId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: hasCheered ? LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      ) : null,
                      color: hasCheered ? null : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: hasCheered ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.glassCheers,
                          color: hasCheered ? Colors.white : AppColors.textPrimary.withOpacity(0.4),
                          size: 20,
                        ),
                        if (cheers.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            '${cheers.length}',
                            style: TextStyle(
                              color: hasCheered ? Colors.white : AppColors.textPrimary.withOpacity(0.4),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Avatars List (Tap to see all)
                if (cheers.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showCheersList(context, cheers),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          _buildAvatarStack(cheers),
                          const SizedBox(width: 8),
                          Icon(AppIcons.angleRight, size: 12, color: AppColors.textPrimary.withOpacity(0.2)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<String> userIds) {
    const double size = 24.0;
    const double overlap = 14.0;
    final displayIds = userIds.take(3).toList();
    
    return SizedBox(
      height: size,
      width: displayIds.length * overlap + (size - overlap),
      child: Stack(
        children: [
          ...displayIds.asMap().entries.map((entry) {
            return Positioned(
              left: entry.key * overlap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: _buildUserAvatar(entry.value, size: size - 4),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showCheersList(BuildContext context, List<String> userIds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppDecorations.glassCard().copyWith(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(
                'ŞEREFE DİYENLER', 
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900, 
                  color: Colors.white, 
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: userIds.length,
                  itemBuilder: (context, index) {
                    final userId = userIds[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, snapshot) {
                        final userData = snapshot.data?.data() as Map<String, dynamic>?;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: _buildUserAvatar(userId, size: 40),
                          title: Text(
                            userData?['name'] ?? 'Yükleniyor...',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '@${userData?['username'] ?? ''}',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
