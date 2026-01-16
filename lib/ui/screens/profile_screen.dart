import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

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
            child: const Text('Çıkış Yap'),
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

  void _showEditDialog(String field, String title, int min, int max, String unit) {
    final currentValue = _userData?[field] as int? ?? min;
    int newValue = currentValue;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleButton(
                    icon: Icons.remove,
                    enabled: newValue > min,
                    onTap: () => setDialogState(() => newValue--),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$newValue $unit',
                    style: AppTextStyles.largeTitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildCircleButton(
                    icon: Icons.add,
                    enabled: newValue < max,
                    onTap: () => setDialogState(() => newValue++),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: newValue.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  onChanged: (val) => setDialogState(() => newValue = val.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$min', style: TextStyle(color: AppColors.textSecondary)),
                  Text('$max', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateField(field, newValue);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }

  void _showGenderDialog() {
    final currentGender = _userData?['gender'] as String?;
    String? selectedGender = currentGender;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cinsiyet', textAlign: TextAlign.center),
          content: Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  icon: Icons.male,
                  label: 'Erkek',
                  isSelected: selectedGender == 'male',
                  onTap: () => setDialogState(() => selectedGender = 'male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption(
                  icon: Icons.female,
                  label: 'Kadın',
                  isSelected: selectedGender == 'female',
                  onTap: () => setDialogState(() => selectedGender = 'female'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: selectedGender != null
                  ? () async {
                      Navigator.pop(context);
                      await _updateField('gender', selectedGender);
                    }
                  : null,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _updateField(String field, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic update - update UI immediately
    setState(() {
      _userData = Map<String, dynamic>.from(_userData ?? {});
      _userData![field] = value;
      _userData!['profileComplete'] = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        field: value,
        'profileComplete': true,
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kaydedildi ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      // Rollback on error
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _getGenderText(String? gender) {
    if (gender == 'male') return 'Erkek';
    if (gender == 'female') return 'Kadın';
    return 'Belirtilmedi';
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifreler eşleşmiyor')),
                );
                return;
              }
              // TODO: Implement password change with Firebase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şifre değiştirme yakında aktif olacak')),
              );
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profil & Ayarlar'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  _buildSection(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Icon(Icons.person, size: 45, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          user?.email ?? 'Kullanıcı',
                          style: AppTextStyles.title2.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _userData?['profileComplete'] == true ? '✓ Profil Tamamlandı' : '⚠ Profil Eksik',
                            style: TextStyle(
                              color: _userData?['profileComplete'] == true ? Colors.green : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Personal Info Section
                  _buildSectionTitle('Kişisel Bilgiler', Icons.person_outline),
                  _buildSection(
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.monitor_weight_outlined,
                          title: 'Kilo',
                          value: _userData?['weight'] != null ? '${_userData!['weight']} kg' : 'Belirtilmedi',
                          onTap: () => _showEditDialog('weight', 'Kilo', 30, 200, 'kg'),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.height,
                          title: 'Boy',
                          value: _userData?['height'] != null ? '${_userData!['height']} cm' : 'Belirtilmedi',
                          onTap: () => _showEditDialog('height', 'Boy', 100, 250, 'cm'),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.cake_outlined,
                          title: 'Yaş',
                          value: _userData?['age'] != null ? '${_userData!['age']} yaş' : 'Belirtilmedi',
                          onTap: () => _showEditDialog('age', 'Yaş', 18, 100, 'yaş'),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.wc,
                          title: 'Cinsiyet',
                          value: _getGenderText(_userData?['gender'] as String?),
                          onTap: _showGenderDialog,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Account Section
                  _buildSectionTitle('Hesap', Icons.manage_accounts_outlined),
                  _buildSection(
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.lock_outline,
                          title: 'Şifre Değiştir',
                          onTap: _showChangePasswordDialog,
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.email_outlined,
                          title: 'E-posta',
                          value: user?.email ?? '',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('E-posta değiştirme yakında aktif olacak')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Social Section
                  _buildSectionTitle('Sosyal', Icons.people_outline),
                  _buildSection(
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.person_add_outlined,
                          title: 'Arkadaş Ekle',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Arkadaş ekleme yakında aktif olacak')),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.group_outlined,
                          title: 'Arkadaşlarım',
                          value: '0 arkadaş',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Arkadaş listesi yakında aktif olacak')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Settings Section
                  _buildSectionTitle('Ayarlar', Icons.settings_outlined),
                  _buildSection(
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.language,
                          title: 'Dil',
                          value: 'Türkçe',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dil ayarları yakında aktif olacak')),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.notifications_outlined,
                          title: 'Bildirimler',
                          value: 'Açık',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bildirim ayarları yakında aktif olacak')),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Karanlık Mod',
                          value: 'Kapalı',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tema ayarları yakında aktif olacak')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Extra space for floating nav
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTextStyles.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: value == 'Belirtilmedi' ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.withOpacity(0.15), height: 1);
  }
}
