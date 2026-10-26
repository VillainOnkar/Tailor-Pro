import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Step1CustomerDetails extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final dynamic selectedImage; // Can be File, String (Path or Base64)
  final TextEditingController customerIdController;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController altMobileController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController dobController;
  final TextEditingController notesController;
  final String selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final String customerType;
  final ValueChanged<String?> onCustomerTypeChanged;
  final VoidCallback onRefreshId;
  final VoidCallback onPickDate;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const Step1CustomerDetails({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    this.selectedImage,
    required this.customerIdController,
    required this.nameController,
    required this.mobileController,
    required this.altMobileController,
    required this.addressController,
    required this.cityController,
    required this.dobController,
    required this.notesController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.customerType,
    required this.onCustomerTypeChanged,
    required this.onRefreshId,
    required this.onPickDate,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  @override
  State<Step1CustomerDetails> createState() => _Step1CustomerDetailsState();
}

class _Step1CustomerDetailsState extends State<Step1CustomerDetails> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'customerId': 'Customer ID',
        'fullName': 'Full Name *',
        'mobile': 'Mobile Number *',
        'altMobile': 'Alternate Mobile',
        'address': 'Address *',
        'city': 'Village / City',
        'gender': 'Gender',
        'dob': 'Date of Birth (Birthday Reminder)',
        'customerType': 'Customer Type',
        'notes': 'Notes (e.g. Slim fit, evening delivery)',
        'uploadPhoto': 'Upload Photo',
        'male': 'Male',
        'female': 'Female',
        'other': 'Other',
        'regular': 'Regular',
        'vip': 'VIP',
        'wholesale': 'Wholesale',
        'camera': 'Camera',
        'gallery': 'Gallery',
      },
      'Hindi': {
        'customerId': 'ग्राहक आईडी',
        'fullName': 'पूरा नाम *',
        'mobile': 'मोबाइल नंबर *',
        'altMobile': 'वैकल्पिक मोबाइल',
        'address': 'पता *',
        'city': 'गाँव / शहर',
        'gender': 'लिंग',
        'dob': 'जन्मतिथि (बर्थडे रिमाइंडर)',
        'customerType': 'ग्राहक का प्रकार',
        'notes': 'नोट्स (जैसे: स्लिम फिट, शाम को डिलीवरी)',
        'uploadPhoto': 'फोटो अपलोड करें',
        'male': 'पुरुष',
        'female': 'महिला',
        'other': 'अन्य',
        'regular': 'रेगुलर',
        'vip': 'VIP',
        'wholesale': 'होलसेल',
        'camera': 'कैमरा',
        'gallery': 'गैलरी',
      },
      'Marathi': {
        'customerId': 'ग्राहक आयडी',
        'fullName': 'पूर्ण नाव *',
        'mobile': 'मोबाईल नंबर *',
        'altMobile': 'पर्यायी मोबाईल',
        'address': 'पत्ता *',
        'city': 'गाव / शहर',
        'gender': 'लिंग',
        'dob': 'जन्मतारीख (वाढदिवस स्मरणपत्र)',
        'customerType': 'ग्राहकाचा प्रकार',
        'notes': 'नोंदी (उदा. स्लिम फिट, संध्याकाळी डिलिव्हरी)',
        'uploadPhoto': 'फोटो अपलोड करा',
        'male': 'पुरुष',
        'female': 'स्त्री',
        'other': 'इतर',
        'regular': 'रेगुलर',
        'vip': 'VIP',
        'wholesale': 'होलसेल',
        'camera': 'कॅमेरा',
        'gallery': 'गॅलरी',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? key;
  }

  void _formatCustomerIdOnFly() {
    String currentText = widget.customerIdController.text.trim();
    if (currentText.isEmpty) {
      widget.customerIdController.text = 'CUST0001';
      return;
    }
    String numericPart = currentText.replaceAll(RegExp(r'[^0-9]'), '');
    int parsedNumber = int.tryParse(numericPart) ?? 1;
    widget.customerIdController.text = 'CUST${parsedNumber.toString().padLeft(4, '0')}';
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_getText('camera')),
              onTap: () {
                Navigator.pop(context);
                widget.onCameraTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(_getText('gallery')),
              onTap: () {
                Navigator.pop(context);
                widget.onGalleryTap();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Debug Prints ke sath Safe Image Provider
  // Corrected Safe Image Provider
  ImageProvider? _getSafeImageProvider() {
    final img = widget.selectedImage;
    
    print("--- [IMAGE DEBUG] ---");
    print("selectedImage type: ${img?.runtimeType}");

    if (img == null) return null;

    try {
      if (img is File) {
        String filePath = img.path;
        // Agar File ka path hi base64 string jaisa hai (/9j/ se shuru ho raha hai)
        if (filePath.startsWith('/9j/') || filePath.length > 300) {
          print("[IMAGE DEBUG] File path is actually raw Base64 data. Decoding as MemoryImage.");
          String cleanBase64 = filePath;
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
          Uint8List decodedBytes = base64Decode(cleanBase64);
          return MemoryImage(decodedBytes);
        } else {
          print("[IMAGE DEBUG] Loading as normal FileImage (Path: $filePath)");
          return FileImage(img);
        }
      } else if (img is String && img.isNotEmpty) {
        if (img.startsWith('http')) {
          print("[IMAGE DEBUG] Loading as NetworkImage");
          return NetworkImage(img);
        } else if (img.startsWith('/') && !img.startsWith('/9j/') && img.length < 300) {
          print("[IMAGE DEBUG] Loading as Local FilePath String");
          return FileImage(File(img));
        } else {
          print("[IMAGE DEBUG] Decoding as Base64 MemoryImage");
          String cleanBase64 = img;
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
          Uint8List decodedBytes = base64Decode(cleanBase64);
          return MemoryImage(decodedBytes);
        }
      }
    } catch (e, stackTrace) {
      print("[IMAGE DEBUG ERROR]: Exception caught -> $e");
      print(stackTrace);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Color scaffoldBg = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = widget.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    Color subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color primaryColor = Color(0xFF2563EB);
    const Color accentColor = Color(0xFF06B6D4);

    if (!widget.customerIdController.text.startsWith('CUST') || widget.customerIdController.text.length < 8) {
      _formatCustomerIdOnFly();
    }

    final imageProvider = _getSafeImageProvider();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(constraints.maxWidth < 360 ? 12 : 18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showPhotoOptions(context),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? const Icon(Icons.person_rounded, size: 40, color: primaryColor)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => _showPhotoOptions(context),
                        icon: const Icon(Icons.camera_alt_rounded, color: accentColor, size: 14),
                        label: Text(_getText('uploadPhoto'), style: const TextStyle(color: accentColor, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: widget.customerIdController,
                  label: _getText('customerId'),
                  icon: Icons.confirmation_number_outlined,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  readOnly: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: accentColor, size: 18),
                    onPressed: () {
                      String currentNumeric = widget.customerIdController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      int nextId = (int.tryParse(currentNumeric) ?? 0) + 1;
                      widget.customerIdController.text = 'CUST${nextId.toString().padLeft(4, '0')}';
                      widget.onRefreshId();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: widget.nameController,
                  label: _getText('fullName'),
                  icon: Icons.person_outline_rounded,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return widget.initialLanguage == 'Hindi' ? 'कृपया पूरा नाम दर्ज करें' : (widget.initialLanguage == 'Marathi' ? 'कृपया पूर्ण नाव प्रविष्ट करा' : 'Please enter full name');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: widget.mobileController,
                  label: _getText('mobile'),
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  validator: (val) {
                    if (val == null || val.trim().length < 10) {
                      return widget.initialLanguage == 'Hindi' ? 'कृपया वैध 10-अंकों का मोबाइल नंबर दर्ज करें' : (widget.initialLanguage == 'Marathi' ? 'कृपया वैध 10-अंकी मोबाईल नंबर प्रविष्ट करा' : 'Please enter valid 10-digit mobile number');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: widget.altMobileController,
                  label: _getText('altMobile'),
                  icon: Icons.phone_callback_rounded,
                  keyboardType: TextInputType.phone,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(_getText('gender'), style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildGenderRadio('Male', _getText('male'), textColor, primaryColor),
                    _buildGenderRadio('Female', _getText('female'), textColor, primaryColor),
                    _buildGenderRadio('Other', _getText('other'), textColor, primaryColor),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: widget.dobController,
                  label: _getText('dob'),
                  icon: Icons.cake_rounded,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  readOnly: true,
                  onTap: widget.onPickDate,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: widget.addressController,
                  label: _getText('address'),
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return widget.initialLanguage == 'Hindi' ? 'कृपया पता दर्ज करें' : (widget.initialLanguage == 'Marathi' ? 'कृपया पत्ता प्रविष्ट करा' : 'Please enter address');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: widget.cityController,
                  label: _getText('city'),
                  icon: Icons.location_city_rounded,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: widget.customerType,
                  dropdownColor: surfaceColor,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: _getText('customerType'),
                    labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                    prefixIcon: const Icon(Icons.star_outline_rounded, color: primaryColor, size: 18),
                    filled: true,
                    fillColor: scaffoldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                  items: ['Regular', 'VIP', 'Wholesale'].map((type) {
                    String labelText = type == 'Regular' ? _getText('regular') : (type == 'VIP' ? _getText('vip') : _getText('wholesale'));
                    return DropdownMenuItem(value: type, child: Text(labelText));
                  }).toList(),
                  onChanged: widget.onCustomerTypeChanged,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: widget.notesController,
                  label: _getText('notes'),
                  icon: Icons.note_alt_outlined,
                  maxLines: 2,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  surfaceColor: scaffoldBg,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderRadio(String value, String label, Color textColor, Color primaryColor) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: widget.selectedGender,
            activeColor: primaryColor,
            onChanged: widget.onGenderChanged,
          ),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color subTextColor,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 12),
        prefixIcon: Icon(icon, color: primaryColor, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
      ),
    );
  }
}