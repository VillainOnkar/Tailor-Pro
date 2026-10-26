import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Yahan apni DatabaseService file ka sahi path import karein
import '../../../database.dart';

class ShopInfoScreen extends StatefulWidget {
  final bool isDarkMode;
  final String selectedLanguage;
  final String userEmail; // User email add ki gayi hai database path ke liye

  const ShopInfoScreen({
    super.key,
    required this.isDarkMode,
    required this.selectedLanguage,
    required this.userEmail,
  });

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _shopImage;
  String? _networkImageUrl; // Firebase se aane wali base64 image ke liye
  final ImagePicker _picker = ImagePicker();
  String _savedQrData = "";
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadShopDataFromFirebase();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Firebase se shop data fetch karna
  Future<void> _loadShopDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? shopData = await DatabaseService.fetchShopInformation(widget.userEmail);
      
      if (shopData != null) {
        _shopNameController.text = shopData['shop_name'] ?? '';
        _ownerNameController.text = shopData['owner_name'] ?? '';
        _phoneController.text = shopData['phone'] ?? '';
        _addressController.text = shopData['address'] ?? '';
        
        String photoStr = shopData['photo'] ?? '';
        if (photoStr.startsWith('data:image')) {
          _networkImageUrl = photoStr;
        }
      }
    } catch (e) {
      debugPrint("Error loading shop info: $e");
    } finally {
      _updateQrDataString();
      setState(() => _isLoading = false);
    }
  }

  void _updateQrDataString() {
    setState(() {
      _savedQrData = "Shop: ${_shopNameController.text.trim()}\n"
                     "Owner: ${_ownerNameController.text.trim()}\n"
                     "Phone: ${_phoneController.text.trim()}\n"
                     "Address: ${_addressController.text.trim()}";
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _shopImage = File(pickedFile.path);
          _networkImageUrl = null; // Nayi image select hone par purani hata dein
        });
      }
    } catch (e) {
      debugPrint("Image picking error: $e");
    }
  }

  // Firebase par data save/update karne ka function
  Future<void> _saveDataToFirebase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> result = await DatabaseService.saveShopInformation(
        userEmail: widget.userEmail,
        shopName: _shopNameController.text,
        ownerName: _ownerNameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        shopImage: _shopImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['status'] ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (result['status']) {
          _updateQrDataString();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'title': 'Shop Information',
        'subtitle': 'Manage boutique details & live QR code',
        'shopName': 'Shop / Boutique Name',
        'ownerName': 'Owner Name',
        'phone': 'Contact Phone Number',
        'address': 'Complete Shop Address',
        'uploadPhoto': 'Change QR / Upload Photo',
        'save': 'Save Changes',
        'qrSection': 'STORE QR CODE',
      },
      'Hindi': {
        'title': 'दुकान की जानकारी',
        'subtitle': 'दुकान का विवरण और लाइव QR कोड प्रबंधित करें',
        'shopName': 'दुकान / बुटीक का नाम',
        'ownerName': 'संचालक का नाम',
        'phone': 'मोबाइल नंबर',
        'address': 'पूरा दुकान का पता',
        'uploadPhoto': 'QR बदलें / फोटो अपलोड करें',
        'save': 'बदलाव सेव करें',
        'qrSection': 'स्टोर QR कोड',
      },
      'Marathi': {
        'title': 'दुकानाची माहिती',
        'subtitle': 'दुकान तपशील आणि थेट QR कोड व्यवस्थापित करा',
        'shopName': 'दुकानाचे नाव',
        'ownerName': 'मालकाचे नाव',
        'phone': 'मोबाईल नंबर',
        'address': 'दुकानाचा पूर्ण पत्ता',
        'uploadPhoto': 'QR बदला / फोटो अपलोड करा',
        'save': 'बदल जतन करा',
        'qrSection': 'स्टोर QR कोड',
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
    
    // Updated primary theme color to Purple / Violet
    const Color primaryPurple = Color(0xFF8B5CF6);

    return Scaffold(
      // Background color updated to light purple/violet tint in light mode
      backgroundColor: isDark ? const Color(0xFF120F1D) : const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _getText('title'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryPurple))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getText('qrSection'),
                      style: const TextStyle(
                        color: primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImageFromGallery,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2A2442) : const Color(0xFFFAF5FF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: primaryPurple.withOpacity(0.6), width: 1.5),
                                  image: _shopImage != null
                                      ? DecorationImage(
                                          image: FileImage(_shopImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: MemoryImage(base64Decode(_networkImageUrl!.split(',').last)),
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                                ),
                                child: (_shopImage == null && (_networkImageUrl == null || _networkImageUrl!.isEmpty))
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: QrImageView(
                                            data: _savedQrData.isNotEmpty ? _savedQrData : "Shop Info",
                                            version: QrVersions.auto,
                                            size: 110.0,
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: isDark ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(Icons.camera_alt_rounded, color: primaryPurple, size: 16),
                              label: Text(
                                _getText('uploadPhoto'),
                                style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "SHOP DETAILS",
                      style: TextStyle(
                        color: primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAttractiveTextField(
                      controller: _shopNameController,
                      label: _getText('shopName'),
                      icon: Icons.store_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryPurple: primaryPurple,
                      onChanged: (val) => _updateQrDataString(),
                    ),
                    const SizedBox(height: 16),
                    _buildAttractiveTextField(
                      controller: _ownerNameController,
                      label: _getText('ownerName'),
                      icon: Icons.person_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryPurple: primaryPurple,
                      onChanged: (val) => _updateQrDataString(),
                    ),
                    const SizedBox(height: 16),
                    _buildAttractiveTextField(
                      controller: _phoneController,
                      label: _getText('phone'),
                      icon: Icons.phone_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryPurple: primaryPurple,
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => _updateQrDataString(),
                    ),
                    const SizedBox(height: 16),
                    _buildAttractiveTextField(
                      controller: _addressController,
                      label: _getText('address'),
                      icon: Icons.location_on_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryPurple: primaryPurple,
                      maxLines: 2,
                      onChanged: (val) => _updateQrDataString(),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 2,
                          shadowColor: primaryPurple.withOpacity(0.4),
                        ),
                        onPressed: _isSaving ? null : _saveDataToFirebase,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _getText('save'),
                                style: const TextStyle(
                                  fontSize: 16,
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

  Widget _buildAttractiveTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryPurple,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(icon, color: primaryPurple, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field cannot be empty';
          }
          return null;
        },
      ),
    );
  }
}