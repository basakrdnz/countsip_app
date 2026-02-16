import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/services/navigation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import 'package:uicons/uicons.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/dual_camera_widget.dart';
import '../../core/services/badge_service.dart';
import '../../data/models/badge_model.dart' as model;
import '../../core/services/preferences_service.dart';
import '../../data/drink_categories.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> with TickerProviderStateMixin {
  // Drink data is imported from lib/data/drink_categories.dart
  static const List<Map<String, dynamic>> _categories = drinkCategories;

  // --- State ---
  String? _selectedPortionKey; // Combined key: categoryId|portionName
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
  double _screenDragY = 0; // State for whole screen dismissal
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  bool _isSearchFocused = false;
  
  // Custom Drink Request Controllers
  final _customNameController = TextEditingController();
  final _customAbvController = TextEditingController();
  final _customVolumeController = TextEditingController(); // Added
  final _customDescController = TextEditingController();
  int _currentRequestStep = 0; // Added for Wizard
  
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

  // --- Smart Search Helper ---
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((curr, next) => curr < next ? curr : next);
      }
      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  List<Map<String, dynamic>> _getSmartSuggestions(String query) {
    if (query.length < 2) return [];
    
    final List<(Map<String, dynamic> cat, int score)> scored = [];
    final lowerQuery = query.toLowerCase();

    for (var cat in _categories) {
      final catName = cat['name'].toString().toLowerCase();
      final distance = _levenshtein(lowerQuery, catName);
      
      // Calculate similarity score (0.0 to 1.0)
      final maxLength = max(lowerQuery.length, catName.length);
      final similarity = 1.0 - (distance / maxLength);

      if (similarity > 0.4) { // Threshold for "close enough"
        scored.add((cat, (similarity * 100).toInt()));
      }
      
      // Also check portions
      if (cat['portions'] != null) {
        for (var p in cat['portions'] as List<dynamic>) {
          final pName = (p['name'] ?? '').toString().toLowerCase();
          final pVariety = (p['variety'] ?? '').toString().toLowerCase();
          
          final dName = _levenshtein(lowerQuery, pName);
          final dVariety = _levenshtein(lowerQuery, pVariety);
          
          final sName = 1.0 - (dName / max(lowerQuery.length, pName.length));
          final sVariety = 1.0 - (dVariety / max(lowerQuery.length, pVariety.length));
          
          final bestSim = max(sName, sVariety);
          if (bestSim > 0.4) {
             scored.add(({
               ...cat, 
               'displayName': "${cat['name']} - ${p['name']}",
               'isPortionMatch': true,
               'selectedPortion': p,
             }, (bestSim * 100).toInt()));
          }
        }
      }
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((s) => s.$1).take(3).toList();
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
    _searchFocusNode.addListener(_onSearchFocusChange);
    _loadSearchHistory();
    _scrollController.addListener(() {
      if (!mounted) return;
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    
    // Listen for navigation events from Home Screen
    NavigationService.instance.selectedCategoryNotifier.addListener(_handleNavigationEvent);
    // Check if there's already a value (in case it was set before this screen built)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigationEvent();
    });
  }

  void _handleNavigationEvent() {
    final categoryId = NavigationService.instance.selectedCategoryNotifier.value;
    if (categoryId != null && mounted) {
      debugPrint('AddEntryScreen: Received navigation event for $categoryId');
      // Clear the value so it doesn't re-trigger
      NavigationService.instance.selectedCategoryNotifier.value = null;
      
      final category = _categories.firstWhere(
        (c) => c['id'] == categoryId, 
        orElse: () => {}, 
      );
      
      if (category.isNotEmpty) {
        // Reset state and select category
        setState(() {
          _focusedCategoryId = categoryId;
          _quantity = 1;
          _selectedVarietyName = null;
          _selectedPortion = null;
          _sheetDragY = 0;
          _selectedTime = DateTime.now(); // Reset to now
        });
        _animationController.forward(from: 0);
      }
    }
    
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
    _searchController.dispose();
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = PreferencesService.instance.getSearchHistory();
    setState(() {
      _recentSearches = history;
    });
  }

  Future<void> _addToHistory(String query) async {
    await PreferencesService.instance.addToSearchHistory(query);
    _loadSearchHistory();
  }

  Future<void> _removeFromHistory(String query) async {
    await PreferencesService.instance.removeFromSearchHistory(query);
    _loadSearchHistory();
  }

  Future<void> _clearHistory() async {
    await PreferencesService.instance.clearSearchHistory();
    setState(() {
      _recentSearches = [];
    });
  }

  // --- Logic ---
  double _calculateScore(int volume, double abv) {
    return (volume * abv) / 100;
  }

  double _getTotalScore() {
    if (_selectedPortion == null) return 0.0;
    return _calculateScore(_selectedPortion!['volume'], _selectedPortion!['abv']) * _quantity;
  }

  int _getTotalCount() {
    return _selectedPortion != null ? _quantity : 0;
  }


  void _resetForm() {
    setState(() {
      _selectedPortionKey = null;
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
    if (_selectedPortion == null) {
      HapticFeedback.vibrate();
      Fluttertoast.showToast(
        msg: 'Lütfen bir içecek seçin',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Step 1: Checking daily entries...');
      int entriesCountToday = 0;
      try {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        
        final todayEntries = await FirebaseFirestore.instance
            .collection('entries')
            .where('userId', isEqualTo: user.uid)
            .where('timestamp', isGreaterThan: Timestamp.fromDate(todayStart))
            .get();

        entriesCountToday = todayEntries.docs.length;
      } catch (e) {
        debugPrint('Daily entries check skipped: $e');
      }

      final totalScore = _calculateScore(_selectedPortion!['volume'], _selectedPortion!['abv']);
      final category = _categories.firstWhere((c) => c['id'] == _focusedCategoryId);
      final portionName = _selectedPortion!['name'];

      String? imageUrl;
      if (_pickedImage != null) {
        debugPrint('Step 2: Uploading image to Storage...');
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('drink_images')
              .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          final uploadTask = storageRef.putFile(File(_pickedImage!.path));
          final snapshot = await uploadTask.timeout(const Duration(seconds: 15));
          imageUrl = await snapshot.ref.getDownloadURL();
          debugPrint('Image uploaded successfully: $imageUrl');
        } catch (e) {
          debugPrint('Error uploading image (skipping image): $e');
        }
      }

      debugPrint('Step 3: Committing Firestore batch...');
      final batch = FirebaseFirestore.instance.batch();
      final entryRef = FirebaseFirestore.instance.collection('entries').doc();
      
      batch.set(entryRef, {
        'userId': user.uid,
        'drinkType': category['name'],
        'drinkEmoji': category['emoji'],
        'portion': portionName,
        'volume': _selectedPortion!['volume'],
        'abv': _selectedPortion!['abv'],
        'quantity': 1,
        'points': totalScore,
        'note': _noteController.text.trim(),
        'locationName': _locationController.text.trim(),
        'intoxicationLevel': _feelingScale,
        'timestamp': Timestamp.fromDate(_selectedTime),
        'createdAt': FieldValue.serverTimestamp(),
        'hasImage': imageUrl != null,
        'imageUrl': imageUrl,
        'imagePath': _pickedImage?.path,
        'taggedFriendIds': _taggedFriendIds,
      });

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {
          'totalPoints': FieldValue.increment(totalScore),
          'totalDrinks': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('Batch committed successfully.');

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSuccessToast(totalScore);
        _runBackgroundTasks(user.uid, entriesCountToday);
        _resetForm();
      }
    } catch (e) {
      debugPrint('Critical error saving entry: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Kaydetme sırasında bir hata oluştu: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runBackgroundTasks(String userId, int entriesCountToday) async {
    try {
      // 1. Badge Check
      final unlockedBadges = await BadgeService.checkBadges(userId);
      if (unlockedBadges.isNotEmpty && mounted) {
        for (var badge in unlockedBadges) {
          if (!mounted) break;
          await _showBadgeNotification(badge);
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // 2. Water Reminder
      if (entriesCountToday >= 2) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'showWaterReminder': true,
        });
      }
    } catch (e) {
      debugPrint('Background tasks error: $e');
    }
  }

  void _showWaterReminder() {
    // Top banner reminder logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(child: Text('Dengeyi hatırla! Bir bardak su içmeye ne dersin? 💧')),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 20,
          right: 20,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  final List<String> _taggedFriendIds = [];

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
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Only trigger if we are at the top of the scroll or pulling down
          if (!isFocused && (_scrollController.offset <= 0 || _screenDragY > 0)) {
            setState(() {
              _screenDragY = (_screenDragY + details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height);
            });
          }
        },
        onVerticalDragEnd: (details) {
          if (_screenDragY > 150 || details.velocity.pixelsPerSecond.dy > 800) {
            Navigator.pop(context);
          } else {
            setState(() {
              _screenDragY = 0;
            });
          }
        },
        child: Transform.translate(
          offset: Offset(0, _screenDragY),
          child: Container(
            color: AppColors.background,
            child: Scaffold(
              backgroundColor: Colors.transparent, // Let Container handle it
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
        
                  // Search Suggestions & History Overlay
                  if (_isSearchFocused && !isFocused)
                    _buildSearchOverlay(),
        
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainListView() {
    return FadeTransition(
      opacity: _entranceController,
      child: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          // Reset form and clear search
          _resetForm();
          setState(() {
            _searchQuery = '';
          });
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        edgeOffset: 120, // Start below title bar
        child: CustomScrollView(
          key: const PageStorageKey('main_list'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 150)),
            SliverToBoxAdapter(child: _buildSearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            if (_searchQuery.isEmpty) ...[
               SliverToBoxAdapter(child: _buildSuggestionsSection()),
               const SliverToBoxAdapter(child: SizedBox(height: 24)),
               SliverToBoxAdapter(
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                   child: Row(
                     children: [
                       Container(
                         width: 3,
                         height: 16,
                         decoration: BoxDecoration(
                           color: const Color(0xFFFF8902),
                           borderRadius: BorderRadius.circular(2),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Text(
                         'TÜM İÇECEKLER',
                         style: GoogleFonts.plusJakartaSans(
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                           color: AppColors.textTertiary, // Lighter, matches profile
                           letterSpacing: 1.2,
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
            ],
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildCategoryGrid(),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    final suggestedIds = ['beer', 'wine', 'whiskey', 'cocktail'];
    final suggestions = _categories.where((c) => suggestedIds.contains(c['id'])).toList();
    final glowColor = const Color(0xFFFF8902);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: glowColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HIZLI EKLE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary.withOpacity(0.5),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110, // Shorter height for a chic look
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final category = suggestions[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _onCategorySelected(category),
                  child: Container(
                    width: 155, // Wider for half-image layout
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // 1. Background Nebula (Subtle)
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  glowColor.withOpacity(0.08),
                                  glowColor.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 2. True Glassmorphism Blur
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.03),
                                    Colors.black.withOpacity(0.12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. Glass Shine Sweep
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: const Alignment(-1.5, -1.2),
                                end: const Alignment(1.5, 1.2),
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.3, 0.45, 0.6],
                              ),
                            ),
                          ),
                        ),

                        // 4. Content - Artistic Half-Visible Image
                        Positioned(
                          left: -35, // Offset to make it half-visible
                          top: -15,
                          bottom: -15,
                          child: category['image'] != null
                              ? Image.asset(
                                  category['image'],
                                  width: 120, // Oversized for artistic look
                                  fit: BoxFit.contain,
                                  opacity: const AlwaysStoppedAnimation(0.8),
                                )
                              : Center(
                                  child: Text(
                                    category['emoji'],
                                    style: const TextStyle(fontSize: 60),
                                  ),
                                ),
                        ),

                        // 5. Title & Action
                        Positioned(
                          right: 12,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  category['name'].toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'EKLE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: glowColor.withOpacity(0.7),
                                    letterSpacing: 1.5,
                                  ),
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
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final filteredCategories = _categories.where((c) {
      return c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredCategories.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
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
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.80, // Slightly taller to prevent overflow
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildCategoryCard(filteredCategories[index]),
              ),
            ),
          );
        },
        childCount: filteredCategories.length,
      ),
    );
  }

  void _onCategorySelected(Map<String, dynamic> category, {Map<String, dynamic>? preSelectedPortion}) {
    HapticFeedback.mediumImpact();
    setState(() {
      _focusedCategoryId = category['id'];
      _quantity = 1;
      _selectedVarietyName = preSelectedPortion?['variety'];
      _selectedPortion = preSelectedPortion;
      _sheetDragY = 0;
      _selectedTime = DateTime.now();
      _searchQuery = '';
      _searchController.clear();
      _isSearchFocused = false;
    });
    _searchFocusNode.unfocus();
    _animationController.forward(from: 0);
    _bounceController.forward(from: 0);
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final portions = category['portions'] as List;
    final varieties = portions.map((p) => p['variety']).where((v) => v != null).toSet();
    final int displayCount = varieties.isNotEmpty ? varieties.length : portions.length;
    // Force Orange/Gold glow for all categories as per 'turuncu ağırlıklı' request
    final glowColor = const Color(0xFFFF8902); 

    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: (category['id'] == 'tequila' || category['id'] == 'rum') ? Clip.none : Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Nebula Ambient Aura (Orange) - Broad and very subtle
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withOpacity(0.08), // Even more subtle
                      glowColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            // 2. Secondary Nebula (Indigo) - Very broad and subtle
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3F51B5).withOpacity(0.06), // Barely there
                      const Color(0xFF3F51B5).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // 3. True Glassmorphism Blur Layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.03), 
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Glass Shine (Reflective Sweep) - Overlaying the blur
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-1.5, -1.2),
                    end: const Alignment(1.5, 1.2),
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.06), // Shine
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.35, 0.45, 0.55],
                  ),
                ),
              ),
            ),

            // 5. Top-Left Highlight
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),



            // 3. Content
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Floating Image with centered glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Focused Soft Glow exactly behind the image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withOpacity(0.12),
                              blurRadius: 35,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      category['image'] != null
                          ? Image.asset(
                              category['image'],
                              width: (category['id'] == 'tequila' || category['id'] == 'rum') ? 180 : 135,
                              height: (category['id'] == 'tequila' || category['id'] == 'rum') ? 180 : 135,
                              fit: BoxFit.contain,
                            )
                          : Text(
                              category['emoji'],
                              style: const TextStyle(fontSize: 100),
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    category['name'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                         Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
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
          border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1.5)),
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary.withOpacity(0.7),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _isSearchFocused ? const Color(0xFF1E2433).withOpacity(0.7) : const Color(0xFF1A1F2E).withOpacity(0.8),
          borderRadius: BorderRadius.circular(_isSearchFocused ? 20 : 16),
          border: Border.all(
            color: _isSearchFocused 
                ? const Color(0xFFFF8902).withOpacity(0.6) 
                : Colors.white.withOpacity(0.12),
            width: _isSearchFocused ? 2.0 : 1.4, // Thicker chic border
          ),
          boxShadow: _isSearchFocused ? [
            BoxShadow(
              color: const Color(0xFFFF8902).withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: -2,
            )
          ] : [],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (val) => setState(() => _searchQuery = val),
          onSubmitted: (val) {
            _addToHistory(val);
          },
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'İçecek ara...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8).withOpacity(0.6),
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 22,
              color: Color(0xFFFF8902),
            ),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
    );
  }

  void _pickImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: DualCameraWidget(
            onCaptured: (mainPath, pipPath) {
              setState(() {
                _pickedImage = XFile(mainPath);
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    if (_searchQuery.isEmpty && _recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use PreferencesService for history
    final history = PreferencesService.instance.getSearchHistory();

    final List<Map<String, dynamic>> suggestions = _searchQuery.isEmpty 
        ? [] 
        : _categories.where((c) => c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Positioned.fill(
      top: MediaQuery.of(context).padding.top + 180, // Position below the search bar
      child: GestureDetector(
        onTap: () {
          _searchFocusNode.unfocus();
          setState(() {
            _searchQuery = '';
            _searchController.clear();
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2433).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_searchQuery.isEmpty && _recentSearches.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SON ARAMALAR',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.4),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _clearHistory,
                                    child: Text(
                                      'TEMİZLE',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFF8902),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _recentSearches.length,
                                itemBuilder: (context, index) {
                                  final query = _recentSearches[index];
                                  return ListTile(
                                    leading: const Icon(Icons.history_rounded, size: 20, color: Colors.white30),
                                    title: Text(
                                      query,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white24),
                                      onPressed: () => _removeFromHistory(query),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = query;
                                        _searchController.text = query;
                                        _searchController.selection = TextSelection.fromPosition(
                                          TextPosition(offset: query.length),
                                        );
                                      });
                                      _addToHistory(query);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                          if (_searchQuery.isNotEmpty) ...[
                            // Deep Search Logic: Filter categories AND their portions
                            Builder(
                              builder: (context) {
                                final List<Map<String, dynamic>> deepSuggestions = [];
                                final query = _searchQuery.toLowerCase();

                                for (var cat in _categories) {
                                  final catName = cat['name'].toString().toLowerCase();
                                  
                                  // 1. Direct Category Match
                                  if (catName.contains(query)) {
                                    deepSuggestions.add(cat);
                                  } 
                                  // 2. Deep Portion Match (if not already matched by category name)
                                  else if (cat['portions'] != null) {
                                    final portions = cat['portions'] as List;
                                    for (var p in portions) {
                                      final pName = p['name'].toString().toLowerCase();
                                      final pVariety = (p['variety'] ?? '').toString().toLowerCase();
                                      
                                      if (pName.contains(query) || pVariety.contains(query)) {
                                        // Create a combined entry for the portion match
                                        deepSuggestions.add({
                                          ...cat,
                                          'displayName': "${cat['name']} - ${p['name']}",
                                          'isPortionMatch': true,
                                          'selectedPortion': p,
                                        });
                                      }
                                    }
                                  }
                                }

                                final fuzzySuggestions = _getSmartSuggestions(_searchQuery);

                                if (deepSuggestions.isEmpty) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                      const SizedBox(height: 40),
                                      // Subtle Gray Icon & Text (Matching Notification Screen)
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 64,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'İçecek bulunamadı',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white.withOpacity(0.24),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (fuzzySuggestions.isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        Text(
                                          'BUNU MU DEMEK İSTEDİN?',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFFF8902).withOpacity(0.6),
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: fuzzySuggestions.map((cat) {
                                            return GestureDetector(
                                              onTap: () {
                                                if (cat['isPortionMatch'] == true) {
                                                  _onCategorySelected(cat, preSelectedPortion: cat['selectedPortion']);
                                                } else {
                                                  _onCategorySelected(cat);
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF8902).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFFFF8902).withOpacity(0.2)),
                                                ),
                                                child: Text(
                                                  cat['displayName'] ?? cat['name'],
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: const Color(0xFFFF8902),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 32),
                                      // Proactive Suggestions
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'ŞUNLARI MI DEMEK İSTEDİN?',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white.withOpacity(0.2),
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              alignment: WrapAlignment.center,
                                              children: ['Bira', 'Rakı', 'Votka', 'Viski'].map((pop) {
                                                return GestureDetector(
                                                  onTap: () => setState(() => _searchQuery = pop),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                                    ),
                                                    child: Text(
                                                      pop,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        color: Colors.white.withOpacity(0.35),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                );
                              }

                                return Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: deepSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final cat = deepSuggestions[index];
                                      final isPortion = cat['isPortionMatch'] == true;
                                      
                                      return InkWell(
                                        onTap: () {
                                          _addToHistory(cat['name']);
                                          if (isPortion) {
                                            _onCategorySelected(cat, preSelectedPortion: cat['selectedPortion']);
                                          } else {
                                            _onCategorySelected(cat);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                alignment: Alignment.center,
                                                child: cat['image'] != null 
                                                  ? Image.asset(cat['image'], width: 30)
                                                  : Text(cat['emoji'], style: const TextStyle(fontSize: 24)),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                cat['displayName'] ?? cat['name'],
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white, 
                                                  fontSize: 16,
                                                  fontWeight: isPortion ? FontWeight.w500 : FontWeight.w700,
                                                ),
                                              ),
                                              if (isPortion) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Kategori: ${cat['name']}',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: Colors.white.withOpacity(0.3),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Icon(
                                                isPortion ? Icons.add_circle_outline_rounded : Icons.chevron_right_rounded, 
                                                size: 20, 
                                                color: Colors.white.withOpacity(0.15),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        final curvedValue = Curves.easeOutExpo.transform(_animationController.value);
        final double animationOffset = screenHeight - (screenHeight - topMargin) * curvedValue;
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
    final currentlyClosingId = _focusedCategoryId;
    _animationController.reverse().then((_) {
      if (mounted && _animationController.status == AnimationStatus.dismissed) {
        // Only nullify if we're not currently showing a NEWly selected category
        if (_focusedCategoryId == currentlyClosingId) {
          setState(() {
            _focusedCategoryId = null;
            _sheetDragY = 0;
          });
        }
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
                      // Pulsing Emoji or Image
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: category['image'] != null
                            ? Image.asset(
                                category['image'],
                                width: 180, // Larger for detail view
                                height: 180,
                                fit: BoxFit.contain,
                              )
                            : Text(
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

                    const SizedBox(height: 24),
                    _buildDrinkingWithSelector(),
                    const SizedBox(height: 32),

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: varieties.map<Widget>((v) {
          final isSelected = _selectedVarietyName == v;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedVarietyName = v;
                  // Auto-select portion if only 1 option exists
                  final allPortions = category['portions'] as List;
                  final filtered = allPortions.where((p) => p['variety'] == v).toList();
                  if (filtered.length == 1) {
                    _selectedPortion = filtered.first;
                  } else {
                    _selectedPortion = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)])
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                        ),
                  color: isSelected ? null : const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF8902).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  v!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: portions.map<Widget>((p) {
          final isSelected = _selectedPortion?['name'] == p['name'];
          // Size label (remove variety name if present)
          String sizeLabel = p['name'].toString();
          if (_selectedVarietyName != null) {
             sizeLabel = sizeLabel.replaceAll(_selectedVarietyName!, '').replaceAll('(', '').replaceAll(')', '').trim();
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedPortion = p);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [Color(0xFFFF8902), Color(0xFFEE5A6F)])
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                        ),
                  color: isSelected ? null : const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF8902).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  sizeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
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
              boxShadow: null,
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
              builder: (context) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: AlertDialog(
                  backgroundColor: AppColors.background.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.2), 
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE66D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFFFFE66D),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Not Ekle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'İçecek hakkında notun...',
                          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.3)),
                          fillColor: Colors.white.withOpacity(0.04),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFE66D), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text(
                                  'VAZGEÇ',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary.withOpacity(0.7),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, controller.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFE66D),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                'KAYDET',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
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
          boxShadow: null,
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
    if (_tempNote != null) _noteController.text = _tempNote!;
    if (_tempLocationName != null) _locationController.text = _tempLocationName!;
    if (_tempPickedImage != null) _pickedImage = _tempPickedImage;

    await _save();
    if (!_isLoading) {
       _showSuccessToast(totalAPS);
       _closeSheet();
    }
  }

  Widget _buildCustomRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'İçki Sihirbazı',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildStepIndicator(),
        const SizedBox(height: 32),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStep(),
        ),
        const SizedBox(height: 40),
        _buildWizardControls(),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index <= _currentRequestStep;
        return Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentRequestStep) {
      case 0:
        return _buildRequestField('İçecek Adı', 'Örn: Hibiscus Gin Tonic', _customNameController);
      case 1:
        return _buildCategoryPickerForRequest();
      case 2:
        return _buildRequestField('Yaklaşık Hacim (ml)', 'Örn: 330', _customVolumeController, keyboardType: TextInputType.number);
      case 3:
        return _buildRequestField('Alkol Oranı (%)', 'Örn: 12.5', _customAbvController, keyboardType: TextInputType.number);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoryPickerForRequest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KATEGORİ SEÇİN',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white30, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.where((c) => c['id'] != 'custom').map((c) {
            final isSelected = _customDescController.text == c['name'];
            return GestureDetector(
              onTap: () => setState(() => _customDescController.text = c['name']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  '${c['emoji']} ${c['name']}',
                  style: TextStyle(color: isSelected ? AppColors.primary : Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWizardControls() {
    return Row(
      children: [
        if (_currentRequestStep > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                onPressed: () => setState(() => _currentRequestStep--),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('GERİ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _currentRequestStep < 3 
                ? () {
                    // Validation
                    if (_currentRequestStep == 0 && _customNameController.text.isEmpty) return;
                    setState(() => _currentRequestStep++);
                  }
                : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              _currentRequestStep < 3 ? 'DEVAM ET' : 'TALEBİ GÖNDER',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        'volume': int.tryParse(_customVolumeController.text) ?? 0,
        'category': _customDescController.text.trim(),
        'requestedBy': user?.uid,
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

  Widget _buildDrinkingWithSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline, size: 16, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 8),
            Text(
              'KİMİNLE İÇİYORSUN?',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAddFriendTag(),
              ..._taggedFriendIds.map((id) => _buildFriendTag(id)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddFriendTag() {
    return GestureDetector(
      onTap: _showFriendSelectionSheet,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Arkadaş Ekle',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTag(String friendId) {
    // In a real app, we'd look up the friend's name/photo
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('👤', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            'Arkadaş', // Simplified for now
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _taggedFriendIds.remove(friendId)),
            child: Icon(Icons.close, size: 14, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  void _showFriendSelectionSheet() {
    // Selection logic would go here
    // For now, let's just add a placeholder ID
    setState(() {
      if (_taggedFriendIds.length < 5) {
        _taggedFriendIds.add('friend_${_taggedFriendIds.length}');
      }
    });
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
                                    'ROZET KAZANILDI! ✨',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: widget.color.withOpacity(0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.badgeSource.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    widget.badgeSource.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
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
