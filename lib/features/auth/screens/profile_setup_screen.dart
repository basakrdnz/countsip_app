import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_decorations.dart';

/// Profile Setup Screen - Collect user info after signup
/// Height, Weight, Age, Gender (for BAC calculation)
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  // Form data
  String? _name; // MANDATORY
  int? _weight; // kg - optional
  int? _height; // cm - optional
  int? _age; // optional
  String? _gender; // 'male' or 'female' - optional

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  // Fun username lists - 50 adjectives × 50 animals × 1000 numbers = 2.5M combinations
  static const _adjectives = [
    'happy', 'crazy', 'chill', 'wild', 'cool', 'lazy', 'fast', 'silent',
    'secret', 'funny', 'epic', 'super', 'mega', 'ultra', 'night', 'party',
    'cosmic', 'ninja', 'pirate', 'savage', 'calm', 'mad', 'funky', 'retro',
    'classic', 'modern', 'ancient', 'mystic', 'magic', 'atomic', 'galactic',
    'sonic', 'turbo', 'hyper', 'royal', 'noble', 'dark', 'bright', 'golden',
    'silver', 'iron', 'steel', 'neo', 'cyber', 'techno', 'astro', 'lucky',
    'swift', 'bold', 'brave',
  ];
  
  static const _animals = [
    'panda', 'fox', 'bear', 'cat', 'wolf', 'eagle', 'lion', 'tiger', 'owl',
    'penguin', 'dolphin', 'elephant', 'giraffe', 'kangaroo', 'koala', 'rabbit',
    'squirrel', 'hedgehog', 'beaver', 'otter', 'jaguar', 'leopard', 'puma',
    'croc', 'cobra', 'dragon', 'phoenix', 'unicorn', 'griffin', 'sphinx',
    'shark', 'whale', 'falcon', 'hawk', 'panther', 'viper', 'raven', 'lynx',
    'orca', 'rhino', 'buffalo', 'monkey', 'gorilla', 'cheetah', 'husky',
    'raccoon', 'badger', 'moose', 'mantis', 'scorpion',
  ];
  
  /// Generate fun username: adjective + animal + 3 digit number
  String _generateUsername(String email) {
    final random = DateTime.now().millisecondsSinceEpoch;
    
    // Pick random adjective and animal
    final adjective = _adjectives[random % _adjectives.length];
    final animal = _animals[(random ~/ 100) % _animals.length];
    
    // Add 3 digit number (000-999)
    final number = (random ~/ 10000) % 1000;
    final numberStr = number.toString().padLeft(3, '0');
    
    return '$adjective$animal$numberStr';
  }
  
  /// Check if username is unique and save it
  Future<String> _createUniqueUsername(String baseUsername) async {
    var username = baseUsername;
    var attempts = 0;
    
    while (attempts < 10) {
      final doc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username)
          .get();
      
      if (!doc.exists) {
        return username;
      }
      
      // Add random suffix
      final random = DateTime.now().millisecondsSinceEpoch % 10000;
      username = '${baseUsername.substring(0, baseUsername.length > 6 ? 6 : baseUsername.length)}$random';
      attempts++;
    }
    
    // Fallback: use timestamp
    return '${baseUsername.substring(0, 4)}${DateTime.now().millisecondsSinceEpoch}';
  }

  void _nextPage() {
    // Name is mandatory on first page
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen adınızı girin')),
      );
      return;
    }
    
    if (_currentPage == 0) {
      _name = _nameController.text.trim();
    }
    
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndFinish() async {
    // Name is mandatory, others are optional
    if (_name == null || _name!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen adınızı girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = <String, dynamic>{
          'name': _name,
          'profileComplete': true,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        // Generate and save username if not exists
        final existingDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (!existingDoc.exists || existingDoc.data()?['username'] == null) {
          final email = user.email ?? 'user';
          final baseUsername = _generateUsername(email);
          final username = await _createUniqueUsername(baseUsername);
          data['username'] = username;
          
          // Reserve username
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(username)
              .set({'uid': user.uid, 'createdAt': FieldValue.serverTimestamp()});
        }
        

        if (_weight != null) data['weight'] = _weight;
        if (_height != null) data['height'] = _height;
        if (_age != null) data['age'] = _age;
        if (_gender != null) data['gender'] = _gender;
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          data, 
          SetOptions(merge: true),
        );

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skipAndFinish() async {
    // Name is still required even when skipping
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce adınızı girin')),
      );
      // Go to first page if not there
      if (_currentPage != 0) {
        _pageController.animateToPage(0, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut,
        );
      }
      return;
    }
    
    _name = _nameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    
    // Navigate immediately
    if (mounted) {
      context.go('/home');
    }
    
    // Save in background (don't block navigation)
    if (user != null) {
      try {
        final data = <String, dynamic>{
          'name': _name,
          'profileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        // Generate and save username if not exists
        final existingDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (!existingDoc.exists || existingDoc.data()?['username'] == null) {
          final email = user.email ?? 'user';
          final baseUsername = _generateUsername(email);
          final username = await _createUniqueUsername(baseUsername);
          data['username'] = username;
          
          // Reserve username
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(username)
              .set({'uid': user.uid, 'createdAt': FieldValue.serverTimestamp()});
        }
        
        if (_weight != null) data['weight'] = _weight;
        if (_height != null) data['height'] = _height;
        if (_age != null) data['age'] = _age;
        if (_gender != null) data['gender'] = _gender;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          data,
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Skip profile save error: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbgwemp.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Main Content
          
          // 4. Content
          SafeArea(
            child: Column(
              children: [
                // Header (Progress Indicator)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                  child: Column(
                    children: [
                      _buildPremiumIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Profilini Tamamla',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: [
                      _buildNamePage(),
                      _buildWeightPage(),
                      _buildHeightPage(),
                      _buildAgePage(),
                      _buildGenderPage(),
                    ],
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (_currentPage > 0)
                            Expanded(
                              child: _buildSecondaryButton('Geri', _previousPage),
                            ),
                          if (_currentPage > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildPrimaryButton(
                              _currentPage == 4 ? 'Tamamla' : 'İleri',
                              _currentPage == 4 ? _saveAndFinish : _nextPage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Only show skip button if name is filled
                      if (_nameController.text.trim().isNotEmpty)
                        TextButton(
                          onPressed: _isLoading ? null : _skipAndFinish,
                          child: Text(
                            'Şimdilik atla',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumIndicator() {
    return Row(
      children: List.generate(5, (index) {
        final isActive = _currentPage >= index;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.symmetric(horizontal: (index != 0) ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive ? AppColors.buttonPrimary : AppColors.buttonPrimary.withOpacity(0.15),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPremiumCard({required List<Widget> children}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: AppDecorations.glassCard(borderRadius: 32).copyWith(
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return _buildPremiumCard(
      children: [
        Text(
          'Adınız nedir?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Size nasıl hitap edelim?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _nameController,
          hintText: 'Adınızı girin',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),
        Text(
          '* Bu alan zorunludur',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildWeightPage() {
    return _buildSliderStep(
      title: 'Kilonuz kaç?',
      subtitle: 'BAC hesaplamalarımız için önemli',
      value: _weight,
      unit: 'kg',
      min: 30,
      max: 200,
      onChanged: (value) => setState(() => _weight = value),
    );
  }

  Widget _buildHeightPage() {
    return _buildSliderStep(
      title: 'Boyunuz kaç?',
      subtitle: 'Fiziksel profilini belirleyelim',
      value: _height,
      unit: 'cm',
      min: 100,
      max: 250,
      onChanged: (value) => setState(() => _height = value),
    );
  }

  Widget _buildAgePage() {
    return _buildSliderStep(
      title: 'Yaşınız kaç?',
      subtitle: 'Uygulama deneyimini özelleştirelim',
      value: _age,
      unit: 'yaş',
      min: 18,
      max: 100,
      onChanged: (value) => setState(() => _age = value),
    );
  }

  Widget _buildSliderStep({
    required String title,
    required String subtitle,
    required int? value,
    required String unit,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final currentValue = value ?? min;
    return _buildPremiumCard(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoundIconButton(AppIcons.minus, currentValue > min ? () => onChanged(currentValue - 1) : null),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                value != null ? '$value $unit' : '-- $unit',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            _buildRoundIconButton(AppIcons.plus, currentValue < max ? () => onChanged(currentValue + 1) : null),
          ],
        ),
        const SizedBox(height: 32),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.buttonPrimary,
            inactiveTrackColor: AppColors.buttonPrimary.withOpacity(0.1),
            thumbColor: AppColors.buttonPrimary,
            overlayColor: AppColors.buttonPrimary.withOpacity(0.1),
            trackHeight: 6,
          ),
          child: Slider(
            value: currentValue.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPage() {
    return _buildPremiumCard(
      children: [
        Text(
          'Cinsiyetiniz?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Daha isabetli sonuçlar için gerekli',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(child: _buildGenderOption('Erkek', AppIcons.mars, _gender == 'male', () => setState(() => _gender = 'male'))),
            const SizedBox(width: 16),
            Expanded(child: _buildGenderOption('Kadın', AppIcons.venus, _gender == 'female', () => setState(() => _gender = 'female'))),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonPrimary.withOpacity(0.1) : AppColors.cardBackground.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.buttonPrimary : AppColors.cardBorder,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? AppColors.buttonPrimary : AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.buttonPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundIconButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, size: 20, color: onTap != null ? AppColors.buttonPrimary : AppColors.textTertiary.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        style: style,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5), fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isLoading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.buttonOnPrimary))
            : Text(text, style: TextStyle(fontSize: 16, color: AppColors.buttonOnPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: AppColors.buttonPrimary.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(text, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
    );
  }
}
