import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

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
  int _totalPoints = 0;
  int _totalDrinks = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
          final date = DateTime(
            timestamp.toDate().year,
            timestamp.toDate().month,
            timestamp.toDate().day,
          );
          events.putIfAbsent(date, () => []);
          events[date]!.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _events = events;
          _totalPoints = _userData?['totalPoints'] ?? 0;
          _totalDrinks = _userData?['totalDrinks'] ?? 0;
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
    final normalizedDay = DateTime(day.year, day.month, day.day);
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
    DateTime currentDay = day;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final currentEntries = _getEventsForDay(currentDay);
            final canGoNext = !currentDay.add(const Duration(days: 1)).isAfter(DateTime.now());
            
            void goToPrevDay() {
              final prevDay = currentDay.subtract(const Duration(days: 1));
              setSheetState(() {
                currentDay = prevDay;
              });
              setState(() {
                _selectedDay = prevDay;
                _focusedDay = prevDay;
              });
            }
            
            void goToNextDay() {
              if (!canGoNext) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('İleri tarih seçemezsin!'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }
              final nextDay = currentDay.add(const Duration(days: 1));
              setSheetState(() {
                currentDay = nextDay;
              });
              setState(() {
                _selectedDay = nextDay;
                _focusedDay = nextDay;
              });
            }
            
            return GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                // Swipe right = previous day
                if (details.primaryVelocity! > 0) {
                  goToPrevDay();
                }
                // Swipe left = next day
                else if (details.primaryVelocity! < 0) {
                  goToNextDay();
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Swipe hint
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '← sağa sola kaydır →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    
                    // Date header with navigation arrows
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Prev day button
                          GestureDetector(
                            onTap: goToPrevDay,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_left, color: AppColors.primary),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Date info - centered
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${currentDay.day}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM', 'tr_TR').format(currentDay),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE', 'tr_TR').format(currentDay),
                                      style: AppTextStyles.title2.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${currentEntries.length} içecek',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Next day button
                          GestureDetector(
                            onTap: canGoNext ? goToNextDay : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: canGoNext 
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: canGoNext ? AppColors.primary : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Divider(height: 1, color: Colors.grey.shade200),
                    
                    // Entries list
                    Flexible(
                      child: currentEntries.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.local_bar_outlined, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Bu gün içecek yok',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: currentEntries.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final entry = currentEntries[index];
                                final drinkType = entry['drinkType'] as String? ?? 'Other';
                                final quantity = entry['quantity'] as int? ?? 1;
                                final points = entry['points'] as int? ?? 0;
                                final venue = entry['venue'] as String?;
                                final timestamp = entry['timestamp'] as Timestamp?;
                                final time = timestamp != null
                                    ? DateFormat('HH:mm').format(timestamp.toDate())
                                    : '';

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      // Time
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          time,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      
                                      // Emoji
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getDrinkEmoji(drinkType),
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${quantity}x $drinkType',
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '+$points',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.amber.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (venue != null && venue.isNotEmpty)
                                              Text(
                                                venue,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
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
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Stats Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.emoji_events,
                                iconColor: Colors.amber,
                                label: 'Toplam Puan',
                                value: '$_totalPoints',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.local_bar,
                                iconColor: AppColors.primary,
                                label: 'Toplam İçecek',
                                value: '$_totalDrinks',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Calendar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Today button row
                            if (!isSameDay(_focusedDay, DateTime.now()))
                              Padding(
                                padding: const EdgeInsets.only(top: 8, right: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _focusedDay = DateTime.now();
                                        _selectedDay = DateTime.now();
                                      });
                                    },
                                    icon: Icon(Icons.today, size: 18, color: AppColors.primary),
                                    label: Text(
                                      'Bugün',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            TableCalendar(
                          locale: 'tr_TR',
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Ay',
                            CalendarFormat.twoWeeks: '2 Hafta',
                            CalendarFormat.week: 'Hafta',
                          },
                          
                          // Calendar style
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            weekendTextStyle: TextStyle(color: AppColors.textPrimary),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            markerDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                            markerSize: 6,
                            markerMargin: const EdgeInsets.only(top: 6),
                          ),
                          
                          // Header style
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false, // Remove format button
                            titleCentered: true,
                            titleTextStyle: AppTextStyles.title2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
                            rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
                            headerPadding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                          ),
                          
                          // Custom header builder with dropdown hint
                          calendarBuilders: CalendarBuilders(
                            headerTitleBuilder: (context, day) {
                              return GestureDetector(
                                onTap: _showYearPicker,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('MMMM yyyy', 'tr_TR').format(day),
                                      style: AppTextStyles.title2.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          // Days of week style
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            weekendStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            
                            final events = _getEventsForDay(selectedDay);
                            _showDayEntriesPopup(selectedDay, events);
                          },
                          
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          
                          // Add year picker when tapping header
                          onHeaderTapped: (_) => _showYearPicker(),
                        ),
                          ],
                        ),
                      ),
                      
                      // Bottom padding for floating nav
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.title2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
