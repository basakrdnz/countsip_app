import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {


  @override
  void initState() {
    super.initState();
  }


  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: AppColors.background.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Çıkış Yap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'VAZGEÇ',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'ÇIKIŞ YAP',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          context.go('/onboarding');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data?.data();
        final name = userData?['name'] as String? ?? 'Misafir';
        final username = userData?['username'] as String?;
        final photoUrl = userData?['photoUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Profile Picture with Glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevated,
                          image: photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: photoUrl == null
                            ? Icon(AppIcons.user, size: 50, color: AppColors.textTertiary)
                            : null,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Name
                    Text(
                      name,
                      style: AppTextStyles.title1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    // Username - tap to copy
                    if (username != null)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '@$username'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(AppIcons.checkCircle, color: AppColors.buttonOnPrimary, size: 18),
                                  const SizedBox(width: 8),
                                  Text('@$username kopyalandı'),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '@$username',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                                Icon(
                                  AppIcons.copy,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Stats Strip - Slim horizontal bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Total Drinks
                          _buildStatItem(
                            label: 'İÇECEK',
                            value: '${(userData?['totalDrinks'] as num?)?.toInt() ?? 0}',
                          ),
                          // Divider
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          // Total Points
                          _buildStatItem(
                            label: 'PUAN',
                            value: '${(userData?['totalPoints'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
                          ),
                          // Divider
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          // Level (PRD 5.1)
                          _buildStatItem(
                            label: 'SEVİYE',
                            value: '${ThemeService.calculateLevel((userData?['totalPoints'] as num?)?.toDouble() ?? 0.0)}',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Main Menu Items
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: AppDecorations.glassCard(),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: AppIcons.user,
                                title: 'Profil Bilgileri',
                                onTap: () => context.push('/profile-details'),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.emoji_events_outlined,
                                title: 'Rozetlerim',
                                onTap: () => context.push('/badges'),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.military_tech_outlined,
                                title: 'Rütbe & Çerçeve',
                                onTap: () => _showFrameSelectionSheet(context, userData),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: AppIcons.settingsSliders,
                                title: 'Ayarlar',
                                onTap: () => context.push('/settings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Social Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: AppDecorations.glassCard(),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: AppIcons.addUser,
                                title: 'Arkadaş Ekle',
                                onTap: () => context.push('/add-friend'),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: AppIcons.users,
                                title: 'Arkadaşlarım',
                                onTap: () => context.push('/friends'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Help Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: AppDecorations.glassCard(),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: AppIcons.helpIcon,
                                title: 'Yardım',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: AppIcons.info,
                                title: 'Hakkında',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Logout Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: AppDecorations.glassCard(),
                          child: _buildMenuItem(
                            icon: AppIcons.exit,
                            title: 'Çıkış Yap',
                            iconColor: AppColors.error,
                            titleColor: AppColors.error,
                            showArrow: false,
                            showIconBg: true,
                            onTap: () => _signOut(context),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Bottom padding for nav bar
                  ],
                ),
              ),
            ),
          ),
        );
        },
      );
    }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool showArrow = true,
    bool showIconBg = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with rounded pink bg
            if (showIconBg)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon, 
                  color: iconColor ?? AppColors.primary, 
                  size: 20,
                ),
              )
            else
              Icon(
                icon, 
                color: iconColor ?? AppColors.primary, 
                size: 20,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? AppColors.textTertiary,
                ),
              ),
            ),
            if (showArrow)
              Icon(
                AppIcons.angleRight, 
                color: AppColors.textTertiary.withOpacity(0.5), 
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 54,
      endIndent: 16,
      color: Colors.white.withOpacity(0.04),
    );
  }
  
  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
  void _showFrameSelectionSheet(BuildContext context, Map<String, dynamic>? userData) {
    final totalPoints = (userData?['totalPoints'] as num?)?.toDouble() ?? 0.0;
    final userLevel = ThemeService.calculateLevel(totalPoints);
    final userFrame = userData?['profileFrame'] ?? 'none';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.glassCard().copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('RÜTBE VE ÇERÇEVE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
            const SizedBox(height: 24),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: ProfileFrameRank.values.map((rank) {
                  final requiredLevel = ThemeService.getRequiredLevel(rank);
                  final isUnlocked = userLevel >= requiredLevel;
                  final isSelected = userFrame == rank.name;

                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: rank.frameColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (rank != ProfileFrameRank.none)
                            BoxShadow(color: rank.frameColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                    ),
                    title: Text(
                      rank.displayName,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: isUnlocked 
                      ? Text(isSelected ? 'Seçili' : 'Açık', style: TextStyle(color: isSelected ? AppColors.primary : Colors.white24, fontSize: 12)) 
                      : Text('Seviye $requiredLevel gerekir', style: const TextStyle(color: Colors.white24, fontSize: 12)),
                    trailing: isUnlocked 
                      ? (isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null)
                      : const Icon(Icons.lock, size: 16, color: Colors.white10),
                    onTap: () async {
                      if (isUnlocked) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .update({'profileFrame': rank.name});
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
