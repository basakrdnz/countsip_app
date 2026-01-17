import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _userData = doc.data();
            _photoUrl = _userData?['photoUrl'] ?? user.photoURL;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
          context.go('/welcome');
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
    final name = _userData?['name'] ?? 'Kullanıcı';
    final username = _userData?['username'] as String?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgwglass.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.85),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Profile Picture
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            image: _photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _photoUrl == null
                              ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                              : null,
                        ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Name
                        Text(
                          name,
                          style: AppTextStyles.title1.copyWith(
                            fontWeight: FontWeight.bold,
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
                                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
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
                                    Icons.copy,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Main Menu Items
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.person_outline,
                                title: 'Profil Bilgileri',
                                onTap: () => context.push('/profile-details').then((_) => _loadUserData()),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.settings_outlined,
                                title: 'Ayarlar',
                                onTap: () => context.push('/settings').then((_) => _loadUserData()),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Social Section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.person_add_outlined,
                                title: 'Arkadaş Ekle',
                                onTap: () => context.push('/add-friend'),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.group_outlined,
                                title: 'Arkadaşlarım',
                                onTap: () => context.push('/friends'),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Help Section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.help_outline,
                                title: 'Yardım',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.info_outline,
                                title: 'Hakkında',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Logout Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildMenuItem(
                            icon: Icons.logout,
                            title: 'Çıkış Yap',
                            iconColor: AppColors.error,
                            titleColor: AppColors.error,
                            showArrow: false,
                            onTap: () => _signOut(context),
                          ),
                        ),
                        
                        const SizedBox(height: 100), // Bottom padding for nav bar
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (showArrow)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 20,
      color: Colors.grey.shade200,
    );
  }
}
