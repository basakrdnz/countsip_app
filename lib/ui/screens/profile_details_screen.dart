import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';

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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kullanıcı Adı Değiştir'),
        content: const Text(
          'Kullanıcı adını haftada sadece 1 kez değiştirebilirsin.\n\n'
          'Devam etmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Değiştir'),
          ),
        ],
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
    
    // Show source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Fotoğraf Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(AppIcons.camera),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(AppIcons.gallery),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    
    if (source == null) return;
    
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile.jpg');
      
      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
        _userData?['photoUrl'] = downloadUrl;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profil fotoğrafı güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateField(String field, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic update
    final oldValue = _userData?[field];
    setState(() {
      _userData = _userData ?? {};
      _userData![field] = value;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({field: value});
      
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
        _userData![field] = oldValue;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userData?['name']?.toString() ?? '');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'İsminizi Düzenleyin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Adınızı girin',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _updateField('name', controller.text.trim());
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
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
                      color: const Color(0xFF4B3126),
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
                  inactiveTrackColor: Colors.grey.shade200,
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
                    Text('$min', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    Text('$max', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              value == 'male' ? AppIcons.mars : AppIcons.venus,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B3126),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF4B3126),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Profile Picture Section with camera icon
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            image: _photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _isUploadingPhoto
                              ? const Center(child: CircularProgressIndicator())
                              : _photoUrl == null
                                  ? Icon(AppIcons.user, size: 60, color: Colors.grey.shade400)
                                  : null,
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
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(AppIcons.camera, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  TextButton(
                    onPressed: _pickAndUploadPhoto,
                    child: const Text('Fotoğrafı Değiştir'),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Name - with edit button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'İsim',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF714A39),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                enabled: _isEditingName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B3126),
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
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                ),
                                textCapitalization: TextCapitalization.words,
                              ),
                            ],
                          ),
                        ),
                        if (_isEditingName) ...[
                          // Cancel button
                          IconButton(
                            onPressed: _cancelEditingName,
                            icon: Icon(AppIcons.cross, color: Colors.grey.shade500, size: 20),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          // Save button
                          IconButton(
                            onPressed: _saveName,
                            icon: Icon(AppIcons.check, color: AppColors.primary, size: 20),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ] else
                          // Edit button
                          IconButton(
                            onPressed: _startEditingName,
                            icon: Icon(AppIcons.edit, color: AppColors.primary, size: 20),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Username - with edit button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kullanıcı Adı',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('@', style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _isEditingUsername ? AppColors.primary : const Color(0xFF4B3126),
                                  )),
                                  Expanded(
                                    child: TextField(
                                      controller: _usernameController,
                                      focusNode: _usernameFocusNode,
                                      enabled: _isEditingUsername,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4B3126),
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
                        if (_isEditingUsername) ...[
                          IconButton(
                            onPressed: _cancelEditingUsername,
                            icon: Icon(AppIcons.cross, color: Colors.grey.shade500, size: 20),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            onPressed: _saveUsername,
                            icon: Icon(AppIcons.check, color: AppColors.primary, size: 20),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ] else
                          IconButton(
                            onPressed: _startEditingUsername,
                            icon: Icon(AppIcons.edit, color: AppColors.primary, size: 20),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Other Info Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Kilo',
                          _userData?['weight'] != null ? '${_userData!['weight']} kg' : 'Belirtilmemiş',
                          onTap: () => _showEditNumberDialog('weight', 'Kilonuz', 'kg', 30, 200),
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          'Boy',
                          _userData?['height'] != null ? '${_userData!['height']} cm' : 'Belirtilmemiş',
                          onTap: () => _showEditNumberDialog('height', 'Boyunuz', 'cm', 100, 250),
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          'Yaş',
                          _userData?['age'] != null ? '${_userData!['age']}' : 'Belirtilmemiş',
                          onTap: () => _showEditNumberDialog('age', 'Yaşınız', 'yaş', 18, 100),
                        ),
                        _buildDivider(),
                        _buildInfoRow(
                          'Cinsiyet',
                          _userData?['gender'] == 'male' ? 'Erkek' : 
                            _userData?['gender'] == 'female' ? 'Kadın' : 'Belirtilmemiş',
                          onTap: _showGenderDialog,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF714A39),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4B3126),
              ),
            ),
            const SizedBox(width: 8),
            Icon(AppIcons.angleRight, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Colors.grey.shade200,
    );
  }
}
