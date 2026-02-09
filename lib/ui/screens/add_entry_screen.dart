import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import 'package:uicons/uicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/badge_service.dart';
import '../../data/models/badge_model.dart' as model;

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
        {'name': 'Standart (330ml)', 'variety': 'Standart', 'volume': 330, 'abv': 5.0},
        {'name': 'Standart (500ml)', 'variety': 'Standart', 'volume': 500, 'abv': 5.0},
        {'name': 'Filtresiz (330ml)', 'variety': 'Filtresiz', 'volume': 330, 'abv': 6.0},
        {'name': 'Filtresiz (500ml)', 'variety': 'Filtresiz', 'volume': 500, 'abv': 6.0},
        {'name': 'Strong (330ml)', 'variety': 'Strong', 'volume': 330, 'abv': 8.5},
        {'name': 'Strong (500ml)', 'variety': 'Strong', 'volume': 500, 'abv': 8.5},
      ],
    },
    {
      'id': 'wine',
      'name': 'Şarap',
      'emoji': '🍷',
      'image': 'assets/images/drinks/wine.png',
      'portions': [
        {'name': 'Kırmızı (150ml)', 'variety': 'Kırmızı', 'volume': 150, 'abv': 13.0},
        {'name': 'Kırmızı (200ml)', 'variety': 'Kırmızı', 'volume': 200, 'abv': 13.0},
        {'name': 'Beyaz (150ml)', 'variety': 'Beyaz', 'volume': 150, 'abv': 11.0},
        {'name': 'Beyaz (200ml)', 'variety': 'Beyaz', 'volume': 200, 'abv': 11.0},
        {'name': 'Rosé (150ml)', 'variety': 'Rosé', 'volume': 150, 'abv': 12.0},
        {'name': 'Rosé (200ml)', 'variety': 'Rosé', 'volume': 200, 'abv': 12.0},
      ],
    },
    {
      'id': 'raki',
      'name': 'Rakı',
      'emoji': '🥃',
      'image': 'assets/images/drinks/raki.png',
      'portions': [
        {'name': 'Tek (50ml)', 'volume': 50, 'abv': 45.0},
        {'name': 'Duble (100ml)', 'volume': 100, 'abv': 45.0},
      ],
    },
    {
      'id': 'whiskey',
      'name': 'Viski',
      'emoji': '🥃',
      'image': 'assets/images/drinks/whiskey.png',
      'portions': [
        {'name': 'Tek (40ml)', 'volume': 40, 'abv': 40.0},
        {'name': 'Duble (80ml)', 'volume': 80, 'abv': 40.0},
      ],
    },
    {
      'id': 'vodka',
      'name': 'Votka',
      'emoji': '🍸',
      'image': 'assets/images/drinks/vodka_enerji.png',
      'portions': [
        {'name': 'Shot (40ml)', 'volume': 40, 'abv': 40.0},
        {'name': 'Duble (80ml)', 'volume': 80, 'abv': 40.0},
        {'name': 'Enerji (200ml)', 'volume': 200, 'abv': 10.0},
        {'name': 'Meyve Suyu (200ml)', 'volume': 200, 'abv': 8.0},
      ],
    },
    {
      'id': 'gin',
      'name': 'Cin',
      'emoji': '�',
      'image': 'assets/images/drinks/gin.png',
      'portions': [
        {'name': 'Shot (40ml)', 'volume': 40, 'abv': 40.0},
        {'name': 'Gin Tonik (250ml)', 'volume': 250, 'abv': 10.0},
      ],
    },
    {
      'id': 'tequila',
      'name': 'Tekila',
      'emoji': '🌵',
      'image': 'assets/images/drinks/tequila.png',
      'portions': [
        {'name': 'Shot (40ml)', 'volume': 40, 'abv': 40.0},
        {'name': 'Duble (80ml)', 'volume': 80, 'abv': 40.0},
      ],
    },
    {
      'id': 'rum',
      'name': 'Rom',
      'emoji': '🥃',
      'image': 'assets/images/drinks/rum.png',
      'portions': [
        {'name': 'Shot (40ml)', 'volume': 40, 'abv': 40.0},
        {'name': 'Rom Kola (250ml)', 'volume': 250, 'abv': 10.0},
      ],
    },
    {
      'id': 'cocktail',
      'name': 'Kokteyl',
      'emoji': '�',
      'image': 'assets/images/drinks/kokteyl.png',
      'portions': [
        {'name': 'AMF', 'volume': 300, 'abv': 26.0},
        {'name': 'Long Island', 'volume': 300, 'abv': 25.0},
        {'name': 'Zombie', 'volume': 300, 'abv': 22.0},
        {'name': 'Margarita', 'volume': 200, 'abv': 17.0},
        {'name': 'Mojito', 'volume': 300, 'abv': 12.0},
        {'name': 'Old Fashioned', 'volume': 100, 'abv': 35.0},
        {'name': 'Negroni', 'volume': 100, 'abv': 26.0},
        {'name': 'Martini', 'volume': 120, 'abv': 32.0},
        {'name': 'Pina Colada', 'volume': 300, 'abv': 13.0},
        {'name': 'Moscow Mule', 'volume': 250, 'abv': 10.0},
        {'name': 'Cosmopolitan', 'volume': 120, 'abv': 20.0},
        {'name': 'Bloody Mary', 'volume': 200, 'abv': 14.0},
        {'name': 'Manhattan', 'volume': 100, 'abv': 30.0},
        {'name': 'Daiquiri', 'volume': 120, 'abv': 22.0},
        {'name': 'Screwdriver', 'volume': 200, 'abv': 10.0},
        {'name': 'Sex on the Beach', 'volume': 250, 'abv': 13.0},
        {'name': 'Tequila Sunrise', 'volume': 250, 'abv': 12.0},
        {'name': 'White Russian', 'volume': 180, 'abv': 15.0},
        {'name': 'Godfather', 'volume': 100, 'abv': 34.0},
        {'name': 'Rusty Nail', 'volume': 100, 'abv': 35.0},
        {'name': 'Sazerac', 'volume': 100, 'abv': 35.0},
        {'name': 'Aperol Spritz', 'volume': 200, 'abv': 9.0},
        {'name': 'Campari Spritz', 'volume': 200, 'abv': 10.0},
        {'name': 'Hugo', 'volume': 200, 'abv': 8.0},
        {'name': 'Americano', 'volume': 180, 'abv': 12.0},
        {'name': 'Negroni Sbagliato', 'volume': 180, 'abv': 14.0},
        {'name': 'Mimosa', 'volume': 150, 'abv': 6.0},
        {'name': 'Bellini', 'volume': 150, 'abv': 7.0},
        {'name': 'Kir Royale', 'volume': 150, 'abv': 11.0},
        {'name': 'Kamikaze', 'volume': 60, 'abv': 30.0},
        {'name': 'Irish Car Bomb', 'volume': 300, 'abv': 12.0},
      ],
    },
    {
      'id': 'liqueur',
      'name': 'Likör',
      'emoji': '🍹',
      'image': 'assets/images/drinks/liqueur.png',
      'portions': [
        {'name': 'Kremsi (Baileys)', 'volume': 50, 'abv': 17.0},
        {'name': 'Bitki (Jäger)', 'volume': 40, 'abv': 35.0},
        {'name': 'Meyve (Limoncello)', 'volume': 40, 'abv': 30.0},
        {'name': 'Anason (Sambuca)', 'volume': 40, 'abv': 40.0},
      ],
    },
    {
      'id': 'custom',
      'name': 'Kendin Yarat',
      'emoji': '✨',
      'image': 'assets/images/drinks/custom.png',
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
  String? _selectedVarietyName;
  Map<String, dynamic>? _selectedPortion;
  
  // Modern Animations State
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  double _previousScore = 0.0;
  
  bool _isButtonPressed = false;
  bool _showLocalToast = false;
  double _toastAPS = 0.0;
  bool _showLocalBadge = false;
  model.Badge? _activeBadge;
  Color? _activeBadgeColor;

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
      case 'rum':
        return AppColors.primary; // Coral Red
      case 'vodka':
      case 'gin':
      case 'tequila':
        return AppColors.secondary; // Teal
      case 'cocktail':
      case 'liqueur':
        return AppColors.primary; // Coral Red
      case 'champagne':
        return AppColors.tertiary; // Yellow
      default:
        return AppColors.primary;
    }
  }


  final ScrollController _scrollController = ScrollController();
  final ScrollController _sheetScrollController = ScrollController();
  double _scrollOffset = 0;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final List<Map<String, dynamic>> _timeShortcuts = [
    {'label': 'Şimdi', 'value': 0},
    {'label': '-10dk', 'value': 10},
    {'label': '-30dk', 'value': 30},
    {'label': '-1sa', 'value': 60},
    {'label': 'Özel', 'value': -1},
  ];
  late AnimationController _guidanceController;
  late Animation<double> _guidanceArrowAnimation;

  // Sheet Animation State
  double _sheetDragY = 0;
  bool _isSheetClosing = false;
  XFile? _tempPickedImage;
  String? _tempLocationName;
  String? _tempNote;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!mounted) return;
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

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _locationController.dispose();
    _customNameController.dispose();
    _customAbvController.dispose();
    _customDescController.dispose();
    _scrollController.dispose();
    _sheetScrollController.dispose();
    _animationController.dispose();
    _entranceController.dispose();
    _guidanceController.dispose();
    _scoreAnimationController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- Logic ---
  double _calculateScore(int volume, double abv) {
    return (volume * abv) / 100;
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
      _customNameController.clear();
      _customAbvController.clear();
      _customDescController.clear();
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
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Hızlı içim uyarısı kontrolü
      final now = DateTime.now();
      final fiveMinsAgo = now.subtract(const Duration(minutes: 5));
      final oneMinAgo = now.subtract(const Duration(minutes: 1));

      final recentEntries = await FirebaseFirestore.instance
          .collection('entries')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinsAgo))
          .get();

      final entriesCount5Min = recentEntries.docs.length;
      final entriesCount1Min = recentEntries.docs.where((doc) {
        final ts = doc['timestamp'] as Timestamp;
        return ts.toDate().isAfter(oneMinAgo);
      }).length;

      if (entriesCount1Min >= 3 || entriesCount5Min >= 5) {
        bool? proceed = await showDialog<bool>(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              backgroundColor: AppColors.background.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(' Biraz hızlı gitmiyor musun? 🏃‍♂️💨', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: const Text(
                'Çok kısa sürede çok fazla içecek kaydettin. Her şey yolunda mı?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Durayım', style: TextStyle(color: Colors.white30)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Devam Et', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
        
        if (proceed != true) return;
      }

      setState(() => _isLoading = true);
      
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
        // Check for new badges
        final unlockedBadges = await BadgeService.checkBadges(user.uid);
        if (unlockedBadges.isNotEmpty) {
          for (var badge in unlockedBadges) {
            if (!mounted) break;
            await _showBadgeNotification(badge);
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }

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

  Future<void> _showBadgeNotification(model.Badge badge) async {
    if (!mounted) return;
    final color = Color(int.parse(badge.colorHex.replaceFirst('#', '0xFF')));
    setState(() {
      _activeBadge = badge;
      _activeBadgeColor = color;
      _showLocalBadge = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusedCategoryId != null;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Index 0: Main List View (Always present, dimmed when focused)
          Opacity(
            opacity: isFocused ? 0.4 : 1.0,
            child: _buildMainListView(),
          ),
          
          // Title Bar (Overlay on list view)
          if (!isFocused)
            _buildFloatingTitleBar(),

          // Dark overlay when sheet is open to prevent clicks on list
          if (isFocused)
            GestureDetector(
              onTap: () => _closeSheet(),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),

          // Detail View Overlay (Draggable Sheet)
          if (isFocused)
            _buildFocusedSheet(),

          // Local Success Toast
          if (_showLocalToast)
            _SuccessToastWidget(
              aps: _toastAPS,
              onDismiss: () => setState(() => _showLocalToast = false),
            ),
            
          // Local Badge Notification
          if (_showLocalBadge && _activeBadge != null)
            _BadgeNotificationWidget(
              badgeSource: _activeBadge!,
              color: _activeBadgeColor ?? Colors.orange,
              onDismiss: () => setState(() => _showLocalBadge = false),
            ),
        ],
      ),
    );
  }

  Widget _buildMainListView() {
    return FadeTransition(
      opacity: _entranceController,
      child: CustomScrollView(
        key: const PageStorageKey('main_list'),
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _buildCategoryGrid()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildFloatingTitleBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).padding.top + 60,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: AppColors.background.withOpacity(0.8),
            child: Center(
              child: Text(
                'İçecek Ekle',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessToast(double aps) {
    if (!mounted) return;
    setState(() {
      _toastAPS = aps;
      _showLocalToast = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showLocalToast = false);
      }
    });
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
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
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
    final bool isCustom = category['id'] == 'custom';
    final int portionsCount = (category['portions'] as List).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _focusedCategoryId = category['id'];
              _quantity = 1;
              _selectedVarietyName = null;
              _selectedPortion = null;
              _sheetDragY = 0;
              _selectedTime = DateTime.now(); // Reset to now on new selection
            });
            _animationController.forward(from: 0);
            _bounceController.forward(from: 0);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFFFF8902).withOpacity(0.1),
          highlightColor: const Color(0xFFFF8902).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Emoji container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242938),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      category['emoji'],
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'],
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$portionsCount seçenek',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFFF8902),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'İçecek ara...',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: Color(0xFFFF8902),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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

  Widget _buildFocusedSheet() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Animation drives from 0.0 (bottom) to 1.0 (top)
        // sheetDragY is added on top of the animation offset
        final double screenHeight = MediaQuery.of(context).size.height;
        final double topMargin = 80.0; // Margin from top when fully opened
        final double animationOffset = screenHeight - (screenHeight - topMargin) * _animationController.value;
        final double totalOffset = (animationOffset + _sheetDragY).clamp(0.0, screenHeight);

        return Positioned(
          top: totalOffset,
          left: 0,
          right: 0,
          bottom: -totalOffset,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 0 || _sheetDragY > 0) {
                setState(() {
                  _sheetDragY = (_sheetDragY + details.delta.dy).clamp(0, screenHeight);
                });
              }
            },
            onVerticalDragEnd: (details) {
              if (_sheetDragY > 100 || details.velocity.pixelsPerSecond.dy > 500) {
                _closeSheet();
              } else {
                setState(() => _sheetDragY = 0);
              }
            },
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 80,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(child: _buildFocusedDrinkView()),
          ],
        ),
      ),
    );
  }

  void _closeSheet() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _focusedCategoryId = null;
          _sheetDragY = 0;
        });
      }
    });
  }

  // This method is assumed to be where the change for _saveDetailed should occur.
  // As _saveDetailed was not provided, this is a placeholder for where it would be.
  // If _saveDetailed existed and had a hard state reset, it would be replaced with _closeSheet().
  // Example of how _saveDetailed might be changed:
  /*
  Future<void> _saveDetailed() async {
    // ... existing logic ...
    // Instead of:
    // setState(() {
    //   _focusedCategoryId = null;
    //   _sheetDragY = 0;
    // });
    // Call:
    _closeSheet();
    // ... rest of existing logic ...
  }
  */

  Widget _buildFocusedDrinkView() {
    if (_focusedCategoryId == null) return const SizedBox.shrink();
    if (_focusedCategoryId == 'custom') return _buildCustomFocusedView();
    
    final category = _categories.firstWhere((c) => c['id'] == _focusedCategoryId);
    
    // Calculate APS dynamically for display
    final currentPortion = _selectedPortion;
    final double calculatedAPS = currentPortion != null ? (currentPortion['volume'] * currentPortion['abv'] / 100.0) * _quantity : 0.0;

    final categoryPortions = category['portions'] as List;
    final varieties = categoryPortions.map((p) => p['variety']).where((v) => v != null).toSet();
    final hasVarieties = varieties.length > 1;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              // If at top and dragging down, transfer scroll to sheet drag
              if (notification.metrics.pixels <= 0 && notification.scrollDelta! < 0) {
                setState(() {
                  _sheetDragY = (_sheetDragY - notification.scrollDelta!).clamp(0, MediaQuery.of(context).size.height);
                });
              } 
              // If we have some sheet drag and user is dragging up, reduce sheet drag first
              else if (_sheetDragY > 0 && notification.scrollDelta! > 0) {
                setState(() {
                  _sheetDragY = (_sheetDragY - notification.scrollDelta!).clamp(0, MediaQuery.of(context).size.height);
                });
              }
            } else if (notification is ScrollEndNotification) {
              if (_sheetDragY > 100) {
                _closeSheet();
              } else if (_sheetDragY > 0) {
                setState(() => _sheetDragY = 0);
              }
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _sheetScrollController,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 160, // Increased bottom padding for shelf visibility
            left: 24,
            right: 24,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
          // Header Word
          Text(
            category['name'],
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
          
          // --- Header Emoji + Glow ---
                SizedBox(
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF8902).withOpacity(0.35),
                              const Color(0xFFFF8902).withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Pulsing Emoji
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Text(
                          category['emoji'],
                          style: const TextStyle(fontSize: 140),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  category['name'],
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 32),

                if (hasVarieties) ...[
                  _buildVarietyToggle(category),
                  const SizedBox(height: 32),
                ],

                // --- STEP 2: Size Selection ---
                // Show if: No varieties OR variety is selected
                if (!hasVarieties || _selectedVarietyName != null) ...[
                  _buildPortionToggle(category),
                  const SizedBox(height: 32),
                ],

                  // --- STEP 3: Quantity & Final Controls ---
                  if (currentPortion != null) ...[
                    // --- İçilme Zamanı ---
                    _buildTimeSelector(),
                    const SizedBox(height: 32),

                    // --- Adet Seçimi (Counter) ---
                  _buildCounter(),
                  const SizedBox(height: 40),

                  // --- Info Cards ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          '%${currentPortion['abv'].toStringAsFixed(1)}',
                          'ALKOL',
                          const Color(0xFFFF8902),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          '${currentPortion['volume']}ml',
                          'HACIM',
                          const Color(0xFF4ECDC4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- APS Gösterimi ---
                  _buildAPSDisplay(calculatedAPS),
                  const SizedBox(height: 32),

                  // --- Opsiyonel Eklemeler ---
                  _buildOptionalAdditions(),
                ] else ...[
                  // Guiding message based on current step
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          _selectedVarietyName == null ? Icons.tune_rounded : Icons.straighten_rounded,
                          color: Colors.white.withOpacity(0.2),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (hasVarieties && _selectedVarietyName == null)
                              ? 'Lütfen önce çeşit seçin' 
                              : 'Lütfen miktar seçin',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

          // --- Bottom Action Button (Only show if selection is made) ---
          if (currentPortion != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 110,
              left: 24,
              right: 24,
              child: _buildPrimaryActionButton(calculatedAPS),
            ),
        ],
    );
  }

  Widget _buildCustomFocusedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => setState(() => _focusedCategoryId = null),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text('Kendin Yarat', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildCustomRequestForm(),
      ),
    );
  }

  Widget _buildVarietyToggle(Map<String, dynamic> category) {
    final portions = category['portions'] as List;
    final varieties = portions
        .map((p) => p['variety'] as String?)
        .where((v) => v != null)
        .toSet()
        .toList();

    if (varieties.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: varieties.map<Widget>((v) {
          final isSelected = _selectedVarietyName == v;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedVarietyName = v;
                _selectedPortion = null; // Reset portion when variety changes
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)])
                    : null,
                color: isSelected ? null : const Color(0xFF242938),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF8902).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                v!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPortionToggle(Map<String, dynamic> category) {
    var portions = category['portions'] as List;
    
    // Filter by variety if selected
    if (_selectedVarietyName != null) {
      portions = portions.where((p) => p['variety'] == _selectedVarietyName).toList();
    }

    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: portions.map<Widget>((p) {
          final isSelected = _selectedPortion?['name'] == p['name'];
          // Size label (remove variety name if present)
          String sizeLabel = p['name'].toString();
          if (_selectedVarietyName != null) {
             sizeLabel = sizeLabel.replaceAll(_selectedVarietyName!, '').replaceAll('(', '').replaceAll(')', '').trim();
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedPortion = p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)])
                    : null,
                color: isSelected ? null : const Color(0xFF242938),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF8902).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                sizeLabel,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İÇİLME ZAMANI',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _timeShortcuts.map((shortcut) {
              final int value = shortcut['value'];
              final String label = shortcut['label'];
              
              // Calculate if this shortcut represents current _selectedTime
              bool isSelected = false;
              if (value == 0) {
                // "Şimdi" is selected if time is close to now
                isSelected = DateTime.now().difference(_selectedTime).inMinutes.abs() < 1;
              } else if (value == -1) {
                // "Özel" is selected if it doesn't match shortcuts
                isSelected = !_timeShortcuts.any((s) => 
                  s['value'] > 0 && 
                  DateTime.now().subtract(Duration(minutes: s['value'])).difference(_selectedTime).inMinutes.abs() < 2
                ) && DateTime.now().difference(_selectedTime).inMinutes.abs() >= 1;
              } else {
                isSelected = DateTime.now().subtract(Duration(minutes: value)).difference(_selectedTime).inMinutes.abs() < 2;
              }

              return GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (value == -1) {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedTime),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFFF8902),
                              onPrimary: Colors.white,
                              surface: Color(0xFF1A1F2E),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      setState(() {
                        _selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                      });
                    }
                  } else {
                    setState(() {
                      _selectedTime = DateTime.now().subtract(Duration(minutes: value));
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF8902).withOpacity(0.15) : const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF8902).withOpacity(0.5) : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFFF8902), size: 14),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        value == -1 && isSelected 
                          ? DateFormat('HH:mm').format(_selectedTime) 
                          : label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFFFF8902) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF242938),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.remove,
              color: _quantity > 1 ? Colors.white : const Color(0xFF6B7785),
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 40),
        Container(
          width: 80,
          alignment: Alignment.center,
          child: Text(
            '$_quantity',
            style: GoogleFonts.inter(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: () {
             HapticFeedback.lightImpact();
             setState(() => _quantity++);
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8902).withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFCBD5E1),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPSDisplay(double aps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF8902).withOpacity(0.15),
            const Color(0xFFEE5A6F).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8902).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Toplam APS',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)],
            ).createShader(bounds),
            child: Text(
              aps.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalAdditions() {
    return Column(
      children: [
        _buildAdditionItem(
          icon: Icons.camera_alt,
          label: _tempPickedImage != null ? 'Fotoğraf eklendi ✓' : 'Fotoğraf Ekle',
          isActive: _tempPickedImage != null,
          color: const Color(0xFFFF8902),
          onTap: () async {
            final picker = ImagePicker();
            final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
            if (photo != null) setState(() => _tempPickedImage = photo);
          },
        ),
        const SizedBox(height: 12),
        _buildAdditionItem(
          icon: Icons.location_on,
          label: _tempLocationName ?? 'Konum Ekle',
          isActive: _tempLocationName != null,
          color: const Color(0xFF4ECDC4),
          onTap: () async {
            final String? selectedLocation = await context.push('/location-picker');
            if (selectedLocation != null) {
              setState(() => _tempLocationName = selectedLocation);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildAdditionItem(
          icon: Icons.edit_note,
          label: _tempNote != null ? 'Not: $_tempNote' : 'Not Ekle',
          isActive: _tempNote != null,
          color: const Color(0xFFFFE66D),
          onTap: () async {
            final controller = TextEditingController(text: _tempNote);
            final String? note = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1F2E),
                title: const Text('Not Ekle', style: TextStyle(color: Colors.white)),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'İçecek hakkında notun...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                  TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Kaydet')),
                ],
              ),
            );
            if (note != null) setState(() => _tempNote = note);
          },
        ),
      ],
    );
  }

  Widget _buildAdditionItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Increased vertical padding
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A1F2E) : const Color(0xFF242938).withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
            style: isActive ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.15) : const Color(0xFF242938),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isActive ? color : const Color(0xFF94A3B8), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16, // Increased font size
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ),
            if (isActive) const Icon(Icons.check_circle, color: Color(0xFF4ECDC4), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton(double aps) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _saveDetailed(aps),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8902).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  'Hemen Ekle',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveDetailed(double totalAPS) async {
    final category = _categories.firstWhere((c) => c['id'] == _focusedCategoryId);
    final currentPortion = _selectedPortion ?? category['portions'][0];
    
    _selectedEntries.clear();
    final key = '$_focusedCategoryId|${currentPortion['name']}';
    _selectedEntries[key] = _quantity;
    
    if (_tempNote != null) _noteController.text = _tempNote!;
    if (_tempLocationName != null) _locationController.text = _tempLocationName!;
    if (_tempPickedImage != null) _pickedImage = _tempPickedImage;

    await _save();
    if (!_isLoading) {
       _showSuccessToast(totalAPS);
       _closeSheet(); // Smoothly close the sheet after saving
    }
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
              color: Colors.white,
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
              color: Colors.white70,
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
                color: const Color(0xFFFF8902).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8902),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('İsteği Gönder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
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
            color: Colors.white30,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
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

  Widget _buildSearchBarWithGrid() {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 8),
        KeyedSubtree(key: const ValueKey('grid'), child: _buildCategoryGrid()),
      ],
    );
  }
}

