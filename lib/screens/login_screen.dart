import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database.dart';
import 'register_screen.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final String initialLanguage;
  const LoginScreen({super.key, required this.initialLanguage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late String _selectedLanguage;
  final List<String> _languages = ['English', 'Hindi', 'Marathi'];

  // Animations
  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnim;

  late AnimationController _logoAnimController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;

    // Screen Fade Animation
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeAnimController, curve: Curves.easeInOut);
    _fadeAnimController.forward();

    // Subtle Glowing Pulse Animation for Logo Badge
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _logoAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _fadeAnimController.dispose();
    _logoAnimController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changeLanguage(String? newLang) async {
    if (newLang == null) return;
    setState(() => _selectedLanguage = newLang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', newLang);
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'welcome': 'Master Darzi Portal',
        'subtitle': 'Stitch your creative fashion ideas into reality',
        'idLabel': 'Username or Email',
        'passLabel': 'Password',
        'loginBtn': 'Enter Workshop',
        'forgotPass': 'Forgot Password?',
        'noAccount': 'New Tailor? Register Shop',
        'success': 'Workshop Unlocked!',
        'resetTitle': 'Reset Password',
        'resetDesc': 'Enter your registered email address to receive a password reset link.',
        'sendLink': 'Send Reset Link',
        'cancel': 'Cancel',
        'howToUseTitle': 'How to Use App',
        'howToUseDesc': '1. Enter your registered Username or Email and Password.\n2. Tap "Enter Workshop" to open your dashboard.\n3. If you are new, click "Register Shop" below to create an account.\n4. Change your preferred language anytime from the top right corner.',
        'gotIt': 'Got It',
        // SnackBar & Validation Messages
        'errUserNotFound': 'Username not found!',
        'errVerifyEmail': 'Please verify your email first!',
        'errWrongPass': 'Incorrect email or password!',
        'errLoginFailed': 'Login Failed',
      },
      'Hindi': {
        'welcome': 'मास्टर दर्जी पोर्टल',
        'subtitle': 'अपने फैशन डिज़ाइन को हकीकत में बदलें',
        'idLabel': 'यूजरनेम या ईमेल',
        'passLabel': 'पासवर्ड',
        'loginBtn': 'कार्यशाला में प्रवेश करें',
        'forgotPass': 'पासवर्ड भूल गए?',
        'noAccount': 'नया टेलर? दुकान रजिस्टर करें',
        'success': 'लॉगिन सफल!',
        'resetTitle': 'पासवर्ड रीसेट करें',
        'resetDesc': 'पासवर्ड रीसेट लिंक प्राप्त करने के लिए अपना रजिस्टर्ड ईमेल दर्ज करें।',
        'sendLink': 'लिंक भेजें',
        'cancel': 'रद्द करें',
        'howToUseTitle': 'ऐप का उपयोग कैसे करें',
        'howToUseDesc': '1. अपना रजिस्टर्ड यूजरनेम या ईमेल और पासवर्ड दर्ज करें。\n2. डैशबोर्ड खोलने के लिए "कार्यशाला में प्रवेश करें" पर क्लिक करें。\n3. यदि आप नए हैं, तो खाता बनाने के लिए नीचे "दुकान रजिस्टर करें" पर क्लिक करें。\n4. ऊपर दिए गए कोने से कभी भी अपनी पसंद की भाषा बदल सकते हैं।',
        'gotIt': 'समझ गए',
        // SnackBar & Validation Messages
        'errUserNotFound': 'यूजरनेम नहीं मिला!',
        'errVerifyEmail': 'पहले अपना ईमेल वेरिफाय करें!',
        'errWrongPass': 'ईमेल या पासवर्ड गलत है!',
        'errLoginFailed': 'लॉगिन असफल रहा',
      },
      'Marathi': {
        'welcome': 'मास्टर दर्जी पोर्टल',
        'subtitle': 'तुमच्या फॅशन डिझाईन्स प्रत्यक्षात आणा',
        'idLabel': 'युजरनेम किंवा ईमेल',
        'passLabel': 'पासवर्ड',
        'loginBtn': 'कार्यशाळेत प्रवेश करा',
        'forgotPass': 'पासवर्ड विसरलात?',
        'noAccount': 'नवीन टेलर? दुकान नोंदणी करा',
        'success': 'लॉगिन यशस्वी!',
        'resetTitle': 'पासवर्ड रीसेट करा',
        'resetDesc': 'पासवर्ड रीसेट लिंक मिळवण्यासाठी तुमचा नोंदणीकृत ईमेल प्रविष्ट करा.',
        'sendLink': 'लिंक पाठवा',
        'cancel': 'रद्द करा',
        'howToUseTitle': 'ॲप कसे वापरावे',
        'howToUseDesc': '1. तुमचा नोंदणीकृत युजरनेम किंवा ईमेल आणि पासवर्ड प्रविष्ट करा.\n2. डॅशबोर्ड उघडण्यासाठी "कार्यशाळेत प्रवेश करा" दाबा.\n3. तुम्ही नवीन असल्यास, खाते तयार करण्यासाठी खालील "दुकान नोंदणी करा" वर क्लिक करा.\n4. वरच्या उजव्या कोपर्यातून कधीही भाषा बदलू शकता.',
        'gotIt': 'समजले',
        // SnackBar & Validation Messages
        'errUserNotFound': 'युजरनेम सापडला नाही!',
        'errVerifyEmail': 'कृपया आधी तुमचा ईमेल सत्यापित करा!',
        'errWrongPass': 'ईमेल किंवा पासवर्ड चुकीचा आहे!',
        'errLoginFailed': 'लॉगिन अयशस्वी',
      }
    };
    return translations[_selectedLanguage]?[key] ?? key;
  }

  // --- How to Use Dialog Popup ---
  void _showHowToUseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161F36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFF818CF8)),
              const SizedBox(width: 10),
              Text(
                _getText('howToUseTitle'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            _getText('howToUseDesc'),
            style: TextStyle(color: Colors.indigo.shade100, fontSize: 14, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(_getText('gotIt')),
            ),
          ],
        );
      },
    );
  }

  void _login() async {
    setState(() => _isLoading = true);

    Map<String, dynamic> response = await DatabaseService.loginUser(
      _identifierController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    
    // Server/Database message key ko translation se map karna
    String messageKey = response['messageKey'] ?? 'errLoginFailed';
    String displayMessage = _getText(messageKey);

    if (response['status'] == true) {
      String userEmail = response['email'] ?? response['user']?['email'] ?? _identifierController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getText('success')),
          backgroundColor: Colors.indigo.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboard(
            email: userEmail,
            initialLanguage: _selectedLanguage,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController forgotEmailController = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161F36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
              title: Text(
                _getText('resetTitle'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _getText('resetDesc'),
                    style: TextStyle(color: Colors.indigo.shade200, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: forgotEmailController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: _getText('idLabel'),
                      labelStyle: TextStyle(color: Colors.indigo.shade200),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF818CF8)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getText('cancel'), style: TextStyle(color: Colors.indigo.shade300)),
                ),
                isResetting
                    ? const CircularProgressIndicator(color: Color(0xFF818CF8))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          String email = forgotEmailController.text.trim();
                          if (email.isEmpty) return;

                          setDialogState(() => isResetting = true);

                          Map<String, dynamic> response = await DatabaseService.resetPassword(email);

                          setDialogState(() => isResetting = false);

                          if (!mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['message']),
                              backgroundColor: response['status'] == true ? Colors.indigo.shade800 : Colors.redAccent.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: Text(_getText('sendLink')),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0F1D),
              Color(0xFF1A1635),
              Color(0xFF2D123D),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: isDesktop ? 480 : double.infinity,
                margin: const EdgeInsets.all(24),
                child: Card(
                  elevation: 25,
                  shadowColor: Colors.black54,
                  color: const Color(0xFF161F36).withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Bar: How to Use Button & Language Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // "How to Use" Help Button[cite: 14]
                            IconButton(
                              onPressed: _showHowToUseDialog,
                              icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF818CF8)),
                              tooltip: 'How to Use',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                side: BorderSide(color: Colors.indigo.shade400.withOpacity(0.3)),
                              ),
                            ),
                            // Language Selector at Top Right[cite: 14]
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                border: Border.all(color: Colors.indigo.shade400.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                dropdownColor: const Color(0xFF0F172A),
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF818CF8)),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF818CF8), fontSize: 13),
                                items: _languages.map((lang) {
                                  return DropdownMenuItem(value: lang, child: Text(lang));
                                }).toList(),
                                onChanged: _changeLanguage,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Logo housing the Master Tailor Badge Custom Painter
                        Center(
                          child: AnimatedBuilder(
                            animation: _logoAnimController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnim.value,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 105,
                                      height: 105,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF6366F1), Color(0xFF9333EA), Color(0xFFEC4899)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.purple.withOpacity(0.5),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 92,
                                      height: 92,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF0F172A),
                                      ),
                                      child: Center(
                                        child: CustomPaint(
                                          size: const Size(64, 64),
                                          painter: MasterTailorBadgePainter(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          _getText('welcome'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getText('subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.indigo.shade200, height: 1.2),
                        ),
                        const SizedBox(height: 32),

                        // Form Inputs
                        TextField(
                          controller: _identifierController,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: _getText('idLabel'),
                            labelStyle: TextStyle(color: Colors.indigo.shade200),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF818CF8)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: _getText('passLabel'),
                            labelStyle: TextStyle(color: Colors.indigo.shade200),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF818CF8)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.indigo.shade200,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                            child: Text(
                              _getText('forgotPass'),
                              style: TextStyle(
                                color: Colors.indigo.shade300,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF818CF8)))
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.indigo.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: _login,
                                  child: Text(
                                    _getText('loginBtn'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 20),
                        
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(initialLanguage: _selectedLanguage),
                              ),
                            );
                          },
                          child: Text(
                            _getText('noAccount'),
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Master Tailor Badge Custom Painter
class MasterTailorBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFF3E8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = const Color(0xFFC084FC)
      ..style = PaintingStyle.fill;

    final suitPath = Path();
    suitPath.moveTo(size.width * 0.20, size.height * 0.32);
    suitPath.lineTo(size.width * 0.38, size.height * 0.40);
    suitPath.lineTo(size.width * 0.32, size.height * 0.75);
    suitPath.lineTo(size.width * 0.5, size.height * 0.68);
    suitPath.lineTo(size.width * 0.68, size.height * 0.75);
    suitPath.lineTo(size.width * 0.62, size.height * 0.40);
    suitPath.lineTo(size.width * 0.80, size.height * 0.32);

    canvas.drawPath(suitPath, linePaint);

    final tiePath = Path();
    tiePath.moveTo(size.width * 0.44, size.height * 0.38);
    tiePath.lineTo(size.width * 0.5, size.height * 0.44);
    tiePath.lineTo(size.width * 0.56, size.height * 0.38);
    tiePath.moveTo(size.width * 0.47, size.height * 0.44);
    tiePath.lineTo(size.width * 0.53, size.height * 0.44);
    tiePath.lineTo(size.width * 0.51, size.height * 0.62);
    tiePath.lineTo(size.width * 0.5, size.height * 0.65);
    tiePath.lineTo(size.width * 0.49, size.height * 0.62);
    tiePath.close();

    canvas.drawPath(tiePath, linePaint..strokeWidth = 1.5);

    final tapePath = Path();
    tapePath.moveTo(size.width * 0.12, size.height * 0.55);
    tapePath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.90,
      size.width * 0.88, size.height * 0.55,
    );
    canvas.drawPath(
      tapePath,
      Paint()
        ..color = const Color(0xFFEC4899)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), 2.5, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}