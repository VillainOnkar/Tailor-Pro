import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
 
import '../../database.dart';                 // DatabaseService ke liye
import 'customer_profile_screen.dart';     // CustomerProfileScreen ke liye
 


// --- 1. CUSTOMER LIST SCREEN ---
class CustomerListScreen extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String userEmail;

  const CustomerListScreen({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.userEmail,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _currentLanguage;
  
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  // 🚀 Caching map to avoid repeated base64 decoding and eliminate blinking/lag
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetched = await DatabaseService.fetchCustomersFromFirebase(widget.userEmail);
      setState(() {
        _customers = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'title': 'Customers Hub',
      'orders': 'Orders',
      'allCustomers': 'Directory',
      'searchHint': 'Search by Name or Mobile...',
      'noCustomers': 'No customers found',
      'addCustomer': 'Add Customer',
      'editCustomer': 'Edit Customer',
      'name': 'Name',
      'mobile': 'Mobile',
      'address': 'Address',
      'cancel': 'Cancel',
      'save': 'Save',
      'deleteTitle': 'Delete Customer?',
      'deleteConfirm': 'Are you sure you want to delete',
      'no': 'No',
      'yes': 'Yes',
      'newOrder': '📦 New Order',
      'edit': '✏ Edit',
      'measurement': '📏 Measurement',
      'delete': '🗑 Delete',
      'customerProfile': 'Customer Profile',
      'orderHistory': 'Order History',
      'masterMeasurement': 'Master Measurement',
      'paymentHistory': 'Payment History',
      'deleteCustomer': 'Delete Customer',
      'totalDue': 'Total Due',
      'lastOrder': 'Last Order',
      'customerSince': 'Customer Since',
      'pendingOrders': 'Pending Orders',
      'completedOrders': 'Completed Orders',
      'pending': 'Pending',
      'delivered': 'Delivered',
      'completed': 'Completed',
    },
    'Hindi': {
      'title': 'ग्राहक हब',
      'orders': 'ऑर्डर्स',
      'allCustomers': 'डिफ़ॉल्ट डायरेक्टरी',
      'searchHint': 'नाम या मोबाइल नंबर से खोजें...',
      'noCustomers': 'कोई ग्राहक नहीं मिला',
      'addCustomer': 'नया ग्राहक जोड़ें',
      'editCustomer': 'ग्राहक विवरण बदलें',
      'name': 'नाम',
      'mobile': 'मोबाइल',
      'address': 'पता',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'deleteTitle': 'ग्राहक हटाएं?',
      'deleteConfirm': 'क्या आप वाकई हटाना चाहते हैं',
      'no': 'नहीं',
      'yes': 'हाँ',
      'newOrder': '📦 नया ऑर्डर',
      'edit': '✏ एडिट',
      'measurement': '📏 माप',
      'delete': '🗑 हटाएं',
      'customerProfile': 'ग्राहक प्रोफाइल',
      'orderHistory': 'ऑर्डर इतिहास',
      'masterMeasurement': 'माप (Measurement)',
      'paymentHistory': 'भुगतान इतिहास',
      'deleteCustomer': 'ग्राहक हटाएं',
      'totalDue': 'कुल बाकी',
      'lastOrder': 'अंतिम ऑर्डर',
      'customerSince': 'ग्राहक कब से',
      'pendingOrders': 'लंबित ऑर्डर्स',
      'completedOrders': 'पूर्ण ऑर्डर्स',
      'pending': 'लंबित',
      'delivered': 'डिलिव्हर्ड',
      'completed': 'पूर्ण',
    },
    'Marathi': {
      'title': 'ग्राहक हब',
      'orders': 'ऑर्डर्स',
      'allCustomers': 'सर्व ग्राहक',
      'searchHint': 'नाव किंवा मोबाईल नंबर द्वारे शोधा...',
      'noCustomers': 'कोणतेही ग्राहक सापडले नाहीत',
      'addCustomer': 'ग्राहक जोडा',
      'editCustomer': 'ग्राहक माहिती संपादित करा',
      'name': 'नाव',
      'mobile': 'मोबाईल',
      'address': 'पत्ता',
      'cancel': 'रद्द करा',
      'save': 'सेव्ह करा',
      'deleteTitle': 'ग्राहक हटवायचा?',
      'deleteConfirm': 'तुम्हाला नक्की हटवायचे आहे का',
      'no': 'नाही',
      'yes': 'होय',
      'newOrder': '📦 नवीन ऑर्डर',
      'edit': '✏ एडिट',
      'measurement': '📏 मोजमाप',
      'delete': '🗑 हटवा',
      'customerProfile': 'ग्राहक प्रोफाइल',
      'orderHistory': 'ऑर्डर इतिहास',
      'masterMeasurement': 'मोजमाप (Measurement)',
      'paymentHistory': 'पेमेंट इतिहास',
      'deleteCustomer': 'ग्राहक हटवा',
      'totalDue': 'एकूण बाकी',
      'lastOrder': 'शेवटचा ऑर्डर',
      'customerSince': 'ग्राहक तेव्हापासून',
      'pendingOrders': 'लंबित ऑर्डर्स',
      'completedOrders': 'पूर्ण ऑर्डर्स',
      'pending': 'प्रलंबित',
      'delivered': 'डिलिव्हर्ड',
      'completed': 'पूर्ण',
    },
  };

  String _t(String key) {
    return _localizedValues[_currentLanguage]?[key] ?? _localizedValues['English']![key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF18181B) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    Color textColor = widget.isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
    Color subTextColor = widget.isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    const Color primaryThemeColor = Color(0xFF7C3AED);

    List<Map<String, dynamic>> filteredList = _customers.where((cust) {
      String name = cust['name']?.toString().toLowerCase() ?? '';
      String phone = (cust['mobile'] ?? cust['phone'])?.toString() ?? '';
      bool matchesName = name.contains(_searchQuery);
      bool matchesPhone = phone.contains(_searchQuery);
      return matchesName || matchesPhone;
    }).toList();

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: primaryThemeColor,
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              _t('title'), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _t('searchHint'),
                  hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: primaryThemeColor, size: 20),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryThemeColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: primaryThemeColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(_t('allCustomers'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryThemeColor))
                    : filteredList.isEmpty
                        ? Center(child: Text(_t('noCustomers'), style: TextStyle(color: subTextColor)))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final customer = filteredList[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerProfileScreen(
                                          customer: customer,
                                          isDarkMode: widget.isDarkMode,
                                          translations: _localizedValues[_currentLanguage]!,
                                          userEmail: widget.userEmail,
                                        ),
                                      ),
                                    ).then((_) => _loadCustomers());
                                  },
                                  child: _buildCustomerCard(customer, surfaceColor, borderColor, textColor, subTextColor, primaryThemeColor),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, Color surfaceColor, Color borderColor, Color textColor, Color subTextColor, Color primaryThemeColor) {
    String custName = customer['name'] ?? 'Unknown';
    String? photoPath = customer['photo'] ?? customer['imageUrl'] ?? customer['image'] ?? customer['photoUrl'];
    String customerId = customer['customer_id'] ?? customer['id'] ?? '';
    
    var ordersList = customer['orders'] ?? customer['orderHistory'] ?? [];
    int orderCount = ordersList is Map ? (ordersList as Map).length : (ordersList as List).length;
    
    String mobile = customer['mobile'] ?? customer['phone'] ?? '';

    // ⚡ Base64 Image Handling & Caching Provider Logic (Updated for Raw Base64)
    ImageProvider? imageProvider;
    if (photoPath != null && photoPath.toString().isNotEmpty) {
      try {
        if (photoPath.toString().startsWith('http')) {
          imageProvider = NetworkImage(photoPath.toString());
        } else {
          if (_imageCache.containsKey(customerId)) {
            imageProvider = MemoryImage(_imageCache[customerId]!);
          } else {
            // Check if it has a data:image prefix or is raw base64
            String cleanBase64 = photoPath.toString();
            if (cleanBase64.contains(',')) {
              cleanBase64 = cleanBase64.split(',').last;
            }
            
            final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
            _imageCache[customerId] = bytes;
            imageProvider = MemoryImage(bytes);
          }
        }
      } catch (e) {
        debugPrint("Error decoding customer image: $e");
        // Fallback to file if it's a local file path
        if (File(photoPath.toString()).existsSync()) {
          imageProvider = FileImage(File(photoPath.toString()));
        }
      }
    }

    return Container(
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: primaryThemeColor.withOpacity(0.15),
              backgroundImage: imageProvider,
              child: (imageProvider == null)
                  ? Text(
                      custName.isNotEmpty ? custName[0].toUpperCase() : 'C',
                      style: TextStyle(color: primaryThemeColor, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    custName, 
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 13, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(mobile.isNotEmpty ? mobile : 'No phone', style: TextStyle(color: subTextColor, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('📦 ${_t('orders')} : $orderCount', style: TextStyle(color: subTextColor, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (customerId.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryThemeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    customerId, 
                    style: TextStyle(color: primaryThemeColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subTextColor),
          ],
        ),
      ),
    );
  }
}