import 'package:flutter/material.dart';
import '../database.dart';

class RegisterScreen extends StatefulWidget {
  final String initialLanguage;
  const RegisterScreen({super.key, required this.initialLanguage});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late String _selectedLanguage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'title': 'Shop Registration',
        'subtitle': 'Setup your professional tailoring workspace',
        'nameLabel': 'Full Name / Shop Name',
        'userLabel': 'Username',
        'emailLabel': 'Email Address',
        'phoneLabel': 'Phone Number',
        'passLabel': 'Secure Password',
        'confirmPassLabel': 'Confirm Password',
        'regBtn': 'Initialize Shop Account',
        'backToLogin': 'Already have an account? Sign In',
        // Messages
        'passMismatch': 'Passwords do not match',
        'errUserExists': 'Username already exists!',
        'errEmailExists': 'Email already exists!',
        'errWeakPass': 'Password is too weak!',
        'errDbSave': 'Database Error: Could not save data.',
        'errLinkSend': 'Account created, but verification link failed to send. Try logging in later.',
        'regSuccess': 'Registration Successful! Check your email and click the verification link.',
        'errRegFailed': 'Registration Failed',
      },
      'Hindi': {
        'title': 'शॉप रजिस्ट्रेशन',
        'subtitle': 'अपना प्रोफेशनल टेलरिंग वर्कस्पेस सेट अप करें',
        'nameLabel': 'पूरा नाम / दुकान का नाम',
        'userLabel': 'यूजरनेम',
        'emailLabel': 'ईमेल आईडी',
        'phoneLabel': 'फोन नंबर',
        'passLabel': 'पासवर्ड',
        'confirmPassLabel': 'पासवर्ड पुष्टि करें',
        'regBtn': 'दुकान खाता बनाएं',
        'backToLogin': 'पहले से खाता है? लॉगिन करें',
        // Messages
        'passMismatch': 'पासवर्ड मेल नहीं खा रहे हैं',
        'errUserExists': 'यह यूजरनेम पहले से मौजूद है!',
        'errEmailExists': 'यह ईमेल पहले से रजिस्टर्ड है!',
        'errWeakPass': 'पासवर्ड बहुत कमज़ोर है!',
        'errDbSave': 'डेटाबेस एरर: डेटा सेव नहीं हो पाया।',
        'errLinkSend': 'खाता बन गया पर वेरिफिकेशन लिंक नहीं भेजा जा सका। लॉगिन करके दोबारा कोशिश करें।',
        'regSuccess': 'रजिस्ट्रेशन सफल! अपना ईमेल चेक करें और वेरिफिकेशन लिंक पर क्लिक करें।',
        'errRegFailed': 'रजिस्ट्रेशन असफल रहा',
      },
      'Marathi': {
        'title': 'दुकान नोंदणी',
        'subtitle': 'तुमचे व्यावसायिक टेलरिंग कार्यक्षेत्र तयार करा',
        'nameLabel': 'पूर्ण नाव / दुकानाचे नाव',
        'userLabel': 'युजरनेम',
        'emailLabel': 'ईमेल पत्ता',
        'phoneLabel': 'मोबाईल नंबर',
        'passLabel': 'पासवर्ड',
        'confirmPassLabel': 'पासवर्ड पुष्टी करा',
        'regBtn': 'दुकानाचे खाते तयार करा',
        'backToLogin': 'आधीच खाते आहे का? लॉगिन करा',
        // Messages
        'passMismatch': 'पासवर्ड जुळत नाहीत',
        'errUserExists': 'हा युजरनेम आधीपासून अस्तित्वात आहे!',
        'errEmailExists': 'हा ईमेल आधीपासून नोंदणीकृत आहे!',
        'errWeakPass': 'पासवर्ड खूप सुरक्षित नाही / कमजोर आहे!',
        'errDbSave': 'डेटाबेस एरर: डेटा सेव्ह होऊ शकला नाही.',
        'errLinkSend': 'खाते तयार झाले परंतु पडताळणी लिंक पाठवली गेली नाही. नंतर लॉगिन करून पुन्हा प्रयत्न करा.',
        'regSuccess': 'नोंदणी यशस्वी! तुमचा ईमेल तपासा  आणि पडताळणी लिंकवर क्लिक करा.',
        'errRegFailed': 'नोंदणी अयशस्वी',
      }
    };
    return translations[_selectedLanguage]?[key] ?? key;
  }

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getText('passMismatch')),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> response = await DatabaseService.registerUserInDb(
      _emailController.text,
      _usernameController.text,
      _passwordController.text,
      _fullNameController.text,
      _phoneController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    String messageKey = response['messageKey'] ?? 'errRegFailed';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getText(messageKey)),
        backgroundColor: response['status'] == true ? Colors.indigo.shade800 : Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (response['status'] == true) {
      Navigator.pop(context);
    }
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              width: isDesktop ? 520 : double.infinity,
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
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF9333EA), Color(0xFFEC4899)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 74,
                              height: 74,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0F172A),
                              ),
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(48, 48),
                                  painter: MasterTailorBadgePainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      Text(
                        _getText('title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getText('subtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.indigo.shade200),
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _fullNameController,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: _getText('nameLabel'),
                                    labelStyle: TextStyle(color: Colors.indigo.shade200),
                                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF818CF8)),
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: _getText('userLabel'),
                                    labelStyle: TextStyle(color: Colors.indigo.shade200),
                                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF818CF8)),
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: _getText('emailLabel'),
                                    labelStyle: TextStyle(color: Colors.indigo.shade200),
                                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF818CF8)),
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _phoneController,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: _getText('phoneLabel'),
                                    labelStyle: TextStyle(color: Colors.indigo.shade200),
                                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF818CF8)),
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: _getText('passLabel'),
                                    labelStyle: TextStyle(color: Colors.indigo.shade200),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF818CF8)),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.indigo.shade200),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: _getText('confirmPassLabel'),
                                    labelStyle: TextStyle(color: Colors.indigo.shade200),
                                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF818CF8)),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.indigo.shade200),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 24),

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
                                          onPressed: _register,
                                          child: Text(
                                            _getText('regBtn'),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    _getText('backToLogin'),
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
                    ],
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