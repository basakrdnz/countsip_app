import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/services/bac_service.dart';
import '../../data/models/drink_entry_model.dart';

class BacStatsScreen extends StatefulWidget {
  final BacResult? currentBac;
  final double? weightKg;
  final double? heightCm;
  final int? age;
  final String? gender;

  const BacStatsScreen({
    super.key,
    this.currentBac,
    this.weightKg,
    this.heightCm,
    this.age,
    this.gender,
  });

  @override
  State<BacStatsScreen> createState() => _BacStatsScreenState();
}

class _BacStatsScreenState extends State<BacStatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final ScrollController _intensityScrollController = ScrollController();




  // Data holders
  bool _loading = true;


  // Computed
  List<FlSpot> _bacCurveSpots = [];
  Map<String, int> _categoryMap = {};
  
  // Storage for all entries to support pagination
  List<Map<String, dynamic>> _allEntries = [];
  
  String _intensityPeriod = 'G'; // G, H, A
  int _currentPageIndex = 0; // 0 = Current (Today/This Week), Increases as we go back
  
  Map<String, double> _records = {};
  String _insightText = '';
  int? _touchedIndex; // For tracking touch on intensity chart




  late PageController _pageController; // Persistent controller

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _intensityScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // DATA LOADING
  // ─────────────────────────────────────────────
  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));

    try {
      // Load all entries in the last 90 days for stats
      final allSnap = await FirebaseFirestore.instance
          .collection('entries')
          .where('userId', isEqualTo: userId)
          .where('timestamp',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(now.subtract(const Duration(days: 90))))
          .orderBy('timestamp', descending: false)
          .get();

      final all = allSnap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      // Partition
      final today = all.where((e) {
        final ts = (e['timestamp'] as Timestamp).toDate();
        return ts.isAfter(todayStart);
      }).toList();

      final week = all.where((e) {
        final ts = (e['timestamp'] as Timestamp).toDate();
        return ts.isAfter(weekStart);
      }).toList();

      if (mounted) {
        setState(() {
          _allEntries = all;
          _currentPageIndex = 0; // Reset to current on reload
        });
        _computeAnalytics(all, today, week);
      }





    } catch (e) {
      debugPrint('BacStatsScreen load error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _animController.forward();
      }
    }
  }

  void _computeAnalytics(
    List<Map<String, dynamic>> all,
    List<Map<String, dynamic>> today,
    List<Map<String, dynamic>> week,
  ) {
    _computeBacCurve(today);
    _computeCategoryMap(all);
    // _computeIntensityData is no longer needed upfront, we calculate on the fly for the page
    _computeRecords(today, week); // Removed 'all'
    _buildInsight(week); // Removed 'all'




  }

  // Today's BAC curve using BacService simulation
  void _computeBacCurve(List<Map<String, dynamic>> today) {
    if (today.isEmpty ||
        widget.weightKg == null ||
        widget.heightCm == null ||
        widget.age == null ||
        widget.gender == null) {
      _bacCurveSpots = [];
      return;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final spots = <FlSpot>[];

    // Pre-convert today's Firestore maps to typed DrinkEntry objects once
    final todayEntries = today
        .where((e) => e['timestamp'] != null)
        .map((e) => DrinkEntry.fromMap(e['id'] as String? ?? '', e))
        .toList();

    // Simulate every 15 minutes from todayStart → now
    DateTime runner = todayStart;
    while (runner.isBefore(now.add(const Duration(minutes: 1)))) {
      final relevantDrinks = todayEntries
          .where((e) => e.timestamp.isBefore(runner))
          .toList();

      if (relevantDrinks.isNotEmpty) {
        final result = BacService.calculateDynamicBac(
          weightKg: widget.weightKg!,
          heightCm: widget.heightCm!,
          age: widget.age!,
          gender: widget.gender!,
          drinks: relevantDrinks,
        );
        final hoursFromMidnight =
            runner.difference(todayStart).inMinutes / 60.0;
        spots.add(FlSpot(hoursFromMidnight, result.average));
      }
      runner = runner.add(const Duration(minutes: 15));
    }

    _bacCurveSpots = spots;
  }

  void _computeCategoryMap(List<Map<String, dynamic>> all) {
    final map = <String, int>{};
    for (final e in all) {
      final type = e['drinkType'] as String? ?? 'Diğer';
      final qty = (e['quantity'] as int? ?? 1);
      map[type] = (map[type] ?? 0) + qty;
    }
    // Sort by count desc, keep top 5
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _categoryMap = Map.fromEntries(sorted.take(5));

  }





  // Methods _computeRecords and _buildInsight moved to end of file to fix duplication


  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            SliverFadeTransition(
              opacity: _fadeAnim,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _buildHeroCard(),
                  _buildSection('Bugünkü BAC Eğrisi', _buildBacCurveChart(), icon: Icons.insights_rounded),
                  _buildSection('İçecek Kategorileri', _buildCategoryBars(), icon: AppIcons.drinkBeer),
                  _buildSection('İçecek Geçmişi', _buildIntensitySection(), icon: Icons.calendar_month_rounded),

                  _buildSection('Kişisel Rekorlar', _buildRecordsGrid(), 
                      icon: Icons.emoji_events_rounded,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24)),

                  _buildInsightCard(),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Analiz',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
    );
  }

  // ─────────────────────────────────────────────
  // INSIGHT CARD
  // ─────────────────────────────────────────────
  Widget _buildInsightCard() {
    if (_insightText.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Öneri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _insightText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.5,
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

  // ─────────────────────────────────────────────
  // HERO CARD
  // ─────────────────────────────────────────────
  Widget _buildHeroCard() {
    final bac = widget.currentBac;
    final bacValue = bac?.average ?? 0.0;

    Color trendColor;
    IconData trendIcon;
    String trendLabel;
    switch (bac?.trend) {
      case BacTrend.rising:
        trendColor = const Color(0xFFEF5350);
        trendIcon = Icons.trending_up_rounded;
        trendLabel = 'YÜKSELİYOR';
        break;
      case BacTrend.falling:
        trendColor = AppColors.primary; // Markanın ana turuncu rengi
        trendIcon = Icons.trending_down_rounded;
        trendLabel = 'DÜŞÜYOR';
        break;
      default:
        trendColor = const Color(0xFF9E9E9E); // Gri
        trendIcon = Icons.trending_flat_rounded;
        trendLabel = 'STABİL';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              trendColor.withOpacity(0.12),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: trendColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: trendColor.withOpacity(0.30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: trendColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        trendLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: trendColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  bac?.statusLabel ?? 'VERİ YOK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bacValue.toStringAsFixed(2),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: trendColor,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                  child: Text(
                    '‰ BAC',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bac?.statusDescription ?? 'Durum bilgisi için içecek kaydet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (bac != null && !bac.isZero) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _heroStat('Günlük Zirve',
                      '${bac.peakAverage.toStringAsFixed(2)}‰'),
                  _heroStatDivider(),
                  _heroStat('Aralık',
                      '${bac.min.toStringAsFixed(2)} – ${bac.max.toStringAsFixed(2)}'),
                  if (bac.trend == BacTrend.falling &&
                      bac.recoveryPercentage > 0.01) ...[
                    _heroStatDivider(),
                    _heroStat('Toparlanma',
                        '%${(bac.recoveryPercentage * 100).round()}'),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _heroStatDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white.withOpacity(0.08),
      );

  // ─────────────────────────────────────────────
  // SECTION WRAPPER
  // ─────────────────────────────────────────────
  Widget _buildSection(String title, Widget content, {IconData? icon, EdgeInsets? contentPadding}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: contentPadding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BAC CURVE CHART
  // ─────────────────────────────────────────────
  Widget _buildBacCurveChart() {
    if (_bacCurveSpots.isEmpty) {
      return _emptyState('Bugün henüz içecek kaydı yok');
    }

    final maxY = (_bacCurveSpots.map((s) => s.y).reduce(math.max) * 1.3)
        .clamp(0.5, 4.0);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(2)} ‰',
                    GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 0.5,
                getTitlesWidget: (v, meta) => Text(
                  v.toStringAsFixed(1),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, color: AppColors.textTertiary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 4,
                getTitlesWidget: (v, meta) {
                  final h = v.toInt();
                  return Text(
                    '${h.toString().padLeft(2, '0')}:00',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 9, color: AppColors.textTertiary),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 24,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: _bacCurveSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.primary,
                  strokeColor: AppColors.background,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.25),
                    AppColors.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0.5,
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => 'KEYİFLİ',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      color: const Color(0xFF4CAF50).withOpacity(0.7)),
                ),
              ),
              HorizontalLine(
                y: 0.8,
                color: const Color(0xFFFF9800).withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => 'ÇAKIRKEYİF',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      color: const Color(0xFFFF9800).withOpacity(0.7)),
                ),
              ),
              HorizontalLine(
                y: 1.2,
                color: const Color(0xFFEF5350).withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => 'SARHOŞ',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      color: const Color(0xFFEF5350).withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CATEGORY BARS
  // ─────────────────────────────────────────────
  Widget _buildCategoryBars() {
    if (_categoryMap.isEmpty) {
      return _emptyState('Henüz içecek kaydı yok');
    }

    final maxCount = _categoryMap.values.reduce(math.max);
    final emojis = {
      'Bira': '🍺',
      'Şarap': '🍷',
      'Kırmızı Şarap': '🍷',
      'Beyaz Şarap': '🥂',
      'Rakı': '🥛',
      'Viski': '🥃',
      'Votka': '🍸',
      'Cin': '🍹',
      'Tekila': '🥃',
      'Şampanya': '🍾',
      'Kokteyl': '🍹',
    };

    return Column(
      children: _categoryMap.entries.toList().asMap().entries.map((entry) {
        final cat = entry.value.key;
        final count = entry.value.value;
        final pct = count / maxCount;
        final emoji = emojis[cat] ?? '🍶';

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(emoji,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$count kadeh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.8),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  // APPLE HEALTH STYLE INTENSITY SECTION
  // ─────────────────────────────────────────────
  Widget _buildIntensitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSegmentedControl(),
        const SizedBox(height: 20),
        _buildIntensityHeader(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: _buildIntensityChart(),
        ),
      ],
    );
  }



  Widget _buildSegmentedControl() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ['G', 'H', 'A', '6A', 'Y'].map((p) {

          final isSel = _intensityPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _intensityPeriod = p;
                  _currentPageIndex = 0;
                  _touchedIndex = null;
                });
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
                _loadData(); // Re-compute everything
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSel ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),

              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIntensityHeader() {
    // 1. Calculate data for the CURRENT displayed page (_currentPageIndex)
    final pageData = _getDataForPage(_currentPageIndex);
    final map = pageData.data;
    double total = 0;
    map.forEach((k, v) => total += v);
    
    // Default Header Data
    String mainValue = total.toInt().toString();
    String mainLabel = 'toplam içecek';
    String periodStr = pageData.label;

    // 2. If touching a specific bar, override with bar details
    if (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < map.length) {
      final val = map[_touchedIndex!] ?? 0;
      mainValue = '$val';
      mainLabel = 'içecek';
      periodStr = _getDetailLabelForBar(_currentPageIndex, _touchedIndex!);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              mainValue,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              mainLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        Text(
          periodStr,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }




  Widget _buildIntensityChart() {
    return SizedBox(
      height: 200, // Slightly taller for labels
      child: PageView.builder(
        reverse: true, // Index 0 is Rightmost (Latest)
        itemCount: 50, // Limit scrolling back to 50 periods for now
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
            _touchedIndex = null; // Clear touch when sliding
          });
        },
        itemBuilder: (context, index) {
          return _buildChartPage(index);
        },
      ),
    );
  }

  Widget _buildChartPage(int pageIndex) {
    final pageData = _getDataForPage(pageIndex);
    final map = pageData.data;
    
    if (map.isEmpty && pageIndex > 0) {
      return Center(
        child: Text('Bu tarih için kayıt yok',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppColors.textTertiary)),
      );
    }

    final maxVal = map.values.isEmpty 
        ? 1.0 
        : map.values.reduce(math.max).toDouble();
            
    int count = map.length;
    final screenWidth = MediaQuery.of(context).size.width - 64; // Available width
    
    // Fit to screen: dynamic bar width based on count
    // G (24h) -> 24 bars
    // H (7d) -> 7 bars
    // A (30d) -> 30 bars (Might be tight, but let's fit it as requested or allow slight scroll if needed? 
    // User asked: "Bİ EKRANA ... SIĞABİLMELİ". 30 bars in ~350px is ~11px per bar. Doable.)
    double barWidth = (screenWidth / count) * 0.6; // 60% bar, 40% spacing
    
    // Limits
    if (barWidth < 4) barWidth = 4;
    if (barWidth > 32) barWidth = 32;

    final bars = List.generate(count, (i) {
      final val = (map[i] ?? 0).toDouble();
      final isTouched = _touchedIndex == i;
      
      final activeGradient = LinearGradient(
        colors: [
           AppColors.primary,
           AppColors.primary.withValues(alpha: 0.6),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

      final touchedGradient = LinearGradient(
        colors: [
           AppColors.primary,
           AppColors.primary.withValues(alpha: 0.9),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            width: barWidth,
            gradient: val > 0 ? (isTouched ? touchedGradient : activeGradient) : null,
            color: val == 0 ? Colors.white.withValues(alpha: 0.04) : null,
            borderRadius: BorderRadius.circular(barWidth / 2), // fully rounded pills
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: math.max(maxVal * 1.1, 1),
              color: isTouched 
                 ? Colors.white.withValues(alpha: 0.08) 
                 : Colors.white.withValues(alpha: 0.02), // subtle global background track
            ),
          ),
        ],
      );
    });
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            enabled: true,
            allowTouchBarBackDraw: true,
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (barTouchResponse?.spot != null) {
                 setState(() {
                   _touchedIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
                 });
              } else if (event is FlTapUpEvent) {
                 // Only clear if tap is released on empty space
                 setState(() => _touchedIndex = null);
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              getTooltipItem: (_,__,___,____) => null, // Info in header
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxVal / 3).clamp(1, 100).toDouble(),
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (v, meta) => _getBottomTitle(v, pageIndex),
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          maxY: maxVal * 1.3,
          barGroups: bars,
        ),
        duration: const Duration(milliseconds: 0), // No animation on scroll/rebuild for snappy feel
      ),
    );
  }

  // Helper Models
  _PageData _getDataForPage(int pageIndex) {
    final now = DateTime.now();
    final map = <int, int>{};
    String label = '';

    if (_intensityPeriod == 'G') {
      // Each page is 1 Day. Index 0 = Today. Index 1 = Yesterday.
      final targetDate = now.subtract(Duration(days: pageIndex));
      label = DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(targetDate);
      
      // Fill 24 hours
      for (int h = 0; h < 24; h++) map[h] = 0;
      
      for (final e in _allEntries) {
        final ts = (e['timestamp'] as Timestamp).toDate();
        if (ts.year == targetDate.year && ts.month == targetDate.month && ts.day == targetDate.day) {
           map[ts.hour] = (map[ts.hour] ?? 0) + (e['quantity'] as int? ?? 1);
        }
      }
    } else if (_intensityPeriod == 'H') {
      // Each page is 1 Week (7 days). Index 0 = Current Week (ending today/now).
      // Or should we align to "This Week" (Mon-Sun)?
      // "Bi haftanın günleri". Usually means fixed Mon-Sun or floating 7 days.
      // Let's do floating 7 days ending on (Now - pageIndex*7). 
      // i.e. Page 0 = [Now-6, Now]. Page 1 = [Now-13, Now-7].
      
      final end = now.subtract(Duration(days: pageIndex * 7));
      final start = end.subtract(const Duration(days: 6));
      label = '${DateFormat('d MMM', 'tr_TR').format(start)} – ${DateFormat('d MMM', 'tr_TR').format(end)}';
      
      for (int i = 0; i < 7; i++) {
        // Bar 0 is start date, Bar 6 is end date
        final d = start.add(Duration(days: i));
        int c = 0;
        for (final e in _allEntries) {
          final ts = (e['timestamp'] as Timestamp).toDate();
           if (ts.year == d.year && ts.month == d.month && ts.day == d.day) {
             c += (e['quantity'] as int? ?? 1);
           }
        }
        map[i] = c;
      }
    } else if (_intensityPeriod == 'A') {
      // Each page is 1 Month. Align to Calendar Month?
      // "Günü seçince saatler... Hafta bitince haftanın günleri..." 
      // Typically 'A' implies Monthly view. Let's do Calendar Months.
      // Page 0 = Current Month. Page 1 = Last Month.
      
      final d = DateTime(now.year, now.month - pageIndex, 1); // 1st of target month
      label = DateFormat('MMMM yyyy', 'tr_TR').format(d);
      
      final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
      
      for (int i = 1; i <= daysInMonth; i++) {
        map[i-1] = 0; // index 0 = day 1
      }
      
      for (final e in _allEntries) {
         final ts = (e['timestamp'] as Timestamp).toDate();
         if (ts.year == d.year && ts.month == d.month) {
            map[ts.day - 1] = (map[ts.day - 1] ?? 0) + (e['quantity'] as int? ?? 1);
         }
      }
    } else if (_intensityPeriod == 'Y') {
      // Each page is 1 Year.
      final y = now.year - pageIndex;
      label = '$y Yılı';
      
      for (int i=1; i<=12; i++) map[i-1] = 0;
      
      for (final e in _allEntries) {
         final ts = (e['timestamp'] as Timestamp).toDate();
         if (ts.year == y) {
            map[ts.month - 1] = (map[ts.month - 1] ?? 0) + (e['quantity'] as int? ?? 1);
         }
      }
    } else {
        // 6A not implemented in paginated view nicely, fallback to "Last 6 Months from Now" fixed chart?
        // Or implement page = 6 month block? 
        // User rarely uses 6A with pagination. Let's treat 6A as "This 6 Months".
        // Actually, let's just make it 6 Months blocks.
        final end = DateTime(now.year, now.month - (pageIndex * 6), 1);
        final start = DateTime(end.year, end.month - 5, 1);
        label = '${DateFormat('MMM yyyy', 'tr_TR').format(start)} - ${DateFormat('MMM yyyy', 'tr_TR').format(end)}';
        
        for (int i=0; i<6; i++) {
          map[i] = 0;
          final m = DateTime(start.year, start.month + i, 1);
          for (final e in _allEntries) {
             final ts = (e['timestamp'] as Timestamp).toDate();
             if (ts.year == m.year && ts.month == m.month) {
               map[i] = (map[i] ?? 0) + (e['quantity'] as int? ?? 1);
             }
          }
        }
    }
    
    return _PageData(map, label);
  }

  Widget _getBottomTitle(double value, int pageIndex) {
     final i = value.toInt();
     String text = '';
     
     if (_intensityPeriod == 'G') {
        if (i % 4 == 0) text = '$i:00'; // Every 4 hours
     } else if (_intensityPeriod == 'H') {
       // i=0 is start date of that week
       // We calculated start of week in _getDataForPage logic
       // Let's replicate logic lightly or pass it?
       // Re-calc:
       final now = DateTime.now();
       final end = now.subtract(Duration(days: pageIndex * 7));
       final start = end.subtract(const Duration(days: 6));
       final d = start.add(Duration(days: i));
       text = DateFormat('E', 'tr_TR').format(d);
     } else if (_intensityPeriod == 'A') {
        if (i % 5 == 0) text = '${i+1}';
     } else if (_intensityPeriod == 'Y') {
        if (i % 2 == 0) { // Jan, Mar, May...
           // i=0 is Jan
           // We need short month name
           text = DateFormat('MMM', 'tr_TR').format(DateTime(2024, i+1, 1));
        }
     }
     
     return Text(text, style: GoogleFonts.plusJakartaSans(
         fontSize: 9, color: AppColors.textTertiary));
  }
  
  String _getDetailLabelForBar(int pageIndex, int barIndex) {
     final now = DateTime.now();
     
     if (_intensityPeriod == 'G') {
       return '${barIndex.toString().padLeft(2,'0')}:00 - ${(barIndex+1).toString().padLeft(2,'0')}:00';
     } else if (_intensityPeriod == 'H') {
       final end = now.subtract(Duration(days: pageIndex * 7));
       final start = end.subtract(const Duration(days: 6));
       final d = start.add(Duration(days: barIndex));
       return DateFormat('d MMMM yyyy', 'tr_TR').format(d);
     } else if (_intensityPeriod == 'A') {
       final d = DateTime(now.year, now.month - pageIndex, barIndex + 1);
       return DateFormat('d MMMM yyyy', 'tr_TR').format(d);
     } else if (_intensityPeriod == 'Y') {
        final y = now.year - pageIndex;
        final d = DateTime(y, barIndex + 1, 1);
        return DateFormat('MMMM yyyy', 'tr_TR').format(d);
     }
     return '';
  }





  // ─────────────────────────────────────────────
  // RECORDS GRID
  // ─────────────────────────────────────────────
  Widget _buildRecordsGrid() {
    if (_records.isEmpty) {
      return _emptyState('Veri yüklenemedi');
    }

    final items = [
      _RecordItem(
        icon: Icons.show_chart_rounded,
        iconColor: const Color(0xFFE57373), // Red-ish for peak
        label: 'Zirve Etki',
        value: '${_records['maxBac']?.toStringAsFixed(2) ?? '0.00'}%',
      ),
      _RecordItem(
        icon: Icons.local_cafe_rounded,
        iconColor: const Color(0xFFFFB74D), // Orange
        label: 'Toplam İçecek',
        value: '${_records['totalDrinks']?.toInt() ?? 0}',
      ),
      _RecordItem(
        icon: Icons.emoji_events_rounded,
        iconColor: const Color(0xFFFFD54F), // Gold
        label: 'Toplam Puan',
        value: '${_records['totalPoints']?.toInt() ?? 0}',
      ),
      _RecordItem(
        icon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF64B5F6), // Blue
        label: 'Bu Hafta',
        value: '${_records['weekDrinks']?.toInt() ?? 0} İçecek',
      ),
      _RecordItem(
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFF81C784), // Green for streak
        label: 'Temiz Seri',
        value: '${_records['cleanStreak']?.toInt() ?? 0} Gün',
      ),
      _RecordItem(
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFF06292), // Pink
        label: 'Fav. İçecek',
        value: _categoryMap.isNotEmpty ? _categoryMap.keys.first : '–',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8, // Even taller aspect ratio as requested
      padding: EdgeInsets.zero,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: items.map((item) => _buildRecordCard(item)).toList(),
    );
  }

  Widget _buildRecordCard(_RecordItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Premium Glass Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.iconColor.withValues(alpha: 0.25),
                  item.iconColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: item.iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              item.icon,
              color: item.iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _computeRecords(List<Map<String, dynamic>> today, List<Map<String, dynamic>> week) {
    if (_allEntries.isEmpty) return; // Use class member
    
    // ... logic using _allEntries instead of passed 'all'
    double maxBac = 0;
    for (final e in _allEntries) {
      final bac = (e['estimated_bac'] ?? 0).toDouble();
      if (bac > maxBac) maxBac = bac;
    }
    
    int totalDrinks = 0;
    _allEntries.forEach((e) => totalDrinks += (e['quantity'] as int? ?? 1));

    // Calculate Week Drinks
    int weekDrinks = 0;
    week.forEach((e) => weekDrinks += (e['quantity'] as int? ?? 1));
    
    // Calculate Clean Streak
    final now = DateTime.now();
    int streak = 0;
    // ... (rest of streak logic using _allEntries if needed, or just keep existing logic)
    // Actually existing logic likely uses 'all'.
     // sort
    final sorted = List<Map<String, dynamic>>.from(_allEntries);
    sorted.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
    
    if (sorted.isNotEmpty) {
       final last = (sorted.first['timestamp'] as Timestamp).toDate();
       final diff = now.difference(last).inDays;
       streak = diff;
    }

    _records = {
      'maxBac': maxBac,
      'totalDrinks': totalDrinks.toDouble(),
      'totalPoints': totalDrinks * 10.0, // Mock points
      'weekDrinks': weekDrinks.toDouble(),
      'cleanStreak': streak.toDouble(),
    };
  }

  // ─────────────────────────────────────────────
  // INSIGHT GENERATION
  // ─────────────────────────────────────────────
  void _buildInsight(List<Map<String, dynamic>> week) {
    if (week.isEmpty) {
      _insightText = 'Bu hafta henüz bir tüketim kaydı yok. Vücudun sana minnettar!';
      return;
    }
    
    // Simple insight logic
    int total = 0;
    week.forEach((e) => total += (e['quantity'] as int? ?? 1));
    
    if (total > 15) {
      _insightText = 'Bu hafta tüketim biraz yüksek. Sıradaki günlerde su tüketimini artırmayı unutma!';
    } else if (total > 5) {
      _insightText = 'Dengeli bir hafta geçiriyorsun. Keyifli anların tadını çıkar!';
    } else {
      _insightText = 'Harika bir hafta! Kontrollü tüketiminle sağlığına dikkat ediyorsun.';
    }
  }

  // ─────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────
  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
} // End of _BacStatsScreenState

class _RecordItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _RecordItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}

class _PageData {
  final Map<int, int> data;
  final String label;
  _PageData(this.data, this.label);
}
