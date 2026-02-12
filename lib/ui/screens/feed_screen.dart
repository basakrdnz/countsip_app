import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/services/feed_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Akış',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false, // Hide back button for main tab
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Friend Activity Stream (Last 24h)
        // We need friend IDs. For simplicity in UI, we fetch friendships here.
        stream: FirebaseFirestore.instance
            .collection('friendships')
            .where('users', arrayContains: user.uid)
            .snapshots(),
        builder: (context, friendshipsSnapshot) {
          if (friendshipsSnapshot.hasError) {
            debugPrint('Friendships stream error: ${friendshipsSnapshot.error}');
          }
           if (friendshipsSnapshot.connectionState == ConnectionState.waiting) {
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

          // If no friends, show empty
          if (relevantUserIds.isEmpty) {
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
                            child: _FeedItemWidget(item: item, currentUserId: user.uid),
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
              AppIcons.glassCheers,
              size: 80,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Akış Sessiz...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary.withOpacity(0.8),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz kimse bir şey içmemiş.\nİlk kadehi sen kaldır! 🥂',
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

class _FeedItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final String currentUserId;

  const _FeedItemWidget({required this.item, required this.currentUserId});

  @override
  State<_FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends State<_FeedItemWidget> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Your own posts start collapsed ('şerit gibi')
    if (widget.item['userId'] == widget.currentUserId) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final currentUserId = widget.currentUserId;
    final timestamp = item['timestamp'] as Timestamp?;
    final timeStr = timestamp != null ? timeago.format(timestamp.toDate(), locale: 'tr') : '';
    final cheers = List<String>.from(item['cheers'] ?? []);
    final hasCheered = cheers.contains(currentUserId);
    final drinkEmoji = item['drinkEmoji'] ?? '🍹';
    final drinkType = item['drinkType'] ?? 'İçecek';
    final portion = item['portion'] ?? '';
    final isOwnPost = item['userId'] == currentUserId;

    return GestureDetector(
      onTap: () {
        if (isOwnPost) {
          setState(() => _isExpanded = !_isExpanded);
          HapticFeedback.selectionClick();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: (isOwnPost && !_isExpanded)
            ? AppDecorations.glassCard(
                borderRadius: 24,
                color: AppColors.primary.withOpacity(0.05),
              ).copyWith(
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              )
            : AppDecorations.glassCard(borderRadius: 24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User Info + Drink Badge (The "Strip" always visible)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    children: [
                      _buildUserAvatar(item['userId'], size: 40),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                          ),
                          child: Text(drinkEmoji, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserName(item['userId']),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 10, color: AppColors.textPrimary.withOpacity(0.3)),
                            const SizedBox(width: 4),
                            Text(timeStr, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.35), fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  if (isOwnPost && !_isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        drinkType,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ),

                  // Portion Chip
                  if (portion.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        portion,
                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  
                  if (isOwnPost)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            
            // Expandable Content
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Content: Image
                  if (item['hasImage'] == true && (item['imageUrl'] != null || item['imagePath'] != null))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: item['imageUrl'] != null
                            ? CachedNetworkImage(
                                imageUrl: item['imageUrl'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.white10),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                              )
                            : Image.file(File(item['imagePath']), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  
                  // Post Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drinkType,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        if (item['locationName'] != null && item['locationName'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(item['locationName'], style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        if (item['note'] != null && item['note'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              item['note'], 
                              style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6), fontSize: 13, height: 1.4),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Social Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            FeedService.toggleCheers(item['id'], currentUserId);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: hasCheered ? AppColors.primary : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(AppIcons.glassCheers, color: hasCheered ? Colors.white : AppColors.textPrimary.withOpacity(0.4), size: 16),
                                if (cheers.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text('${cheers.length}', style: TextStyle(color: hasCheered ? Colors.white : AppColors.textPrimary.withOpacity(0.4), fontWeight: FontWeight.w900, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (cheers.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showCheersList(context, cheers),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  _buildAvatarStack(cheers),
                                  const SizedBox(width: 6),
                                  Icon(AppIcons.angleRight, size: 10, color: AppColors.textPrimary.withOpacity(0.2)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  // Identical helper methods moved into the widget
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
            ? ClipRRect(borderRadius: BorderRadius.circular(size / 2), child: CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover))
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
        );
      },
    );
  }

  Widget _buildAvatarStack(List<String> userIds) {
    const double size = 20.0;
    const double overlap = 12.0;
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
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 1.5)),
                child: _buildUserAvatar(entry.value, size: size - 3),
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
          decoration: AppDecorations.glassCard().copyWith(borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('ŞEREFE DİYENLER', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2, fontSize: 13)),
              const SizedBox(height: 20),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          leading: _buildUserAvatar(userId, size: 36),
                          title: Text(userData?['name'] ?? '...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('@${userData?['username'] ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
