import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../core/theme/app_decorations.dart';
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

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'beer':
        return AppColors.tertiary; // Yellow
      case 'wine':
        return AppColors.primary; // Coral Red
      case 'raki':
        return AppColors.secondary; // Teal
      case 'whiskey':
        return AppColors.primary; // Coral Red
      case 'vodka':
        return AppColors.secondary; // Teal
      case 'gin':
        return AppColors.secondary; // Teal
      case 'cocktail':
        return AppColors.primary; // Coral Red
      case 'champagne':
        return AppColors.tertiary; // Yellow
      default:
        return AppColors.primary;
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
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        titleSpacing: 24,
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _entranceController,
        child: Stack(
          children: [
            Container(color: AppColors.background),
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
                        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: (_selectedEntries.isEmpty && _focusedCategoryId == null)
                            ? _buildSearchBarWithGrid()
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
            if (_selectedEntries.isEmpty && _focusedCategoryId == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                   height: 100,
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       begin: Alignment.topCenter,
                       end: Alignment.bottomCenter,
                       colors: [
                         AppColors.background.withOpacity(0),
                         AppColors.background.withOpacity(0.8),
                         AppColors.background,
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

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
      ),
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
                Icon(UIcons.regularStraight.clock, size: 18, color: AppColors.textSecondary.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(_selectedTime),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800, 
                    fontSize: 13, 
                    color: AppColors.textPrimary
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 12, color: AppColors.textPrimary.withOpacity(0.1)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('d MMM', 'tr').format(_selectedTime),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800, 
                    fontSize: 13, 
                    color: AppColors.textPrimary
                  ),
                ),
              ],
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.1), width: 1.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tarih ve Saat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Picker
            SizedBox(
              height: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600, // Reduced bold
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: _selectedTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() => _selectedTime = newDateTime);
                  },
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16), // Reduced height
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'VAZGEÇ', 
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800, 
                          fontSize: 12, 
                          letterSpacing: 1.2
                        )
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 16), // Reduced height
                      ),
                      child: Text(
                        'DÜZENLE', 
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800, 
                          fontSize: 12, 
                          letterSpacing: 1.2
                        )
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          : Column(
              children: List.generate(filteredCategories.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 600),
                    child: SlideAnimation(
                      horizontalOffset: index.isEven ? -50.0 : 50.0,
                      child: FadeInAnimation(
                        child: _buildCategoryCard(filteredCategories[index]),
                      ),
                    ),
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80, // Horizontal strip height
          decoration: AppDecorations.glassCard(borderWidth: 1.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _focusedCategoryId = category['id'];
                  _selectedPortion = (category['portions'] as List).first;
                  final key = '${category['id']}|${_selectedPortion!['name']}';
                  _selectedEntries.clear();
                  _selectedEntries[key] = _quantity;
                });
                _updateScoreAnimation();
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  // Image with overflow on the left
                  SizedBox(
                    width: 100,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -20,
                          top: -10,
                          bottom: -10,
                          width: 110,
                          child: Hero(
                            tag: 'drink_grid_${category['id']}',
                            child: category['id'] == 'custom'
                                ? Center(
                                    child: Icon(
                                      UIcons.regularStraight.interrogation,
                                      size: 40,
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  )
                                : Image.asset(
                                    category['image'],
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.wine_bar, size: 30, color: AppColors.textTertiary.withOpacity(0.5)),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${(category['portions'] as List).length} seçenek',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Detail indicator
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.primary.withOpacity(0.6),
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
            decoration: AppDecorations.glassCard(borderRadius: 20, borderWidth: 1.2),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ne içmiştin?',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600),
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
            color: AppColors.textPrimary,
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
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 12, 
            color: AppColors.textSecondary, 
            letterSpacing: 1.2
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15), 
                    width: 1.5
                  ),
                ),
                child: _pickedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(UIcons.regularStraight.camera, color: AppColors.primary.withOpacity(0.4), size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Bir fotoğraf ekle',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.6), 
                              fontWeight: FontWeight.w700, 
                              fontSize: 13
                            ),
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
          ),
        ),
      ],
    );
  }
  // Code cleanup: removed obsolete UI helpers.

  Widget _buildFocusedDrinkView() {
    final category = _categories.firstWhere((c) => c['id'] == _focusedCategoryId);

    return Transform.translate(
      offset: Offset(0, _cardDragY),
      child: Column(
        children: [
          // Glass Handle with Drag Detector
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 0) {
                setState(() => _cardDragY += details.delta.dy);
              } else if (_cardDragY > 0) {
                setState(() => _cardDragY = (_cardDragY + details.delta.dy).clamp(0, double.infinity));
              }
            },
            onVerticalDragEnd: (details) {
              if (_cardDragY > 100) {
                _dismissFocused();
              } else {
                setState(() => _cardDragY = 0);
              }
            },
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                decoration: AppDecorations.glassCard(borderWidth: 1.5),
                child: Column(
                  children: [
                    if (category['id'] == 'custom')
                      _buildCustomRequestForm()
                    else ...[
                      // Floating Hero Image with subtle glow/shadow + Drag Detector
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (details) {
                           if (details.delta.dy > 0) {
                             setState(() => _cardDragY += details.delta.dy);
                           } else if (_cardDragY > 0) {
                             setState(() => _cardDragY = (_cardDragY + details.delta.dy).clamp(0, double.infinity));
                           }
                        },
                        onVerticalDragEnd: (details) {
                          if (_cardDragY > 100) {
                            _dismissFocused();
                          } else {
                            setState(() => _cardDragY = 0);
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.05),
                              ),
                            ),
                            Hero(
                              tag: 'drink_focused_${category['id']}',
                              child: ScaleTransition(
                                scale: _bounceController,
                                child: Image.asset(
                                  category['image'],
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.wine_bar, size: 100, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                        const SizedBox(height: 32),
                        
                        // Drink Identity
                        Text(
                          category['name'],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Portion Selector (Modern Segmented style)
                        if ((category['portions'] as List).length > 1) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.textPrimary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: AppColors.textPrimary.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ] : [],
                                    ),
                                    child: Text(
                                      p['name'],
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
          
                        // Elegant Quantity Stepper
                        Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildModernQtyBtn(Icons.remove, () {
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
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  '$_quantity',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              _buildModernQtyBtn(Icons.add, () {
                                setState(() {
                                  _quantity++;
                                  final key = '${category['id']}|${_selectedPortion!['name']}';
                                  _selectedEntries[key] = _quantity;
                                });
                                _updateScoreAnimation();
                              }),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Attributes Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPremiumTag('%${_selectedPortion!['abv']}', 'Alkol'),
                            const SizedBox(width: 8),
                            _buildPremiumTag('${_selectedPortion!['volume']}ml', 'Hacim'),
                          ],
                        ),
                        const SizedBox(height: 48),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: IconButton(
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
                                icon: const Icon(Icons.close_rounded),
                                color: AppColors.textSecondary,
                                iconSize: 28,
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: AppColors.primary.withOpacity(0.05),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: const Text(
                                    'Hemen Ekle',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
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
      );
  }

  Widget _buildCustomRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'İçecek Talebi Oluştur',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Aradığın içeceği bulamadın mı? Bilgileri gir, yönetici onaylayınca listeye eklensin!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildRequestField('İçecek Adı', 'Örn: Hibiscus Gin Tonic', _customNameController),
        const SizedBox(height: 20),
        _buildRequestField('Alkol Oranı (%)', 'Örn: 12.5', _customAbvController, keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        _buildRequestField('Not / Açıklama', 'Bardak boyutu veya özel içerik...', _customDescController, maxLines: 3),
        const SizedBox(height: 40),
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('İsteği Gönder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _focusedCategoryId = null),
            child: Text(
              'Vazgeç',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
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
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: AppColors.textPrimary.withOpacity(0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.2), fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget _buildModernQtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textPrimary.withOpacity(0.05),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 24),
        ),
      ),
    );
  }

  Widget _buildPremiumTag(String text, String label, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isHighlight ? AppColors.primary.withOpacity(0.12) : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlight ? AppColors.primary.withOpacity(0.25) : AppColors.primary.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isHighlight ? AppColors.textPrimary : AppColors.textPrimary.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isHighlight ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEREDESİN?',
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 12, 
            color: AppColors.textSecondary, 
            letterSpacing: 1.2
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _locationController,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(AppIcons.marker, color: AppColors.primary, size: 18),
                  labelText: 'Mekan İsmi',
                  labelStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontWeight: FontWeight.w700),
                  floatingLabelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  hintText: 'Mekan ismi veya bölge...',
                  hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.4), fontSize: 14),
                  filled: true,
                  fillColor: AppColors.primary.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildLocationActionBtn(
              UIcons.regularStraight.marker, 
              () {
                HapticFeedback.mediumImpact();
                // Future: Open Map Selection
              }
            ),
            const SizedBox(width: 8),
            _buildLocationActionBtn(
              Icons.gps_fixed_rounded, 
              () {
                HapticFeedback.mediumImpact();
                // Future: Get Current Location
              }
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationActionBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.primary),
        onPressed: onTap,
        padding: const EdgeInsets.all(12),
      ),
    );
  }




  Widget _buildFeelingScale() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NASIL HİSSEDİYORSUN?',
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 12, 
            color: AppColors.textSecondary, 
            letterSpacing: 1.2
          ),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
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
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 12, 
            color: AppColors.textSecondary, 
            letterSpacing: 1.2
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Not Ekle',
            labelStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontWeight: FontWeight.w700),
            floatingLabelStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            hintText: 'Mekanı veya anılarını kısaca not al...',
            hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.4), fontSize: 14),
            filled: true,
            fillColor: AppColors.primary.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBarWithGrid() {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 8),
        KeyedSubtree(key: const ValueKey('grid'), child: _buildCategoryGrid()),
      ],
    );
  }

  void _dismissFocused() {
    HapticFeedback.lightImpact();
    setState(() {
      _cardDragY = 0;
      _selectedEntries.clear();
      _focusedCategoryId = null;
      _selectedPortion = null;
      _quantity = 1;
    });
    _updateScoreAnimation();
  }
}
