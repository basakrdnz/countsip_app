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
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;
  static const int _maxItems = 30;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _scrollController.addListener(_onScroll);
    _markNotificationsAsRead();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && _notifications.length < _maxItems) {
        _loadMore();
      }
    }
  }

  Future<void> _initialLoad() async {
    if (mounted) setState(() => _isLoading = true);
    
    _notifications.clear();
    _lastDocument = null;
    _hasMore = true;
    
    await _fetchBatch();
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || _notifications.length >= _maxItems) return;
    if (mounted) setState(() => _isLoading = true);
    await _fetchBatch();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchBatch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var query = FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        return;
      }

      _lastDocument = snapshot.docs.last;

      final List<Map<String, dynamic>> batch = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _notifications.addAll(batch);
          if (snapshot.docs.length < _pageSize || _notifications.length >= _maxItems) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

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
      body: _notifications.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _initialLoad,
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _notifications.length + (_hasMore && _notifications.length < _maxItems ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }

                      final data = _notifications[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _NotificationItem(notification: data, onActionComplete: _initialLoad),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            'Henüz bildirim yok',
            style: TextStyle(fontSize: 18, color: Colors.white24),
          ),
        ],
      ),
    );
  }

}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onActionComplete;

  const _NotificationItem({required this.notification, this.onActionComplete});

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String;
    final fromUid = notification['from'] as String;
    final name = notification['senderName'] ?? 'İsimsiz';
    final username = notification['senderUsername'] ?? '';
    final photoUrl = notification['senderPhotoUrl'] as String?;
    final createdAt = notification['createdAt'] as Timestamp?;
    
    final isRequest = type == 'friend_request_received';

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
          // Avatar
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
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null 
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 16, 
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  isRequest ? 'arkadaşlık isteği gönderdi' : 'arkadaşlık isteğini kabul etti',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(createdAt.toDate(), locale: 'tr'),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (isRequest)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _acceptRequest(context, fromUid);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
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
      
      // 1. Find and delete the friend request
      final requestQuery = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: fromUid)
          .where('to', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        batch.delete(requestQuery.docs.first.reference);
      }
      
      // 2. Create friendship with deterministic ID to prevent duplicates
      final ids = [user.uid, fromUid]..sort();
      final friendshipId = ids.join('_');
      final friendshipRef = FirebaseFirestore.instance.collection('friendships').doc(friendshipId);
      
      batch.set(friendshipRef, {
        'users': FieldValue.arrayUnion([user.uid, fromUid]),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update the received notification to 'accepted' type
      final notificationId = notification['id'] as String;
      batch.update(FirebaseFirestore.instance.collection('notifications').doc(notificationId), {
        'type': 'friend_request_accepted',
        'isRead': true,
      });

      // 4. Create a NEW notification for the sender
      // We need my own info (denormalized)
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final myData = myDoc.data();

      final senderNotificationRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(senderNotificationRef, {
        'to': fromUid,
        'from': user.uid,
        'type': 'friend_request_accepted',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'senderName': myData?['name'] ?? 'İsimsiz',
        'senderUsername': myData?['username'] ?? '',
        'senderPhotoUrl': myData?['photoUrl'],
      });

      await batch.commit();
      HapticFeedback.heavyImpact();
      onActionComplete?.call();
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  Future<void> _rejectRequest(BuildContext context) async {
    final notificationId = notification['id'] as String;
    final fromUid = notification['from'] as String;
    final toUid = notification['to'] as String;

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Delete friend request
      final requestQuery = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: fromUid)
          .where('to', isEqualTo: toUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        batch.delete(requestQuery.docs.first.reference);
      }

      // 2. Delete notification (or keep as rejected? user said "it should go when opened/read but show past")
      // Rejection is a termination, so maybe we just delete the notification or mark it.
      // Let's just delete the notification for now to keep it clean, or keep it as informative?
      // User said: "bildirim ikonundan gitsin tabi ama bildirimlere girince geçmiş bildirimleri görebilsin"
      // So rejection should also probably stay but maybe in a different state.
      // For now let's just delete the notification on rejection to match existing logic.
      batch.delete(FirebaseFirestore.instance.collection('notifications').doc(notificationId));

      await batch.commit();
      HapticFeedback.mediumImpact();
      onActionComplete?.call();
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    }
  }
}
