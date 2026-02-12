import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import 'package:flutter/cupertino.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  bool _isEditingName = false;
  bool _isEditingUsername = false;
  String? _photoUrl;
  String? _originalName;
  String? _originalUsername;
  String? _usernameError;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _startEditingName() {
    setState(() {
      _originalName = _nameController.text;
      _isEditingName = true;
    });
    _nameFocusNode.requestFocus();
  }
  
  void _saveName() {
    if (_nameController.text.trim().isNotEmpty) {
      final newName = _nameController.text.trim();
      if (newName != _userData?['name']) {
        _updateField('name', newName);
      }
    }
    setState(() => _isEditingName = false);
    _nameFocusNode.unfocus();
  }
  
  void _cancelEditingName() {
    _nameController.text = _originalName ?? '';
    setState(() => _isEditingName = false);
    _nameFocusNode.unfocus();
  }

  Future<void> _startEditingUsername() async {
    // Check weekly limit
    final lastChanged = _userData?['usernameLastChanged'];
    if (lastChanged != null) {
      final lastChangedDate = (lastChanged as Timestamp).toDate();
      final daysSinceChange = DateTime.now().difference(lastChangedDate).inDays;
      if (daysSinceChange < 7) {
        final daysRemaining = 7 - daysSinceChange;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı adını $daysRemaining gün sonra değiştirebilirsin'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    // Show warning about weekly limit
    final confirmed = await showDialog<bool>(
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
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kullanıcı Adı Değiştir',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kullanıcı adını haftada sadece 1 kez değiştirebilirsin. Devam etmek istiyor musun?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
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
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'DEĞİŞTİR',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
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
    
    if (confirmed != true) return;
    
    setState(() {
      _originalUsername = _usernameController.text;
      _isEditingUsername = true;
      _usernameError = null;
    });
    _usernameFocusNode.requestFocus();
  }
  
  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim().toLowerCase();
    
    // Validate length
    if (newUsername.length < 6) {
      setState(() => _usernameError = 'En az 6 karakter olmalı');
      return;
    }
    
    // Validate format
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(newUsername)) {
      setState(() => _usernameError = 'Sadece harf, rakam ve _ kullanabilirsin');
      return;
    }
    
    // Check if same as current
    if (newUsername == _userData?['username']) {
      setState(() {
        _isEditingUsername = false;
        _usernameError = null;
      });
      _usernameFocusNode.unfocus();
      return;
    }
    
    // Check uniqueness
    final existingDoc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(newUsername)
        .get();
    
    if (existingDoc.exists) {
      setState(() => _usernameError = 'Bu kullanıcı adı zaten alınmış');
      return;
    }
    
    // Save new username
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final oldUsername = _userData?['username'] as String?;
      
      // Delete old username reservation
      if (oldUsername != null) {
        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(oldUsername)
            .delete();
      }
      
      // Reserve new username
      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(newUsername)
          .set({'uid': user.uid, 'createdAt': FieldValue.serverTimestamp()});
      
      // Update user doc
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'username': newUsername,
            'usernameLastChanged': FieldValue.serverTimestamp(),
          });
      
      // Update local state properly
      final now = DateTime.now();
      setState(() {
        _userData = _userData ?? {};
        _userData!['username'] = newUsername;
        _userData!['usernameLastChanged'] = Timestamp.fromDate(now);
        _usernameController.text = newUsername;
        _isEditingUsername = false;
        _usernameError = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Kullanıcı adı güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    _usernameFocusNode.unfocus();
  }
  
  void _cancelEditingUsername() {
    _usernameController.text = _originalUsername ?? '';
    setState(() {
      _isEditingUsername = false;
      _usernameError = null;
    });
    _usernameFocusNode.unfocus();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _userData = doc.data() ?? {};
            _photoUrl = _userData?['photoUrl'] ?? user.photoURL;
            _nameController.text = _userData?['name'] ?? '';
            _usernameController.text = _userData?['username'] ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    
    // 1. Explain why we need gallery/camera access
    final proceed = await showDialog<bool>(
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
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Profil Fotoğrafı Seç',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Profilini kişiselleştirmek için galerinden bir fotoğraf seçebilir veya yeni bir tane çekebilirsin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
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
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'DEVAM ET',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
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

    if (proceed != true) return;

    // 1.5. Check Permissions
    final photoStatus = await Permission.photos.status;
    final cameraStatus = await Permission.camera.status;

    if (photoStatus.isPermanentlyDenied || cameraStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf erişimi için ayarlardan izin vermelisin.')),
        );
      }
      openAppSettings();
      return;
    }

    // 2. Select source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fotoğraf Kaynağı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceCard(
                    icon: AppIcons.camera,
                    label: 'Kamera',
                    color: Colors.blue,
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceCard(
                    icon: AppIcons.gallery,
                    label: 'Galeri',
                    color: Colors.orange,
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
    
    if (source == null) return;

    // Check specific permission based on source
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    } else {
      // For gallery, permission_handler photos check is enough for iOS and Android 13+
      // For older Android, it falls back gracefully or isn't strictly required for pickImage
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        // Fallback for some Android versions where Permission.photos might not trigger
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) return;
      }
    }
    
    if (source == null) return;
    
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    // 3. Crop Image (How it should look)
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı Düzenle',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Fotoğrafı Düzenle',
          cancelButtonTitle: 'Vazgeç',
          doneButtonTitle: 'Bitti',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı girişi yapılmamış');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Upload task
      final uploadTask = storageRef.putFile(File(croppedFile.path));
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Database
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
        _userData = _userData ?? {};
        _userData!['photoUrl'] = downloadUrl;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profil fotoğrafın başarıyla güncellendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Photo upload error: $e');
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmedik bir hata oluştu. Lütfen tekrar dene.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateField(String field, dynamic value) async {
    await _updateMultipleFields({field: value});
  }

  Future<void> _updateMultipleFields(Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Change Detection: Only update if there are actual changes
    final Map<String, dynamic> actualChanges = {};
    final Map<String, dynamic> oldValues = {};

    updates.forEach((field, value) {
      final oldValue = _userData?[field];
      if (oldValue != value) {
        actualChanges[field] = value;
        oldValues[field] = oldValue;
      }
    });

    if (actualChanges.isEmpty) return;

    // Optimistic update
    setState(() {
      _userData = _userData ?? {};
      actualChanges.forEach((field, value) {
        _userData![field] = value;
      });
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(actualChanges);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Güncellendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        if (_userData != null) {
          oldValues.forEach((field, value) {
            _userData![field] = value;
          });
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }



  void _showEditNumberDialog(String field, String title, String unit, int min, int max) {
    int value = _userData?[field] ?? ((min + max) ~/ 2);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              
              // Value with unit - big and centered
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Minimal slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.white.withOpacity(0.05),
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  onChanged: (v) => setSheetState(() => value = v.round()),
                ),
              ),
              
              // Min/Max labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$min', style: TextStyle(fontSize: 12, color: AppColors.textTertiary.withOpacity(0.4))),
                    Text('$max', style: TextStyle(fontSize: 12, color: AppColors.textTertiary.withOpacity(0.4))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Save button - full width, minimal
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _updateField(field, value);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.buttonOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showDobDialog() {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_userData?['dob'] != null) {
      initialDate = (_userData!['dob'] as Timestamp).toDate();
    }
    
    DateTime newDate = initialDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Doğum Tarihi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: DateTime(1900),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (val) => newDate = val,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  final age = DateTime.now().year - newDate.year;
                  // Update both dob and age in one call to avoid double notifications
                  _updateMultipleFields({
                    'dob': Timestamp.fromDate(newDate),
                    'age': age,
                  });
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.buttonOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            
            // Gender options - side by side
            Row(
              children: [
                Expanded(child: _buildGenderOption('Erkek', 'male')),
                const SizedBox(width: 16),
                Expanded(child: _buildGenderOption('Kadın', 'female')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = _userData?['gender'] == value;
    return GestureDetector(
      onTap: () {
        _updateField('gender', value);
        Navigator.pop(context);
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value == 'male' ? AppIcons.user : AppIcons.user, // Add gender specific if available
              color: isSelected ? AppColors.primary : AppColors.textTertiary.withOpacity(0.5),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textTertiary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _userData?['name'] ?? 'Kullanıcı';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Bilgileri', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Profile Picture Section with coral glow ring
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        // Glow container
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              image: _photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                            child: _isUploadingPhoto
                                ? const Center(child: CircularProgressIndicator())
                                : _photoUrl == null
                                    ? Icon(AppIcons.user, size: 50, color: AppColors.textTertiary)
                                    : null,
                          ),
                        ),
                        // Camera badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 3),
                            ),
                            child: Icon(AppIcons.camera, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // TEMEL BİLGİLER Section Header
                  _buildSectionHeader('TEMEL BİLGİLER'),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Name Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ADI SOYADI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                                letterSpacing: 1,
                              ),
                            ),
                            if (_isEditingName) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _cancelEditingName,
                                    child: Text(
                                      'İPTAL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: _saveName,
                                    child: Text(
                                      'KAYDET',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              GestureDetector(
                                onTap: _startEditingName,
                                child: Text(
                                  'DÜZENLE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          enabled: _isEditingName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            border: _isEditingName 
                                ? UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.primary),
                                  )
                                : InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Username - with edit button
                  // Username Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KULLANICI ADI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                                letterSpacing: 1,
                              ),
                            ),
                            if (_isEditingUsername) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _cancelEditingUsername,
                                    child: Text(
                                      'İPTAL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: _saveUsername,
                                    child: Text(
                                      'KAYDET',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              GestureDetector(
                                onTap: _startEditingUsername,
                                child: Text(
                                  'DÜZENLE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('@', style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _isEditingUsername ? AppColors.primary : AppColors.textPrimary,
                            )),
                            Expanded(
                              child: TextField(
                                controller: _usernameController,
                                focusNode: _usernameFocusNode,
                                enabled: _isEditingUsername,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  border: _isEditingUsername 
                                      ? UnderlineInputBorder(
                                          borderSide: BorderSide(color: _usernameError != null ? Colors.red : AppColors.primary),
                                        )
                                      : InputBorder.none,
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: _usernameError != null ? Colors.red : AppColors.primary),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: _usernameError != null ? Colors.red : AppColors.primary, width: 2),
                                  ),
                                  disabledBorder: InputBorder.none,
                                  isDense: true,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_usernameError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _usernameError!,
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // FİZİKSEL ÖZELLİKLER Section Header
                  _buildSectionHeader('FİZİKSEL ÖZELLİKLER'),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // 2x2 Grid for Physical Stats
                  Row(
                    children: [
                      // Cinsiyet
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people_outline_rounded,
                          label: 'CİNSİYET',
                          value: _userData?['gender'] == 'male' ? 'ERKEK' : 
                            _userData?['gender'] == 'female' ? 'KADIN' : '-',
                          onTap: _showGenderDialog,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Yaş
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_today_outlined,
                          label: 'YAŞ',
                          value: _userData?['age'] != null ? '${_userData!['age']}' : '-',
                          onTap: _showDobDialog,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  Row(
                    children: [
                      // Boy
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.straighten_rounded,
                          label: 'BOY',
                          value: _userData?['height'] != null ? '${_userData!['height']} CM' : '-',
                          onTap: () => _showEditNumberDialog('height', 'Boyunuz', 'cm', 100, 250),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Kilo
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.monitor_weight_outlined,
                          label: 'KİLO',
                          value: _userData?['weight'] != null ? '${_userData!['weight']} KG' : '-',
                          onTap: () => _showEditNumberDialog('weight', 'Kilonuz', 'kg', 30, 200),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: AppColors.primary.withOpacity(0.6), 
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded, 
              color: AppColors.primary.withOpacity(0.3), 
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 54,
      endIndent: 16,
      color: Colors.white.withOpacity(0.04),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.darken(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsv = HSVColor.fromColor(this);
    final darkenedHsv = hsv.withValue((hsv.value - amount).clamp(0.0, 1.0));
    return darkenedHsv.toColor();
  }
}
