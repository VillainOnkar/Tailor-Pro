import 'dart:convert'; // Base64 decode ke liye zaroori import
import 'package:flutter/material.dart';
import 'login_screen.dart'; 
import 'wizard/add_customer_screen.dart';
import 'customer_list/customer_list_screen.dart';
import 'billing_screen.dart';
import 'workers/worker_screen.dart';
import 'settings/settings_screen.dart'; 
import 'reports_screen.dart'; 
import '../database.dart'; // <-- Database service import karein

class AdminDashboard extends StatefulWidget {
  final String email;
  final String initialLanguage;
  const AdminDashboard({super.key, required this.email, this.initialLanguage = 'English'});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  late String _selectedLanguage;
  bool _isDarkMode = true;
  
  // Database Data Variables
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  
  // Animation Controllers
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  // Entry Pulse Animation for Title
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Background Moving Purple-Violet Gradient Controller
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedLanguage = widget.initialLanguage;
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    
    _animController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Dashboard Data Fetching (First time with loader)
    _fetchDashboardData(showLoader: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Sirf tab fetch karein jab user dashboard par ho aur app resume ho (Bina loader ke)[cite: 23]
    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _fetchDashboardData(showLoader: false);
    }
  }

  Future<void> _fetchDashboardData({bool showLoader = false}) async {
    if (!mounted) return;
    
    // Sirf tabhi _isLoading true karein jab pehli baar load ho raha ho (taki blinking na ho)
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final data = await DatabaseService.getAdminDashboardData(widget.email);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AdminDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sirf dashboard par hone par hi update karein[cite: 23]
    if (_currentIndex == 0) {
      _fetchDashboardData(showLoader: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'dashboard': 'Dashboard',
        'shopName': 'Royal Boutique & Tailors',
        'customers': 'Customers',
        'bill': 'Billing', 
        'workers': 'Workers',
        'reports': 'Reports',
        'settings': 'Settings',
        'totalCustomers': 'Total Customers',
        'totalOrders': 'Total Orders',
        'pendingOrders': 'Pending Orders',
        'readyOrders': 'Ready Orders',
        'deliveredOrders': 'Delivered Orders',
        'logout': 'Logout',
        'newCustomer': 'New Customer',
        'paymentBreakdown': 'Revenue Matrix (Cash vs UPI)',
        'cashPayment': 'Cash Collected',
        'upiPayment': 'UPI Digital',
        'totalIncome': 'Total Income',
        'pendingDueCard': 'Market Outstanding Dues',
        'alertCenterTitle': 'Live Orders & Today\'s Deliveries',
        'alertSubtitle': 'Active order dispatches and production updates',
        'ordersCountLabel': 'Orders',
        'noDispatches': 'No order dispatches pending today! 📦',
        'dueTodayTag': 'Due Today',
        'collectTag': 'Collect',
      },
      'Hindi': {
        'dashboard': 'डॅशबोर्ड',
        'shopName': 'रॉयल बुटीक एंड टेलर',
        'customers': 'ग्राहक',
        'bill': 'बिलिंग', 
        'workers': 'कर्मचारी',
        'reports': 'रिपोर्ट्स',
        'settings': 'सेटिंग्स',
        'totalCustomers': 'कुल ग्राहक',
        'totalOrders': 'कुल ऑर्डर्स',
        'pendingOrders': 'लंबित ऑर्डर्स',
        'readyOrders': 'तैयार ऑर्डर्स',
        'deliveredOrders': 'डिलीवर किए गए',
        'logout': 'लॉग आउट',
        'newCustomer': 'नया ग्राहक',
        'paymentBreakdown': 'रेवेन्यू मैट्रिक्स (Cash vs UPI)',
        'cashPayment': 'Cash प्राप्त',
        'upiPayment': 'UPI डिजिटल',
        'totalIncome': 'कुल आय',
        'pendingDueCard': 'बाकी बाजार भुगतान',
        'alertCenterTitle': 'लाइव ऑर्डर्स और आज की डिलीवरी',
        'alertSubtitle': 'आज के ऑर्डर्स और डिलीवरी की स्थिति',
        'ordersCountLabel': 'ऑर्डर्स',
        'noDispatches': 'आज कोई डिलीवरी लंबित नहीं है! 📦',
        'dueTodayTag': 'आज देय',
        'collectTag': 'वसूली',
      },
      'Marathi': {
        'dashboard': 'डॅशबोर्ड', 
        'shopName': 'रॉयल बुटीक आणि टेलर',
        'customers': 'ग्राहक',
        'bill': 'बिलिंग', 
        'workers': 'कामगार',
        'reports': 'अहवाल',
        'settings': 'सेटिंग्स',
        'totalCustomers': 'एकूण ग्राहक',
        'totalOrders': 'एकूण ऑर्डर्स',
        'pendingOrders': 'प्रलंबित ऑर्डर्स',
        'readyOrders': 'तयार ऑर्डर्स',
        'deliveredOrders': 'वितरित ऑर्डर्स',
        'logout': 'बाहेर पडा',
        'newCustomer': 'नवीन ग्राहक',
        'paymentBreakdown': 'उत्पन्न मॅट्रिक्स',
        'cashPayment': 'Cash जमा',
        'upiPayment': 'UPI डिजिटल',
        'totalIncome': 'एकूण उत्पन्न',
        'pendingDueCard': 'बाकी रक्कम',
        'alertCenterTitle': 'थेट ऑर्डर्स आणि आजचे वितरण',
        'alertSubtitle': 'सक्रिय ऑर्डर्स आणि डिलिव्हरी तपशील',
        'ordersCountLabel': 'ऑर्डर्स',
        'noDispatches': 'आज कोणतीही डिलिव्हरी बाकी नाही! 📦',
        'dueTodayTag': 'आज देणे आहे',
        'collectTag': 'वसूल करा',
      }
    };
    return translations[_selectedLanguage]?[key] ?? key;
  }

  void _handleLogout() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginScreen(initialLanguage: _selectedLanguage),
      ),
      (route) => false,
    );
  }

  void _openAddCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(
          initialLanguage: _selectedLanguage,
          isDarkMode: _isDarkMode,
          userEmail: widget.email,
        ),
      ),
    );
    // Sirf tabhi refresh ho jab user dashboard par hi ho[cite: 23]
    if (_currentIndex == 0) {
      _fetchDashboardData(showLoader: false);
    }
  }

  Widget _getSelectedScreen(Color surfaceColor, Color borderColor, Color textColor, Color subTextColor, Color accentColor, bool isDesktop) {
    if (_currentIndex == 1) {
      return CustomerListScreen(initialLanguage: _selectedLanguage, isDarkMode: _isDarkMode, userEmail: widget.email);
    } else if (_currentIndex == 2) {
      return BillingScreen(initialLanguage: _selectedLanguage, isDarkMode: _isDarkMode, userEmail: widget.email);
    } else if (_currentIndex == 3) {
      return WorkerScreen(initialLanguage: _selectedLanguage, isDarkMode: _isDarkMode, userEmail: widget.email);
    } else if (_currentIndex == 4) {
      return ReportsScreen(initialLanguage: _selectedLanguage, isDarkMode: _isDarkMode, userEmail: widget.email);
    } else if (_currentIndex == 5) {
      return SettingsScreen(
        initialLanguage: _selectedLanguage,
        isDarkMode: _isDarkMode,
        userEmail: widget.email,
        onThemeChanged: (val) => setState(() => _isDarkMode = val),
        onLanguageChanged: (val) => setState(() => _selectedLanguage = val),
      );
    }
    return _buildDashboardBody(surfaceColor, borderColor, textColor, subTextColor, accentColor, isDesktop);
  }

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = _isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    Color borderColor = _isDarkMode ? const Color(0xFF2D2D3F) : const Color(0xFFE2E2E9);
    Color textColor = _isDarkMode ? Colors.white : const Color(0xFF1E1B2E);
    Color subTextColor = _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    const Color accentColor = Color(0xFF8B5CF6);

    String rawFullName = _dashboardData['full_name'] ?? widget.email.split('@')[0];
    String greetingText = "👋 Hello, $rawFullName";

    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth >= 950;

            return Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(75),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor.withOpacity(0.92),
                    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(_isDarkMode ? 0.4 : 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (!isDesktop)
                                IconButton(
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.menu_rounded, color: textColor, size: 20),
                                  onPressed: () {
                                    showMenu(
                                      context: context,
                                      position: const RelativeRect.fromLTRB(10, 70, 100, 0),
                                      color: surfaceColor,
                                      items: [
                                        PopupMenuItem(
                                          child: Row(children: [
                                            const Icon(Icons.badge_rounded, color: accentColor, size: 18),
                                            const SizedBox(width: 10),
                                            Text(_getText('workers'), style: TextStyle(color: textColor, fontSize: 13)),
                                          ]),
                                          onTap: () => Future.delayed(const Duration(milliseconds: 100), () => setState(() => _currentIndex = 3)),
                                        ),
                                        PopupMenuItem(
                                          child: Row(children: [
                                            const Icon(Icons.settings_rounded, color: accentColor, size: 18),
                                            const SizedBox(width: 10),
                                            Text(_getText('settings'), style: TextStyle(color: textColor, fontSize: 13)),
                                          ]),
                                          onTap: () => Future.delayed(const Duration(milliseconds: 100), () => setState(() => _currentIndex = 5)),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  greetingText, 
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildCompactIconButton(
                              icon: _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: accentColor,
                              tooltip: "Toggle Theme",
                              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                            ),
                            const SizedBox(width: 6),
                            _buildCompactIconButton(
                              icon: Icons.power_settings_new_rounded,
                              color: Colors.redAccent,
                              tooltip: _getText('logout'),
                              onPressed: _handleLogout,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(_backgroundController.value - 1, -1),
                    end: Alignment(_backgroundController.value, 1),
                    colors: _isDarkMode 
                      ? [const Color(0xFF0F0A1F), const Color(0xFF2E1A47), const Color(0xFF130B29)]
                      : [const Color(0xFFF7F5FC), const Color(0xFFE5D5F8), const Color(0xFFF0E6FC)],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (isDesktop)
                        Container(
                          width: 240,
                          decoration: BoxDecoration(
                            color: surfaceColor.withOpacity(0.9),
                            border: Border(right: BorderSide(color: borderColor, width: 1)),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildSidebarItem(0, Icons.space_dashboard_rounded, _getText('dashboard'), accentColor, subTextColor, textColor),
                              _buildSidebarItem(1, Icons.people_alt_rounded, _getText('customers'), accentColor, subTextColor, textColor),
                              _buildSidebarItem(2, Icons.receipt_long_rounded, _getText('bill'), accentColor, subTextColor, textColor), 
                              _buildSidebarItem(3, Icons.badge_rounded, _getText('workers'), accentColor, subTextColor, textColor),
                              _buildSidebarItem(4, Icons.analytics_rounded, _getText('reports'), accentColor, subTextColor, textColor),
                              _buildSidebarItem(5, Icons.admin_panel_settings_rounded, _getText('settings'), accentColor, subTextColor, textColor),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: accentColor.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rawFullName, 
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), 
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(widget.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subTextColor, fontSize: 9)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: _isLoading 
                                    ? const Center(child: CircularProgressIndicator(color: accentColor))
                                    : _getSelectedScreen(surfaceColor, borderColor, textColor, subTextColor, accentColor, isDesktop),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: isDesktop ? null : SizedBox(
                height: 48,
                width: 48,
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 4,
                  onPressed: _openAddCustomer,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
                      boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: const Center(child: Icon(Icons.add_rounded, color: Colors.white, size: 24)),
                  ),
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: isDesktop ? null : BottomAppBar(
                color: surfaceColor.withOpacity(0.95),
                shape: const CircularNotchedRectangle(),
                notchMargin: 6.0,
                elevation: 10,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomNavItem(0, Icons.space_dashboard_rounded, _getText('dashboard'), accentColor, subTextColor, textColor),
                        _buildBottomNavItem(1, Icons.people_alt_rounded, _getText('customers'), accentColor, subTextColor, textColor),
                        const SizedBox(width: 32), 
                        _buildBottomNavItem(2, Icons.receipt_long_rounded, _getText('bill'), accentColor, subTextColor, textColor), 
                        _buildBottomNavItem(4, Icons.analytics_rounded, _getText('reports'), accentColor, subTextColor, textColor), 
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardBody(Color surfaceColor, Color borderColor, Color textColor, Color subTextColor, Color accentColor, bool isDesktop) {
    String totalCustomers = (_dashboardData['totalCustomers'] ?? 0).toString();
    String totalOrders = (_dashboardData['totalOrders'] ?? 0).toString();
    String pendingOrders = (_dashboardData['pendingOrdersCount'] ?? 0).toString();
    String readyOrders = (_dashboardData['readyOrdersCount'] ?? 0).toString();
    String deliveredOrders = (_dashboardData['deliveredOrdersCount'] ?? 0).toString();
    
    double totalRevenue = (_dashboardData['totalRevenue'] ?? 0.0);
    double pendingAmount = (_dashboardData['pendingAmount'] ?? 0.0);
    
    Map paymentModes = _dashboardData['paymentModes'] ?? {'cash': 0.0, 'upi': 0.0};
    double cashCollected = paymentModes['cash'] ?? 0.0;
    double upiCollected = paymentModes['upi'] ?? 0.0;

    List alertsList = _dashboardData['alertsList'] ?? [];
    
    List orderAlertsList = alertsList.where((alert) {
      String title = (alert['title'] ?? '').toLowerCase();
      String tag = (alert['tag'] ?? '').toLowerCase();
      return title.contains('order') || title.contains('delivery') || tag.contains('shipping') || alert['icon'] == 'shipping';
    }).toList();

    String fetchedShopName = _dashboardData['shopName'] ?? _getText('shopName');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Color(0xFFE879F9),
                        Color(0xFFA78BFA),
                        Color(0xFF38BDF8),
                        Color(0xFFE879F9),
                      ],
                      stops: [0.0, _glowAnimation.value, _glowAnimation.value + 0.3, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Text(
                        fetchedShopName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 34 : 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFA78BFA).withOpacity(_glowAnimation.value),
                              blurRadius: 22,
                              offset: const Offset(0, 0),
                            ),
                            const Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(1, 3),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (isDesktop) ...[
            const SizedBox(height: 10),
            Center(
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(_glowAnimation.value),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _openAddCustomer,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: Text(_getText('newCustomer'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          _buildLiveAlertBanner(textColor, subTextColor, orderAlertsList),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth >= 1100 ? 5 : (constraints.maxWidth >= 650 ? 3 : 2);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildColorfulCard(_getText('totalCustomers'), totalCustomers, Icons.groups_rounded, [const Color(0xFF1E88E5), const Color(0xFF1565C0)]),
                  _buildColorfulCard(_getText('totalOrders'), totalOrders, Icons.inventory_2_rounded, [const Color(0xFFFB8C00), const Color(0xFFEF6C00)]),
                  _buildColorfulCard(_getText('pendingOrders'), pendingOrders, Icons.hourglass_top_rounded, [const Color(0xFFFFB300), const Color(0xFFF57F17)]),
                  _buildColorfulCard(_getText('readyOrders'), readyOrders, Icons.verified_rounded, [const Color(0xFF43A047), const Color(0xFF2E7D32)]),
                  _buildColorfulCard(_getText('deliveredOrders'), deliveredOrders, Icons.local_shipping_rounded, [const Color(0xFF8E24AA), const Color(0xFF6A1B9A)]),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, boxConstraints) {
              bool useRow = boxConstraints.maxWidth >= 900;
              if (useRow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPaymentChartContainer(surfaceColor, borderColor, textColor, subTextColor, totalRevenue, cashCollected, upiCollected)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPendingDueCard(surfaceColor, borderColor, textColor, subTextColor, pendingAmount)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPaymentChartContainer(surfaceColor, borderColor, textColor, subTextColor, totalRevenue, cashCollected, upiCollected),
                    const SizedBox(height: 16),
                    _buildPendingDueCard(surfaceColor, borderColor, textColor, subTextColor, pendingAmount),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAlertBanner(Color textColor, Color subTextColor, List orderAlertsList) {
    int totalAlertsCount = orderAlertsList.length;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1035), Color(0xFF2D1657), Color(0xFF1E1035)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(_glowAnimation.value * 0.4),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA78BFA).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFA78BFA), size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _getText('alertCenterTitle'),
                            style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w900, fontSize: 13),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                    ),
                    child: Text(
                      "$totalAlertsCount ${_getText('ordersCountLabel')}",
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getText('alertSubtitle'),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
              const SizedBox(height: 12),
              if (orderAlertsList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    _getText('noDispatches'),
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                )
              else
                ...orderAlertsList.map((alert) {
                  IconData icon = Icons.local_shipping_rounded;
                  Color iconColor = Colors.greenAccent;
                  
                  String originalTag = alert['tag'] ?? 'Order';
                  String translatedTag = originalTag;
                  if (originalTag.toLowerCase().contains('today') || originalTag.toLowerCase().contains('due')) {
                    translatedTag = _getText('dueTodayTag');
                  } else if (originalTag.toLowerCase().contains('collect')) {
                    translatedTag = _getText('collectTag');
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildAlertBubbleItem(
                      icon, 
                      iconColor, 
                      alert['title'] ?? '', 
                      translatedTag
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertBubbleItem(IconData icon, Color iconColor, String title, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(color: iconColor, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactIconButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPaymentChartContainer(Color surfaceColor, Color borderColor, Color textColor, Color subTextColor, double totalRevenue, double cashCollected, double upiCollected) {
    double totalCol = cashCollected + upiCollected;
    double cashPercentage = totalCol > 0 ? (cashCollected / totalCol) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Colors.green, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getText('paymentBreakdown'), 
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isCompact = constraints.maxWidth < 360;
              if (isCompact) {
                return Column(
                  children: [
                    _buildChartCenter(textColor, subTextColor, totalRevenue, cashPercentage),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildExactLegendItem(Colors.green, _getText('cashPayment'), "₹${cashCollected.toStringAsFixed(0)}", textColor, subTextColor),
                        _buildExactLegendItem(Colors.redAccent.shade200, _getText('upiPayment'), "₹${upiCollected.toStringAsFixed(0)}", textColor, subTextColor),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChartCenter(textColor, subTextColor, totalRevenue, cashPercentage),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExactLegendItem(Colors.green, _getText('cashPayment'), "₹${cashCollected.toStringAsFixed(0)}", textColor, subTextColor),
                      const SizedBox(height: 12),
                      _buildExactLegendItem(Colors.redAccent.shade200, _getText('upiPayment'), "₹${upiCollected.toStringAsFixed(0)}", textColor, subTextColor),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartCenter(Color textColor, Color subTextColor, double totalRevenue, double cashPercentage) {
    return SizedBox(
      width: 115,
      height: 115,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 115,
            height: 115,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 14,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent.shade200),
            ),
          ),
          SizedBox(
            width: 115,
            height: 115,
            child: CircularProgressIndicator(
              value: cashPercentage,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "₹${totalRevenue.toStringAsFixed(0)}", 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor),
              ),
              const SizedBox(height: 1),
              Text(
                _getText('totalIncome'), 
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: subTextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDueCard(Color surfaceColor, Color borderColor, Color textColor, Color subTextColor, double pendingAmount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.redAccent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getText('pendingDueCard'), 
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Outstanding", style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text("₹${pendingAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
          Divider(color: borderColor, height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: subTextColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Market Dues Active", maxLines: 2, overflow: TextOverflow.visible, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 1),
                            const Text("Tap customers for ledger", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExactLegendItem(Color color, String label, String amount, Color textColor, Color subTextColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.visible),
            const SizedBox(height: 1),
            Text(amount, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildColorfulCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, Color accentColor, Color subTextColor, Color textColor) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => _currentIndex = index);
            // Agar user wapas Dashboard par click kare toh silently refresh karein[cite: 23]
            if (_currentIndex == 0) {
              _fetchDashboardData(showLoader: false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? accentColor.withOpacity(0.4) : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? accentColor : subTextColor, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: TextStyle(color: isSelected ? accentColor : textColor, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 13), overflow: TextOverflow.visible)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label, Color accentColor, Color subTextColor, Color textColor) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        // Agar user dashboard par click kare tabhi data fetch ho[cite: 23]
        if (_currentIndex == 0) {
          _fetchDashboardData(showLoader: false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? accentNameColorOrFallback(accentColor) : subTextColor, size: isSelected ? 22 : 18),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? accentColor : textColor, fontSize: 9, fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
  
  Color accentNameColorOrFallback(Color c) => c;
}