import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';

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
  int _previousIndex = 0;

  @override
  void didUpdateWidget(RootShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      _previousIndex = oldWidget.navigationShell.currentIndex;
    }
  }

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
      backgroundColor: AppColors.background,
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
          // Main content with sliding transitions
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                final isForward = widget.navigationShell.currentIndex >= _previousIndex;
                final beginOffset = isForward ? const Offset(1, 0) : const Offset(-1, 0);
                
                return SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: beginOffset,
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(widget.navigationShell.currentIndex),
                child: widget.navigationShell,
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 70,
              decoration: AppDecorations.glassCard(borderRadius: 35, borderWidth: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: AppIcons.home,
                    selectedIcon: AppIcons.home,
                    isSelected: currentIndex == 0,
                    onTap: () => _onDestinationSelected(0),
                    iconSize: 24,
                  ),
                  _NavItem(
                    icon: AppIcons.plus,
                    selectedIcon: AppIcons.plus,
                    isSelected: currentIndex == 1,
                    onTap: () => _onDestinationSelected(1),
                    iconSize: 24,
                  ),
                  GestureDetector(
                    onTap: () => _onDestinationSelected(1),
                    child: Container(
                      width: 58,
                      height: 58,
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
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wine_bar_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  _NavItem(
                    icon: AppIcons.trophyIcon,
                    selectedIcon: AppIcons.trophyIcon,
                    isSelected: currentIndex == 2,
                    onTap: () => _onDestinationSelected(2),
                    iconSize: 29, // Keeping leaderboard larger as requested
                  ),
                  _NavItem(
                    icon: AppIcons.user,
                    selectedIcon: AppIcons.user,
                    isSelected: currentIndex == 3,
                    onTap: () => _onDestinationSelected(3),
                    iconSize: 24,
                  ),
                ],
              ),
            ),
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
  final double iconSize;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    this.iconSize = 25,
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
          color: isSelected ? AppColors.primary : AppColors.textTertiary,
          size: iconSize,
        ),
      ),
    );
  }
}
