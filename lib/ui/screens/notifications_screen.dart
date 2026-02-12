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
             return Center(child: Text('Hata: ${requestsSnapshot.error}'));
          }
          
          if (requestsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = requestsSnapshot.data?.docs ?? [];
          
          if (requests.isEmpty) {
             return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              data['id'] = requests[index].id;
              
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                     child: _NotificationItem(request: data),
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
          // Home Screen Style Icon with Spreading Glow
          Stack(
            alignment: Alignment.center,
            children: [
              // Spreading Glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              // Home Screen Notification Icon
              Icon(
                Icons.notifications_none_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Bildirim Yok',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
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
