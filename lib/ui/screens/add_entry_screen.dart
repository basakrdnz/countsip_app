import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' show pi;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import 'package:uicons/uicons.dart';
import 'package:image_picker/image_picker.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> with TickerProviderStateMixin {
  // --- Data Structure ---
  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'beer',
      'name': 'Bira',
      'emoji': '🍺',
      'image': 'assets/images/drinks/beer.png',
      'portions': [
        {'name': '33 cl', 'volume': 330, 'abv': 4.5},
        {'name': '50 cl', 'volume': 500, 'abv': 4.5},
      ],
    },
    {
      'id': 'wine',
      'name': 'Şarap',
      'emoji': '🍷',
      'image': 'assets/images/drinks/wine.png',
      'portions': [
        {'name': 'Kadeh (150 ml)', 'volume': 150, 'abv': 12.5},
      ],
    },
    {
      'id': 'raki',
      'name': 'Rakı',
      'emoji': '🥃',
      'image': 'assets/images/drinks/raki.png',
      'portions': [
        {'name': 'Tek (35 ml)', 'volume': 35, 'abv': 45.0},
        {'name': 'Duble (70 ml)', 'volume': 70, 'abv': 45.0},
      ],
    },
    {
      'id': 'whiskey',
      'name': 'Viski',
      'emoji': '🥃',
      'image': 'assets/images/drinks/whiskey.png',
      'portions': [
        {'name': 'Tek (35 ml)', 'volume': 35, 'abv': 41.5},
        {'name': 'Duble (70 ml)', 'volume': 70, 'abv': 41.5},
      ],
    },
    {
      'id': 'vodka',
      'name': 'Vodka',
      'emoji': '🍸',
      'image': 'assets/images/drinks/vodka_enerji.png',
      'portions': [
        {'name': 'Shot (40 ml)', 'volume': 40, 'abv': 38.5},
        {'name': 'Vodka + Enerji (200 ml)', 'volume': 200, 'abv': 38.5},
      ],
    },
    {
      'id': 'gin',
      'name': 'Cin',
      'emoji': '🍸',
      'image': 'assets/images/drinks/gin.png',
      'portions': [
        {'name': 'Shot (35 ml)', 'volume': 35, 'abv': 42.0},
        {'name': 'Cin Tonik (250 ml)', 'volume': 250, 'abv': 42.0},
      ],
    },
    {
      'id': 'cocktail',
      'name': 'Kokteyl',
      'emoji': '🍹',
      'image': 'assets/images/drinks/kokteyl.png',
      'portions': [
        {'name': 'Özel Kokteyl', 'volume': 250, 'abv': 10.0},
        {'name': 'Margarita', 'volume': 200, 'abv': 12.0},
      ],
    },
    {
      'id': 'other',
      'name': 'Diğer',
      'emoji': '🍻',
      'image': 'assets/images/drinks/7.png',
      'portions': [
        {'name': 'Shot', 'volume': 40, 'abv': 35.0},
        {'name': 'Likit', 'volume': 100, 'abv': 20.0},
      ],
    },
    {
      'id': 'custom',
      'name': 'Kendin Yarat',
      'emoji': '✨',
      'image': 'assets/images/drinks/custom.png', // This will be handled in UI
      'portions': [
        {'name': 'Talep Et', 'abv': 0.0, 'volume': 0},
      ],
    },
  ];

  // --- State ---
  final Map<String, int> _selectedEntries = {};
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  int _feelingScale = 5;
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _entranceController;
  
  // Interaction State
  double _cardDragX = 0; // Keeping for now to avoid broken refs, will replace
  double _cardDragY = 0;
  String _searchQuery = '';
  
  // Custom Drink Request Controllers
  final _customNameController = TextEditingController();
  final _customAbvController = TextEditingController();
  final _customDescController = TextEditingController();
  
  XFile? _pickedImage;
  int _quantity = 1;
  String? _focusedCategoryId;
  Map<String, dynamic>? _selectedPortion;
  
  // Modern Animations State
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  double _previousScore = 0.0;
  
  bool _isButtonPressed = false;

  // --- Premium Accents ---
  Color get _accentColor {
    if (_feelingScale < 5) {
      return Color.lerp(Colors.red.shade400, Colors.orange.shade400, (_feelingScale - 1) / 4) ?? Colors.red.shade400;
    } else if (_feelingScale == 5) {
      return Colors.orange.shade400;
    } else {
      return Color.lerp(Colors.orange.shade400, Colors.green.shade500, (_feelingScale - 5) / 5) ?? Colors.green.shade500;
    }
  }

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  late AnimationController _bounceController;
  late AnimationController _guidanceController;
  late Animation<double> _guidanceArrowAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceController.forward();

    _guidanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _guidanceArrowAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _guidanceController, curve: Curves.easeInOut),
    );

    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 0).animate(_scoreAnimationController);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _entranceController.dispose();
    _guidanceController.dispose();
    _scoreAnimationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // --- Logic ---
  double _calculateScore(int volume, double abv) {
    return (volume * abv / 100) / 10;
  }

  double _getTotalScore() {
    double total = 0;
    _selectedEntries.forEach((key, count) {
      if (count > 0) {
        final categoryId = key.split('|')[0];
        final portionName = key.split('|')[1];
        final category = _categories.firstWhere((c) => c['id'] == categoryId);
        final portion = (category['portions'] as List).firstWhere((p) => p['name'] == portionName);
        total += _calculateScore(portion['volume'], portion['abv']) * count;
      }
    });
    return total;
  }

  int _getTotalCount() {
    int total = 0;
    _selectedEntries.forEach((_, count) => total += count);
    return total;
  }

  void _addPortion(String categoryId, Map<String, dynamic> portion) {
    HapticFeedback.mediumImpact();
    final key = '$categoryId|${portion['name']}';
    setState(() {
      _selectedEntries.clear(); // Rule: Only 1 drink at a time
      _selectedEntries[key] = 1;
    });
    _updateScoreAnimation();
    _animationController.forward(from: 0);
  }

  void _updateScoreAnimation() {
    final newScore = _getTotalScore();
    _scoreAnimation = Tween<double>(
      begin: _previousScore,
      end: newScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _previousScore = newScore;
    _scoreAnimationController.forward(from: 0);
  }

  void _removePortion(String key) {
    if ((_selectedEntries[key] ?? 0) > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedEntries[key] = _selectedEntries[key]! - 1;
        if (_selectedEntries[key] == 0) _selectedEntries.remove(key);
      });
      _updateScoreAnimation();
      _animationController.forward(from: 0);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedEntries.clear();
      _noteController.clear();
      _locationController.clear();
      _selectedTime = DateTime.now();
      _feelingScale = 5;
      _isLoading = false;
      _pickedImage = null;
      _quantity = 1;
      _focusedCategoryId = null;
      _selectedPortion = null;
    });
  }

  Future<void> _save() async {
    if (_getTotalCount() == 0) {
      HapticFeedback.vibrate();
      Fluttertoast.showToast(
        msg: 'Lütfen en az bir içecek seçin',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final totalScore = _getTotalScore();
      final totalCount = _getTotalCount();

      _selectedEntries.forEach((key, count) {
        if (count > 0) {
          final categoryId = key.split('|')[0];
          final portionName = key.split('|')[1];
          final category = _categories.firstWhere((c) => c['id'] == categoryId);
          final portion = (category['portions'] as List).firstWhere((p) => p['name'] == portionName);

          final entryRef = FirebaseFirestore.instance.collection('entries').doc();
          batch.set(entryRef, {
            'userId': user.uid,
            'drinkType': category['name'],
            'drinkEmoji': category['emoji'],
            'portion': portionName,
            'volume': portion['volume'],
            'abv': portion['abv'],
            'quantity': count,
            'points': _calculateScore(portion['volume'], portion['abv']) * count,
            'note': _noteController.text.trim(),
            'locationName': _locationController.text.trim(),
            'intoxicationLevel': _feelingScale,
            'timestamp': Timestamp.fromDate(_selectedTime),
            'createdAt': FieldValue.serverTimestamp(),
            // In a real app we'd upload this to Firebase Storage first
            'hasImage': _pickedImage != null,
            'imagePath': _pickedImage?.path, 
          });
        }
      });

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {
          'totalPoints': FieldValue.increment(totalScore),
          'totalDrinks': FieldValue.increment(totalCount),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (mounted) {
        HapticFeedback.heavyImpact();
        
        await Fluttertoast.showToast(
          msg: "✓ Başarıyla kaydedildi! +${totalScore.toStringAsFixed(1)} puan 🎉",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        _resetForm();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Hata: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  // --- UI Components ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'İçecek Ekle',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF4B3126),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.brandDark,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildTimeSelector(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _entranceController,
        child: Stack(
          children: [
            Container(color: AppColors.innerBackground),
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: (_selectedEntries.isEmpty && _focusedCategoryId == null) ? 120 : 120),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 220),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeInOutQuart,
                        switchOutCurve: Curves.easeInOutQuart,
                        child: (_selectedEntries.isEmpty && _focusedCategoryId == null)
                            ? Column(
                                  children: [
                                   _buildSearchBar(),
                                   const SizedBox(height: 8),
                                   KeyedSubtree(key: const ValueKey('grid'), child: _buildCategoryGrid()),
                                 ],
                              )
                            : KeyedSubtree(key: const ValueKey('focused'), child: _buildFocusedDrinkView()),
                      ),
                      if (_focusedCategoryId != null) ...[
                        const SizedBox(height: 40),
                        _buildFeelingScale(),
                        const SizedBox(height: 40),
                        _buildLocationField(),
                        const SizedBox(height: 40),
                        _buildImageSelector(),
                        const SizedBox(height: 40),
                        _buildNoteField(),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showModernDateTimePicker,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(UIcons.regularStraight.clock, size: 18, color: Color(0xFF4B3126).withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(_selectedTime),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF4B3126)),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 12, color: Colors.grey.withOpacity(0.2)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMM', 'tr').format(_selectedTime),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF4B3126)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showModernDateTimePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tarih ve Saat Seç',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedTime,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => _selectedTime = newDateTime);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _selectedTime = DateTime.now());
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('ŞİMDİ YAP', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('TAMAM', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final filteredCategories = _categories.where((c) {
      return c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AnimationLimiter(
      child: filteredCategories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(UIcons.regularStraight.search, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'İçecek bulunamadı',
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          : GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(filteredCategories.length, (index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 600),
                  columnCount: 2,
                  child: ScaleAnimation(
                    scale: 0.9,
                    child: FadeInAnimation(
                      child: _buildCategoryCard(filteredCategories[index]),
                    ),
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 100, // Explicit height for horizontal layout
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _focusedCategoryId = category['id'];
                  _selectedPortion = (category['portions'] as List).first;
                  final key = '${category['id']}|${_selectedPortion!['name']}';
                  _selectedEntries.clear();
                  _selectedEntries[key] = _quantity;
                });
                _updateScoreAnimation();
              },
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Image on the left - DRAMATICALLY larger and overflowing significantly
                  Positioned(
                    left: -40, // Deeply overflowing left for "half-visible" effect
                    top: -15,
                    bottom: -15,
                    width: 130, // Much wider for the oversized image
                    child: Hero(
                      tag: 'drink_${category['id']}',
                      child: category['id'] == 'custom'
                          ? Center(
                              child: Icon(
                                UIcons.regularStraight.interrogation,
                                size: 50,
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            )
                          : Image.asset(
                              category['image'],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.wine_bar, size: 40, color: Colors.grey),
                            ),
                    ),
                  ),
                  
                  // Text on the right
                  Positioned(
                    left: 70, // Start after the image
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        category['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF4B3126),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF4B3126)),
              decoration: InputDecoration(
                hintText: 'Ne içmiştin?',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                prefixIcon: Icon(UIcons.regularStraight.search, size: 20, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  // Obsolete: _buildGuidance removed.
  /*
  Widget _buildGuidance() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'İçeceğini seç',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4B3126),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _guidanceArrowAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _guidanceArrowAnimation.value),
              child: child,
            );
          },
          child: Icon(
            UIcons.regularStraight.arrow_small_down,
            color: AppColors.primary.withOpacity(0.5),
            size: 32,
          ),
        ),
      ],
    );
  }
  */

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GÖRSEL EKLE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 2, style: BorderStyle.solid),
            ),
            child: _pickedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(UIcons.regularStraight.camera, color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Bir fotoğraf ekle',
                        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _pickedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  // Code cleanup: removed obsolete UI helpers.

  Widget _buildFocusedDrinkView() {
    final category = _categories.firstWhere((c) => c['id'] == _focusedCategoryId);
    final score = _calculateScore(_selectedPortion!['volume'], _selectedPortion!['abv']);
    final totalPoints = score * _quantity;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _cardDragY += details.delta.dy;
          if (_cardDragY < 0) _cardDragY = 0; // Prevent upward drag
        });
      },
      onVerticalDragEnd: (details) {
        if (_cardDragY > 150) {
          // Dismiss
          HapticFeedback.lightImpact();
          setState(() {
            _cardDragY = 0;
            _selectedEntries.clear();
            _focusedCategoryId = null;
            _selectedPortion = null;
            _quantity = 1;
          });
          _updateScoreAnimation();
        } else {
          // Spring back
          setState(() {
            _cardDragY = 0;
          });
        }
      },
      child: Transform.translate(
        offset: Offset(0, _cardDragY),
        child: Column(
          children: [
            // Glass Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (category['id'] == 'custom')
                        _buildCustomRequestForm()
                      else ...[
                        Hero(
                          tag: 'drink_${category['id']}',
                          child: ScaleTransition(
                            scale: _bounceController,
                            child: Image.asset(
                              category['image'],
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.wine_bar, size: 100, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          category['name'],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4B3126),
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Portion Selector Chip Grid (if more than 1)
                        if ((category['portions'] as List).length > 1) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: (category['portions'] as List).map<Widget>((p) {
                              final isSelected = _selectedPortion!['name'] == p['name'];
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedPortion = p;
                                    final key = '${category['id']}|${p['name']}';
                                    _selectedEntries.clear();
                                    _selectedEntries[key] = _quantity;
                                  });
                                  _updateScoreAnimation();
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.brandDark : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    p['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
          
                        // Quantity Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildQtyBtn(Icons.remove, () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                  final key = '${category['id']}|${_selectedPortion!['name']}';
                                  _selectedEntries[key] = _quantity;
                                });
                                _updateScoreAnimation();
                              }
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF4B3126)),
                              ),
                            ),
                            _buildQtyBtn(Icons.add, () {
                              setState(() {
                                _quantity++;
                                final key = '${category['id']}|${_selectedPortion!['name']}';
                                _selectedEntries[key] = _quantity;
                              });
                              _updateScoreAnimation();
                            }),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDetailTag('%${_selectedPortion!['abv']}', 'Alkol'),
                            const SizedBox(width: 12),
                            _buildDetailTag('${_selectedPortion!['volume']}ml', 'Hacim'),
                            const SizedBox(width: 12),
                            _buildDetailTag('+${totalPoints.toStringAsFixed(1)}', 'Puan', isHighlight: true),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedEntries.clear();
                                    _focusedCategoryId = null;
                                    _selectedPortion = null;
                                    _quantity = 1;
                                  });
                                  _updateScoreAnimation();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade400,
                                  side: BorderSide(color: Colors.grey.shade200),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Geri Dön', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text('Hemen Ekle', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'İçecek Talebi Oluştur',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4B3126)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Aradığın içeceği bulamadın mı? Bilgileri gir, yönetici onaylayınca listeye eklensin!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 32),
        _buildRequestField('İçecek Adı', 'Örn: Hibiscus Gin Tonic', _customNameController),
        const SizedBox(height: 20),
        _buildRequestField('Alkol Oranı (%)', 'Örn: 12.5', _customAbvController, keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        _buildRequestField('Not / Açıklama', 'Bardak boyutu veya özel içerik...', _customDescController, maxLines: 3),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('İsteği Gönder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _focusedCategoryId = null),
            child: Text('Vazgeç', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestField(String label, String hint, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF4B3126)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (_customNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Lütfen içecek adını girin");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('drink_requests').add({
        'name': _customNameController.text.trim(),
        'abv': double.tryParse(_customAbvController.text) ?? 0.0,
        'description': _customDescController.text.trim(),
        'requestedBy': user?.uid,
        'userEmail': user?.email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: "İsteğin başarıyla gönderildi! Onaylanınca eklenecek.",
        gravity: ToastGravity.CENTER,
      );

      // Reset
      _customNameController.clear();
      _customAbvController.clear();
      _customDescController.clear();
      
      setState(() {
        _focusedCategoryId = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Hata oluştu: $e");
    }
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade100, width: 2),
        ),
        child: Icon(icon, size: 24, color: AppColors.brandDark),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEREDESİN?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(AppIcons.marker, color: AppColors.primary, size: 20),
            labelText: 'Mekan İsmi',
            labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700),
            floatingLabelStyle: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            hintText: 'Örn: Kadıköy Bar, Ev...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTag(String top, String bottom, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlight ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Text(
            top,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isHighlight ? AppColors.primary : const Color(0xFF4B3126),
            ),
          ),
          Text(
            bottom,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFeelingScale() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NASIL HİSSEDİYORSUN?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFeelingOption(1, '🤢', 'Kötü'),
            _buildFeelingOption(3, '😕', 'Bayağı'),
            _buildFeelingOption(5, '😐', 'Normal'),
            _buildFeelingOption(8, '😊', 'İyi'),
            _buildFeelingOption(10, '🥳', 'Mükemmel'),
          ],
        ),
      ],
    );
  }

  Widget _buildFeelingOption(int value, String emoji, String label) {
    bool isSelected = _feelingScale == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _feelingScale = value);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? _accentColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _accentColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? _accentColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KISA BİR NOT?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Not Ekle',
            labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700),
            floatingLabelStyle: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            hintText: 'Mekanı veya anılarını kısaca not al...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    if (_focusedCategoryId == null) return const SizedBox.shrink();
    
    final totalScore = _getTotalScore();
    return AnimatedSlide(
      offset: _focusedCategoryId != null ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.grey.shade100, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TAHMİNİ PUAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _scoreAnimation,
                            builder: (context, child) {
                              final displayScore = _scoreAnimation.value;
                              return Text(
                                '+${displayScore.toStringAsFixed(1)} pt',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: _accentColor,
                                  letterSpacing: -1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedTime = DateTime.now());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.bolt, size: 18, color: _accentColor),
                              const SizedBox(width: 4),
                              const Text(
                                'ŞİMDİ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isButtonPressed = true),
                    onTapUp: (_) => setState(() => _isButtonPressed = false),
                    onTapCancel: () => setState(() => _isButtonPressed = false),
                    child: AnimatedScale(
                      scale: _isButtonPressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 6,
                            shadowColor: AppColors.primary.withOpacity(0.35),
                          ),
                          child: _isLoading
                              ? Shimmer.fromColors(
                                  baseColor: Colors.white.withOpacity(0.3),
                                  highlightColor: Colors.white,
                                  child: const Text(
                                    'KAYDET',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                                  ),
                                )
                              : const Text('KAYDET', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                        ),
                      ),
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
}
