import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';

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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            child: SingleChildScrollView(
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
                    
                    // Logout Button (prominent)
                    _buildMenuItem(
                      icon: AppIcons.exit,
                      title: 'Çıkış Yap',
                      iconColor: AppColors.primary,
                      titleColor: AppColors.primary,
                      showArrow: false,
                      showIconBg: false,
                      onTap: () => _signOut(context),
                    ),
                    
                    const SizedBox(height: 100), // Bottom padding for nav bar
                  ],
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
            // Icon with rounded pink bg (very subtle, like profile photo glow)
            if (showIconBg)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: iconColor ?? AppColors.primary.withOpacity(0.6), 
                  size: 18,
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
                color: AppColors.primary.withOpacity(0.3), 
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
}
