import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_icons.dart';

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
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: List.generate(
                      5,
                      (index) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            left: index == 0 ? 0 : 4,
                            right: index == 4 ? 0 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: index <= _currentPage
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
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
                              child: OutlinedButton(
                                onPressed: _previousPage,
                                child: const Text('Geri'),
                              ),
                            ),
                          if (_currentPage > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (_currentPage == 4 ? _saveAndFinish : _nextPage),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : Text(_currentPage == 4 ? 'Tamamla' : 'İleri'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Only show skip button if name is filled
                      if (_nameController.text.trim().isNotEmpty)
                        TextButton(
                          onPressed: _isLoading ? null : _skipAndFinish,
                          child: Text(
                            'Şimdilik atla',
                            style: TextStyle(color: AppColors.textSecondary),
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

  Widget _buildNamePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Adınız nedir?',
                      style: AppTextStyles.largeTitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Size nasıl hitap edelim?',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Adınızı girin',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.normal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '* Bu alan zorunludur',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildWeightPage() {
    return _buildInputPage(
      title: 'Kilonuz kaç?',
      subtitle: 'Hesaplamalarınızı doğru yapabilmemiz için',
      value: _weight,
      unit: 'kg',
      min: 30,
      max: 200,
      onChanged: (value) => setState(() => _weight = value),
    );
  }

  Widget _buildHeightPage() {
    return _buildInputPage(
      title: 'Boyunuz kaç?',
      subtitle: 'Daha kişiselleştirilmiş bir deneyim için',
      value: _height,
      unit: 'cm',
      min: 100,
      max: 250,
      onChanged: (value) => setState(() => _height = value),
    );
  }

  Widget _buildAgePage() {
    return _buildInputPage(
      title: 'Yaşınız kaç?',
      subtitle: 'Yasal düzenlemeler için bilmemiz gerekiyor',
      value: _age,
      unit: 'yaş',
      min: 18,
      max: 100,
      onChanged: (value) => setState(() => _age = value),
    );
  }

  Widget _buildGenderPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cinsiyetiniz?',
                      style: AppTextStyles.largeTitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Hesaplamalarınızı doğru yapabilmemiz için',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Gender Selection
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _gender = 'male'),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: _gender == 'male'
                                    ? AppColors.primary.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _gender == 'male'
                                      ? AppColors.primary
                                      : Colors.grey.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    AppIcons.mars,
                                    size: 48,
                                    color: _gender == 'male'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Erkek',
                                    style: AppTextStyles.title3.copyWith(
                                      color: _gender == 'male'
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _gender = 'female'),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: _gender == 'female'
                                    ? AppColors.primary.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _gender == 'female'
                                      ? AppColors.primary
                                      : Colors.grey.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    AppIcons.venus,
                                    size: 48,
                                    color: _gender == 'female'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Kadın',
                                    style: AppTextStyles.title3.copyWith(
                                      color: _gender == 'female'
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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
          ),
      ),
    );
  }

  Widget _buildInputPage({
    required String title,
    required String subtitle,
    required int? value,
    required String unit,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final currentValue = value ?? min;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.largeTitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Value Display with +/- buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button
                      IconButton(
                        onPressed: currentValue > min
                            ? () => onChanged(currentValue - 1)
                            : null,
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: currentValue > min
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.minus,
                            color: currentValue > min
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Value
                      Text(
                        value != null ? '$value $unit' : '-- $unit',
                        style: AppTextStyles.largeTitle.copyWith(
                          fontSize: 48,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Plus button
                      IconButton(
                        onPressed: currentValue < max
                            ? () => onChanged(currentValue + 1)
                            : null,
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: currentValue < max
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.plus,
                            color: currentValue < max
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Slider
                  Slider(
                    value: currentValue.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.grey.withOpacity(0.3),
                    onChanged: (val) => onChanged(val.round()),
                  ),
                  
                  // Min/Max labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$min', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      Text('$max', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    ],
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
