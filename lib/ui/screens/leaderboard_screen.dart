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

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _rankingType = 'totalPoints'; // 'totalPoints' or 'totalDrinks'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'Liderlik Tablosu',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
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
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz veri yok',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
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
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Puan',
              isSelected: _rankingType == 'totalPoints',
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _rankingType = 'totalPoints');
              },
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'İçecek',
              isSelected: _rankingType == 'totalDrinks',
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _rankingType = 'totalDrinks');
              },
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            color: isSelected ? Colors.white : AppColors.textTertiary,
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
