import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: AppColors.background.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: AppColors.primary.withOpacity(0.2), 
              width: 1.5,
            ),
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
                child: const Icon(Icons.report_problem_rounded, color: AppColors.error, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'Hesabı Sil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hesabınız 7 gün sonra kalıcı olarak silinecek. Onaylamak için e-posta adresinizi girin:',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: user.email,
                  hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.3)),
                  fillColor: Colors.white.withOpacity(0.04),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'VAZGEÇ',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary.withOpacity(0.7), 
                            fontWeight: FontWeight.w800, 
                            fontSize: 13, 
                            letterSpacing: 1
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (emailController.text.trim().toLowerCase() == user.email?.toLowerCase()) {
                          Navigator.pop(context, true);
                        } else {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('E-posta adresi eşleşmiyor'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'ONAYLA',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1),
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

  Future<bool?> _showConfirmDialog(BuildContext context, {
    required String title,
    required String content,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: AppColors.background.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: AppColors.primary.withOpacity(0.2), 
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDestructive ? AppColors.error : AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDestructive ? Icons.report_problem_rounded : Icons.info_outline_rounded,
                  color: isDestructive ? AppColors.error : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                        color: Colors.white.withOpacity(0.05),
                      ),
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
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'ONAYLA',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Ayarlar', 
           style: GoogleFonts.plusJakartaSans(
             fontWeight: FontWeight.w900, 
             fontSize: 20, 
             letterSpacing: -0.5,
             color: AppColors.textPrimary,
           ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: Icon(AppIcons.angleLeft, size: 20),
          onPressed: () => context.pop(),
        ),
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
                      // Ghost Mode Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppIcons.eyeCrossed, 
                                color: AppColors.primary.withOpacity(0.6), 
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hayalet Mod',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  Text(
                                    'Kimse aktivitelerini göremez',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isFrozen,
                              onChanged: _toggleFreeze,
                              activeColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withOpacity(0.3),
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
                        _buildTapRow(
                          icon: AppIcons.trash,
                          title: 'Hesabı Sil',
                          titleColor: AppColors.error,
                          iconColor: AppColors.error,
                          onTap: _scheduleDelete,
                        ),
                      _buildDivider(),
                      // Reset All Data
                      _buildTapRow(
                        icon: AppIcons.refresh,
                        title: 'Tüm Verileri Sıfırla',
                        titleColor: AppColors.error,
                        iconColor: AppColors.error,
                        onTap: () async {
                          HapticFeedback.heavyImpact();
                          final confirm = await _showConfirmDialog(
                            context,
                            title: 'Verileri Sıfırla?',
                            content: 'Bütün içecek geçmişin, toplam puanın ve istatistiklerin kalıcı olarak silinecek. Bu işlem geri alınamaz!',
                            isDestructive: true,
                          );
                          if (confirm == true) _resetAllData();
                        },
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
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTapRow({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: (iconColor ?? AppColors.primary).withOpacity(0.6), 
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? AppColors.textTertiary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary.withOpacity(0.6),
                ),
              ),
            const SizedBox(width: 8),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: AppColors.primary.withOpacity(0.6), 
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary.withOpacity(0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: AppColors.textTertiary.withOpacity(0.3), 
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary.withOpacity(0.5),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary.withOpacity(0.3),
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
      indent: 54,
      endIndent: 16,
      color: Colors.white.withOpacity(0.04),
    );
  }
}
