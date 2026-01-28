import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _rankingType = 'totalPoints'; // 'totalPoints' or 'totalDrinks'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.innerBackground,
      appBar: AppBar(
        title: const Text(
          'Liderlik Tablosu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B3126),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
            children: [
              // Toggle Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildRankingToggle(),
              ),
              
              // List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy(_rankingType, descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Henüz veri yok'));
                    }

                    final docs = snapshot.data!.docs;
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final user = docs[index].data() as Map<String, dynamic>;
                        final userId = docs[index].id;
                        final isCurrentUser = userId == currentUserId;

                        return _buildUserRankItem(
                          rank: index + 1,
                          user: user,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildRankingToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF4B3126),
          ),
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

    // Medal colors for top 3
    Color? medalColor;
    IconData? medalIcon;
    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalIcon = AppIcons.trophyIcon;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = AppIcons.trophyIcon;
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = AppIcons.trophyIcon;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.15)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withOpacity(0.25)
              : AppColors.primary.withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: rank <= 3 && medalIcon != null
                ? Icon(medalIcon, color: medalColor, size: 20)
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: user['photoUrl'] != null
                ? NetworkImage(user['photoUrl'])
                : null,
            child: user['photoUrl'] == null
                ? Icon(AppIcons.user, color: Colors.grey, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          
          // Name
          Expanded(
            child: Text(
              user['name'] ?? 'İsimsiz',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: const Color(0xFF4B3126),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Score
          Text(
            '$score ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
