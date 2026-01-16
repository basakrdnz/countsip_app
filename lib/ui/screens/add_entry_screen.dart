import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  // Drink types with points
  static const List<Map<String, dynamic>> _drinkTypes = [
    {'name': 'Bira', 'emoji': '🍺', 'points': 1},
    {'name': 'Şarap', 'emoji': '🍷', 'points': 2},
    {'name': 'Viski', 'emoji': '🥃', 'points': 3},
    {'name': 'Vodka', 'emoji': '🍸', 'points': 3},
    {'name': 'Tekila', 'emoji': '🥃', 'points': 3},
    {'name': 'Kokteyl', 'emoji': '🍹', 'points': 2},
    {'name': 'Shot', 'emoji': '🥃', 'points': 2},
    {'name': 'Rakı', 'emoji': '🥃', 'points': 3},
    {'name': 'Diğer', 'emoji': '🍻', 'points': 1},
  ];

  String? _selectedDrink;
  int _quantity = 1;
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _venueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _getPoints() {
    if (_selectedDrink == null) return 0;
    final drink = _drinkTypes.firstWhere((d) => d['name'] == _selectedDrink);
    return (drink['points'] as int) * _quantity;
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      final newDateTime = DateTime(
        _selectedTime.year,
        _selectedTime.month,
        _selectedTime.day,
        time.hour,
        time.minute,
      );
      
      // Check if future time
      if (newDateTime.isAfter(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ İleri tarihli giriş yapamazsın!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      setState(() => _selectedTime = newDateTime);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedTime.isAfter(DateTime.now()) ? DateTime.now() : _selectedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Cannot select future
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  void _setNow() {
    setState(() => _selectedTime = DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Şu anki zaman ayarlandı'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (_selectedDrink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir içecek seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final points = _getPoints();
      final drink = _drinkTypes.firstWhere((d) => d['name'] == _selectedDrink);

      // Save entry
      await FirebaseFirestore.instance.collection('entries').add({
        'userId': user.uid,
        'drinkType': _selectedDrink,
        'drinkEmoji': drink['emoji'],
        'quantity': _quantity,
        'points': points,
        'venue': _venueController.text.trim(),
        'note': _noteController.text.trim(),
        'timestamp': Timestamp.fromDate(_selectedTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user's total points and drinks
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'totalPoints': FieldValue.increment(points),
        'totalDrinks': FieldValue.increment(_quantity),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_quantity}x $_selectedDrink eklendi! +$points puan 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('İçecek Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drink Type Grid
            _buildSectionTitle('Ne içtin?', Icons.local_bar),
            const SizedBox(height: AppSpacing.sm),
            _buildDrinkGrid(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Quantity Stepper
            _buildSectionTitle('Kaç tane?', Icons.add_circle_outline),
            const SizedBox(height: AppSpacing.sm),
            _buildQuantityStepper(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Date & Time
            _buildSectionTitle('Ne zaman?', Icons.access_time),
            const SizedBox(height: AppSpacing.sm),
            _buildDateTimePicker(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Venue (Optional)
            _buildSectionTitle('Nerede? (opsiyonel)', Icons.place_outlined),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: _venueController,
              hint: 'Murphy\'s Pub, Ev, Club XYZ...',
              maxLength: 50,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Note (Optional)
            _buildSectionTitle('Not (opsiyonel)', Icons.note_outlined),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: _noteController,
              hint: 'Harika bir geceydi! 🎉',
              maxLength: 200,
              maxLines: 2,
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Points Preview
            if (_selectedDrink != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '+${_getPoints()} puan kazanacaksın!',
                      style: AppTextStyles.title2.copyWith(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kaydet 🍻',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 100), // Bottom padding for nav
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.title3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDrinkGrid() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _drinkTypes.length,
        itemBuilder: (context, index) {
          final drink = _drinkTypes[index];
          final isSelected = _selectedDrink == drink['name'];
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDrink = drink['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    drink['emoji'],
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    drink['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '+${drink['points']} pt',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepperButton(
            icon: Icons.remove,
            enabled: _quantity > 1,
            onTap: () => setState(() => _quantity--),
          ),
          const SizedBox(width: 32),
          Text(
            '$_quantity',
            style: AppTextStyles.largeTitle.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 32),
          _buildStepperButton(
            icon: Icons.add,
            enabled: _quantity < 20,
            onTap: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy', 'tr_TR').format(_selectedTime),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(_selectedTime),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Now button
          GestureDetector(
            onTap: _setNow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Şimdi',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
    int maxLines = 1,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
