import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

class RootShellPage extends StatefulWidget {
  const RootShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<RootShellPage> createState() => _RootShellPageState();
}

class _RootShellPageState extends State<RootShellPage> {
  bool _isGhostMode = false;
  DateTime? _deletionScheduledAt;
  bool _hasCheckedStatus = false;

  @override
  void initState() {
    super.initState();
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    final data = doc.data();
    if (data == null) return;

    setState(() {
      _isGhostMode = data['isFrozen'] ?? false;
      final deletionTs = data['deletionScheduledAt'];
      if (deletionTs != null) {
        _deletionScheduledAt = (deletionTs as Timestamp).toDate();
      }
      _hasCheckedStatus = true;
    });

    // Show delete recovery dialog if deletion is scheduled
    if (_deletionScheduledAt != null) {
      _showDeleteRecoveryDialog();
    }
  }

  Future<void> _showDeleteRecoveryDialog() async {
    final daysLeft = _deletionScheduledAt!.difference(DateTime.now()).inDays;
    
    final recover = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(AppIcons.exclamation, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Hesabın Silinecek!'),
          ],
        ),
        content: Text(
          'Hesabın $daysLeft gün içinde silinecek şekilde planlanmış.\n\n'
          'Hesabını geri açmak ister misin?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pop(context, false);
                context.go('/onboarding');
              }
            },
            child: const Text('Çıkış Yap'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Hesabı Geri Aç', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (recover == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'deletionScheduledAt': FieldValue.delete()});
        
        setState(() => _deletionScheduledAt = null);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Hesabın geri açıldı!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    
    return Scaffold(
      body: Column(
        children: [
          // Ghost Mode Banner
          if (_isGhostMode && _hasCheckedStatus)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.purple,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(AppIcons.eyeCrossed, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Hayalet Mod aktif - Kimse seni göremez',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Kapat',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Main content
          Expanded(child: widget.navigationShell),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: AppIcons.home,
                selectedIcon: AppIcons.home, //rs doesn't have filled/outlined usually, we can use same or find counterpart
                isSelected: currentIndex == 0,
                onTap: () => _onDestinationSelected(0),
              ),
              _NavItem(
                icon: AppIcons.plus,
                selectedIcon: AppIcons.plus,
                isSelected: currentIndex == 1,
                onTap: () => _onDestinationSelected(1),
              ),
              GestureDetector(
                onTap: () => _onDestinationSelected(1),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.85),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    AppIcons.drinkAlt,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              _NavItem(
                icon: AppIcons.trophyIcon,
                selectedIcon: AppIcons.trophyIcon,
                isSelected: currentIndex == 2,
                onTap: () => _onDestinationSelected(2),
              ),
              _NavItem(
                icon: AppIcons.user,
                selectedIcon: AppIcons.user,
                isSelected: currentIndex == 3,
                onTap: () => _onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade400,
          size: 26,
        ),
      ),
    );
  }
}
