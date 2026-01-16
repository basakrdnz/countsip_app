import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

/// Profile Setup Screen - Collect user info after signup
/// Height, Weight, Age, Gender (for BAC calculation)
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  int? _weight; // kg
  int? _height; // cm
  int? _age;
  String? _gender; // 'male' or 'female'

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
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
    if (_weight == null || _height == null || _age == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'weight': _weight,
          'height': _height,
          'age': _age,
          'gender': _gender,
          'profileComplete': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

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
    final user = FirebaseAuth.instance.currentUser;
    
    // Navigate immediately
    if (mounted) {
      context.go('/home');
    }
    
    // Save in background (don't block navigation)
    if (user != null) {
      try {
        final data = <String, dynamic>{
          'profileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
        };
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/onlybg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : 4,
                          right: index == 3 ? 0 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.3),
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
                                : (_currentPage == 3 ? _saveAndFinish : _nextPage),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(_currentPage == 3 ? 'Tamamla' : 'İleri'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                              Icons.male,
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
                              Icons.female,
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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                        Icons.remove,
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
                        Icons.add,
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
    );
  }
}
