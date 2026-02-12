import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  DateTime? _dob; // Date of Birth - optional
  String? _gender; // 'male' or 'female' - optional

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start listening to controller
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() {}); // Rebuild to update UI and physics
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
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
    // Ensure name is up to date from controller
    _name = _nameController.text.trim();

    // Name is mandatory, others are optional
    if (_name == null || _name!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen adınızı girin')),
      );
      // Go back to start if name is missing
      if (_currentPage != 0) {
        _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
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
        if (_dob != null) {
          final age = DateTime.now().year - _dob!.year;
          data['age'] = age;
          data['dob'] = Timestamp.fromDate(_dob!);
        }
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
        if (_dob != null) {
          final age = DateTime.now().year - _dob!.year;
          data['age'] = age;
          data['dob'] = Timestamp.fromDate(_dob!);
        }
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
          // 1. Base Background
          Positioned.fill(
            child: Container(color: AppColors.background),
          ),
          
          // 2. Glow Effects (Subtle & Immersive)
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.primary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.08),
                    AppColors.secondary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Main Content
          
          // 4. Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Header (Progress)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const SizedBox(width: 8), // Slight breathing room
                      Expanded(child: _buildPremiumIndicator()),
                      if (_currentPage > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _skipAndFinish,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Şimdilik atla',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Title Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Profilini Tamamla',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Seni daha iyi tanıyalım',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Pages
                Expanded(
                  flex: 10,
                  child: PageView(
                    controller: _pageController,
                    // If on page 0 and name is empty, disable swipe
                    physics: (_currentPage == 0 && _nameController.text.trim().isEmpty)
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() {
                        // If leaving page 0, save name
                        if (_currentPage == 0 && page > 0) {
                          _name = _nameController.text.trim();
                        }
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildNamePage(),
                      _buildWeightPage(),
                      _buildHeightPage(),
                      _buildDobPage(),
                      _buildGenderPage(),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),

                  // Navigation buttons
                  Padding(
                    // Reduced vertical padding to prevent main buttons from shifting up
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 8),
                    child: Column(
                      children: [
                        if (_currentPage == 0)
                          // Step 1: Only Next button (No Skip, No Back)
                          _buildPrimaryButton('İleri', _nextPage)
                        else
                          // Step 2+: Back + Next (Side by Side)
                          Row(
                            children: [
                              Expanded(
                                child: _buildSecondaryButton('Geri', _previousPage),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildPrimaryButton(
                                  _currentPage == 4 ? 'Tamamla' : 'İleri',
                                  _currentPage == 4 ? _saveAndFinish : _nextPage,
                                ),
                              ),
                            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = _currentPage >= index;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isActive ? 5 : 4,
              margin: EdgeInsets.symmetric(horizontal: (index != 0) ? 6 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive ? AppColors.primary : Colors.white.withOpacity(0.06),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ] : null,
              ),
            ),
          );
        }),
      ),
    );
  }


  Widget _buildPremiumCard({required List<Widget> children}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2433).withOpacity(0.5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
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
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Size nasıl hitap edelim?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 48),
        _buildTextField(
          controller: _nameController,
          hintText: 'Adını buraya yaz...',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              'Bu alan zorunludur',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

  Widget _buildDobPage() {
    return _buildPremiumCard(
      children: [
        Text(
          'Doğum tarihiniz?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yaşınızı hesaplamak için gerekli',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          height: 200,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Brightness.dark,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _dob ?? DateTime(2000, 1, 1),
              minimumDate: DateTime(1900),
              maximumDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18+ limit
              onDateTimeChanged: (DateTime newDate) {
                setState(() => _dob = newDate);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_dob != null)
          Text(
            '${DateTime.now().year - _dob!.year} yaşındasınız',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
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
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _buildRoundIconButton(Icons.remove, currentValue > min ? () => onChanged(currentValue - 1) : null),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Transform.translate(
                      offset: Offset(0, value == null ? 8.0 : 0.0), // Push "--" down
                      child: Text(
                        value != null ? '$value' : '--',
                        style: GoogleFonts.inter(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unit,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildRoundIconButton(Icons.add, currentValue < max ? () => onChanged(currentValue + 1) : null),
          ],
        ),
        const SizedBox(height: 40),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.05),
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withOpacity(0.1),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 6,
              pressedElevation: 8,
            ),
            trackShape: const RoundedRectSliderTrackShape(),
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
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Daha isabetli sonuçlar için gerekli',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                'Erkek',
                Icons.male,
                _gender == 'male',
                () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderOption(
                'Kadın',
                Icons.female,
                _gender == 'female',
                () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundIconButton(IconData icon, VoidCallback? onTap) {
    return AnimatedScale(
      scale: onTap == null ? 1.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: onTap != null ? Colors.white : Colors.white.withOpacity(0.1),
          ),
        ),
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
        color: const Color(0xFF0F1218), // Slightly darker for input
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        style: style,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.2),
            fontWeight: FontWeight.w500,
            fontSize: style?.fontSize ?? 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          suffixIcon: textAlign == TextAlign.center ? null : Icon(
            Icons.edit,
            color: Colors.white.withOpacity(0.1),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        color: Colors.white.withOpacity(0.03),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
// reload
