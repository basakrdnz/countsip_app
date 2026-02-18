import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_decorations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  String _rankingType = 'totalPoints';
  String _timeFilter = 'allTime'; // Default allTime restored
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Sıralama',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110), // Back to 110
              child: _buildHeaderControls(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGlobalLeaderboard(),
            _buildFriendsLeaderboard(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER: Scope Tabs + Filter Row
  // ─────────────────────────────────────────────
  Widget _buildHeaderControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Scope toggle (Global / Arkadaşlar) ──
          _buildScopeToggle(),
          const SizedBox(height: 10),
          // ── Filter row: Ranking type + Time ──
          _buildFiltersRow(),
        ],
      ),
    );
  }

  Widget _buildScopeToggle() {
    final isGlobal = _tabController.index == 0;
    return LayoutBuilder(builder: (context, constraints) {
      final iw = (constraints.maxWidth - 8) / 2;
      return Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutQuart,
            left: isGlobal ? 0 : iw,
            width: iw,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Row(children: [
            _scopeBtn('Global', isGlobal, () => _tabController.animateTo(0)),
            _scopeBtn('Arkadaşlar', !isGlobal, () => _tabController.animateTo(1)),
          ]),
        ]),
      );
    });
  }

  Widget _scopeBtn(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textTertiary,
              letterSpacing: -0.2,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    // Left: Ranking chips  |  Right: Time chips
    final timeOpts = [('Haftalık', 'weekly'), ('Aylık', 'monthly'), ('Hepsi', 'allTime')];

    return Row(
      children: [
        // Ranking toggle (Puan / İçecek) — compact pill group
        _buildChipGroup(
          items: [('🏆  Puan', 'totalPoints'), ('🍺  İçecek', 'totalDrinks')],
          selected: _rankingType,
          onSelect: (v) => setState(() => _rankingType = v),
        ),
        const Spacer(),
        // Time filter
        _buildChipGroup(
          items: timeOpts,
          selected: _timeFilter,
          onSelect: (v) => setState(() => _timeFilter = v),
        ),
      ],
    );
  }

  Widget _buildChipGroup({
    required List<(String, String)> items,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final (label, value) = item;
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onSelect(value); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isSelected ? AppColors.primary.withOpacity(0.4) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textTertiary,
                    letterSpacing: -0.2,
                  ),
                  child: Text(label),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GLOBAL LEADERBOARD
  // ─────────────────────────────────────────────
  Widget _buildGlobalLeaderboard() {
    if (_timeFilter == 'allTime') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy(_rankingType, descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isFrozen = data['isFrozen'] ?? false;
            return !isFrozen || doc.id == currentUserId;
          }).toList();

          return _buildList(docs.length, (index) {
            final user = docs[index].data() as Map<String, dynamic>;
            final isCurrentUser = docs[index].id == currentUserId;
            final anon = Map<String, dynamic>.from(user);
            if (!isCurrentUser) {
              final name = user['name'] as String? ?? 'Kullanıcı';
              anon['name'] = '${name[0]}${'*' * (name.length - 1)}';
              anon['photoUrl'] = null;
            }
            return _buildUserRankItem(rank: index + 1, user: anon, isCurrentUser: isCurrentUser);
          });
        },
      );
    } else {
      return _buildTimeBasedLeaderboard(isGlobal: true);
    }
  }

  // ─────────────────────────────────────────────
  // FRIENDS LEADERBOARD
  // ─────────────────────────────────────────────
  Widget _buildFriendsLeaderboard() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox();

    if (_timeFilter == 'allTime') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friendships')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, friendshipsSnapshot) {
          if (!friendshipsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final friendIds = friendshipsSnapshot.data!.docs.map((doc) {
            final users = (doc.data() as Map<String, dynamic>)['users'] as List;
            return users.firstWhere((id) => id != currentUserId) as String;
          }).toList();

          final allIds = [currentUserId, ...friendIds];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: allIds.take(10).toList())
                .snapshots(),
            builder: (context, usersSnapshot) {
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final users = usersSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['uid'] = doc.id;
                return data;
              }).where((u) {
                final isFrozen = u['isFrozen'] ?? false;
                return !isFrozen || u['uid'] == currentUserId;
              }).toList();
              users.sort((a, b) => (b[_rankingType] ?? 0).compareTo(a[_rankingType] ?? 0));

              return _buildList(users.length, (index) {
                final user = users[index];
                return _buildUserRankItem(
                  rank: index + 1,
                  user: user,
                  isCurrentUser: user['uid'] == currentUserId,
                );
              });
            },
          );
        },
      );
    } else {
      return _buildTimeBasedLeaderboard(isGlobal: false);
    }
  }

  // ─────────────────────────────────────────────
  // TIME-BASED LEADERBOARD
  // ─────────────────────────────────────────────
  Widget _buildTimeBasedLeaderboard({required bool isGlobal}) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    final startTime = _timeFilter == 'weekly'
        ? now.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month, 1);

    if (isGlobal) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entries')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty('Bu dönemde kayıt yok');
          }
          final Map<String, Map<String, dynamic>> totals = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId'] as String;
            totals.putIfAbsent(userId, () => {'uid': userId, 'totalPoints': 0.0, 'totalDrinks': 0});
            totals[userId]!['totalPoints'] += (data['points'] ?? 0.0).toDouble();
            totals[userId]!['totalDrinks'] += 1;
          }
          final sorted = totals.values.toList()
            ..sort((a, b) => (b[_rankingType] ?? 0).compareTo(a[_rankingType] ?? 0));
          final limited = sorted.take(20).toList();

          return _buildList(limited.length, (index) {
            final userData = limited[index];
            final userId = userData['uid'];
            final isCurrentUser = userId == currentUserId;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnap) {
                final profile = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                final isFrozen = profile['isFrozen'] ?? false;
                if (isFrozen && !isCurrentUser) return const SizedBox();
                final displayUser = {...profile, ...userData};
                if (!isCurrentUser) {
                  final name = profile['name'] as String? ?? 'Kullanıcı';
                  displayUser['name'] = '${name[0]}${'*' * (name.length - 1)}';
                  displayUser['photoUrl'] = null;
                }
                return _buildUserRankItem(rank: index + 1, user: displayUser, isCurrentUser: isCurrentUser);
              },
            );
          });
        },
      );
    } else {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friendships')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, friendshipsSnapshot) {
          if (!friendshipsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final friendIds = friendshipsSnapshot.data!.docs.map((doc) {
            final users = (doc.data() as Map<String, dynamic>)['users'] as List;
            return users.firstWhere((id) => id != currentUserId) as String;
          }).toList();

          final allIds = [currentUserId!, ...friendIds];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('entries')
                .where('userId', whereIn: allIds.take(10).toList())
                .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
                .snapshots(),
            builder: (context, entriesSnapshot) {
              if (entriesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final Map<String, Map<String, dynamic>> totals = {};
              if (entriesSnapshot.hasData) {
                for (var doc in entriesSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data['userId'] as String;
                  totals.putIfAbsent(userId, () => {'uid': userId, 'totalPoints': 0.0, 'totalDrinks': 0});
                  totals[userId]!['totalPoints'] += (data['points'] ?? 0.0).toDouble();
                  totals[userId]!['totalDrinks'] += 1;
                }
              }
              final sorted = totals.values.toList()
                ..sort((a, b) => (b[_rankingType] ?? 0).compareTo(a[_rankingType] ?? 0));

              return _buildList(sorted.length, (index) {
                final userData = sorted[index];
                final userId = userData['uid'];
                final isCurrentUser = userId == currentUserId;
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                  builder: (context, userSnap) {
                    final profile = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                    final isFrozen = profile['isFrozen'] ?? false;
                    if (isFrozen && !isCurrentUser) return const SizedBox();
                    return _buildUserRankItem(
                      rank: index + 1,
                      user: {...profile, ...userData},
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              });
            },
          );
        },
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _buildList(int count, Widget Function(int) builder) {
    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: count,
        itemBuilder: (context, index) => builder(index),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: AppColors.textTertiary.withOpacity(0.5))),
    );
  }

  // ─────────────────────────────────────────────
  // RANK ITEM CARD
  // ─────────────────────────────────────────────
  Widget _buildUserRankItem({
    required int rank,
    required Map<String, dynamic> user,
    required bool isCurrentUser,
  }) {
    final isTop3 = rank <= 3;
    final score = _rankingType == 'totalPoints'
        ? '${(user['totalPoints'] ?? 0.0).toStringAsFixed(1)}'
        : '${user['totalDrinks'] ?? 0}';
    final unit = _rankingType == 'totalPoints' ? 'puan' : 'içecek';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.08)
            : isTop3
                ? AppColors.surface.withOpacity(0.8)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withOpacity(0.35)
              : isTop3
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.04),
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: _topColor(rank).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank number / badge
          SizedBox(width: 36, child: _buildRankBadge(rank)),
          const SizedBox(width: 10),
          // Avatar
          _buildAvatar(user, rank),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              user['name'] ?? 'İsimsiz',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCurrentUser ? AppColors.primary : AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score
          _buildScore(score, unit, rank, isCurrentUser),
        ],
      ),
    );
  }

  Color _topColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }

  Widget _buildRankBadge(int rank) {
    if (rank > 3) {
      return Center(
        child: Text(
          '$rank',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary.withOpacity(0.6),
          ),
        ),
      );
    }
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: AppDecorations.rankBadge(rank),
        child: Center(
          child: rank == 1
              ? const Text('🏆', style: TextStyle(fontSize: 15))
              : Text(
                  '$rank',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user, int rank) {
    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
      child: user['photoUrl'] == null
          ? Icon(AppIcons.user, color: AppColors.textTertiary, size: 18)
          : null,
    );

    if (rank > 3) return avatar;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _topColor(rank).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: avatar,
    );
  }

  Widget _buildScore(String score, String unit, int rank, bool isCurrentUser) {
    final color = isCurrentUser
        ? AppColors.primary
        : rank <= 3
            ? _topColor(rank)
            : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          unit,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.textTertiary.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
