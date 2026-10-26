import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Step5ReviewSummary extends StatelessWidget {
  final String initialLanguage;
  final bool isDarkMode;
  
  // Order ID
  final String orderId;

  // Customer Details
  final String customerId;
  final String fullName;
  final String mobile;
  final String altMobile;
  final String address;
  final String city;
  final String gender;
  final String dob; 
  final String customerType;
  final String customerNotes;
  final String? customerImagePath; // Can be URL, File path, or Base64 string

  // Order Details
  final String itemType;
  final String quantity;
  final String orderDate;
  final String trialDate;
  final String deliveryDate;
  final String clothSource;
  final String clothDetail;
  final String designStyle;
  final String priority;
  final String orderNotes;

  // Measurement Details
  final Map<String, TextEditingController> measurementControllers;
  final String measurementNotes;

  // Payment Details
  final String totalAmount;
  final String advanceAmount;
  final String discountAmount; 
  final String discountPercent; 
  final String paymentMethod;
  final String paymentNotes;

  const Step5ReviewSummary({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.orderId,
    required this.customerId,
    required this.fullName,
    required this.mobile,
    required this.altMobile,
    required this.address,
    required this.city,
    required this.gender,
    required this.dob, 
    required this.customerType,
    required this.customerNotes,
    this.customerImagePath, 
    required this.itemType,
    required this.quantity,
    required this.orderDate,
    required this.trialDate,
    required this.deliveryDate,
    required this.clothSource,
    required this.clothDetail,
    required this.designStyle,
    required this.priority,
    required this.orderNotes,
    required this.measurementControllers,
    required this.measurementNotes,
    required this.totalAmount,
    required this.advanceAmount,
    required this.discountAmount, 
    required this.discountPercent, 
    required this.paymentMethod,
    required this.paymentNotes,
  });

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'step5Title': 'Complete Order Review & Summary',
        'orderId': 'Order ID',
        'customerId': 'Customer ID',
        'fullName': 'Full Name',
        'mobile': 'Mobile Number',
        'altMobile': 'Alt Mobile',
        'address': 'Address',
        'gender': 'Gender',
        'dob': 'Date of Birth',
        'customerType': 'Customer Type',
        'customerNotes': 'Customer Notes',
        'itemType': 'Item Type',
        'quantity': 'Quantity',
        'orderDate': 'Order Date',
        'trialDate': 'Trial Date',
        'deliveryDate': 'Delivery Date',
        'clothSource': 'Cloth Source',
        'clothDetail': 'Cloth Detail',
        'designStyle': 'Design / Style',
        'priority': 'Priority',
        'orderNotes': 'Order Notes',
        'measurementNotes': 'Measurement Notes',
        'grossTotal': 'Gross Total',
        'discount': 'Discount',
        'netTotal': 'Grand Total',
        'advanceAmount': 'Advance Paid',
        'balanceAmount': 'Balance Due',
        'paymentMethod': 'Payment Method',
        'paymentNotes': 'Payment Notes',
        'revCustomerHeader': '1. Customer Information',
        'revOrderHeader': '2. Order Information',
        'revMeasureHeader': '3. Measurement Details',
        'revPaymentHeader': '4. Payment Information',
        
        // Labels
        'lengthLabel': 'Length',
        'chestLabel': 'Chest',
        'stomachLabel': 'Stomach',
        'shoulderLabel': 'Shoulder',
        'sleeveLabel': 'Sleeve',
        'collarLabel': 'Collar',
        'cuffLabel': 'Cuff',
        'frontLabel': 'Front',
        'pantLengthLabel': 'Pant Length',
        'waistLabel': 'Waist',
        'seatLabel': 'Seat',
        'thighLabel': 'Thigh',
        'kneeLabel': 'Knee',
        'bottomLabel': 'Bottom',
        'kurtaLengthLabel': 'Kurta Length',
        'damanLabel': 'Daman',
        'armholeLabel': 'Armhole',
        'blazerLengthLabel': 'Blazer Length',
        'bicepsLabel': 'Biceps',
        'backLengthLabel': 'Back Length',
        'coatLengthLabel': 'Coat Length',
        'sherwaniLengthLabel': 'Sherwani Length',
        'hipLabel': 'Hip',
        'upperChestLabel': 'Upper Chest',
        'suitLengthLabel': 'Suit Length',
        'frontNeckLabel': 'Front Neck',
        'backNeckLabel': 'Back Neck',
        'blouseLengthLabel': 'Blouse Length',
        'apexPointLabel': 'Apex Point',
        'riseLabel': 'Rise',
      },
      'Hindi': {
        'step5Title': 'पूर्ण ऑर्डर समीक्षा और सारांश',
        'orderId': 'ऑर्डर आईडी',
        'customerId': 'ग्राहक आईडी',
        'fullName': 'पूरा नाम',
        'mobile': 'मोबाइल नंबर',
        'altMobile': 'वैकल्पिक मोबाइल',
        'address': 'पता',
        'gender': 'लिंग',
        'dob': 'जन्मतिथि',
        'customerType': 'ग्राहक का प्रकार',
        'customerNotes': 'ग्राहक नोट्स',
        'itemType': 'आइटम का प्रकार',
        'quantity': 'मात्रा (Quantity)',
        'orderDate': 'ऑर्डर की तारीख',
        'trialDate': 'ट्रायल तारीख',
        'deliveryDate': 'डिलीवरी तारीख',
        'clothSource': 'कपड़े का स्रोत',
        'clothDetail': 'कपड़े का विवरण',
        'designStyle': 'डिज़ाइन / स्टाइल',
        'priority': 'प्राथमिकता',
        'orderNotes': 'ऑर्डर नोट्स',
        'measurementNotes': 'माप नोट्स',
        'grossTotal': 'कुल योग (Gross Total)',
        'discount': 'छूट (Discount)',
        'netTotal': 'अंतिम कुल राशि (Grand Total)',
        'advanceAmount': 'एडवांस भुगतान',
        'balanceAmount': 'शेष राशि (Balance)',
        'paymentMethod': 'भुगतान का तरीका',
        'paymentNotes': 'भुगतान नोट्स',
        'revCustomerHeader': '1. ग्राहक की जानकारी',
        'revOrderHeader': '2. ऑर्डर की जानकारी',
        'revMeasureHeader': '3. माप विवरण',
        'revPaymentHeader': '4. भुगतान विवरण',

        // Labels Hindi
        'lengthLabel': 'लंबाई',
        'chestLabel': 'छाती',
        'stomachLabel': 'पेट',
        'shoulderLabel': 'शोल्डर',
        'sleeveLabel': 'बाजू',
        'collarLabel': 'कॉलर',
        'cuffLabel': 'कफ',
        'frontLabel': 'सामने (Front)',
        'pantLengthLabel': 'पैंट की लंबाई',
        'waistLabel': 'कंबर (Waist)',
        'seatLabel': 'सीट',
        'thighLabel': 'थाई',
        'kneeLabel': 'घुटना',
        'bottomLabel': 'बॉटम',
        'kurtaLengthLabel': 'कुर्ता लंबाई',
        'damanLabel': 'दामन',
        'armholeLabel': 'आर्महोल',
        'blazerLengthLabel': 'ब्लेज़र लंबाई',
        'bicepsLabel': 'बाइसेप्स',
        'backLengthLabel': 'बैक लंबाई',
        'coatLengthLabel': 'कोट लंबाई',
        'sherwaniLengthLabel': 'शेरवानी लंबाई',
        'hipLabel': 'हिप',
        'upperChestLabel': 'ऊपरी छाती',
        'suitLengthLabel': 'सूट लंबाई',
        'frontNeckLabel': 'आगे का गला',
        'backNeckLabel': 'पीछे का गला',
        'blouseLengthLabel': 'ब्लाउज लंबाई',
        'apexPointLabel': 'एपिक्स पॉइंट',
        'riseLabel': 'राइज',
      },
      'Marathi': {
        'step5Title': 'पूर्ण ऑर्डर पुनरावलोकन आणि सारांश',
        'orderId': 'ऑर्डर आयडी',
        'customerId': 'ग्राहक आयडी',
        'fullName': 'पूर्ण नाव',
        'mobile': 'मोबाईल नंबर',
        'altMobile': 'पर्यायी मोबाईल',
        'address': 'पत्ता',
        'gender': 'लिंग',
        'dob': 'जन्मतारीख',
        'customerType': 'ग्राहक प्रकार',
        'customerNotes': 'ग्राहक नोट्स',
        'itemType': 'वस्तूचा प्रकार',
        'quantity': 'नगसंख्या (Quantity)',
        'orderDate': 'ऑर्डर तारीख',
        'trialDate': 'ट्रायल तारीख',
        'deliveryDate': 'डिलिव्हरी तारीख',
        'clothSource': 'कापड स्रोत',
        'clothDetail': 'कापड तपशील',
        'designStyle': 'डिझाइन / स्टाइल',
        'priority': 'प्राधान्य',
        'orderNotes': 'ऑर्डर नोट्स',
        'measurementNotes': 'माप नोट्स',
        'grossTotal': 'एकूण ग्रॉस टोटल (Gross Total)',
        'discount': 'सूट (Discount)',
        'netTotal': 'अंतिम एकूण रक्कम (Grand Total)',
        'advanceAmount': 'एडवान्स रक्कम',
        'balanceAmount': 'बाकी रक्कम',
        'paymentMethod': 'पेमेंट पद्धत',
        'paymentNotes': 'पेमेंट नोट्स',
        'revCustomerHeader': '1. ग्राहक माहिती',
        'revOrderHeader': '2. ऑर्डर माहिती',
        'revMeasureHeader': '3. मापे तपशील',
        'revPaymentHeader': '4. पेमेंट माहिती',

        // Labels Marathi
        'lengthLabel': 'लांबी',
        'chestLabel': 'छाती',
        'stomachLabel': 'पोट',
        'shoulderLabel': 'खांदा',
        'sleeveLabel': 'बाहु',
        'collarLabel': 'कॉलर',
        'cuffLabel': 'कफ',
        'frontLabel': 'पुढचा भाग',
        'pantLengthLabel': 'पँटची लांबी',
        'waistLabel': 'कंबर',
        'seatLabel': 'सीट',
        'thighLabel': 'थाई',
        'kneeLabel': 'गुंडा',
        'bottomLabel': 'बॉटम',
        'kurtaLengthLabel': 'कुर्ता लांबी',
        'damanLabel': 'दामन',
        'armholeLabel': 'आर्महोल',
        'blazerLengthLabel': 'ब्लेझर लांबी',
        'bicepsLabel': 'बायसेप्स',
        'backLengthLabel': 'मागील लांबी',
        'coatLengthLabel': 'कोट लांबी',
        'sherwaniLengthLabel': 'शेरवानी लांबी',
        'hipLabel': 'हिप',
        'upperChestLabel': 'वरची छाती',
        'suitLengthLabel': 'सूट लांबी',
        'frontNeckLabel': 'पुढचा गळा',
        'backNeckLabel': 'मागचा गळा',
        'blouseLengthLabel': 'ब्लाउज लांबी',
        'apexPointLabel': 'एपिक्स पॉईंट',
        'riseLabel': 'राईज',
      }
    };
    return translations[initialLanguage]?[key] ?? translations['English']?[key] ?? key;
  }

  Map<String, List<Map<String, String>>> _getGarmentFieldConfigs() {
    return {
      'Shirt': [
        {'key': 'length', 'label': _getText('lengthLabel')},
        {'key': 'chest', 'label': _getText('chestLabel')},
        {'key': 'stomach', 'label': _getText('stomachLabel')},
        {'key': 'shoulder', 'label': _getText('shoulderLabel')},
        {'key': 'sleeve', 'label': _getText('sleeveLabel')},
        {'key': 'collar', 'label': _getText('collarLabel')},
        {'key': 'cuff', 'label': _getText('cuffLabel')},
        {'key': 'front', 'label': _getText('frontLabel')},
      ],
      'Pant': [
        {'key': 'length', 'label': _getText('pantLengthLabel')},
        {'key': 'waist', 'label': _getText('waistLabel')},
        {'key': 'seat', 'label': _getText('seatLabel')},
        {'key': 'thigh', 'label': _getText('thighLabel')},
        {'key': 'knee', 'label': _getText('kneeLabel')},
        {'key': 'bottom', 'label': _getText('bottomLabel')},
      ],
      'Kurta': [
        {'key': 'chest', 'label': _getText('chestLabel')},
        {'key': 'length', 'label': _getText('kurtaLengthLabel')},
        {'key': 'shoulder', 'label': _getText('shoulderLabel')},
        {'key': 'sleeve', 'label': _getText('sleeveLabel')},
        {'key': 'collar', 'label': _getText('collarLabel')},
        {'key': 'daman', 'label': _getText('damanLabel')},
        {'key': 'waist', 'label': _getText('waistLabel')},
        {'key': 'armhole', 'label': _getText('armholeLabel')},
      ],
      'Blazer': [
        {'key': 'chest', 'label': _getText('chestLabel')},
        {'key': 'length', 'label': _getText('blazerLengthLabel')},
        {'key': 'shoulder', 'label': _getText('shoulderLabel')},
        {'key': 'sleeve', 'label': _getText('sleeveLabel')},
        {'key': 'stomach', 'label': _getText('stomachLabel')},
        {'key': 'collar', 'label': _getText('collarLabel')},
        {'key': 'biceps', 'label': _getText('bicepsLabel')},
        {'key': 'backLength', 'label': _getText('backLengthLabel')},
      ],
      'Coat': [
        {'key': 'chest', 'label': _getText('chestLabel')},
        {'key': 'length', 'label': _getText('coatLengthLabel')},
        {'key': 'shoulder', 'label': _getText('shoulderLabel')},
        {'key': 'sleeve', 'label': _getText('sleeveLabel')},
        {'key': 'stomach', 'label': _getText('stomachLabel')},
        {'key': 'collar', 'label': _getText('collarLabel')},
        {'key': 'biceps', 'label': _getText('bicepsLabel')},
      ],
      'Sherwani': [
        {'key': 'chest', 'label': _getText('chestLabel')},
        {'key': 'length', 'label': _getText('sherwaniLengthLabel')},
        {'key': 'shoulder', 'label': _getText('shoulderLabel')},
        {'key': 'sleeve', 'label': _getText('sleeveLabel')},
        {'key': 'collar', 'label': _getText('collarLabel')},
        {'key': 'waist', 'label': _getText('waistLabel')},
        {'key': 'hip', 'label': _getText('hipLabel')},
        {'key': 'daman', 'label': _getText('damanLabel')},
      ],
      'Ladies Suit': [
        {'key': 'chest', 'label': _getText('chestLabel')},
        {'key': 'upperChest', 'label': _getText('upperChestLabel')},
        {'key': 'waist', 'label': _getText('waistLabel')},
        {'key': 'hip', 'label': _getText('hipLabel')},
        {'key': 'length', 'label': _getText('suitLengthLabel')},
        {'key': 'shoulder', 'label': _getText('shoulderLabel')},
        {'key': 'sleeve', 'label': _getText('sleeveLabel')},
        {'key': 'frontNeck', 'label': _getText('frontNeckLabel')},
        {'key': 'backNeck', 'label': _getText('backNeckLabel')},
        {'key': 'daman', 'label': _getText('damanLabel')},
      ],
      'Blouse': [
        {'key': 'chest', 'label': _getText('chestLabel')},
        {'key': 'upperChest', 'label': _getText('upperChestLabel')},
        {'key': 'waist', 'label': _getText('waistLabel')},
        {'key': 'length', 'label': _getText('blouseLengthLabel')},
        {'key': 'shoulder', 'label': _getText('shoulderLabel')},
        {'key': 'sleeve', 'label': _getText('sleeveLabel')},
        {'key': 'frontNeck', 'label': _getText('frontNeckLabel')},
        {'key': 'backNeck', 'label': _getText('backNeckLabel')},
        {'key': 'apexPoint', 'label': _getText('apexPointLabel')},
      ],
      'Jeans Alteration': [
        {'key': 'waist', 'label': _getText('waistLabel')},
        {'key': 'length', 'label': _getText('pantLengthLabel')},
        {'key': 'bottom', 'label': _getText('bottomLabel')},
        {'key': 'thigh', 'label': _getText('thighLabel')},
        {'key': 'rise', 'label': _getText('riseLabel')},
      ],
    };
  }

  // Helper function to safely render the customer image whether it's Network URL, File, or Base64 String
  Widget _buildCustomerImage(Color primaryColor) {
    if (customerImagePath == null || customerImagePath!.isEmpty) {
      return const SizedBox.shrink();
    }

    ImageProvider? imageProvider;

    try {
      if (customerImagePath!.startsWith('http')) {
        imageProvider = NetworkImage(customerImagePath!);
      } else if (customerImagePath!.startsWith('data:image') || !File(customerImagePath!).existsSync()) {
        // Handle Base64 string / Data URL
        String base64String = customerImagePath!;
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        Uint8List decodedBytes = base64Decode(base64String);
        return Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: MemoryImage(decodedBytes),
          ),
        );
      } else {
        // Handle local file path
        imageProvider = FileImage(File(customerImagePath!));
      }
    } catch (e) {
      debugPrint("Error loading review image: $e");
      return const SizedBox.shrink();
    }

    return Center(
      child: CircleAvatar(
        radius: 40,
        backgroundColor: primaryColor.withOpacity(0.1),
        backgroundImage: imageProvider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    Color subTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color primaryColor = Color(0xFF2563EB);
    const Color accentColor = Color(0xFF06B6D4);

    double netTotalVal = double.tryParse(totalAmount) ?? 0.0;
    double advance = double.tryParse(advanceAmount) ?? 0.0;
    
    double discAmt = double.tryParse(discountAmount) ?? 0.0;
    double discPer = double.tryParse(discountPercent) ?? 0.0;
    
    double actualDiscount = discAmt > 0 ? discAmt : 0;
    double grossTotalVal = netTotalVal + actualDiscount;
    if (discPer > 0) {
      grossTotalVal = netTotalVal / (1 - (discPer / 100));
      actualDiscount = grossTotalVal - netTotalVal;
    }

    double balance = netTotalVal - advance;
    
    Map<String, List<Map<String, String>>> garmentConfigs = _getGarmentFieldConfigs();

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getText('step5Title'), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)
            ),
            const Divider(height: 20),
            
            // 1. Customer Section
            Text(_getText('revCustomerHeader'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor)),
            const SizedBox(height: 10),

            if (customerImagePath != null && customerImagePath!.isNotEmpty) ...[
              _buildCustomerImage(primaryColor),
              const SizedBox(height: 12),
            ],

            _buildReviewRow(_getText('customerId'), customerId, textColor, subTextColor),
            _buildReviewRow(_getText('fullName'), fullName, textColor, subTextColor),
            _buildReviewRow(_getText('mobile'), mobile, textColor, subTextColor),
            if (altMobile.isNotEmpty) _buildReviewRow(_getText('altMobile'), altMobile, textColor, subTextColor),
            _buildReviewRow(_getText('gender'), gender, textColor, subTextColor),
            if (dob.isNotEmpty) _buildReviewRow(_getText('dob'), dob, textColor, subTextColor), 
            _buildReviewRow(_getText('customerType'), customerType, textColor, subTextColor),
            _buildReviewRow(_getText('address'), "$address, $city", textColor, subTextColor),
            if (customerNotes.isNotEmpty) _buildReviewRow(_getText('customerNotes'), customerNotes, textColor, subTextColor),
            const Divider(height: 20),

            // 2. Order Section
            Text(_getText('revOrderHeader'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor)),
            const SizedBox(height: 6),
            _buildReviewRow(_getText('orderId'), orderId, textColor, subTextColor),
            _buildReviewRow(_getText('itemType'), itemType, textColor, subTextColor),
            _buildReviewRow(_getText('quantity'), quantity, textColor, subTextColor),
            _buildReviewRow(_getText('orderDate'), orderDate, textColor, subTextColor),
            if (trialDate.isNotEmpty) _buildReviewRow(_getText('trialDate'), trialDate, textColor, subTextColor),
            _buildReviewRow(_getText('deliveryDate'), deliveryDate, textColor, subTextColor),
            _buildReviewRow(_getText('clothSource'), clothSource, textColor, subTextColor),
            if (clothDetail.isNotEmpty) _buildReviewRow(_getText('clothDetail'), clothDetail, textColor, subTextColor),
            _buildReviewRow(_getText('designStyle'), designStyle, textColor, subTextColor),
            _buildReviewRow(_getText('priority'), priority, textColor, subTextColor),
            if (orderNotes.isNotEmpty) _buildReviewRow(_getText('orderNotes'), orderNotes, textColor, subTextColor),
            const Divider(height: 20),

            // 3. Measurement Section
            Text(_getText('revMeasureHeader'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor)),
            const SizedBox(height: 10),

            ...garmentConfigs.entries.map((configEntry) {
              String garmentName = configEntry.key;
              List<Map<String, String>> fieldsConfig = configEntry.value;

              List<Widget> fieldGrids = [];
              for (var fieldConfig in fieldsConfig) {
                String fieldKey = fieldConfig['key']!;
                String fieldLabel = fieldConfig['label']!;
                
                String fullControllerKey = "${garmentName}_$fieldKey";
                if (measurementControllers.containsKey(fullControllerKey)) {
                  String val = measurementControllers[fullControllerKey]!.text;
                  
                  fieldGrids.add(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              fieldLabel, 
                              style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            val.isEmpty ? '-' : val, 
                            style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }

              if (fieldGrids.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.straighten, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            garmentName.toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: fieldGrids,
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (measurementNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getText('measurementNotes'), 
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      measurementNotes, 
                      style: TextStyle(color: textColor, fontSize: 12)
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 20),

            // 4. Payment Section
            Text(_getText('revPaymentHeader'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor)),
            const SizedBox(height: 6),
            _buildReviewRow(_getText('grossTotal'), "₹${grossTotalVal.toStringAsFixed(0)}", textColor, subTextColor),
            if (actualDiscount > 0) 
              _buildReviewRow(_getText('discount'), "- ₹${actualDiscount.toStringAsFixed(0)}", Colors.green, subTextColor),
            _buildReviewRow(_getText('netTotal'), "₹${netTotalVal.toStringAsFixed(0)}", primaryColor, subTextColor),
            _buildReviewRow(_getText('advanceAmount'), "₹${advance.toStringAsFixed(0)}", textColor, subTextColor),
            _buildReviewRow(_getText('balanceAmount'), "₹${balance.toStringAsFixed(0)}", Colors.redAccent, subTextColor),
            _buildReviewRow(_getText('paymentMethod'), paymentMethod, textColor, subTextColor),
            if (paymentNotes.isNotEmpty) _buildReviewRow(_getText('paymentNotes'), paymentNotes, textColor, subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String title, String value, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty || value == '₹' ? '-' : value, 
              textAlign: TextAlign.end,
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}