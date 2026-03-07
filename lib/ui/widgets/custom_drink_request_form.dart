import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/drink_categories.dart';
import '../../data/models/drink_category_model.dart';
import 'countsip_button.dart';

/// Standalone widget for the custom drink request wizard.
/// Extracted from AddEntryScreen to reduce file size.
class CustomDrinkRequestForm extends StatefulWidget {
  /// Called when the request is submitted successfully, so the parent can
  /// dismiss the focused-category view.
  final VoidCallback onSubmitSuccess;

  const CustomDrinkRequestForm({super.key, required this.onSubmitSuccess});

  @override
  State<CustomDrinkRequestForm> createState() => _CustomDrinkRequestFormState();
}

class _CustomDrinkRequestFormState extends State<CustomDrinkRequestForm> {
  static const List<DrinkCategory> _categories = drinkCategories;

  final _nameController = TextEditingController();
  final _abvController = TextEditingController();
  final _volumeController = TextEditingController();
  // Re-using desc controller to store selected category name
  final _categoryController = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _abvController.dispose();
    _volumeController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        final isActive = index <= _currentStep;
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
    switch (_currentStep) {
      case 0:
        return _buildRequestField('İçecek Adı', 'Örn: Hibiscus Gin Tonic', _nameController);
      case 1:
        return _buildCategoryPicker();
      case 2:
        return _buildRequestField('Yaklaşık Hacim (ml)', 'Örn: 330', _volumeController,
            keyboardType: TextInputType.number);
      case 3:
        return _buildRequestField('Alkol Oranı (%)', 'Örn: 12.5', _abvController,
            keyboardType: TextInputType.number);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KATEGORİ SEÇİN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: Colors.white30,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.where((c) => c.id != 'custom').map((c) {
            final isSelected = _categoryController.text == c.name;
            return GestureDetector(
              onTap: () => setState(() => _categoryController.text = c.name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  '${c.emoji} ${c.name}',
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
        if (_currentStep > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CountSipButton(
                onPressed: () => setState(() => _currentStep--),
                text: 'GERİ',
                variant: CountSipButtonVariant.outlined,
                borderRadius: 20,
                height: 56,
              ),
            ),
          ),
        Expanded(
          flex: 2,
          child: CountSipButton(
            onPressed: (_currentStep < 3
                ? () {
                    if (_currentStep == 0 && _nameController.text.isEmpty) return;
                    setState(() => _currentStep++);
                  }
                : _submitRequest),
            text: _currentStep < 3 ? 'DEVAM ET' : 'TALEBİ GÖNDER',
            isLoading: _isSubmitting,
            borderRadius: 20,
            height: 56,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
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
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 15),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Lütfen içecek adını girin');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('drink_requests').add({
        'name': _nameController.text.trim(),
        'abv': double.tryParse(_abvController.text) ?? 0.0,
        'volume': int.tryParse(_volumeController.text) ?? 0,
        'category': _categoryController.text.trim(),
        'requestedBy': user?.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: 'İsteğin başarıyla gönderildi! Onaylanınca eklenecek.',
        gravity: ToastGravity.CENTER,
      );

      widget.onSubmitSuccess();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Hata oluştu: $e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
