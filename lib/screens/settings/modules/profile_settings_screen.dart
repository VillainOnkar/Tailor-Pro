import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../database.dart'; 
import '../../login_screen.dart'; 

class ProfileSettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final String selectedLanguage;
  final String userEmail;

  const ProfileSettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.selectedLanguage,
    required this.userEmail,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? userData = await DatabaseService.fetchUserProfile(widget.userEmail);
      if (userData != null && mounted) {
        setState(() {
          _nameController.text = userData['full_name'] ?? userData['name'] ?? '';
          _usernameController.text = userData['username'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _profileImageUrl = userData['profile_image'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  ImageProvider? _getProfileImageProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('data:image')) {
        try {
          final base64String = _profileImageUrl!.split(',').last;
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          debugPrint("Error decoding base64 image: $e");
          return null;
        }
      } else {
        return NetworkImage(_profileImageUrl!);
      }
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      bool success = await DatabaseService.updateUserProfile(
        email: widget.userEmail,
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
        imageFile: _selectedImage,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(_getText('successMsg'), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Failed to update");
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.selectedLanguage == 'Hindi' ? "प्रोफाइल अपडेट करने में विफल" : "Failed to update profile"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Password Confirmation Dialog for Account Deletion
  void _confirmAndDeleteAccount() {
    bool isDark = widget.isDarkMode;
    Color surfaceColor = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    Color textColor = isDark ? const Color(0xFFF3E8FF) : const Color(0xFF2E1065);
    Color subTextColor = isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);
    
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _getText('deleteAccountTitle'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getText('deleteAccountConfirm'),
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: _getText('enterPassword'),
                  labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF120F1D) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _getText('no'),
                style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                String password = passwordController.text.trim();
                if (password.isEmpty) return;

                // Dialog context ko pehle hi save kar lein
                final currentContext = dialogContext;

                // Sabse pehle Dialog ko close karein[cite: 10]
                Navigator.of(currentContext).pop();
                
                setState(() => _isLoading = true);
                
                try {
                  // Database se account delete karein[cite: 10]
                  Map<String, dynamic> result = await DatabaseService.deleteUserAccount(widget.userEmail, password);
                  
                  if (mounted) {
                    if (result['status'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.selectedLanguage == 'Hindi' ? "खाता सफलतापूर्वक हटा दिया गया" : "Account deleted successfully")),
                      );
                      
                      // Root Navigator ka use karke LoginScreen par redirect karein[cite: 10]
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(initialLanguage: widget.selectedLanguage),
                        ),
                        (route) => false,
                      );
                    } else {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? "Failed to delete account"), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("Error deleting account: $e");
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: Text(
                _getText('yes'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'profileSettings': 'Edit Profile',
        'subtitle': 'Update your personal details below',
        'name': 'Full Name',
        'username': 'Username',
        'phone': 'Phone Number',
        'email': 'Email Address',
        'save': 'Save Changes',
        'deleteAccount': 'Delete Account',
        'deleteAccountTitle': 'Delete Account',
        'deleteAccountConfirm': 'Please enter your password to confirm account deletion. All your records will be permanently deleted.',
        'enterPassword': 'Enter Password',
        'yes': 'Yes',
        'no': 'No',
        'enterName': 'Please enter your name',
        'enterUsername': 'Please enter your username',
        'enterPhone': 'Please enter your phone number',
        'successMsg': 'Profile updated successfully!',
        'role': 'Store Administrator',
      },
      'Hindi': {
        'profileSettings': 'प्रोफाइल संपादित करें',
        'subtitle': 'नीचे दिए गए अपने विवरण को अपडेट करें',
        'name': 'पूरा नाम',
        'username': 'यूजरनेम',
        'phone': 'फ़ोन नंबर',
        'email': 'ईमेल आईडी',
        'save': 'परिवर्तन सहेजें',
        'deleteAccount': 'खाता हटाएं (Delete Account)',
        'deleteAccountTitle': 'खाता हटाएं',
        'deleteAccountConfirm': 'खाता हटाने की पुष्टि करने के लिए कृपया अपना पासवर्ड दर्ज करें। आपके सभी रिकॉर्ड स्थायी रूप से हटा दिए जाएंगे।',
        'enterPassword': 'पासवर्ड दर्ज करें',
        'yes': 'हाँ',
        'no': 'नहीं',
        'enterName': 'कृपया अपना नाम दर्ज करें',
        'enterUsername': 'कृपया अपना यूजरनेम दर्ज करें',
        'enterPhone': 'कृपया अपना फोन नंबर दर्ज करें',
        'successMsg': 'प्रोफाइल सफलतापूर्वक अपडेट हो गई!',
        'role': 'स्टोर एडमिनिस्ट्रेटर',
      },
      'Marathi': {
        'profileSettings': 'प्रोफाइल संपादित करा',
        'subtitle': 'खालील तुमचे तपशील अपडेट करा',
        'name': 'पूर्ण नाव',
        'username': 'वापरकर्ता नाव (Username)',
        'phone': 'फोन नंबर',
        'email': 'ईमेल पत्ता',
        'save': 'बदल जतन करा',
        'deleteAccount': 'खाते हटवा (Delete Account)',
        'deleteAccountTitle': 'खाते हटवा',
        'deleteAccountConfirm': 'खाते हटवण्याची पुष्टी करण्यासाठी कृपया तुमचा पासवर्ड प्रविष्ट करा. तुमचे सर्व रेकॉर्ड कायमचे हटवले जातील.',
        'enterPassword': 'पासवर्ड प्रविष्ट करा',
        'yes': 'होय',
        'no': 'नाही',
        'enterName': 'कृपया तुमचे नाव प्रविष्ट करा',
        'enterUsername': 'कृपया तुमचे युजरनेम प्रविष्ट करा',
        'enterPhone': 'कृपया तुमचा फोन नंबर प्रविष्ट करा',
        'successMsg': 'प्रोफाइल यशस्वीरित्या अपडेट केली!',
        'role': 'स्टोर प्रशासक',
      }
    };
    return translations[widget.selectedLanguage]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    Color surfaceColor = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    Color borderColor = isDark ? const Color(0xFF3B3556) : const Color(0xFFE9D5FF);
    Color textColor = isDark ? const Color(0xFFF3E8FF) : const Color(0xFF2E1065);
    Color subTextColor = isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);
    const Color primaryPurple = Color(0xFF8B5CF6);

    String firstLetter = _nameController.text.isNotEmpty 
        ? _nameController.text.trim()[0].toUpperCase() 
        : 'U';

    final imageProvider = _getProfileImageProvider();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF120F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _getText('profileSettings'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor.withOpacity(0.5), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryPurple))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF2D2640), const Color(0xFF1A1625)]
                              : [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.transparent : const Color(0xFFDDD6FE),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                                ? primaryPurple.withOpacity(0.15)
                                : primaryPurple.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImageFromGallery,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.8) : primaryPurple.withOpacity(0.4), 
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundColor: isDark ? Colors.white.withOpacity(0.2) : primaryPurple.withOpacity(0.1),
                                    backgroundImage: imageProvider,
                                    child: imageProvider == null
                                        ? Text(
                                            firstLetter,
                                            style: TextStyle(
                                              fontSize: 44,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : primaryPurple,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white : primaryPurple,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded, 
                                      size: 18, 
                                      color: isDark ? primaryPurple : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.15) : primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.2) : primaryPurple.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              _getText('role'),
                              style: TextStyle(
                                color: isDark ? Colors.white : primaryPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _getText('subtitle'),
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _getText('name'),
                        labelStyle: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 14),
                        prefixIcon: Icon(Icons.person_outline_rounded, color: primaryPurple),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('enterName') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: _getText('username'),
                        labelStyle: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 14),
                        prefixIcon: Icon(Icons.alternate_email_rounded, color: primaryPurple),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('enterUsername') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: _getText('phone'),
                        labelStyle: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 14),
                        prefixIcon: Icon(Icons.phone_outlined, color: primaryPurple),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('enterPhone') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: widget.userEmail,
                      readOnly: true,
                      style: TextStyle(color: subTextColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: _getText('email'),
                        labelStyle: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 14),
                        prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                        suffixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: subTextColor.withOpacity(0.6)),
                        filled: true,
                        fillColor: surfaceColor.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: primaryPurple.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saveProfile,
                        child: Text(
                          _getText('save'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Delete Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _confirmAndDeleteAccount,
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: Text(
                          _getText('deleteAccount'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}