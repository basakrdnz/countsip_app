import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/services/theme_service.dart';

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
  AppThemeMode _currentTheme = AppThemeMode.defaultMode;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userThemeStream;
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
      _userThemeStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    } else {
      _userThemeStream = const Stream.empty();
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
                    child: TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pop(context, false);
                          context.go('/onboarding');
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'ÇIKIŞ YAP',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'GERİ AÇ',
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
      stream: _userThemeStream,
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        _currentTheme = AppThemeMode.fromName(userData?['theme'] ?? 'defaultMode');
        final gradient = ThemeService.getBackgroundGradient(_currentTheme);
        final accentColor = ThemeService.getAccentColor(_currentTheme);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            gradient: gradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
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
                    accentColor: accentColor,
                  ),
                  _NavItem(
                    icon: AppIcons.plus,
                    selectedIcon: AppIcons.plus,
                    isSelected: currentIndex == 1,
                    onTap: () => _onDestinationSelected(1),
                    iconSize: 24,
                    accentColor: accentColor,
                  ),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isAddButtonPressed = true),
                    onTapUp: (_) => setState(() => _isAddButtonPressed = false),
                    onTapCancel: () => setState(() => _isAddButtonPressed = false),
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      context.push('/add');
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
                            colors: [
                              accentColor,
                              accentColor.withOpacity(0.85),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.5),
                              blurRadius: _isAddButtonPressed ? 20 : 30,
                              spreadRadius: _isAddButtonPressed ? 2 : 4,
                            ),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.wine_bar_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  _NavItem(
                    icon: AppIcons.trophyIcon,
                    selectedIcon: AppIcons.trophyIcon,
                    isSelected: currentIndex == 2,
                    onTap: () => _onDestinationSelected(2),
                    iconSize: 29,
                    accentColor: accentColor,
                  ),
                  _NavItem(
                    icon: AppIcons.user,
                    selectedIcon: AppIcons.user,
                    isSelected: currentIndex == 3,
                    onTap: () => _onDestinationSelected(3),
                    iconSize: 24,
                    accentColor: accentColor,
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
