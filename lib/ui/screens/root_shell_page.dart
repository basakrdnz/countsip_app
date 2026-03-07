import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/services/theme_service.dart';
import '../widgets/countsip_button.dart';

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
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  bool _isAddButtonPressed = false;

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
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    } else {
      _userStream = const Stream.empty();
    }
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
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hesabın Silinecek!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hesabın $daysLeft gün içinde silinecek şekilde planlanmış. Hesabını geri açmak ister misin?',
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
                    child: CountSipButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pop(context, false);
                          context.go('/onboarding');
                        }
                      },
                      text: 'ÇIKIŞ YAP',
                      variant: CountSipButtonVariant.secondary,
                      borderRadius: 16,
                      height: 52,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CountSipButton(
                      onPressed: () => Navigator.pop(context, true),
                      text: 'GERİ AÇ',
                      borderRadius: 16,
                      height: 52,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        return Container(
          color: AppColors.background,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true, // Allow body to flow behind floating navbar
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
            child: widget.navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent, // Ensure no background is rendered here
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 70,
              decoration: AppDecorations.glassCard(borderRadius: 35, borderWidth: 1.5).copyWith(
                color: Colors.white.withOpacity(0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: AppIcons.home,
                    selectedIcon: AppIcons.home,
                    isSelected: currentIndex == 0,
                    onTap: () => _onDestinationSelected(0),
                    iconSize: 24,
                    accentColor: AppColors.primary,
                  ),
                  _NavItem(
                    icon: AppIcons.plus,
                    selectedIcon: AppIcons.plus,
                    isSelected: currentIndex == 1,
                    onTap: () => _onDestinationSelected(1),
                    iconSize: 24,
                    accentColor: AppColors.primary,
                  ),
                  // Center Button: Social Feed (Replaces 'Add' button in Nav, 'Add' is now Floating or elsewhere)
                  // Wait, design says Center Button = Feed.
                  // 'Add' button is usually floating. 
                  // But previously 'Add' was index 2? Let's check the routes in main.dart first.
                  // Assuming index 2 in navigationShell is now FeedScreen.
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isAddButtonPressed = true),
                    onTapUp: (_) => setState(() => _isAddButtonPressed = false),
                    onTapCancel: () => setState(() => _isAddButtonPressed = false),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Navigate to Feed (Index 2 after revert)
                      _onDestinationSelected(2);
                    },
                    child: AnimatedScale(
                      scale: _isAddButtonPressed ? 0.94 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: currentIndex == 2 
                                ? [AppColors.primary, AppColors.primary.withOpacity(0.8)] // Active: Pure Orange
                                : [AppColors.primary.withOpacity(0.9), AppColors.primary.withOpacity(0.7)], // Inactive: Solid Orange
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentIndex == 2 
                                  ? AppColors.primary.withOpacity(0.6) 
                                  : AppColors.primary.withOpacity(0.2),
                              blurRadius: currentIndex == 2 ? 16 : 8,
                              offset: const Offset(0, 4),
                              spreadRadius: currentIndex == 2 ? 2 : 0,
                            ),
                          ],
                          border: Border.all(
                            color: currentIndex == 2 
                                ? Colors.white.withOpacity(0.5) 
                                : Colors.white.withOpacity(0.1), 
                            width: 1.5
                          ),
                        ),
                        child: Icon(
                          AppIcons.glassWhiskey, 
                          color: Colors.white, // Always white
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  _NavItem(
                    icon: AppIcons.trophyIcon,
                    selectedIcon: AppIcons.trophyIcon,
                    isSelected: currentIndex == 3,
                    onTap: () => _onDestinationSelected(3),
                    iconSize: 29,
                    accentColor: AppColors.primary,
                  ),
                  _NavItem(
                    icon: AppIcons.user,
                    selectedIcon: AppIcons.user,
                    isSelected: currentIndex == 4,
                    onTap: () => _onDestinationSelected(4),
                    iconSize: 24,
                    accentColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  },
);
  }
}
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;
  final Color accentColor;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
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
          color: isSelected ? accentColor : AppColors.textTertiary,
          size: iconSize,
        ),
      ),
    );
  }
}
