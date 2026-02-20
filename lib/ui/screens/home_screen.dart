import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uicons/uicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../widgets/animated_notification_bell.dart';
import '../widgets/durum_meter_widget.dart';
import '../widgets/home_quick_add_section.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/bac_service.dart';
import '../../core/services/navigation_service.dart';
import '../../data/drink_categories.dart'; // Import Categories
import '../../core/services/preferences_service.dart';
import '../../core/services/drink_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _recentDrinks = [];
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Quick Add Data
  List<Map<String, dynamic>> _quickAddConfigs = [];
  List<String> _quickAddIds = [];
  
  
  bool _isLoading = true;
  double _totalPoints = 0;
  // Durum State
  BacResult _currentBacResult = BacResult(min: 0, max: 0, trend: BacTrend.stable);
  int _activeSessionDrinkCount = 0;
  
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _entriesStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _friendRequestsStream;

  @override
  void initState() {
    super.initState();
    
    // Quick Add Sync
    _loadQuickAddPreferences();
    NavigationService.instance.quickAddUpdateNotifier.addListener(_loadQuickAddPreferences);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
      _entriesStream = FirebaseFirestore.instance
          .collection('entries')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
      _friendRequestsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots();
      _loadData();
    } else {
      _userStream = const Stream.empty();
      _entriesStream = const Stream.empty();
      _friendRequestsStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    NavigationService.instance.quickAddUpdateNotifier.removeListener(_loadQuickAddPreferences);
    super.dispose();
  }

  Future<void> _loadQuickAddPreferences() async {
    // Slight delay to ensure prefs are written
    await Future.delayed(const Duration(milliseconds: 100));
    // Re-read from prefs (assuming prefs service re-reads or file is updated)
    // Actually PreferencesService in memory should be up to date if single instance.
    // If not, we might need to reload? SharedPreferences usually syncs memory.
    
    final ids = PreferencesService.instance.getQuickAddIds(); // Legacy support
    final configs = PreferencesService.instance.getQuickAddConfigs();
        setState(() {
       if (configs.isNotEmpty) {
         _quickAddConfigs = configs;
         _quickAddIds = configs.map((c) => c['categoryId'] as String).toList();
       } else {
         // Fallback/Migration
         _quickAddConfigs = ids.map((id) => <String, dynamic>{'categoryId': id}).toList();
         _quickAddIds = List<String>.from(ids);
       }
    });
  }


  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      // Load all entries for calendar
      final entriesQuery = await FirebaseFirestore.instance
          .collection('entries')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      // Group entries by date
      final Map<DateTime, List<Map<String, dynamic>>> events = {};
      final List<Map<String, dynamic>> flatEntries = [];
      
      for (final doc in entriesQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final normalizedDate = DateTime.utc(date.year, date.month, date.day);
          events.putIfAbsent(normalizedDate, () => []);
          events[normalizedDate]!.add(data);
          flatEntries.add(data);
        }
      }

      final userDataMap = userDoc.data() ?? {};
      final weight = (userDataMap['weight'] ?? 70).toDouble();
      final gender = userDataMap['gender'] ?? 'Male';
      
      // Calculate Dynamic BAC with complete profile
      final bacResult = BacService.calculateDynamicBac(
        weightKg: weight, 
        heightCm: (userDataMap['height'] ?? 175).toDouble(),
        age: userDataMap['age'] ?? 25,
        gender: gender, 
        drinks: flatEntries,
      );
      
      // Calculate Active Session Drink Count (Drinks in last 12h?)
      final now = DateTime.now();
      final activeDrinks = flatEntries.where((d) {
        final ts = (d['timestamp'] as Timestamp).toDate();
        return now.difference(ts).inHours < 12;
      }).length;

      if (mounted) {
        setState(() {
          _userData = userDataMap;
          _events = events;
          _recentDrinks = flatEntries;
          _totalPoints = (userDataMap['totalPoints'] ?? 0).toDouble();
          _currentBacResult = bacResult;
          _activeSessionDrinkCount = activeDrinks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  String _getDrinkEmoji(String drinkType) {
    switch (drinkType.toLowerCase()) {
      case 'beer':
      case 'bira':
        return '🍺';
      case 'wine':
      case 'şarap':
        return '🍷';
      case 'whisky':
      case 'viski':
        return '🥃';
      case 'vodka':
        return '🍸';
      case 'tequila':
      case 'tekila':
        return '🥃';
      case 'cocktail':
      case 'kokteyl':
        return '🍹';
      case 'shot':
        return '🥃';
      case 'rakı':
        return '🥃';
      default:
        return '🍻';
    }
  }

  Future<void> _deleteEntry(String entryId, double points, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(FirebaseFirestore.instance.collection('entries').doc(entryId));
      batch.update(FirebaseFirestore.instance.collection('users').doc(user.uid), {
        'totalPoints': FieldValue.increment(-points),
        'totalDrinks': FieldValue.increment(-quantity),
      });

      await batch.commit();
      
      // Sync badges after deletion
      await BadgeService.syncBadges(user.uid);
      
      _loadData(); // Refresh list
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }

  void _showMonthYearPicker() {
    int selectedMonth = _focusedDay.month;
    int selectedYear = _focusedDay.year;
    
    // Create controllers with initial values
    final monthController = FixedExtentScrollController(initialItem: selectedMonth - 1);
    final yearController = FixedExtentScrollController(initialItem: selectedYear - 2020);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 430,
            padding: const EdgeInsets.only(bottom: 90),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tarih Seç',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(selectedYear, selectedMonth, 1);
                          });
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: Text(
                          'Tamam',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Month List
                      Expanded(
                        flex: 3,
                        child: _buildPickerList(
                          controller: monthController,
                          items: [
                            'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                            'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
                          ],
                          selectedIndex: selectedMonth - 1,
                          onSelected: (index) => setModalState(() => selectedMonth = index + 1),
                        ),
                      ),
                      // Year List
                      Expanded(
                        flex: 2,
                        child: _buildPickerList(
                          controller: yearController,
                          items: List.generate(11, (i) => (2020 + i).toString()),
                          selectedIndex: selectedYear - 2020,
                          onSelected: (index) => setModalState(() => selectedYear = 2020 + index),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerList({
    required FixedExtentScrollController controller,
    required List<String> items,
    required int selectedIndex,
    required Function(int) onSelected,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(
            child: Text(
              items[index],
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSelected ? 18 : 16,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.4),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDayEntriesPopup(DateTime day, List<Map<String, dynamic>> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final totalDayPoints = entries.fold<double>(0, (sum, item) => sum + (item['points'] ?? 0).toDouble());
        final totalDayDrinks = entries.fold<int>(0, (sum, item) => sum + (item['quantity'] ?? 1) as int);

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: AppDecorations.glassCard(borderRadius: 36).copyWith(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            children: [
              // Apple Style Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // Header with Date and Totals
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM EEEE', 'tr_TR').format(day),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '🥤 $totalDayDrinks İçecek',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: Colors.grey.shade300)),
                            const SizedBox(width: 8),
                            Text(
                              '💎 ${totalDayPoints.toStringAsFixed(1)} Puan',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(UIcons.regularStraight.cross, size: 20, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, color: Colors.grey.shade100),
              
              // Entries List
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.glassWhiskey, size: 64, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Text(
                              'Bu gün için kayıt bulunmuyor',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final entryId = entry['id'] as String;
                          final drinkType = entry['drinkType'] as String? ?? 'Diğer';
                          final String categoryId = entry['categoryId'] as String? ?? 'cocktail';
                          final drinkData = DrinkDataService.instance.resolveFromId(categoryId);
                          final portion = entry['portion'] as String? ?? '';
                          final quantity = entry['quantity'] as int? ?? 1;
                          final points = (entry['points'] ?? 0).toDouble();
                          final note = entry['note'] as String? ?? '';
                          final locationName = entry['locationName'] as String? ?? '';
                          final timestamp = entry['timestamp'] as Timestamp?;
                          final time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    // Time & Emoji
                                    Column(
                                      children: [
                                        Text(
                                          time,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Icon(drinkData.icon, size: 24, color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${quantity}x $drinkType',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          if (portion.isNotEmpty)
                                            Text(
                                              portion,
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                            ),
                                          if (locationName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(
                                                children: [
                                                  Icon(AppIcons.marker, size: 10, color: AppColors.primary.withOpacity(0.5)),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      locationName,
                                                      style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.7), fontWeight: FontWeight.w600),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (note.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                note,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Points & Action
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '+${points.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(sheetContext);
                                            _showDeleteConfirmation(entryId, points, quantity);
                                          },
                                          child: Text(
                                            'Sil',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.primary.withOpacity(0.8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (index != entries.length - 1)
                                Divider(height: 1, color: Colors.grey.shade100, indent: 64),
                            ],
                          );
                        },
                      ),
              ),
              
              // Bottom Safe Area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }
  Widget _buildCalendarSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _entriesStream,
      builder: (context, entriesSnapshot) {
        final Map<DateTime, List<Map<String, dynamic>>> currentEvents = {};
        if (entriesSnapshot.hasData) {
          for (final doc in entriesSnapshot.data!.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            final timestamp = data['timestamp'] as Timestamp?;
            if (timestamp != null) {
              final date = timestamp.toDate();
              final normalizedDate = DateTime.utc(date.year, date.month, date.day);
              currentEvents.putIfAbsent(normalizedDate, () => []);
              currentEvents[normalizedDate]!.add(data);
            }
          }
        }
        final activeEvents = entriesSnapshot.hasData ? currentEvents : _events;

        // Check if TODAY has any entries (for hiding "First Drink" card)
        final todayKey = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final todayHasEntries = (activeEvents[todayKey]?.isNotEmpty ?? false);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: !todayHasEntries
                  ? GestureDetector(
                      onTap: () {
                        StatefulNavigationShell.of(context).goBranch(1);
                      },
                      child: AppDecorations.glassCardWidget(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        color: AppColors.surface, // Navy background
                        borderWidth: 1.0,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // Keep it compact
                                children: [
                                  Text(
                                    'GÜNÜN İLK İÇKİSİNİ EKLE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Puanlamaya başlamak için dokun',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.primary.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSize(
              duration: const Duration(milliseconds: 600),
              curve: Curves.fastLinearToSlowEaseIn,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        decoration: AppDecorations.glassCard(),
                        child: TableCalendar(
                          locale: 'tr_TR',
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          eventLoader: (day) => activeEvents[DateTime.utc(day.year, day.month, day.day)] ?? [],
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          rowHeight: 58.0,
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            weekendTextStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                            defaultTextStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                            markerDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            markerSize: 4,
                            cellMargin: const EdgeInsets.all(10.0),
                            markersAlignment: Alignment.bottomCenter,
                            markerMargin: const EdgeInsets.symmetric(horizontal: 1.0),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false, 
                            titleCentered: true, 
                            leftChevronVisible: false, 
                            rightChevronVisible: false,
                            headerPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isNotEmpty) {
                                final isSelected = isSameDay(_selectedDay, date);
                                
                                // Calculate total drinks for the day
                                int totalQuantity = 0;
                                for (var event in events) {
                                  if (event is Map<String, dynamic>) {
                                    totalQuantity += (event['quantity'] as int? ?? 1);
                                  }
                                }
                                
                                // Cap at 3 dots (1, 2, or 3+)
                                final int dotsToShow = totalQuantity > 3 ? 3 : totalQuantity;
                                
                                return Positioned(
                                  bottom: isSelected ? 3 : 5,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(dotsToShow, (index) {
                                      return Container(
                                        width: 4,
                                        height: 4,
                                        margin: index < dotsToShow - 1 
                                            ? const EdgeInsets.only(right: 2.0) // Space between dots
                                            : EdgeInsets.zero,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              }
                              return null;
                            },
                            headerTitleBuilder: (context, day) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _focusedDay = DateTime.utc(_focusedDay.year, _focusedDay.month - 1, 1);
                                            });
                                          },
                                          icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                                        ),
                                        const Spacer(),
                                        if (!isSameDay(_focusedDay, DateTime.now()))
                                          TextButton(
                                             onPressed: () {
                                               setState(() {
                                                 final now = DateTime.now();
                                                 final today = DateTime.utc(now.year, now.month, now.day);
                                                 _focusedDay = today;
                                                 _selectedDay = today;
                                               });
                                             },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'BUGÜN',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10, 
                                                fontWeight: FontWeight.bold, 
                                                color: AppColors.primary,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _focusedDay = DateTime.utc(_focusedDay.year, _focusedDay.month + 1, 1);
                                            });
                                          },
                                          icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: _showMonthYearPicker,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            DateFormat('MMMM yyyy', 'tr_TR').format(day).toUpperCase(),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 0.5),
                                          ),
                                          Text(
                                            'TARİH SEÇ',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },

                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              if (isSameDay(_selectedDay, selectedDay)) {
                                _selectedDay = null;
                              } else {
                                _selectedDay = selectedDay;
                              }
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 16),
              _buildInlineDayDetails(
                _selectedDay!, 
                activeEvents[DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? []
              ),
            ],
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        final showWaterReminder = userSnapshot.data?.data()?['showWaterReminder'] == true;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(user.uid),
                // Water Reminder Banner
                if (showWaterReminder)
                  _buildWaterReminderBanner(user.uid),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // Durum Meter Section
                        SliverToBoxAdapter(
                          child: DurumMeterWidget(
                            bacResult: _currentBacResult,
                            drinkCount: _activeSessionDrinkCount,
                            isPremium: _userData?['isPremium'] == true,
                            isProfileComplete: _userData?['gender'] != null &&
                                _userData?['age'] != null &&
                                _userData?['height'] != null &&
                                _userData?['weight'] != null,
                            onProfileTap: () => context.push('/profile-details'),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/bac-stats', extra: {
                                'currentBac': _currentBacResult,
                                'weightKg': (_userData?['weight'] as num?)?.toDouble(),
                                'heightCm': (_userData?['height'] as num?)?.toDouble(),
                                'age': _userData?['age'] as int?,
                                'gender': _userData?['gender'] as String?,
                              });
                            },
                          ),
                        ),
                        // Quick Add Section
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverToBoxAdapter(child: HomeQuickAddSection(quickAddConfigs: _quickAddConfigs)),
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        
                        // Calendar Section (Takvimli Kısım)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          sliver: SliverToBoxAdapter(
                            child: _buildCalendarSection(),
                          ),
                        ),
                        // Add extra padding at the bottom for scrolling past FAB/BottomBar
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterReminderBanner(String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppDecorations.glassCardWidget(
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        color: const Color(0xFF0D47A1).withOpacity(0.15),
        blurSigma: 12,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('💧', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün hiç su içtin mi?',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dengeyi korumak için şimdi bir bardak su iç 💪',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'showWaterReminder': false});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'İçtim ✓',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CountSip',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: AppColors.primary,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _friendRequestsStream,
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return AnimatedNotificationBell(
                count: count,
                onTap: () => context.push('/notifications'),
              );
            },
          ),
        ],
      ),
    );
  }




  Widget _buildInlineDayDetails(DateTime day, List<Map<String, dynamic>> entries) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppDecorations.glassCardWidget(
        padding: const EdgeInsets.all(24),
        color: AppColors.surface,
        borderWidth: 0.5,
        borderRadius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Shrink to fit content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Date & Collapse Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 Text(
                   DateFormat('d MMMM EEEE', 'tr_TR').format(day),
                   style: GoogleFonts.plusJakartaSans(
                     fontSize: 16,
                     fontWeight: FontWeight.w700,
                     color: AppColors.textPrimary,
                     letterSpacing: -0.3,
                   ),
                 ),
                if (entries.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setState(() => _selectedDay = null);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textTertiary.withOpacity(0.5), size: 22),
                    ),
                  ),
              ],
            ),
            
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 6),
              // Minimal Summary Row (No Chips, Just Text)
              Row(
                children: [
                  Text(
                    '${entries.fold<double>(0, (sum, e) => sum + (e['points'] as num).toDouble()).toStringAsFixed(1)} Puan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    width: 4, 
                    height: 4, 
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  ),
                  Text(
                    '${entries.fold<int>(0, (sum, e) => sum + (e['quantity'] as int))} İçecek',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ListView.separated(
                padding: EdgeInsets.zero, // Remove default padding
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20), // Increased spacing
                itemBuilder: (context, index) {
                    final entry = entries[index];
                    final entryId = entry['id'] as String;
                    final drinkType = entry['drinkType'] as String? ?? 'Diğer';
                    final String categoryId = entry['categoryId'] as String? ?? 'cocktail';
                    final drinkData = DrinkDataService.instance.resolveFromId(categoryId);
                    final portion = entry['portion'] as String? ?? '';
                    final quantity = entry['quantity'] as int? ?? 1;
                    final points = (entry['points'] ?? 0).toDouble();
                    final locationName = entry['locationName'] as String? ?? '';
                    final note = entry['note'] as String? ?? '';
                    final timestamp = entry['timestamp'] as Timestamp?;
                    final hasImage = entry['hasImage'] as bool? ?? false;
                    final time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

                    return GestureDetector(
                      onTap: () => _showEntryDetails(entry),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4), // Added margin for breathability
                        color: Colors.transparent, // Hit test
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Time
                            SizedBox(
                              width: 40,
                              child: Text(
                                time,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary.withOpacity(0.7),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 8),

                            // 2. Minimal Line/Dot
                            Container(
                              height: 28,
                              width: 2,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            
                            const SizedBox(width: 12),

                            // 3. Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        drinkData.icon,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '$quantity x $drinkType',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (portion.isNotEmpty || note.isNotEmpty || locationName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2, left: 22), // Align with text start
                                      child: Text(
                                        [portion, if (locationName.isNotEmpty) '📍'].where((s) => s.isNotEmpty).join(' • '),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.textSecondary.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 4. Points & Delete
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+${points.toStringAsFixed(1)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _showDeleteConfirmation(entryId, points, quantity),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.close_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 24,
                      color: AppColors.textTertiary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kayıt bulunamadı',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
  void _showDeleteConfirmation(String entryId, double points, int quantity) {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Emin misin?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bu içecek kaydını silmek üzeresin. Bu işlem geri alınamaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
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
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteEntry(entryId, points, quantity);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('SİL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryDetails(Map<String, dynamic> entry) {
    HapticFeedback.lightImpact();
    final drinkType = entry['drinkType'] as String? ?? 'Diğer';
    final String categoryId = entry['categoryId'] as String? ?? 'cocktail';
    final drinkData = DrinkDataService.instance.resolveFromId(categoryId);
    final portion = entry['portion'] as String? ?? '';
    final quantity = entry['quantity'] as int? ?? 1;
    final points = (entry['points'] ?? 0).toDouble();
    final locationName = entry['locationName'] as String? ?? '';
    final note = entry['note'] as String? ?? '';
    final timestamp = entry['timestamp'] as Timestamp?;
    final hasImage = entry['hasImage'] as bool? ?? false;
    final imagePath = entry['imagePath'] as String?;
    final time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(child: Icon(drinkData.icon, size: 32, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drinkType,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        Text(
                          '$time • $quantity Adet • $portion',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.6), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '+${points.toStringAsFixed(1)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (note.isNotEmpty) ...[
                const Text('NOTLAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Text(note, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
              ],
              if (locationName.isNotEmpty) ...[
                const Text('KONUM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(locationName, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              if (hasImage && imagePath != null) ...[
                const Text('GÖRSEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await Share.shareXFiles([XFile(imagePath)], text: 'Check out my $drinkType from Countsip!');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDashboardItem({
    required String label,
    required String value,
    required IconData icon,
    required bool isLight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isLight ? AppColors.textPrimary.withOpacity(0.8) : AppColors.primary.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isLight ? AppColors.textSecondary.withOpacity(0.7) : AppColors.primary.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : AppColors.primary,
            fontSize: isLight ? 28 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }


}