class _BadgeNotificationWidget extends StatefulWidget {
  final model.Badge badgeSource;
  final Color color;
  final VoidCallback onDismiss;

  const _BadgeNotificationWidget({
    required this.badgeSource,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_BadgeNotificationWidget> createState() => _BadgeNotificationWidgetState();
}

class _BadgeNotificationWidgetState extends State<_BadgeNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;
  bool _isRemoved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 4), _handleDismiss);
  }

  void _handleDismiss() {
    if (_isRemoved) return;
    if (!mounted) return;
    
    _controller.reverse().then((value) {
      if (!_isRemoved && mounted) {
        _isRemoved = true;
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Material(
              color: Colors.transparent,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.horizontal,
                onDismissed: (_) {
                  _isRemoved = true;
                  widget.onDismiss();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: widget.color.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: widget.color.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  widget.badgeSource.icon,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ROZET KAZANILDI! 🏆',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: widget.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    widget.badgeSource.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessToastWidget extends StatefulWidget {
  final double aps;
  final VoidCallback onDismiss;

  const _SuccessToastWidget({required this.aps, required this.onDismiss});

  @override
  State<_SuccessToastWidget> createState() => _SuccessToastWidgetState();
}

class _SuccessToastWidgetState extends State<_SuccessToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Offset _randomDrift;

  @override
  void initState() {
    super.initState();
    // Random drift direction for the fade-out
    final random = Random();
    _randomDrift = Offset(
      (random.nextDouble() - 0.5) * 200, // dx: -100 to 100
      (random.nextDouble() - 0.5) * 200, // dy: -100 to 100
    );

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Entrance: Drop from top (-100) to center (0)
    // Drift: Move to random offset during late fade
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, -300), end: Offset.zero)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: _randomDrift)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 30,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _slideAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'İÇECEK EKLENDİ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)],
                        ).createShader(bounds),
                        child: Text(
                          '+${widget.aps.toStringAsFixed(1)} APS',
                          style: GoogleFonts.inter(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFF8902).withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
