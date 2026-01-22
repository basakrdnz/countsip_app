import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';

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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İçeceği Sil'),
        content: const Text('Bu içeceği silmek istediğine emin misin? Puanların geri alınacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(iconColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yıl Seç', textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            selectedDate: _focusedDay,
            onChanged: (DateTime dateTime) {
              Navigator.pop(context);
              setState(() {
                _focusedDay = DateTime(dateTime.year, _focusedDay.month, 1);
              });
            },
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                            _deleteEntry(entryId, points, quantity);
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
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/mainbgempty.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SafeArea(
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
                                      color: AppColors.primary,
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
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          IconButton(
                                            onPressed: () => context.push('/notifications'),
                                            icon: Icon(UIcons.regularStraight.bell),
                                            color: Colors.black87,
                                            iconSize: 26,
                                          ),
                                          if (count > 0)
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 16,
                                                  minHeight: 16,
                                                ),
                                                child: Text(
                                                  '$count',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
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
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildDashboardItem(
                                              label: 'PUAN',
                                              value: selectedPoints.toStringAsFixed(1),
                                              icon: UIcons.regularStraight.magic_wand,
                                              isLight: false,
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
                                              isLight: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: AppSpacing.lg),
                            
                            // Calendar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                                  ),
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
                                          weekendTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                          defaultTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                          todayDecoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          todayTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          selectedDecoration: BoxDecoration(
                                            color: Colors.transparent,
                                            border: Border.all(color: AppColors.primary, width: 2),
                                            shape: BoxShape.circle,
                                          ),
                                          selectedTextStyle: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          markerDecoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          markerSize: 4.5,
                                          markersMaxCount: 1,
                                          markerMargin: const EdgeInsets.only(top: 6),
                                        ),
                                        headerStyle: HeaderStyle(
                                          formatButtonVisible: false,
                                          titleCentered: true,
                                          leftChevronIcon: Icon(AppIcons.angleLeft, color: Colors.black54, size: 24),
                                          rightChevronIcon: Icon(AppIcons.angleRight, color: Colors.black54, size: 24),
                                          headerPadding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        calendarBuilders: CalendarBuilders(
                                          headerTitleBuilder: (context, day) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: _showYearPicker,
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              DateFormat('MMMM yyyy', 'tr_TR').format(day),
                                                              style: const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.w900,
                                                                color: Colors.black,
                                                                letterSpacing: -0.5,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                           Icon(AppIcons.angleDown, size: 20, color: Colors.black54),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _focusedDay = DateTime.now();
                                                        _selectedDay = DateTime.now();
                                                      });
                                                    },
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    child: const Text(
                                                      'Bugün',
                                                      style: TextStyle(
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        daysOfWeekStyle: const DaysOfWeekStyle(
                                          weekdayStyle: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal),
                                          weekendStyle: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal),
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
                            
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    UIcons.regularStraight.calendar,
                    size: 40,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Günü Seç Geçmişini Gör',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Detayları ve istatistikleri görmek için takvimden bir gün seçebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.go('/add'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(UIcons.regularStraight.plus, size: 18, color: AppColors.primary.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text(
                          'Eklemeye Başla',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary.withOpacity(0.8),
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
      ),
    );
  }

  Widget _buildInlineDayDetails(DateTime day, List<Map<String, dynamic>> entries) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  if (entries.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(UIcons.regularStraight.drink_alt, color: AppColors.primary.withOpacity(0.5), size: 18),
                    ),
                ],
              ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade100),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final entryId = entry['id'] as String;
                    final drinkType = entry['drinkType'] as String? ?? 'Diğer';
                    final drinkEmoji = entry['drinkEmoji'] as String? ?? '🍹';
                    final portion = entry['portion'] as String? ?? '';
                    final quantity = entry['quantity'] as int? ?? 1;
                    final points = (entry['points'] ?? 0).toDouble();
                    final locationName = entry['locationName'] as String? ?? '';
                    final timestamp = entry['timestamp'] as Timestamp?;
                    final time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(drinkEmoji, style: const TextStyle(fontSize: 20)),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${quantity}x $drinkType',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (portion.isNotEmpty)
                                      Text(
                                        portion,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                                                style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.7), fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${points.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _deleteEntry(entryId, points, quantity),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Sil',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary.withOpacity(0.6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (index != entries.length - 1)
                          Divider(height: 1, color: Colors.grey.shade50),
                      ],
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Icon(UIcons.regularStraight.moon, size: 40, color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Text(
                        'Kayıt bulunmuyor',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500),
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
              color: isLight ? Colors.white.withOpacity(0.8) : AppColors.primary.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isLight ? Colors.white.withOpacity(0.7) : AppColors.primary.withOpacity(0.6),
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
            color: isLight ? Colors.white : AppColors.primary,
            fontSize: isLight ? 28 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
