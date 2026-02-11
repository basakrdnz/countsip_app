import 'dart:ui';
import 'package:flutter/material.dart' hide Badge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/services/badge_service.dart';
import '../../data/models/badge_model.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'consumption', 'variety', 'social', 'location', 'photo', 'streak', 'special'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Rozetlerim',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('badges')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final unlockedBadgeIds = snapshot.data?.docs.map((doc) => doc.id).toSet() ?? {};

          List<Badge> filteredBadges = BadgeService.allBadges.where((badge) {
            if (_selectedCategory == 'All') return true;
            return badge.category.name == _selectedCategory;
          }).toList();

          return Column(
            children: [
              _buildCategorySelector(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredBadges.length,
                  itemBuilder: (context, index) {
                    final badge = filteredBadges[index];
                    final isUnlocked = unlockedBadgeIds.contains(badge.id);
                    return _buildBadgeCard(badge, isUnlocked);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(
                _getCategoryName(cat),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategory = cat);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getCategoryName(String cat) {
    switch (cat) {
      case 'All': return 'Hepsi';
      case 'consumption': return 'Tüketim';
      case 'variety': return 'Çeşitlilik';
      case 'social': return 'Sosyal';
      case 'location': return 'Konum';
      case 'photo': return 'Fotoğraf';
      case 'streak': return 'Seri';
      case 'special': return 'Özel';
      default: return cat;
    }
  }

  Widget _buildBadgeCard(Badge badge, bool isUnlocked) {
    final color = Color(int.parse(badge.colorHex.replaceFirst('#', '0xFF')));
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge, isUnlocked),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? color.withOpacity(0.1) : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? color.withOpacity(0.5) : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
          boxShadow: null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: isUnlocked ? 1.0 : 0.2,
              child: Text(
                badge.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.name,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  value: 0.0, // Progress would need to be calculated/stored
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation(color.withOpacity(0.3)),
                  minHeight: 3,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(Badge badge, bool isUnlocked) {
    final color = Color(int.parse(badge.colorHex.replaceFirst('#', '0xFF')));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isUnlocked ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.3,
                  child: Text(
                    badge.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge.name,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(badge.rarity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _getRarityColor(badge.rarity).withOpacity(0.3)),
              ),
              child: Text(
                badge.rarity.name.toUpperCase(),
                style: TextStyle(color: _getRarityColor(badge.rarity), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            if (isUnlocked)
              Text(
                'Kazanıldı! 🎉',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              )
            else
              Text(
                'Henüz kazanılmadı. Devam et!',
                style: TextStyle(color: Colors.white38),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common: return const Color(0xFF4ECDC4);
      case BadgeRarity.uncommon: return const Color(0xFFB4D4FF);
      case BadgeRarity.rare: return const Color(0xFFFFB4D4);
      case BadgeRarity.epic: return const Color(0xFFFFE66D);
      case BadgeRarity.legendary: return const Color(0xFFFFD700);
    }
  }
}
