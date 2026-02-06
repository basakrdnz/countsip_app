import 'dart:io';
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
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = true;
  double _totalPoints = 0;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _entriesStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
      _entriesStream = FirebaseFirestore.instance
          .collection('entries')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      _userStream = const Stream.empty();
      _entriesStream = const Stream.empty();
    }
    _loadData();
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
      for (final doc in entriesQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final normalizedDate = DateTime.utc(date.year, date.month, date.day);
          events.putIfAbsent(normalizedDate, () => []);
          events[normalizedDate]!.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _events = events;
          _totalPoints = (_userData?['totalPoints'] ?? 0).toDouble();
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
      _loadData(); // Refresh list
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
                  'Yıl Seç',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final year = 2020 + index;
                    final isSelected = year == _focusedDay.year;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _focusedDay = DateTime(year, _focusedDay.month, 1);
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.05),
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        child: Text(
                          year.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Kapat',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                          final drinkEmoji = entry['drinkEmoji'] as String? ?? '🍹';
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
                                            child: Text(drinkEmoji, style: const TextStyle(fontSize: 24)),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _entriesStream,
          builder: (context, entriesSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting && _userData == null) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final userData = userSnapshot.data?.data();
            
            // Group entries by date
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
              // Update local cache without triggering rebuild
              _events = currentEvents; 
            }
            
            final activeEvents = entriesSnapshot.hasData ? currentEvents : _events;

            // Selected Day Stats
            double selectedPoints = 0;
            int selectedDrinks = 0;
            if (_selectedDay != null) {
              final selectedKey = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
              if (activeEvents.containsKey(selectedKey)) {
                for (var e in activeEvents[selectedKey]!) {
                  selectedPoints += (e['points'] ?? 0).toDouble();
                  selectedDrinks += (e['quantity'] ?? 1) as int;
                }
              }
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CountSip',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Rosaline',
                                      letterSpacing: -1,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('friend_requests')
                                        .where('to', isEqualTo: user.uid)
                                        .where('status', isEqualTo: 'pending')
                                        .snapshots(),
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
                            ),
                            
                            // Welcome Placeholder or Stats Dashboard
                            if (_selectedDay == null)
                              _buildInitialPlaceholder()
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                      decoration: AppDecorations.glassCard(),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildDashboardItem(
                                              label: 'PUAN',
                                              value: selectedPoints.toStringAsFixed(1),
                                              icon: UIcons.regularStraight.magic_wand,
                                              isLight: true,
                                            ),
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: AppColors.primary.withOpacity(0.1),
                                            margin: const EdgeInsets.symmetric(horizontal: 24),
                                          ),
                                          Expanded(
                                            child: _buildDashboardItem(
                                              label: 'İÇECEK',
                                              value: '$selectedDrinks',
                                              icon: UIcons.regularStraight.drink_alt,
                                              isLight: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: AppSpacing.lg),
                            
                            // Calendar Section with Animated Resize
                            AnimatedSize(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCirc,
                              child: Column(
                                children: [
                                  ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  decoration: AppDecorations.glassCard(),
                                  child: Column(
                                    children: [
                                      TableCalendar(
                                        locale: 'tr_TR',
                                        firstDay: DateTime.utc(2020, 1, 1),
                                        lastDay: DateTime.utc(2030, 12, 31),
                                        focusedDay: _focusedDay,
                                        calendarFormat: _calendarFormat,
                                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                        eventLoader: (day) => activeEvents[DateTime.utc(day.year, day.month, day.day)] ?? [],
                                        startingDayOfWeek: StartingDayOfWeek.monday,
                                        availableGestures: AvailableGestures.none,
                                        availableCalendarFormats: const {
                                          CalendarFormat.month: 'Ay',
                                          CalendarFormat.week: 'Hafta',
                                        },
                                        calendarStyle: CalendarStyle(
                                            outsideDaysVisible: false,
                                            weekendTextStyle: const TextStyle(
                                              color: AppColors.textPrimary, 
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                            defaultTextStyle: const TextStyle(
                                              color: AppColors.textPrimary, 
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                            todayDecoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.08),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
                                            ),
                                            todayTextStyle: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            selectedDecoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            selectedTextStyle: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            markerDecoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            markerSize: 4,
                                            markersMaxCount: 1,
                                            markerMargin: const EdgeInsets.only(top: 6),
                                          ),
                                          headerStyle: const HeaderStyle(
                                            formatButtonVisible: false,
                                            titleCentered: true,
                                            leftChevronVisible: false,
                                            rightChevronVisible: false,
                                            headerPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                          ),
                                        calendarBuilders: CalendarBuilders(
                                          headerTitleBuilder: (context, day) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _focusedDay = DateTime.utc(_focusedDay.year, _focusedDay.month - 1, 1);
                                                      });
                                                    },
                                                    icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                                                  ),
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: _showYearPicker,
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            DateFormat('MMMM yyyy', 'tr_TR').format(day).toUpperCase(),
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w900,
                                                              color: AppColors.textPrimary,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'TARİH SEÇ',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w900,
                                                              color: AppColors.primary,
                                                              letterSpacing: 1.2,
                                                            ),
                                                          ),
                                                        ],
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
                                            );
                                          },
                                        ),
                                        daysOfWeekStyle: DaysOfWeekStyle(
                                          weekdayStyle: TextStyle(
                                            color: AppColors.textTertiary.withOpacity(0.5), 
                                            fontSize: 12, 
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                          weekendStyle: TextStyle(
                                            color: AppColors.textTertiary.withOpacity(0.5), 
                                            fontSize: 12, 
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        onDaySelected: (selectedDay, focusedDay) {
                                          setState(() {
                                            if (isSameDay(_selectedDay, selectedDay)) {
                                              _selectedDay = null; // Toggle off
                                            } else {
                                              _selectedDay = selectedDay;
                                            }
                                            _focusedDay = focusedDay;
                                          });
                                        },
                                        onFormatChanged: (format) => setState(() => _calendarFormat = format),
                                        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                                        onHeaderTapped: (_) => _showYearPicker(),
                                      ),
                                    ],
                                  ),
                                ),
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
                              ),
                            ),
                            
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInitialPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: double.infinity,
              child: GestureDetector(
              onTap: () => context.go('/add'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: AppDecorations.glassCard(borderRadius: 28),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        UIcons.regularStraight.plus,
                        size: 26,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bugün Neler İçtin?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'İçeceklerini kaydetmek için dokun',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary.withOpacity(0.3),
                      size: 28,
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

  Widget _buildInlineDayDetails(DateTime day, List<Map<String, dynamic>> entries) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(24),
          decoration: AppDecorations.glassCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMMM EEEE', 'tr_TR').format(day),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  if (entries.isNotEmpty)
                    InkWell(
                      onTap: () {
                        setState(() => _selectedDay = null);
                      },
                      child: Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textSecondary.withOpacity(0.5), size: 24),
                    ),
                ],
              ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.primary.withOpacity(0.08)),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.primary.withOpacity(0.08)),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final entryId = entry['id'] as String;
                    final drinkType = entry['drinkType'] as String? ?? 'Diğer';
                    final drinkEmoji = entry['drinkEmoji'] as String? ?? '🍹';
                    final portion = entry['portion'] as String? ?? '';
                    final quantity = entry['quantity'] as int? ?? 1;
                    final points = (entry['points'] ?? 0).toDouble();
                    final locationName = entry['locationName'] as String? ?? '';
                    final note = entry['note'] as String? ?? '';
                    final timestamp = entry['timestamp'] as Timestamp?;
                    final hasImage = entry['hasImage'] as bool? ?? false;
                    final imagePath = entry['imagePath'] as String?;
                    final time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

                    return GestureDetector(
                      onTap: () => _showEntryDetails(entry),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            // Time Section
                            Container(
                              width: 50,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    time,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SAAT',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textTertiary.withOpacity(0.8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Separator
                            Container(
                              height: 24,
                              width: 1,
                              color: AppColors.primary.withOpacity(0.1),
                              margin: const EdgeInsets.only(right: 14),
                            ),

                            // Drink & Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$drinkEmoji ${quantity}x $drinkType',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (portion.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Text(
                                            portion,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary.withOpacity(0.6),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      // Attachment Indicators
                                      if (note.isNotEmpty) 
                                        const Padding(padding: EdgeInsets.only(right: 4), child: Text('📝', style: TextStyle(fontSize: 10))),
                                      if (locationName.isNotEmpty) 
                                        const Padding(padding: EdgeInsets.only(right: 4), child: Text('📍', style: TextStyle(fontSize: 10))),
                                      if (hasImage) 
                                        const Padding(padding: EdgeInsets.only(right: 4), child: Text('🖼️', style: TextStyle(fontSize: 10))),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Points & Delete
                            Row(
                              children: [
                                Text(
                                  '+${points.toStringAsFixed(1)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _showDeleteConfirmation(entryId, points, quantity),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(UIcons.regularStraight.moon, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bu gün için henüz kayıt yok',
                         style: TextStyle(
                           color: AppColors.textTertiary.withOpacity(0.6), 
                           fontSize: 14, 
                           fontWeight: FontWeight.w700,
                           letterSpacing: -0.2,
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
                  'Bu alkol kaydını silmek üzeresin. Bu işlem geri alınamaz.',
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
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'VAZGEÇ',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.6),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
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
    final drinkEmoji = entry['drinkEmoji'] as String? ?? '🍹';
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
                    child: Center(child: Text(drinkEmoji, style: const TextStyle(fontSize: 32))),
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
