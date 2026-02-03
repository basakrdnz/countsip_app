import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isFrozen = false;
  DateTime? _deletionScheduledAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountStatus();
  }

  Future<void> _loadAccountStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _isFrozen = doc.data()?['isFrozen'] ?? false;
          final deletionTs = doc.data()?['deletionScheduledAt'];
          if (deletionTs != null) {
            _deletionScheduledAt = (deletionTs as Timestamp).toDate();
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFreeze(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'isFrozen': value});

    setState(() => _isFrozen = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '👻 Hayalet Mod aktif' : '👋 Tekrar görünür oldun'),
        backgroundColor: value ? Colors.purple : Colors.green,
      ),
    );
  }

  Future<void> _scheduleDelete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final emailController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(AppIcons.exclamation, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Hesabı Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem geri alınamaz!\n\n'
              'Hesabın 7 gün sonra kalıcı olarak silinecek. '
              'Bu süre içinde giriş yaparsan silme işlemi iptal edilir.\n\n'
              'Onaylamak için e-posta adresini yaz:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: user.email,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().toLowerCase() == user.email?.toLowerCase()) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('E-posta adresi eşleşmiyor'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hesabı Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final deletionDate = DateTime.now().add(const Duration(days: 7));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'deletionScheduledAt': Timestamp.fromDate(deletionDate)});

    setState(() => _deletionScheduledAt = deletionDate);

    // Sign out
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go('/onboarding');
    }
  }

  Future<void> _cancelDelete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({'deletionScheduledAt': FieldValue.delete()});

    setState(() => _deletionScheduledAt = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hesap silme işlemi iptal edildi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _resetAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Verileri Sıfırla?'),
        content: const Text('Bütün içecek geçmişin, toplam puanın ve istatistiklerin kalıcı olarak silinecek. Bu işlem geri alınamaz!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(iconColor: Colors.red),
            child: const Text('Sıfırla', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // 1. Delete all entries
      final entries = await FirebaseFirestore.instance
          .collection('entries')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in entries.docs) {
        batch.delete(doc.reference);
      }

      // 2. Reset user stats
      batch.update(FirebaseFirestore.instance.collection('users').doc(user.uid), {
        'totalPoints': 0,
        'totalDrinks': 0,
      });

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm istatistikler ve geçmiş sıfırlandı! ✨'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About Section
            _buildSectionTitle('Hakkında'),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: AppDecorations.glassCard(),
                  child: Column(
                    children: [
                      _buildTapRow(
                        icon: AppIcons.document,
                        title: 'Gizlilik Politikası',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildTapRow(
                        icon: AppIcons.memoPad,
                        title: 'Kullanım Şartları',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: AppIcons.infoCircle,
                        title: 'Versiyon',
                        value: '1.0.0',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Coming Soon Section
            _buildSectionTitle('Yakında'),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: AppDecorations.glassCard(),
                  child: Column(
                    children: [
                      _buildDisabledRow(
                        icon: AppIcons.moon,
                        title: 'Karanlık Mod',
                        subtitle: 'Yakında',
                      ),
                      _buildDivider(),
                      _buildDisabledRow(
                        icon: AppIcons.bell,
                        title: 'Bildirimler',
                        subtitle: 'Yakında',
                      ),
                      _buildDivider(),
                      _buildDisabledRow(
                        icon: AppIcons.world,
                        title: 'Dil',
                        subtitle: 'Yakında',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Account Management Section
            _buildSectionTitle('Hesap Yönetimi'),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: AppDecorations.glassCard(),
                  child: Column(
                    children: [
                      // Ghost Mode Toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Icon(AppIcons.eyeCrossed, color: Colors.purple, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hayalet Mod',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Kimse aktivitelerini göremez',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isFrozen,
                              onChanged: _toggleFreeze,
                              activeColor: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                      _buildDivider(),
                      // Blocked Users
                      _buildTapRow(
                        icon: AppIcons.ban,
                        title: 'Engellenen Kullanıcılar',
                        onTap: () => context.push('/blocked-users'),
                      ),
                      _buildDivider(),
                      // Delete Account
                      if (_deletionScheduledAt != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(AppIcons.exclamation, color: Colors.orange, size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Silme Planlandı',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        Text(
                                          '${_deletionScheduledAt!.day}/${_deletionScheduledAt!.month}/${_deletionScheduledAt!.year} tarihinde silinecek',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _cancelDelete,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                  child: const Text('Silmeyi İptal Et'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: _scheduleDelete,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Icon(AppIcons.trash, color: Colors.red, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hesabı Sil',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      Text(
                                        '7 gün sonra kalıcı olarak silinir',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                 Icon(AppIcons.angleRight, color: AppColors.textTertiary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      _buildDivider(),
                      // Reset All Data
                      _buildTapRow(
                        icon: AppIcons.refresh,
                        title: 'İstatistikleri Sıfırla',
                        onTap: _resetAllData,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTapRow({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            const SizedBox(width: 8),
            Icon(AppIcons.angleRight, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 20,
      color: AppColors.primary.withOpacity(0.1),
    );
  }
}
