import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../database.dart';
import 'steps/step1_customer_details.dart';
import 'steps/step2_order_details.dart';
import 'steps/step3_measurement_details.dart';
import 'steps/step4_payment_details.dart';
import 'steps/step5_review_summary.dart';

class AddCustomerScreen extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String userEmail;
  final Map<String, dynamic>? prefilledCustomer; 
  final int startAtStep; 

  const AddCustomerScreen({
    super.key, 
    this.initialLanguage = 'English', 
    required this.isDarkMode,
    required this.userEmail,
    this.prefilledCustomer,
    this.startAtStep = 1,
  });

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  late final PageController _pageController;
  late int _currentStep;
  final int _totalSteps = 5;
  
  int currentOrderSeq = 1; 
  String get formattedOrderId => "ORD${currentOrderSeq.toString().padLeft(4, '0')}";

  // Step 1 Controllers
  final TextEditingController customerIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController altMobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  String selectedGender = 'Male';
  String customerType = 'Regular';
  File? _customerImage;

  // Step 2 Controllers & State
  final TextEditingController itemTypeController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController orderDateController = TextEditingController();
  final TextEditingController trialDateController = TextEditingController();
  final TextEditingController deliveryDateController = TextEditingController();
  final TextEditingController orderNotesController = TextEditingController();
  final TextEditingController collarSleeveDetailsController = TextEditingController();

  String clothSource = 'Customer Cloth';
  String clothDetail = 'Cotton';
  String designStyle = 'Regular Fit';
  String priority = 'Normal';

  // Step 3 Dynamic & Notes Controllers
  final TextEditingController measurementNotesController = TextEditingController();
  final Map<String, TextEditingController> measurementControllers = {};

  // Step 4 Enhanced Payment Controllers & State
  final Map<String, TextEditingController> itemPriceControllers = {};
  final TextEditingController discountAmountController = TextEditingController();
  final TextEditingController discountPercentController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController(); 
  final TextEditingController advanceAmountController = TextEditingController();
  final TextEditingController paymentNotesController = TextEditingController();
  String paymentMethod = 'Cash';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("DEBUG: AddCustomerScreen initState called.");

    _currentStep = widget.startAtStep - 1; 
    _pageController = PageController(initialPage: _currentStep);

    if (widget.prefilledCustomer != null) {
      final cust = widget.prefilledCustomer!;
      customerIdController.text = cust['customer_id']?.toString() ?? cust['id']?.toString() ?? '';
      nameController.text = cust['name']?.toString() ?? '';
      mobileController.text = cust['mobile']?.toString() ?? '';
      altMobileController.text = cust['alt_mobile']?.toString() ?? '';
      addressController.text = cust['address']?.toString() ?? '';
      cityController.text = cust['city']?.toString() ?? '';
      selectedGender = cust['gender']?.toString() ?? 'Male';
      dobController.text = cust['dob']?.toString() ?? '';
      customerType = cust['customer_type']?.toString() ?? 'Regular';
      notesController.text = cust['notes']?.toString() ?? '';
      
      if (cust['photo'] != null && cust['photo'].toString().isNotEmpty) {
        _customerImage = File(cust['photo'].toString());
      }

      if (customerIdController.text.isNotEmpty) {
        _fetchAndGenerateNextOrderId(customerIdController.text.trim());
        _loadExistingMeasurements(customerIdController.text.trim());
      }
    } else {
      _generateCustomerId();
    }
  }

  Future<void> _fetchAndGenerateNextOrderId(String customerId) async {
    try {
      int nextSeq = await DatabaseService.getNextOrderSequenceForCustomer(
        userEmail: widget.userEmail, 
        customerId: customerId,
      );
      setState(() {
        currentOrderSeq = nextSeq;
      });
    } catch (e) {
      print("DEBUG error fetching next order sequence: $e");
    }
  }

  Future<void> _loadExistingMeasurements(String customerId) async {
    try {
      Map<String, String> savedMeasurements = await DatabaseService.fetchCustomerMasterMeasurements(
        userEmail: widget.userEmail, 
        customerId: customerId,
      );

      if (savedMeasurements.isNotEmpty) {
        setState(() {
          savedMeasurements.forEach((key, value) {
            if (key == 'notes') {
              measurementNotesController.text = value;
            } else {
              if (!measurementControllers.containsKey(key)) {
                measurementControllers[key] = TextEditingController();
              }
              measurementControllers[key]?.text = value;
            }
          });
        });
      }
    } catch (e) {
      print("Error loading measurements into controllers: $e");
    }
  }

  @override
  void dispose() {
    print("DEBUG: AddCustomerScreen dispose called. Cleaning up controllers...");
    _pageController.dispose();
    customerIdController.dispose();
    nameController.dispose();
    mobileController.dispose();
    altMobileController.dispose();
    addressController.dispose();
    cityController.dispose();
    dobController.dispose();
    notesController.dispose();
    itemTypeController.dispose();
    quantityController.dispose();
    orderDateController.dispose();
    trialDateController.dispose();
    deliveryDateController.dispose();
    orderNotesController.dispose();
    collarSleeveDetailsController.dispose();
    measurementNotesController.dispose();
    
    measurementControllers.forEach((key, controller) {
      try {
        controller.dispose();
      } catch (e) {
        print("DEBUG error disposing $key: $e");
      }
    });
    measurementControllers.clear();

    itemPriceControllers.forEach((key, controller) {
      try {
        controller.dispose();
      } catch (e) {
        print("DEBUG error disposing item price $key: $e");
      }
    });
    itemPriceControllers.clear();

    discountAmountController.dispose();
    discountPercentController.dispose();
    totalAmountController.dispose();
    advanceAmountController.dispose();
    paymentNotesController.dispose();
    super.dispose();
  }

  void _generateCustomerId() {
    int randomId = Random().nextInt(9000) + 1000;
    setState(() {
      customerIdController.text = randomId.toString();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() {
        _customerImage = File(image.path);
      });
    }
  }

  List<Map<String, dynamic>> _getOrderedItemsList() {
    String itemsText = itemTypeController.text.trim();
    String qtyText = quantityController.text.trim();

    Map<String, int> parsedQuantities = {};
    
    if (qtyText.contains(':')) {
      List<String> pairs = qtyText.split(',');
      for (var pair in pairs) {
        List<String> parts = pair.split(':');
        if (parts.length == 2) {
          String name = parts[0].trim();
          int qty = int.tryParse(parts[1].trim()) ?? 1;
          parsedQuantities[name] = qty;
        }
      }
    }

    List<String> rawItems = itemsText.isEmpty ? ['Shirt'] : itemsText.split(',').map((e) => e.trim()).toList();
    List<Map<String, dynamic>> list = [];

    for (var item in rawItems) {
      String trimmed = item.trim();
      if (trimmed.isNotEmpty) {
        int itemQty = parsedQuantities[trimmed] ?? int.tryParse(qtyText) ?? 1;
        list.add({'name': trimmed, 'qty': itemQty});
      }
    }

    return list.isNotEmpty ? list : [{'name': 'Shirt', 'qty': 1}];
  }

  double _calculateGrossTotalForSave() {
    double gross = 0;
    List<Map<String, dynamic>> orderedItems = _getOrderedItemsList();
    for (var item in orderedItems) {
      String itemName = item['name'] ?? '';
      int qty = item['qty'] ?? 1;
      double price = double.tryParse(itemPriceControllers[itemName]?.text ?? '0') ?? 0.0;
      gross += price * qty;
    }
    return gross;
  }

  // Multi-language Text Definitions
  String getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'title': 'New Order & Customer Wizard',
        'step1Title': 'Customer Details',
        'step2Title': 'Order Details',
        'step3Title': 'Measurements',
        'step4Title': 'Payment',
        'step5Title': 'Review & Save',
        'save': 'Save Order & Customer',
        'next': 'Next',
        'back': 'Back',
        'successMsg': 'Customer & Order Saved Successfully!',
        'validationName': 'Please enter full name',
        'validationMobile': 'Please enter a valid 10-digit mobile number',
        'validationAddress': 'Please enter address and city',
        'validationItem': 'Please select at least one garment type and delivery date',
        'validationPayment': 'Please enter item prices / total amount',
        // Dialog translations
        'confirmTitle': 'Confirm Save',
        'confirmMsg': 'Do you want to save this order and customer details?',
        'cancelBtn': 'Cancel',
        'yesSaveBtn': 'Yes, Save',
      },
      'Hindi': {
        'title': 'नया ग्राहक और ऑर्डर विजार्ड',
        'step1Title': 'ग्राहक विवरण',
        'step2Title': 'ऑर्डर विवरण',
        'step3Title': 'माप (Measurements)',
        'step4Title': 'भुगतान (Payment)',
        'step5Title': 'समीक्षा और सहेजें',
        'save': 'ऑर्डर सहेजें',
        'next': 'आगे',
        'back': 'पीछे',
        'successMsg': 'ग्राहक और ऑर्डर सफलतापूर्वक सहेजे गए!',
        'validationName': 'कृपया पूरा नाम दर्ज करें',
        'validationMobile': 'कृपया वैध 10-अंकों का मोबाइल नंबर दर्ज करें',
        'validationAddress': 'कृपया पता और शहर दर्ज करें',
        'validationItem': 'कृपया कम से कम एक गार्मेंट और डिलीवरी तारीख चुनें',
        'validationPayment': 'कृपया गार्मेंट की कीमत / कुल राशि दर्ज करें',
        // Dialog translations
        'confirmTitle': 'पुष्टि करें (Confirm)',
        'confirmMsg': 'क्या आप इस ऑर्डर और ग्राहक विवरण को सहेजना चाहते हैं?',
        'cancelBtn': 'रद्द करें',
        'yesSaveBtn': 'हाँ, सहेजें',
      },
      'Marathi': {
        'title': 'नवीन ग्राहक आणि ऑर्डर विजार्ड',
        'step1Title': 'ग्राहक तपशील',
        'step2Title': 'ऑर्डर तपशील',
        'step3Title': 'माप (Measurements)',
        'step4Title': 'पेमेंट (Payment)',
        'step5Title': 'पुनरावलोकन आणि जतन',
        'save': 'ऑर्डर जतन करा',
        'next': 'पुढे',
        'back': 'मागे',
        'successMsg': 'ग्राहक आणि ऑर्डर यशस्वीरित्या जतन केले!',
        'validationName': 'कृपया पूर्ण नाव प्रविष्ट करा',
        'validationMobile': 'कृपया वैध 10-अंकी मोबाईल नंबर प्रविष्ट करा',
        'validationAddress': 'कृपया पत्ता आणि शहर प्रविष्ट करा',
        'validationItem': 'कृपया किमान एक कपड्याचा प्रकार आणि डिलिव्हरी तारीख निवडा',
        'validationPayment': 'कृपया कपड्यांची किंमत / एकूण रक्कम प्रविष्ट करा',
        // Dialog translations
        'confirmTitle': 'जतन करण्याची पुष्टी करा',
        'confirmMsg': 'तुम्हाला हा ऑर्डर आणि ग्राहक तपशील जतन करायचा आहे का?',
        'cancelBtn': 'रद्द करा',
        'yesSaveBtn': 'होय, जतन करा',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? key;
  }

  // Confirmation Dialog Function with Multi-Language Support
  void _showConfirmSaveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(getText('confirmTitle'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(getText('confirmMsg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getText('cancelBtn'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // Dialog close hoga
                _saveCustomerAndOrder(); // Actual save function run hoga
              },
              child: Text(getText('yesSaveBtn')),
            ),
          ],
        );
      },
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (nameController.text.trim().isEmpty) {
        _showError(getText('validationName'));
        return;
      }
      if (mobileController.text.trim().length < 10) {
        _showError(getText('validationMobile'));
        return;
      }
      if (addressController.text.trim().isEmpty || cityController.text.trim().isEmpty) {
        _showError(getText('validationAddress'));
        return;
      }
    } else if (_currentStep == 1) {
      if (itemTypeController.text.trim().isEmpty || deliveryDateController.text.trim().isEmpty) {
        _showError(getText('validationItem'));
        return;
      }
    } else if (_currentStep == 3) {
      if (totalAmountController.text.trim().isEmpty) {
        _showError(getText('validationPayment'));
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _saveCustomerAndOrder() async {
    setState(() => _isLoading = true);

    String base64Image = "";
    if (_customerImage != null) {
      try {
        List<int> imageBytes = await _customerImage!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      } catch (e) {
        print("DEBUG Error encoding image to base64: $e");
      }
    }

    Map<String, dynamic> customerData = {
      "customer_id": customerIdController.text.trim(),
      "name": nameController.text.trim(),
      "mobile": mobileController.text.trim(),
      "alt_mobile": altMobileController.text.trim(),
      "address": addressController.text.trim(),
      "city": cityController.text.trim(),
      "gender": selectedGender,
      "dob": dobController.text.trim(),
      "customer_type": customerType,
      "notes": notesController.text.trim(),
      "photo": base64Image,
    };

    List<Map<String, dynamic>> orderedItems = _getOrderedItemsList();

    List<Map<String, dynamic>> structuredGarmentsList = [];
    List<String> formattedItemsList = [];
    double totalQuantityCount = 0;

    for (var item in orderedItems) {
      String trimmedName = item['name'];
      int itemQty = item['qty'];
      totalQuantityCount += itemQty;

      if (trimmedName.contains('(')) {
        trimmedName = trimmedName.split('(')[0].trim();
      }

      double itemRate = double.tryParse(
        itemPriceControllers[trimmedName]?.text ?? '0'
      ) ?? 0.0;

      structuredGarmentsList.add({
        "name": trimmedName,
        "rate": itemRate,
        "qty": itemQty.toDouble(),
      });

      formattedItemsList.add("$trimmedName (Qty: $itemQty, Rate: $itemRate)");
    }

    String finalItemWithRateStr = formattedItemsList.join(', ');

    Map<String, dynamic> orderDetails = {
      "order_id": formattedOrderId,
      "garments": structuredGarmentsList, 
      "quantity": totalQuantityCount,
      "item_with_rate": finalItemWithRateStr,
      "cloth_source": clothSource,
      "cloth_detail": clothDetail,
      "design_style": designStyle,
      "priority": priority,
      "order_date": orderDateController.text.trim(),
      "trial_date": trialDateController.text.trim(),
      "delivery_date": deliveryDateController.text.trim(),
      "notes": orderNotesController.text.trim(),
    };

    Map<String, dynamic> measurementDetails = {};
    measurementControllers.forEach((key, controller) {
      if (controller.text.trim().isNotEmpty) {
        measurementDetails[key] = controller.text.trim();
      }
    });
    
    if (measurementNotesController.text.trim().isNotEmpty) {
      measurementDetails["notes"] = measurementNotesController.text.trim();
    }

    double totalVal = double.tryParse(totalAmountController.text) ?? 0.0;
    double advanceVal = double.tryParse(advanceAmountController.text) ?? 0.0;
    double discountVal = double.tryParse(discountAmountController.text) ?? 0.0;
    double discountPercentVal = double.tryParse(discountPercentController.text) ?? 0.0;
    double grossTotalVal = double.tryParse(_calculateGrossTotalForSave().toString()) ?? 0.0;

    Map<String, dynamic> paymentDetails = {
      "gross_total": grossTotalVal, 
      "total": totalVal,
      "advance": advanceVal,
      "discount_amount": discountVal,
      "discount_percent": discountPercentVal,
      "due": totalVal - advanceVal,
      "payment_method": paymentMethod,
      "notes": paymentNotesController.text.trim(),
    };

    Map<String, dynamic> masterMeasurements = Map.from(measurementDetails);

    Map<String, dynamic> result = await DatabaseService.saveCompleteCustomerOrder(
      userEmail: widget.userEmail,
      customerId: customerIdController.text.trim(),
      orderId: formattedOrderId,
      customerData: customerData,
      orderDetails: orderDetails,
      measurementDetails: measurementDetails,
      paymentDetails: paymentDetails,
      masterMeasurements: masterMeasurements,
      isNewCustomer: widget.prefilledCustomer == null,
    );

    setState(() => _isLoading = false);

    if (result['status'] == true) {
      // --- यहाँ SMS भेजने वाला कोड जोड़ दिया गया है[cite: 2] ---
      String customerMobile = mobileController.text.trim();
      String customerName = nameController.text.trim();
      if (customerMobile.length >= 10) {
        _sendOrderConfirmationSms(customerMobile, customerName, formattedOrderId);
      }
      // ----------------------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getText('successMsg')), backgroundColor: Colors.teal, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _sendOrderConfirmationSms(String mobileNumber, String customerName, String orderId) async {
    // 1. डेटाबेस से दुकान का नाम (Shop Name) फेच करना
    String shopName = "Tailor App"; // डिफ़ॉल्ट नाम
    try {
      Map<String, dynamic>? shopDetails = await DatabaseService.fetchShopInformation(widget.userEmail);
      if (shopDetails != null && shopDetails['shop_name'] != null) {
        shopName = shopDetails['shop_name'].toString();
      }
    } catch (e) {
      print("DEBUG ERROR fetching shop name: $e");
    }

    // 2. फॉर्म के कंट्रोलर्स से वैल्यू लेना
    String customerId = customerIdController.text.trim(); 
    String totalBill = totalAmountController.text.trim();
    String orderDate = orderDateController.text.trim();
    String trialDate = trialDateController.text.trim();
    String deliveryDate = deliveryDateController.text.trim();

    // 3. मराठी में प्रोफेशनल और विस्तृत मैसेज फॉर्मेट (डेटाबेस वाले shopName के साथ)
    String message = "🙏 नमस्कार $customerName,\n\n"
        "✂️ *आपली ऑर्डर यशस्वीरित्या नोंदविण्यात आली आहे.*\n\n"
        "👤 ग्राहक क्रमांक : $customerId\n"
        "🆔 ऑर्डर क्रमांक : $orderId\n"
        "📅 ऑर्डर दिनांक : $orderDate\n"
        "👔 ट्रायल दिनांक : $trialDate\n"
        "🚚 डिलिव्हरी दिनांक : $deliveryDate\n"
        "💰 एकूण बिल : ₹$totalBill\n\n"
        "📌 कृपया आपला ऑर्डर क्रमांक जतन करून ठेवा.\n\n"
        "आपल्या विश्वासाबद्दल मनःपूर्वक धन्यवाद! 🙏\n"
        "आपली सेवा करण्यास आम्हाला आनंद होत आहे.\n\n"
        "— *$shopName*";
    
    // SMS यूआरआई (URI) तैयार करना
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: mobileNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      print("DEBUG: Launching SMS app for $mobileNumber");
      
      // URL Launcher का उपयोग करके SMS ऐप खोलना
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        print("DEBUG: SMS app launched successfully");
      } else {
        print("DEBUG ERROR: Could not launch SMS app");
      }
    } catch (e, stackTrace) {
      print("DEBUG ERROR: Exception while launching SMS: $e");
      print("DEBUG ERROR StackTrace: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    Color scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color primaryColor = Color(0xFF2563EB); 

    List<String> stepTitles = [
      getText('step1Title'),
      getText('step2Title'),
      getText('step3Title'),
      getText('step4Title'),
      getText('step5Title'),
    ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Text(getText('title'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              color: surfaceColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_totalSteps, (index) {
                      bool isActive = index <= _currentStep;
                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? primaryColor : borderColor),
                              child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            ),
                            if (index < _totalSteps - 1)
                              Expanded(child: Container(height: 2, color: index < _currentStep ? primaryColor : borderColor)),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Step ${_currentStep + 1} of ${_totalSteps}: ${stepTitles[_currentStep]}", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Step1CustomerDetails(
                          initialLanguage: widget.initialLanguage,
                          isDarkMode: isDark,
                          selectedImage: _customerImage,
                          customerIdController: customerIdController,
                          nameController: nameController,
                          mobileController: mobileController,
                          altMobileController: altMobileController,
                          addressController: addressController,
                          cityController: cityController,
                          dobController: dobController,
                          notesController: notesController,
                          selectedGender: selectedGender,
                          onGenderChanged: (val) => setState(() => selectedGender = val!),
                          customerType: customerType,
                          onCustomerTypeChanged: (val) => setState(() => customerType = val!),
                          onRefreshId: _generateCustomerId,
                          onPickDate: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(1995, 1, 1),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                dobController.text = "${picked.day}/${picked.month}/${picked.year}";
                              });
                            }
                          },
                          onCameraTap: () => _pickImage(ImageSource.camera),
                          onGalleryTap: () => _pickImage(ImageSource.gallery),
                        ),
                        Step2OrderDetails(
                          initialLanguage: widget.initialLanguage,
                          isDarkMode: isDark,
                          orderId: formattedOrderId,
                          itemTypeController: itemTypeController,
                          quantityController: quantityController,
                          orderDateController: orderDateController,
                          trialDateController: trialDateController,
                          deliveryDateController: deliveryDateController,
                          orderNotesController: orderNotesController,
                          clothSource: clothSource,
                          onClothSourceChanged: (val) => setState(() => clothSource = val),
                          clothDetail: clothDetail,
                          onClothDetailChanged: (val) => setState(() => clothDetail = val),
                          designStyle: designStyle,
                          onDesignStyleChanged: (val) => setState(() => designStyle = val),
                          priority: priority,
                          onPriorityChanged: (val) => setState(() => priority = val),
                        ),
                        
                        Step3MeasurementDetails(
                          initialLanguage: widget.initialLanguage,
                          isDarkMode: isDark,
                          selectedGarments: itemTypeController.text,
                          onGarmentsChanged: (updatedGarments) {
                            setState(() {
                              itemTypeController.text = updatedGarments;
                            });
                          },
                          measurementNotesController: measurementNotesController,
                          measurementControllers: measurementControllers,
                        ),
                        Step4PaymentDetails(
                          initialLanguage: widget.initialLanguage,
                          isDarkMode: isDark,
                          customerName: nameController.text.trim().isEmpty ? 'Rahul Patil' : nameController.text,
                          mobile: mobileController.text.trim().isEmpty ? '9876543210' : mobileController.text,
                          customerId: customerIdController.text.trim().isEmpty ? '001' : customerIdController.text,
                          orderNo: formattedOrderId,
                          orderedItems: _getOrderedItemsList(),
                          itemPriceControllers: itemPriceControllers,
                          discountAmountController: discountAmountController,
                          discountPercentController: discountPercentController,
                          totalAmountController: totalAmountController,
                          advanceAmountController: advanceAmountController,
                          paymentNotesController: paymentNotesController,
                          selectedPaymentMethod: paymentMethod,
                          onPaymentMethodChanged: (val) => setState(() => paymentMethod = val),
                        ),
                        Step5ReviewSummary(
                          initialLanguage: widget.initialLanguage,
                          isDarkMode: widget.isDarkMode,
                          customerId: customerIdController.text,
                          orderId: formattedOrderId,
                          fullName: nameController.text,
                          mobile: mobileController.text,
                          altMobile: altMobileController.text,
                          address: addressController.text,
                          city: cityController.text,
                          gender: selectedGender,
                          dob: dobController.text,
                          customerType: customerType,
                          customerNotes: notesController.text,
                          customerImagePath: _customerImage?.path, 

                          itemType: itemTypeController.text,
                          quantity: quantityController.text,
                          orderDate: orderDateController.text,
                          trialDate: trialDateController.text,
                          deliveryDate: deliveryDateController.text,
                          clothSource: clothSource,
                          clothDetail: clothDetail,
                          designStyle: designStyle,
                          priority: priority,
                          orderNotes: orderNotesController.text,

                          measurementControllers: measurementControllers, 
                          measurementNotes: measurementNotesController.text,

                          totalAmount: totalAmountController.text,
                          advanceAmount: advanceAmountController.text,
                          discountAmount: discountAmountController.text, 
                          discountPercent: discountPercentController.text, 
                          paymentMethod: paymentMethod,
                          paymentNotes: paymentNotesController.text,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: surfaceColor,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _prevStep,
                        child: Text(getText('back'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryColor, Color(0xFF06B6D4)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _currentStep == _totalSteps - 1 
                            ? (_isLoading ? null : _showConfirmSaveDialog) 
                            : _nextStep,
                        child: _isLoading 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_currentStep == _totalSteps - 1 ? getText('save') : getText('next'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}