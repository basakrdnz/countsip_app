import 'dart:ui';
import 'package:flutter/material.dart'; // Hot reload trigger v2
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
import '../../core/services/drink_data_service.dart';
import '../widgets/empty_state_widget.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _feedItems = [];
  final Map<String, DateTime> _friendshipTimes = {}; // friendId -> createdAt
  
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;
  static const int _maxItems = 50;
  String _currentFilter = 'all'; // 'all' or 'me'

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && _feedItems.length < _maxItems) {
        _loadMore();
      }
    }
  }

  Future<void> _initialLoad() async {
    if (mounted) setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch friendships to get timestamps and relevant IDs
      final friendships = await FirebaseFirestore.instance
          .collection('friendships')
          .where('users', arrayContains: user.uid)
          .get();

      _friendshipTimes.clear();
      final List<String> relevantUserIds = [user.uid]; // Always include self

      for (var doc in friendships.docs) {
        final data = doc.data();
        final users = data['users'] as List;
        final friendId = users.firstWhere((id) => id != user.uid) as String;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        
        _friendshipTimes[friendId] = createdAt;
        relevantUserIds.add(friendId);
      }

      // 2. Load first batch of entries
      _feedItems.clear();
      _lastDocument = null;
      _hasMore = true;
      
      await _fetchBatch(relevantUserIds);
    } catch (e) {
      debugPrint('Error in initial load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || _feedItems.length >= _maxItems) return;

    if (mounted) setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final relevantUserIds = [user.uid, ..._friendshipTimes.keys];
      await _fetchBatch(relevantUserIds);
    } catch (e) {
      debugPrint('Error loading more: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBatch(List<String> userIds) async {
    if (userIds.isEmpty) {
      if (mounted) setState(() => _hasMore = false);
      return;
    }

    final queryIds = userIds.take(10).toList();
    bool foundItems = false;

    while (_hasMore && _feedItems.length < _maxItems && !foundItems) {
      var query = FirebaseFirestore.instance
          .collection('entries')
          .where('userId', whereIn: queryIds)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() => _hasMore = false);
        break;
      }

      _lastDocument = snapshot.docs.last;

      final List<Map<String, dynamic>> batch = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

        // IMPORTANT: Post-Friendship Filter
        bool shouldInclude = true;
        if (userId != FirebaseAuth.instance.currentUser?.uid) {
          final friendshipTime = _friendshipTimes[userId];
          if (friendshipTime != null && timestamp.isBefore(friendshipTime)) {
            shouldInclude = false;
          }
        }

        if (shouldInclude) {
          data['id'] = doc.id;
          data['_type'] = 'activity';
          batch.add(data);
        }
      }

      if (mounted) {
        setState(() {
          if (batch.isNotEmpty) {
            _feedItems.addAll(batch);
            foundItems = true;
          }
          
          if (snapshot.docs.length < _pageSize || _feedItems.length >= _maxItems) {
            _hasMore = false;
          }
        });
      }

      // If we didn't find any items in this batch but there are more documents,
      // the loop will continue to fetch the next batch.
      if (!foundItems && !_hasMore) break;
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));

    // Filter items locally for immediate response
    final displayItems = _currentFilter == 'me' 
        ? _feedItems.where((item) => item['userId'] == user.uid).toList()
        : _feedItems;

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
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, color: AppColors.textPrimary.withOpacity(0.7)),
            color: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              setState(() {
                _currentFilter = value;
              });
              HapticFeedback.selectionClick();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.public, color: _currentFilter == 'all' ? AppColors.primary : AppColors.textPrimary.withOpacity(0.5), size: 20),
                    const SizedBox(width: 12),
                    Text('Tümü', style: TextStyle(color: _currentFilter == 'all' ? AppColors.primary : AppColors.textPrimary, fontWeight: _currentFilter == 'all' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'me',
                child: Row(
                  children: [
                    Icon(Icons.person, color: _currentFilter == 'me' ? AppColors.primary : AppColors.textPrimary.withOpacity(0.5), size: 20),
                    const SizedBox(width: 12),
                    Text('Sadece Ben', style: TextStyle(color: _currentFilter == 'me' ? AppColors.primary : AppColors.textPrimary, fontWeight: _currentFilter == 'me' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _feedItems.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _initialLoad,
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: displayItems.length + (_hasMore && _isLoading && _feedItems.length < _maxItems ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayItems.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }

                      final item = displayItems[index];
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
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.local_drink_rounded,
      message: 'Henüz akışta bir şey yok',
      subtitle: 'Arkadaşlarının paylaşımlarını burada görebilirsin',
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
  late List<String> _localCheers;

  @override
  void initState() {
    super.initState();
    // Your own posts start collapsed ('şerit gibi')
    if (widget.item['userId'] == widget.currentUserId) {
      _isExpanded = false;
    }
    _localCheers = List<String>.from(widget.item['cheers'] ?? []);
  }

  void _toggleLocalCheers() {
    setState(() {
      if (_localCheers.contains(widget.currentUserId)) {
        _localCheers.remove(widget.currentUserId);
      } else {
        _localCheers.add(widget.currentUserId);
      }
    });

    HapticFeedback.lightImpact();
    // Optimistically update — pass current like state before local toggle
    final wasLiked = !_localCheers.contains(widget.currentUserId);
    FeedService.toggleCheers(
      widget.item['id'],
      widget.currentUserId,
      currentlyLiked: wasLiked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final currentUserId = widget.currentUserId;
    final timestamp = item['timestamp'] as Timestamp?;
    final timeStr = timestamp != null ? timeago.format(timestamp.toDate(), locale: 'tr') : '';
    final hasCheered = _localCheers.contains(currentUserId);
    final drinkType = item['drinkType'] ?? 'İçecek';
    final isOwnPost = item['userId'] == currentUserId;
    final portion = item['portion'] ?? '';
    
    final String categoryId = item['categoryId'] ?? 'cocktail';
    final drinkData = DrinkDataService.instance.resolveFromId(categoryId);

    return GestureDetector(
      onTap: () {
        if (isOwnPost) {
          setState(() => _isExpanded = !_isExpanded);
          HapticFeedback.selectionClick();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              constraints: BoxConstraints(
                minHeight: (isOwnPost && !_isExpanded) ? 60 : 0, // Thinner when collapsed
              ),
              decoration: AppDecorations.outlinedGlassCard(
                borderRadius: 24,
                backgroundColor: (isOwnPost && !_isExpanded) 
                    ? Colors.transparent // Faded background
                    : null,
                borderColor: (isOwnPost && !_isExpanded)
                    ? Colors.white.withOpacity(0.08) // Very subtle border
                    : null,
              ),
              child: Opacity(
                opacity: (isOwnPost && !_isExpanded) ? 0.6 : 1.0, // Silik görünüm
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
                      _buildUserAvatar(item['userId'], size: (isOwnPost && !_isExpanded) ? 32 : 40, isSubdued: isOwnPost && !_isExpanded),
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
                          child: Icon(drinkData.icon, size: (isOwnPost && !_isExpanded) ? 10 : 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeedHeader(item['userId'], drinkType, portion, timestamp?.toDate(), isOwnPost && !_isExpanded),
                        SizedBox(height: (isOwnPost && !_isExpanded) ? 4 : 8),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: AppColors.textPrimary.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(timeStr, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.45), fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Portion or Cheers Chip
                  if (isOwnPost && !_isExpanded)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.glassCheers, color: AppColors.primary, size: 12),
                          if (_localCheers.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${_localCheers.length}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else if (portion.isNotEmpty)
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['locationName'] != null && item['locationName'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(item['locationName'], style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        if (item['note'] != null && item['note'].isNotEmpty)
                          Text(
                            item['note'], 
                            style: TextStyle(color: AppColors.textPrimary.withOpacity(0.8), fontSize: 14, height: 1.5),
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
                          onTap: _toggleLocalCheers,
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
                                if (_localCheers.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text('${_localCheers.length}', style: TextStyle(color: hasCheered ? Colors.white : AppColors.textPrimary.withOpacity(0.4), fontWeight: FontWeight.w900, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_localCheers.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showCheersList(context, _localCheers),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  _buildAvatarStack(_localCheers),
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
              duration: const Duration(milliseconds: 500),
              sizeCurve: Curves.easeOutQuart,
              firstCurve: Curves.easeOutQuart,
              secondCurve: Curves.easeOutQuart,
            ), // Close AnimatedCrossFade
          ], // Close children list
        ), // Close Column
              ), // Close Opacity
      ), // Close AnimatedContainer
    ), // Close BackdropFilter
  ), // Close ClipRRect
        ), // outer Container
      ); // GestureDetector
    }

  Widget _buildUserAvatar(String userId, {double size = 40, bool isSubdued = false}) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final photoUrl = data?['photoUrl'];
        return Opacity(
          opacity: isSubdued ? 0.6 : 1.0,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
            child: photoUrl != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(size / 2), child: CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover))
              : Icon(Icons.person, color: Colors.white24, size: size * 0.6),
          ),
        );
      },
    );
  }

  Widget _buildFeedHeader(String userId, String drinkType, String portion, DateTime? timestamp, [bool isSubdued = false]) {
    if (timestamp == null) return Container();
    
    final startOfDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final nextDay = startOfDay.add(const Duration(days: 1));

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('entries')
          .where('userId', isEqualTo: userId)
          .where('drinkType', isEqualTo: drinkType)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: nextDay)
          .orderBy('timestamp', descending: false)
          .get(),
      builder: (context, drinkSnapshot) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final fullName = userData?['name'] ?? '...';
            final name = fullName.split(' ').first;
            
            // Calculate which drink this was in sequence
            int sequence = 0;
            if (drinkSnapshot.hasData) {
              final docs = drinkSnapshot.data!.docs;
              for (int i = 0; i < docs.length; i++) {
                if (docs[i].id == widget.item['id']) {
                  sequence = i + 1;
                  break;
                }
              }
            }

            // Simplified natural language logic
            String action = 'bir';
            if (portion.toLowerCase().contains('kadeh')) action = 'bir kadeh';
            if (portion.toLowerCase().contains('shot')) action = 'bir shot';
            if (portion.toLowerCase().contains('duble')) action = 'bir duble';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isSubdued ? 14 : 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (sequence > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BUGÜN $sequence.',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: isSubdued ? 2 : 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isSubdued ? 12 : 13,
                      color: AppColors.textPrimary.withOpacity(0.7),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: action,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: drinkType,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const TextSpan(text: ' içti'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserName(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = (data?['name'] ?? 'Yükleniyor...').split(' ').first;
        return Text(
          name,
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
              Text('ŞEREFE!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0, fontSize: 16)),
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
                        final name = (userData?['name'] ?? '...').split(' ').first;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          leading: _buildUserAvatar(userId, size: 36),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
