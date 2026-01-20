import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String _rankingType = 'totalPoints'; // 'totalPoints' or 'totalDrinks'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header & Podium Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'LİDERLİK TABLOSU',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRankingToggle(),
                  const SizedBox(height: 40),
                  _buildPodiumSection(),
                ],
              ),
            ),
          ),

          // Users List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy(_rankingType, descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(child: _buildShimmerList());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Henüz veri yok')),
                );
              }

              final docs = snapshot.data!.docs;
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              // Filter out top 3 for the list
              final listDocs = docs.length > 3 ? docs.sublist(3) : [];

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = listDocs[index].data() as Map<String, dynamic>;
                        final userId = listDocs[index].id;
                        final isCurrentUser = userId == currentUserId;

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildUserRankItem(
                                rank: index + 4,
                                user: user,
                                isCurrentUser: isCurrentUser,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: listDocs.length,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingToggle() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Puan',
              isSelected: _rankingType == 'totalPoints',
              onTap: () => setState(() => _rankingType = 'totalPoints'),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'İçecek',
              isSelected: _rankingType == 'totalDrinks',
              onTap: () => setState(() => _rankingType = 'totalDrinks'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
            color: isSelected ? AppColors.primary : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy(_rankingType, descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(height: 180);
        }

        final top3 = snapshot.data!.docs;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              if (top3.length > 1)
                _buildPodiumUser(
                  user: top3[1].data() as Map<String, dynamic>,
                  rank: 2,
                  height: 140,
                  avatarSize: 70,
                  color: const Color(0xFFC0C0C0),
                ),
              const SizedBox(width: 15),
              // 1st Place
              if (top3.length > 0)
                _buildPodiumUser(
                  user: top3[0].data() as Map<String, dynamic>,
                  rank: 1,
                  height: 180,
                  avatarSize: 90,
                  color: const Color(0xFFFFD700),
                ),
              const SizedBox(width: 15),
              // 3rd Place
              if (top3.length > 2)
                _buildPodiumUser(
                  user: top3[2].data() as Map<String, dynamic>,
                  rank: 3,
                  height: 120,
                  avatarSize: 60,
                  color: const Color(0xFFCD7F32),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodiumUser({
    required Map<String, dynamic> user,
    required int rank,
    required double height,
    required double avatarSize,
    required Color color,
  }) {
    final score = _rankingType == 'totalPoints' 
        ? (user['totalPoints'] ?? 0.0).toStringAsFixed(1)
        : (user['totalDrinks'] ?? 0).toString();
    final unit = _rankingType == 'totalPoints' ? 'pt' : 'içk';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: avatarSize + 8,
              height: avatarSize + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.5)],
                ),
              ),
            ),
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
              child: user['photoUrl'] == null ? Icon(AppIcons.user, color: Colors.white) : null,
            ),
            Positioned(
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user['name'] ?? 'İsimsiz',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$score $unit',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 80,
          height: height - 100,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRankItem({required int rank, required Map<String, dynamic> user, required bool isCurrentUser}) {
    final score = _rankingType == 'totalPoints' 
        ? (user['totalPoints'] ?? 0.0).toStringAsFixed(1)
        : (user['totalDrinks'] ?? 0).toString();
    final unit = _rankingType == 'totalPoints' ? 'pt' : 'içk';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade100,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
            child: user['photoUrl'] == null ? Icon(AppIcons.user, color: Colors.grey, size: 20) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'İsimsiz',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (isCurrentUser)
                  const Text(
                    'SENSİN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            score,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1.0),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(5, (index) => 
          Shimmer.fromColors(
            baseColor: Colors.grey.shade100,
            highlightColor: Colors.white,
            child: Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
