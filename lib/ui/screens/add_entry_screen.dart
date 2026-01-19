import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_colors.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> with SingleTickerProviderStateMixin {
  // --- Data Structure ---
  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'beer',
      'name': 'Bira',
      'emoji': '🍺',
      'portions': [
        {'name': '33 cl', 'volume': 330, 'abv': 4.5},
        {'name': '50 cl', 'volume': 500, 'abv': 4.5},
      ],
    },
    {
      'id': 'wine',
      'name': 'Şarap',
      'emoji': '🍷',
      'portions': [
        {'name': 'Kadeh (150 ml)', 'volume': 150, 'abv': 12.5},
      ],
    },
    {
      'id': 'raki',
      'name': 'Rakı',
      'emoji': '🥃',
      'portions': [
        {'name': 'Tek (35 ml)', 'volume': 35, 'abv': 45.0},
        {'name': 'Duble (70 ml)', 'volume': 70, 'abv': 45.0},
      ],
    },
    {
      'id': 'vodka',
      'name': 'Vodka',
      'emoji': '🍸',
      'portions': [
        {'name': 'Shot (40 ml)', 'volume': 40, 'abv': 38.5},
        {'name': 'Vodka + Enerji (200 ml)', 'volume': 200, 'abv': 38.5},
      ],
    },
    {
      'id': 'gin',
      'name': 'Gin',
      'emoji': '🍸',
      'portions': [
        {'name': 'Shot (35 ml)', 'volume': 35, 'abv': 42.0},
        {'name': 'Gin Tonic (250 ml)', 'volume': 250, 'abv': 42.0},
      ],
    },
    {
      'id': 'whiskey',
      'name': 'Viski',
      'emoji': '🥃',
      'portions': [
        {'name': 'Tek (35 ml)', 'volume': 35, 'abv': 41.5},
        {'name': 'Duble (70 ml)', 'volume': 70, 'abv': 41.5},
      ],
    },
    {
      'id': 'other',
      'name': 'Diğer',
      'emoji': '🍹',
      'portions': [
        {'name': 'Kokteyl', 'volume': 150, 'abv': 10.0},
        {'name': 'Shot', 'volume': 40, 'abv': 35.0},
      ],
    },
  ];

  // --- State ---
  final Map<String, int> _selectedEntries = {};
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  int _feelingScale = 5;
  bool _isLoading = false;
  late AnimationController _animationController;

  // --- Premium Accents ---
  Color get _accentColor {
    return Color.lerp(AppColors.primary, Colors.deepOrangeAccent, (_feelingScale - 1) / 9) ?? AppColors.primary;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animationController.dispose();
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
      _selectedEntries[key] = (_selectedEntries[key] ?? 0) + 1;
    });
    _animationController.forward(from: 0);
  }

  void _removePortion(String key) {
    if ((_selectedEntries[key] ?? 0) > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedEntries[key] = _selectedEntries[key]! - 1;
        if (_selectedEntries[key] == 0) _selectedEntries.remove(key);
      });
      _animationController.forward(from: 0);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedEntries.clear();
      _noteController.clear();
      _selectedTime = DateTime.now();
      _feelingScale = 5;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_getTotalCount() == 0) {
      HapticFeedback.vibrate();
      _showSnackBar('Lütfen en az bir içecek seçin', isError: true);
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
            'intoxicationLevel': _feelingScale,
            'timestamp': Timestamp.fromDate(_selectedTime),
            'createdAt': FieldValue.serverTimestamp(),
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
        _showSnackBar(
          '✓ Başarıyla kaydedildi! +${totalScore.toStringAsFixed(1)} puan 🎉',
          isError: false,
        );
        _resetForm();
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red.withOpacity(0.9) : Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- UI Components ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'İçecek Ekle',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.8,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildTimeSelector(),
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 70)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 220),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: _selectedEntries.isEmpty
                          ? KeyedSubtree(key: const ValueKey('grid'), child: _buildCategoryGrid())
                          : KeyedSubtree(key: const ValueKey('summary'), child: _buildSummaryAndCategories()),
                    ),
                    const SizedBox(height: 40),
                    _buildFeelingScale(),
                    const SizedBox(height: 40),
                    _buildNoteField(),
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
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                Icon(Icons.schedule_rounded, size: 16, color: _accentColor),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(_selectedTime),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Text(
                  DateFormat('dd MMM', 'tr_TR').format(_selectedTime),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPortionPicker(category),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  category['emoji'],
                  style: const TextStyle(fontSize: 34),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                category['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPortionPicker(Map<String, dynamic> category) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: SafeArea(
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
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(category['emoji'], style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Text(
                      category['name'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: (category['portions'] as List).length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final portion = category['portions'][index];
                  final score = _calculateScore(portion['volume'], portion['abv']);
                  return _buildPortionCard(category, portion, score);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortionCard(Map<String, dynamic> category, Map<String, dynamic> portion, double score) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _addPortion(category['id'], portion);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(portion['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        '%${portion['abv']} • ${portion['volume']} ml',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: _accentColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    '+${score.toStringAsFixed(1)} pt',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryAndCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade100, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seçimlerim', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedEntries.clear());
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Temizle'),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._selectedEntries.keys.map((key) {
                final count = _selectedEntries[key]!;
                final categoryId = key.split('|')[0];
                final portionName = key.split('|')[1];
                final category = _categories.firstWhere((c) => c['id'] == categoryId);
                return _buildSelectedItem(key, count, category, portionName);
              }),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'BAŞKA NE VAR?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (context, index) => _buildQuickAddCard(_categories[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItem(String key, int count, Map<String, dynamic> category, String portionName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(category['emoji'], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(portionName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                _buildSmallActionBtn(Icons.remove, () => _removePortion(key)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('$count', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _accentColor)),
                ),
                _buildSmallActionBtn(Icons.add, () {
                  final portion = (category['portions'] as List).firstWhere((p) => p['name'] == portionName);
                  _addPortion(category['id'], portion);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.grey.shade400),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildQuickAddCard(Map<String, dynamic> category) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100, width: 1.5)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPortionPicker(category),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(category['emoji'], style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(category['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(10, (index) {
            final val = index + 1;
            final isSelected = _feelingScale == val;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _feelingScale = val);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? _accentColor : Colors.grey.shade100, width: 2),
                    boxShadow: isSelected ? [BoxShadow(color: _accentColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$val',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
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
            hintText: 'Mekan, arkadaş grubu veya özel bir an...',
            hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final totalScore = _getTotalScore();
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.grey.shade100, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, -10))],
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
                        const Text('TAHMİNİ PUAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: totalScore),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, _) => Text(
                            '+${value.toStringAsFixed(1)} pt',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _accentColor, letterSpacing: -1),
                          ),
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
                        decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 18, color: _accentColor),
                            const SizedBox(width: 4),
                            const Text('ŞİMDİ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                      shadowColor: _accentColor.withOpacity(0.35),
                    ),
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text('KAYDET', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
