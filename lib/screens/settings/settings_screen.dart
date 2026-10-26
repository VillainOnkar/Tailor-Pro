import 'package:flutter/material.dart';
import 'modules/shop_info_screen.dart';
import 'modules/profile_settings_screen.dart';
import 'modules/change_password_screen.dart';


class SettingsScreen extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String userEmail;
  final Function(bool)? onThemeChanged;
  final Function(String)? onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.userEmail,
    this.onThemeChanged,
    this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _isDarkMode = widget.isDarkMode;
    }
    if (oldWidget.initialLanguage != widget.initialLanguage) {
      _selectedLanguage = widget.initialLanguage;
    }
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'settings': 'Settings',
        'profileSettings': 'Profile Settings',
        'profileDesc': 'Update your name, phone and photo',
        'languageSettings': 'Language Preferences',
        'languageDesc': 'Change application language (English, Hindi, Marathi)',
        'themeSettings': 'Display & Theme',
        'themeDesc': 'Switch between Dark and Light mode',
        'notificationSettings': 'Notification Alerts',
        'notificationDesc': 'Manage push notifications and reminders',
        'securitySettings': 'Security & Password',
        'securityDesc': 'Change password and security options',
        'shopInfo': 'Shop Information',
        'shopDesc': 'Manage tailorshop name, address and timing',
      },
      'Hindi': {
        'settings': 'सेटिंग्स',
        'profileSettings': 'प्रोफाइल सेटिंग्स',
        'profileDesc': 'अपना नाम, फोन और फोटो अपडेट करें',
        'languageSettings': 'भाषा प्राथमिकताएं',
        'languageDesc': 'ऐप की भाषा बदलें (English, Hindi, Marathi)',
        'themeSettings': 'डिस्प्ले और थीम',
        'themeDesc': 'डार्क और लाइट मोड के बीच स्विच करें',
        'notificationSettings': 'नोटिफिकेशन अलर्ट',
        'notificationDesc': 'पुश नोटिफिकेशन और रिमाइंडर मैनेज करें',
        'securitySettings': 'सुरक्षा और पासवर्ड',
        'securityDesc': 'पासवर्ड और सुरक्षा विकल्प बदलें',
        'shopInfo': 'दुकान की जानकारी',
        'shopDesc': 'अपनी टेलर शॉप का नाम, पता और समय प्रबंधित करें',
      },
      'Marathi': {
        'settings': 'सेटिंग्स',
        'profileSettings': 'प्रोफाइल सेटिंग्स',
        'profileDesc': 'तुमचे नाव, फोन आणि फोटो अपडेट करा',
        'languageSettings': 'भाषा प्राधान्ये',
        'languageDesc': 'अॅपची भाषा बदला (English, Hindi, Marathi)',
        'themeSettings': 'डिस्प्ले आणि थीम',
        'themeDesc': 'डार्क आणि लाइट मोड दरम्यान बदला',
        'notificationSettings': 'सूचना अलर्ट',
        'notificationDesc': 'पुश सूचना आणि रिमाइंडर व्यवस्थापित करा',
        'securitySettings': 'सुरक्षा आणि पासवर्ड',
        'securityDesc': 'पासवर्ड आणि सुरक्षा पर्याय बदला',
        'shopInfo': 'दुकानाची माहिती',
        'shopDesc': 'तुमच्या टेलर शॉपचे नाव, पत्ता आणि वेळ व्यवस्थापित करा',
      }
    };
    return translations[_selectedLanguage]?[key] ?? key;
  }


  @override
  Widget build(BuildContext context) {
    Color surfaceColor = _isDarkMode ? const Color(0xFF1E1B2E) : Colors.white;
    Color borderColor = _isDarkMode ? const Color(0xFF3B3556) : const Color(0xFFE9D5FF);
    Color textColor = _isDarkMode ? const Color(0xFFF3E8FF) : const Color(0xFF2E1065);
    Color subTextColor = _isDarkMode ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);
    const Color primaryPurple = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF120F1D) : const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Text(
          _getText('settings'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        children: [
          // 1. Profile Settings Button
          _buildSettingCard(
            icon: Icons.person_rounded,
            title: _getText('profileSettings'),
            subtitle: _getText('profileDesc'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            primaryPurple: primaryPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(
                    isDarkMode: _isDarkMode,
                    selectedLanguage: _selectedLanguage,
                    userEmail: widget.userEmail,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),


          // 3. Notification Settings Button
          _buildSettingCard(
            icon: Icons.notifications_active_rounded,
            title: _getText('notificationSettings'),
            subtitle: _getText('notificationDesc'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            primaryPurple: primaryPurple,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: surfaceColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Text(
                          "Coming Soon",
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    content: Text(
                      "यह फीचर बहुत जल्द भविष्य के अपडेट में आने वाला है! (This feature will be available soon in a future update.)",
                      style: TextStyle(color: subTextColor, fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          "ठीक आहे / OK",
                          style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),

          // 4. Security Settings Button
          // 4. Security Settings Button
          _buildSettingCard(
            icon: Icons.security_rounded,
            title: _getText('securitySettings'),
            subtitle: _getText('securityDesc'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            primaryPurple: primaryPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordScreen(
                    isDarkMode: _isDarkMode, // Yahan _isDarkMode karein
                    selectedLanguage: _selectedLanguage, // Yahan _selectedLanguage karein
                    userEmail: widget.userEmail,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 6. Shop Information Button
          _buildSettingCard(
            icon: Icons.store_rounded,
            title: _getText('shopInfo'),
            subtitle: _getText('shopDesc'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            primaryPurple: primaryPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopInfoScreen(
                    isDarkMode: _isDarkMode,
                    selectedLanguage: _selectedLanguage,
                    userEmail: widget.userEmail,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryPurple,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryPurple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: subTextColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}