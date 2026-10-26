import 'package:flutter/material.dart';
import '../../../database.dart'; // Apni database file ka sahi import path dein

class ChangePasswordScreen extends StatefulWidget {
  final bool isDarkMode;
  final String selectedLanguage;
  final String userEmail;

  const ChangePasswordScreen({
    super.key,
    required this.isDarkMode,
    required this.selectedLanguage,
    required this.userEmail,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Password validation tracking variables
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePasswordRules);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRules() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Mandatory Password Rules Check
    if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
      String ruleErrorMsg = "Please meet all password requirements";
      if (widget.selectedLanguage == 'Hindi') {
        ruleErrorMsg = "कृपया पासवर्ड की सभी शर्तों को पूरा करें";
      } else if (widget.selectedLanguage == 'Marathi') {
        ruleErrorMsg = "कृपया पासवर्डच्या सर्व अटी पूर्ण करा";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ruleErrorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Check if new password and confirm password match
    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      String mismatchMsg = "New passwords do not match";
      if (widget.selectedLanguage == 'Hindi') {
        mismatchMsg = "नए पासवर्ड मेल नहीं खा रहे हैं";
      } else if (widget.selectedLanguage == 'Marathi') {
        mismatchMsg = "नवीन पासवर्ड जुळत नाहीत";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mismatchMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // DatabaseService ka function call karke current password verify aur update karein
      Map<String, dynamic> result = await DatabaseService.updatePasswordOnly(
        userEmail: widget.userEmail,
        currentPassword: _currentPasswordController.text.trim(), // <--- Yahan current password add kar diya gaya hai
        newPassword: _newPasswordController.text.trim(),
      );

      bool success = result['status'] == true;

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
        Navigator.pop(context);
      } else if (mounted) {
        String errorMsg = result['message'] ?? "Failed to update password";
        
        // Multilingual support for error messages if needed
        if (widget.selectedLanguage == 'Hindi' && errorMsg.contains("Current password galat hai")) {
          errorMsg = "वर्तमान पासवर्ड गलत है!";
        } else if (widget.selectedLanguage == 'Marathi' && errorMsg.contains("Current password galat hai")) {
          errorMsg = "सध्याचा पासवर्ड चुकीचा आहे!";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'title': 'Change Password',
        'subtitle': "For your security, please don't use an easy to guess password.",
        'currentPassword': 'Current Password',
        'newPassword': 'New Password',
        'confirmPassword': 'Confirm New Password',
        'update': 'Update Password',
        'enterCurrent': 'Please enter current password',
        'enterNew': 'Please enter new password',
        'enterConfirm': 'Please confirm your new password',
        'successMsg': 'Password changed successfully!',
        'ruleTitle': 'Password must contain:',
        'rule1': 'At least 8 characters',
        'rule2': 'One uppercase letter',
        'rule3': 'One number',
        'rule4': 'One special character',
      },
      'Hindi': {
        'title': 'पासवर्ड बदलें',
        'subtitle': 'आपकी सुरक्षा के लिए, कृपया अनुमान लगाने में आसान पासवर्ड का उपयोग न करें।',
        'currentPassword': 'वर्तमान पासवर्ड',
        'newPassword': 'नया पासवर्ड',
        'confirmPassword': 'नए पासवर्ड की पुष्टि करें',
        'update': 'पासवर्ड अपडेट करें',
        'enterCurrent': 'कृपया वर्तमान पासवर्ड दर्ज करें',
        'enterNew': 'कृपया नया पासवर्ड दर्ज करें',
        'enterConfirm': 'कृपया नया पासवर्ड दोबारा दर्ज करें',
        'successMsg': 'पासवर्ड सफलतापूर्वक बदल गया!',
        'ruleTitle': 'पासवर्ड में शामिल होना चाहिए:',
        'rule1': 'कम से कम 8 अक्षर',
        'rule2': 'एक बड़ा अक्षर (Uppercase)',
        'rule3': 'एक नंबर',
        'rule4': 'एक विशेष वर्ण (Special character)',
      },
      'Marathi': {
        'title': 'पासवर्ड बदला',
        'subtitle': 'तुमच्या सुरक्षेसाठी, कृपया अंदाज लावण्यास सोपा पासवर्ड वापरू नका.',
        'currentPassword': 'सध्याचा पासवर्ड',
        'newPassword': 'नवीन पासवर्ड',
        'confirmPassword': 'नवीन पासवर्ड पुष्टी करा',
        'update': 'पासवर्ड अपडेट करा',
        'enterCurrent': 'कृपया सध्याचा पासवर्ड प्रविष्ट करा',
        'enterNew': 'कृपया नवीन पासवर्ड प्रविष्ट करा',
        'enterConfirm': 'कृपया नवीन पासवर्ड पुन्हा प्रविष्ट करा',
        'successMsg': 'पासवर्ड यशस्वीरित्या बदलला!',
        'ruleTitle': 'पासवर्डमध्ये समाविष्ट असणे आवश्यक आहे:',
        'rule1': 'किमान ८ अक्षरे',
        'rule2': 'एक मोठे अक्षर (Uppercase)',
        'rule3': 'एक क्रमांक (Number)',
        'rule4': 'एक विशेष चिन्ह (Special character)',
      }
    };
    return translations[widget.selectedLanguage]?[key] ?? translations['English']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    Color surfaceColor = isDark ? const Color(0xFF161325) : Colors.white;
    Color borderColor = isDark ? const Color(0xFF2D2640) : const Color(0xFFE9D5FF);
    Color textColor = isDark ? const Color(0xFFF3E8FF) : const Color(0xFF2E1065);
    Color subTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF7E22CE);
    const Color primaryPurple = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0914) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _getText('title'),
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
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryPurple.withOpacity(0.15),
                          border: Border.all(color: primaryPurple.withOpacity(0.4), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 36,
                          color: primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _getText('subtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Current Password
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: _getText('currentPassword'),
                        labelStyle: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 14),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryPurple.withOpacity(0.8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: subTextColor,
                          ),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('enterCurrent') : null,
                    ),
                    const SizedBox(height: 16),
                    // New Password
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: _getText('newPassword'),
                        labelStyle: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 14),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryPurple.withOpacity(0.8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: subTextColor,
                          ),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('enterNew') : null,
                    ),
                    const SizedBox(height: 16),
                    // Confirm New Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: _getText('confirmPassword'),
                        labelStyle: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 14),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryPurple.withOpacity(0.8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: subTextColor,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('enterConfirm') : null,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getText('ruleTitle'),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRuleRow(_getText('rule1'), _hasMinLength, textColor),
                          const SizedBox(height: 8),
                          _buildRuleRow(_getText('rule2'), _hasUppercase, textColor),
                          const SizedBox(height: 8),
                          _buildRuleRow(_getText('rule3'), _hasNumber, textColor),
                          const SizedBox(height: 8),
                          _buildRuleRow(_getText('rule4'), _hasSpecialChar, textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
                        onPressed: _changePassword,
                        child: Text(
                          _getText('update'),
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

  Widget _buildRuleRow(String text, bool isMet, Color textColor) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
          size: 18,
          color: isMet ? const Color(0xFF10B981) : Colors.grey.shade500,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: isMet ? textColor : Colors.grey.shade500,
            fontSize: 13,
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}