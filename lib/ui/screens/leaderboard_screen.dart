import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_decorations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  String _rankingType = 'totalPoints'; // 'totalPoints' or 'totalDrinks'
  String _timeFilter = 'allTime'; // 'weekly', 'monthly', 'allTime'
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
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'Sıralama',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white24,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Arkadaşlar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Toggle Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildRankingToggle(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildTimeFilterToggle(),
          ),
          
          // List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalLeaderboard(),
                _buildFriendsLeaderboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    if (_timeFilter == 'allTime') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy(_rankingType, descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          
          // Filter out frozen users unless it's the current user
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.id;
            final isFrozen = data['isFrozen'] ?? false;
            return !isFrozen || userId == currentUserId;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
            color: AppColors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final user = docs[index].data() as Map<String, dynamic>;
                final userId = docs[index].id;
                final isCurrentUser = userId == currentUserId;
                
                final anonymizedUser = Map<String, dynamic>.from(user);
                if (!isCurrentUser) {
                  final name = user['name'] as String? ?? 'Kullanıcı';
                  anonymizedUser['name'] = '${name[0]}${'*' * (name.length - 1)}';
                  anonymizedUser['photoUrl'] = null;
                }

                return _buildUserRankItem(
                  rank: index + 1,
                  user: anonymizedUser,
                  isCurrentUser: isCurrentUser,
                );
              },
            ),
          );
        },
      );
    } else {
      return _buildTimeBasedLeaderboard(isGlobal: true);
    }
  }

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
          if (!friendshipsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final friendIds = friendshipsSnapshot.data!.docs.map((doc) {
            final users = (doc.data() as Map<String, dynamic>)['users'] as List;
            return users.firstWhere((id) => id != currentUserId) as String;
          }).toList();

          final allInterestedIds = [currentUserId, ...friendIds];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: allInterestedIds.take(10).toList())
                .snapshots(),
            builder: (context, usersSnapshot) {
              if (!usersSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final users = usersSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['uid'] = doc.id;
                return data;
              }).where((u) {
                // Filter out frozen users unless it's the current user
                final isFrozen = u['isFrozen'] ?? false;
                return !isFrozen || u['uid'] == currentUserId;
              }).toList();

              users.sort((a, b) => (b[_rankingType] ?? 0).compareTo(a[_rankingType] ?? 0));

              return RefreshIndicator(
                onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
                color: AppColors.primary,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isCurrentUser = user['uid'] == currentUserId;

                    return _buildUserRankItem(
                      rank: index + 1,
                      user: user,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              );
            },
          );
        },
      );
    } else {
      return _buildTimeBasedLeaderboard(isGlobal: false);
    }
  }

  Widget _buildTimeBasedLeaderboard({required bool isGlobal}) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    DateTime startTime;
    final now = DateTime.now();
    
    if (_timeFilter == 'weekly') {
      startTime = now.subtract(const Duration(days: 7));
    } else {
      startTime = DateTime(now.year, now.month, 1);
    }

    if (isGlobal) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entries')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bu dönemde veri yok', style: TextStyle(color: Colors.white24)));
          }

          // Aggregate client-side
          final Map<String, Map<String, dynamic>> userTotals = {};
          
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId'] as String;
            
            if (!userTotals.containsKey(userId)) {
              userTotals[userId] = {
                'uid': userId,
                'totalPoints': 0.0,
                'totalDrinks': 0,
              };
            }
            
            userTotals[userId]!['totalPoints'] += (data['points'] ?? 0.0).toDouble();
            userTotals[userId]!['totalDrinks'] += 1;
          }

          // Sort
          var sortedUsers = userTotals.values.toList();
          sortedUsers.sort((a, b) => (b[_rankingType] ?? 0).compareTo(a[_rankingType] ?? 0));

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
            color: AppColors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: sortedUsers.length > 20 ? 20 : sortedUsers.length,
              itemBuilder: (context, index) {
                final userData = sortedUsers[index];
                final userId = userData['uid'];
                final isCurrentUser = userId == currentUserId;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                  builder: (context, userSnap) {
                    final profile = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                    final displayUser = {
                      ...profile,
                      ...userData,
                    };
                    
                    // Filter out frozen users unless it's the current user
                    final isFrozen = profile['isFrozen'] ?? false;
                    if (isFrozen && !isCurrentUser) return const SizedBox();

                    if (isGlobal && !isCurrentUser) {
                       final name = profile['name'] as String? ?? 'Kullanıcı';
                       displayUser['name'] = '${name[0]}${'*' * (name.length - 1)}';
                       displayUser['photoUrl'] = null;
                    }

                    return _buildUserRankItem(
                      rank: index + 1,
                      user: displayUser,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              },
            ),
          );
        },
      );
    } else {
      // Friends logic for time-based
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friendships')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, friendshipsSnapshot) {
          if (!friendshipsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final friendIds = friendshipsSnapshot.data!.docs.map((doc) {
            final users = (doc.data() as Map<String, dynamic>)['users'] as List;
            return users.firstWhere((id) => id != currentUserId) as String;
          }).toList();

          final allInterestedIds = [currentUserId, ...friendIds];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('entries')
                .where('userId', whereIn: allInterestedIds.take(10).toList())
                .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
                .snapshots(),
            builder: (context, entriesSnapshot) {
              if (entriesSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final Map<String, Map<String, dynamic>> userTotals = {};
              if (entriesSnapshot.hasData) {
                for (var doc in entriesSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data['userId'] as String;
                  
                  if (!userTotals.containsKey(userId)) {
                    userTotals[userId] = {
                      'uid': userId,
                      'totalPoints': 0.0,
                      'totalDrinks': 0,
                    };
                  }
                  
                  userTotals[userId]!['totalPoints'] += (data['points'] ?? 0.0).toDouble();
                  userTotals[userId]!['totalDrinks'] += 1;
                }
              }

              var sortedUsers = userTotals.values.toList();
              sortedUsers.sort((a, b) => (b[_rankingType] ?? 0).compareTo(a[_rankingType] ?? 0));

              return RefreshIndicator(
                onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
                color: AppColors.primary,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedUsers.length,
                  itemBuilder: (context, index) {
                    final userData = sortedUsers[index];
                    final userId = userData['uid'];
                    final isCurrentUser = userId == currentUserId;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnap) {
                        final profile = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                        final displayUser = {
                          ...profile,
                          ...userData,
                        };
                        
                        // Filter out frozen users unless it's the current user
                        final isFrozen = profile['isFrozen'] ?? false;
                        if (isFrozen && !isCurrentUser) return const SizedBox();

                        return _buildUserRankItem(
                          rank: index + 1,
                          user: displayUser,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      );
    }
}

  Widget _buildTimeFilterToggle() {
    final List<String> options = ['weekly', 'monthly', 'allTime'];
    final labels = ['Haftalık', 'Aylık', 'Hepsi'];
    final selectedIndex = options.indexOf(_timeFilter);
    final count = options.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double indicatorWidth = (width - 8) / count;

        return Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Stack(
            children: [
              // Animated Background Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                left: selectedIndex * indicatorWidth,
                width: indicatorWidth,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                ),
              ),
              // Buttons
              Row(
                children: List.generate(count, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _timeFilter = options[index]);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textTertiary,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          child: Text(labels[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankingToggle() {
    final isPoints = _rankingType == 'totalPoints';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double indicatorWidth = (width - 8) / 2;

        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Stack(
            children: [
              // Sliding Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                left: isPoints ? 0 : indicatorWidth,
                width: indicatorWidth,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Puan',
                      isSelected: isPoints,
                      onTap: () {
                        if (!isPoints) {
                           HapticFeedback.selectionClick();
                           setState(() => _rankingType = 'totalPoints');
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      label: 'İçecek',
                      isSelected: !isPoints,
                      onTap: () {
                        if (isPoints) {
                           HapticFeedback.selectionClick();
                           setState(() => _rankingType = 'totalDrinks');
                        }
                      },
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

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: AppTextStyles.buttonText.copyWith(
            color: isSelected ? Colors.white : AppColors.textTertiary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildUserRankItem({
    required int rank,
    required Map<String, dynamic> user,
    required bool isCurrentUser,
  }) {
    final score = _rankingType == 'totalPoints'
        ? (user['totalPoints'] ?? 0.0).toStringAsFixed(1)
        : (user['totalDrinks'] ?? 0).toString();
    final unit = _rankingType == 'totalPoints' ? 'puan' : 'içecek';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? AppColors.primary.withOpacity(0.1) 
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser 
              ? AppColors.primary.withOpacity(0.3) 
              : Colors.white.withOpacity(0.05),
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          _buildRankBadge(rank),
          const SizedBox(width: 12),
          
          // Avatar with glow for top 3
          _buildAvatar(user, rank),
          const SizedBox(width: 12),
          
          // Name
          Expanded(
            child: Text(
              user['name'] ?? 'İsimsiz',
              style: AppTextStyles.h3.copyWith(
                color: isCurrentUser ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Score with gradient for top 3
          _buildScore(score, unit, rank),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      return Container(
        width: 32,
        height: 32,
        decoration: AppDecorations.rankBadge(rank),
        child: Center(
          child: rank == 1
              ? const Text('🏆', style: TextStyle(fontSize: 16))
              : Text(
                  '$rank',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    }
    
    return SizedBox(
      width: 32,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user, int rank) {
    final avatarWidget = CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage: user['photoUrl'] != null
          ? NetworkImage(user['photoUrl'])
          : null,
      child: user['photoUrl'] == null
          ? Icon(AppIcons.user, color: AppColors.textTertiary, size: 18)
          : null,
    );

    // Add glow effect for top 3
    if (rank <= 3) {
      Color glowColor;
      switch (rank) {
        case 1:
          glowColor = const Color(0xFFFFD700);
          break;
        case 2:
          glowColor = const Color(0xFFC0C0C0);
          break;
        default:
          glowColor = const Color(0xFFCD7F32);
      }
      
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: avatarWidget,
      );
    }
    
    return avatarWidget;
  }

  Widget _buildScore(String score, String unit, int rank) {
    // Gradient text for top 3
    if (rank <= 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: rank == 1
                  ? AppColors.rank1Gradient
                  : rank == 2
                      ? AppColors.rank2Gradient
                      : AppColors.rank3Gradient,
            ).createShader(bounds),
            child: Text(
              score,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            unit,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          score,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          unit,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
