import 'package:flutter/material.dart';

class Step2OrderDetails extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String orderId; 
  final TextEditingController itemTypeController; 
  final TextEditingController quantityController;
  final TextEditingController orderDateController;
  final TextEditingController trialDateController;
  final TextEditingController deliveryDateController;
  final TextEditingController orderNotesController;
  
  final String clothSource;
  final ValueChanged<String> onClothSourceChanged;
  
  final String clothDetail;
  final ValueChanged<String> onClothDetailChanged;
  
  final String designStyle;
  final ValueChanged<String> onDesignStyleChanged;

  final String priority;
  final ValueChanged<String> onPriorityChanged;

  const Step2OrderDetails({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.orderId,
    required this.itemTypeController,
    required this.quantityController,
    required this.orderDateController,
    required this.trialDateController,
    required this.deliveryDateController,
    required this.orderNotesController,
    required this.clothSource,
    required this.onClothSourceChanged,
    required this.clothDetail,
    required this.onClothDetailChanged,
    required this.designStyle,
    required this.onDesignStyleChanged,
    required this.priority,
    required this.onPriorityChanged,
  });

  @override
  State<Step2OrderDetails> createState() => _Step2OrderDetailsState();
}

class _Step2OrderDetailsState extends State<Step2OrderDetails> {
  final Map<String, TextEditingController> _garmentQuantities = {};
  final TextEditingController _otherGarmentController = TextEditingController();
  late final TextEditingController _orderIdController;
  bool _isOtherSelected = false;

  @override
  void initState() {
    super.initState();
    _orderIdController = TextEditingController(text: widget.orderId);
    DateTime now = DateTime.now();
    
    if (widget.orderDateController.text.isEmpty) {
      widget.orderDateController.text = "${now.day}/${now.month}/${now.year}";
    }

    // 🚀 Set default to 'None' if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.clothDetail.isEmpty) {
        widget.onClothDetailChanged('None');
      }
      if (widget.designStyle.isEmpty) {
        widget.onDesignStyleChanged('None');
      }
    });
    
    _initializeGarmentQuantities();
  }

  @override
  void didUpdateWidget(covariant Step2OrderDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _orderIdController.text = widget.orderId;
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _otherGarmentController.dispose();
    for (var controller in _garmentQuantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeGarmentQuantities() {
    List<String> currentSelected = widget.itemTypeController.text.isEmpty
        ? []
        : widget.itemTypeController.text.split(', ').map((e) => e.trim()).toList();

    Map<String, String> existingQuantities = {};
    if (widget.quantityController.text.contains(':')) {
      List<String> qtyPairs = widget.quantityController.text.split(', ');
      for (var pair in qtyPairs) {
        List<String> parts = pair.split(':');
        if (parts.length == 2) {
          existingQuantities[parts[0].trim()] = parts[1].trim();
        }
      }
    }

    for (var garment in currentSelected) {
      if (garment.startsWith('Other:') || garment.contains('Other') || garment.contains('अन्य') || garment.contains('इतर')) {
        _isOtherSelected = true;
        if (garment.contains(':')) {
          _otherGarmentController.text = garment.split(':').last.trim();
        }
      }
      if (!_garmentQuantities.containsKey(garment)) {
        String initialQty = existingQuantities[garment] ?? '1';
        _garmentQuantities[garment] = TextEditingController(text: initialQty);
      }
    }
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'step2Title': 'Order Details & Specifications',
        'orderNumber': 'Order Number',
        'orderDate': 'Order Date',
        'garmentType': 'Garment Type (Multi-Select) *',
        'garmentQuantities': 'Enter Quantity Separately for Each Garment',
        'otherGarmentHint': 'Enter custom garment name (e.g., Sherwani)',
        'clothSource': 'Cloth Source',
        'customerCloth': 'Customer Cloth',
        'shopCloth': 'Shop Cloth',
        'clothDetails': 'Cloth Material Details',
        'designStyle': 'Design / Style',
        'trialDate': 'Trial Date (Optional)',
        'deliveryDate': 'Delivery Date *',
        'priority': 'Priority',
        'normal': 'Normal',
        'urgent': 'Urgent 🔥',
        'specialInstructions': 'Special Instructions (e.g. Extra Pocket, Embroidery, Collar/Sleeve notes)',
        'qtyLabel': 'Qty',
        'Shirt': 'Shirt',
        'Pant': 'Pant',
        'Kurta': 'Kurta',
        'Blazer': 'Blazer',
        'Coat': 'Coat',
        'Sherwani': 'Sherwani',
        'Ladies Suit': 'Ladies Suit',
        'Blouse': 'Blouse',
        'Jeans Alteration': 'Jeans Alteration',
        'Other': 'Other',
        'None': 'None',
        'Cotton': 'Cotton',
        'Linen': 'Linen',
        'Silk': 'Silk',
        'Denim': 'Denim',
        'Regular Fit': 'Regular Fit',
        'Slim Fit': 'Slim Fit',
        'Loose Fit': 'Loose Fit',
        'Custom Design': 'Custom Design',
      },
      'Hindi': {
        'step2Title': 'ऑर्डर विवरण और विशेषताएँ',
        'orderNumber': 'ऑर्डर नंबर (Order No)',
        'orderDate': 'ऑर्डर की तारीख',
        'garmentType': 'गार्मेंट का प्रकार (एक से अधिक चुनें) *',
        'garmentQuantities': 'प्रत्येक गार्मेंट के लिए अलग-अलग मात्रा (Quantity) दर्ज करें',
        'otherGarmentHint': 'अन्य गार्मेंट का नाम लिखें',
        'clothSource': 'कपड़े का स्रोत (Cloth Source)',
        'customerCloth': 'ग्राहक का कपड़ा',
        'shopCloth': 'दुकान का कपड़ा',
        'clothDetails': 'कपड़े की सामग्री (Material)',
        'designStyle': 'डिज़ाइन / स्टाइल',
        'trialDate': 'ट्रायल की तारीख (वैकल्पिक)',
        'deliveryDate': 'डिलीवरी की तारीख *',
        'priority': 'प्राथमिकता (Priority)',
        'normal': 'सामान्य (Normal)',
        'urgent': 'तत्काल (Urgent 🔥)',
        'specialInstructions': 'विशेष निर्देश (जैसे: कॉलर/स्लीव डिज़ाइन, एक्स्ट्रा पॉकेट)',
        'qtyLabel': 'मात्रा',
        'Shirt': 'Shirt',
        'Pant': 'Pant',
        'Kurta': 'Kurta',
        'Blazer': 'Blazer',
        'Coat': 'Coat',
        'Sherwani': 'Sherwani',
        'Ladies Suit': 'Ladies Suit',
        'Blouse': 'Blouse',
        'Jeans Alteration': 'Jeans Alteration',
        'Other': 'Other',
        'None': 'कोई नहीं (None)',
        'Cotton': 'कॉटन',
        'Linen': 'लिनन',
        'Silk': 'सिल्क',
        'Denim': 'डेनिम',
        'Regular Fit': 'रेगुलर फिट',
        'Slim Fit': 'स्लिम फिट',
        'Loose Fit': 'लूज फिट',
        'Custom Design': 'कस्टम डिज़ाइन',
      },
      'Marathi': {
        'step2Title': 'ऑर्डर तपशील आणि वैशिष्ट्ये',
        'orderNumber': 'ऑर्डर क्रमांक',
        'orderDate': 'ऑर्डरची तारीख',
        'garmentType': 'कपड्याचा प्रकार (मल्टी-निवड) *',
        'garmentQuantities': 'प्रत्येक कपड्यासाठी स्वतंत्र नगसंख्या (Quantity) प्रविष्ट करा',
        'otherGarmentHint': 'इतर कपड्याचे नाव प्रविष्ट करा',
        'clothSource': 'कापडाचा स्रोत',
        'customerCloth': 'ग्राहकाचे कापड',
        'shopCloth': 'दुकानाचे कापड',
        'clothDetails': 'कापडाचा प्रकार (Material)',
        'designStyle': 'डिझाइन / स्टाइल',
        'trialDate': 'ट्रायल तारीख (पर्यायी)',
        'deliveryDate': 'डिलिव्हरी तारीख *',
        'प्राधान्य': 'प्राधान्य',
        'normal': 'सामान्य',
        'urgent': 'तातडीचे (Urgent 🔥)',
        'specialInstructions': 'विशेष सूचना (उदा. कॉलर/बाहू तपशील, पॉकेट)',
        'qtyLabel': 'नग',
        'Shirt': 'Shirt',
        'Pant': 'Pant',
        'Kurta': 'Kurta',
        'Blazer': 'Blazer',
        'Coat': 'Coat',
        'Sherwani': 'Sherwani',
        'Ladies Suit': 'Ladies Suit',
        'Blouse': 'Blouse',
        'Jeans Alteration': 'Jeans Alteration',
        'Other': 'Other',
        'None': 'काहीही नाही (None)',
        'Cotton': 'सुती (Cotton)',
        'Linen': 'लिनन',
        'Silk': 'सिल्क',
        'Denim': 'डेनिम',
        'Regular Fit': 'रेगुलर फिट',
        'Slim Fit': 'स्लिम फिट',
        'Loose Fit': 'लूज फिट',
        'Custom Design': 'कस्टम डिझाइन',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? translations['English']?[key] ?? key;
  }

  String _getDisplayLabel(String key) {
    Map<String, Map<String, String>> displayNames = {
      'Hindi': {
        'Shirt': 'शर्ट (Shirt)', 'Pant': 'पैंट (Pant)', 'Kurta': 'कुर्ता', 'Blazer': 'ब्लेज़र', 
        'Coat': 'कोट', 'Sherwani': 'शेरवानी', 'Ladies Suit': 'लेडीज सूट', 'Blouse': 'ब्लाउज', 
        'Jeans Alteration': 'जींस अल्टरेशन', 'Other': 'अन्य (Other)', 'None': 'कोई नहीं (None)',
        'Cotton': 'कॉटन', 'Linen': 'लिनन', 'Silk': 'सिल्क', 'Denim': 'डेनिम',
        'Regular Fit': 'रेगुलर फिट', 'Slim Fit': 'स्लिम फिट', 'Loose Fit': 'लूज फिट', 'Custom Design': 'कस्टम डिज़ाइन',
      },
      'Marathi': {
        'Shirt': 'शर्ट', 'Pant': 'पँट', 'Kurta': 'कुर्ता', 'Blazer': 'ब्लेझर', 
        'Coat': 'कोट', 'Sherwani': 'शेरवानी', 'Ladies Suit': 'लेडीज सूट', 'Blouse': 'ब्लाउज', 
        'Jeans Alteration': 'जीन्स अल्टरेशन', 'Other': 'इतर', 'None': 'काहीही नाही (None)',
        'Cotton': 'सुती (Cotton)', 'Linen': 'लिनन', 'Silk': 'सिल्क', 'Denim': 'डेनिम',
        'Regular Fit': 'रेगुलर फिट', 'Slim Fit': 'स्लिम फिट', 'Loose Fit': 'लूज फिट', 'Custom Design': 'कस्टम डिझाइन',
      }
    };
    return displayNames[widget.initialLanguage]?[key] ?? key;
  }

  List<Map<String, dynamic>> get _garmentOptions => [
    {'key': 'Shirt', 'icon': '👔'},
    {'key': 'Pant', 'icon': '👖'},
    {'key': 'Kurta', 'icon': '🥻'},
    {'key': 'Blazer', 'icon': '🤵'},
    {'key': 'Coat', 'icon': '🧥'},
    {'key': 'Sherwani', 'icon': '👘'},
    {'key': 'Ladies Suit', 'icon': '👗'},
    {'key': 'Blouse', 'icon': '👚'},
    {'key': 'Jeans Alteration', 'icon': '👖'},
    {'key': 'Other', 'icon': '✂️'},
  ];

  // Added 'None' as the first element
  List<String> get _clothDetailsList => ['None', 'Cotton', 'Linen', 'Silk', 'Denim', 'Other'];
  List<String> get _designStyles => ['None', 'Regular Fit', 'Slim Fit', 'Loose Fit', 'Custom Design'];

  void _toggleGarmentSelection(String garmentKey) {
    if (garmentKey == 'Other') {
      setState(() {
        _isOtherSelected = !_isOtherSelected;
        if (!_isOtherSelected) {
          _otherGarmentController.clear();
          _removeGarmentFromSelection('Other');
        } else {
          String customName = _otherGarmentController.text.trim().isEmpty 
              ? 'Other' 
              : 'Other: ${_otherGarmentController.text.trim()}';
          _addGarmentToSelection(customName);
        }
      });
    } else {
      List<String> currentSelected = _getCurrentSelectedGarments();
      if (currentSelected.contains(garmentKey)) {
        _removeGarmentFromSelection(garmentKey);
      } else {
        _addGarmentToSelection(garmentKey);
      }
    }
  }

  List<String> _getCurrentSelectedGarments() {
    return widget.itemTypeController.text.isEmpty
        ? []
        : widget.itemTypeController.text.split(', ').map((e) => e.trim()).toList();
  }

  void _addGarmentToSelection(String garment) {
    List<String> currentSelected = _getCurrentSelectedGarments();
    if (!currentSelected.contains(garment)) {
      currentSelected.add(garment);
      if (!_garmentQuantities.containsKey(garment)) {
        _garmentQuantities[garment] = TextEditingController(text: '1');
      }
    }
    _updateControllersAndState(currentSelected);
  }

  void _removeGarmentFromSelection(String garment) {
    List<String> currentSelected = _getCurrentSelectedGarments();
    currentSelected.removeWhere((item) => item == garment || (garment == 'Other' && item.startsWith('Other')));
    
    final removedCtrl = _garmentQuantities.remove(garment);
    removedCtrl?.dispose();

    _updateControllersAndState(currentSelected);
  }

  void _updateCustomOtherName(String value) {
    List<String> currentSelected = _getCurrentSelectedGarments();
    currentSelected.removeWhere((item) => item.startsWith('Other'));
    
    String finalName = value.trim().isEmpty ? 'Other' : 'Other: ${value.trim()}';
    currentSelected.add(finalName);
    
    TextEditingController? qtyCtrl = _garmentQuantities.remove('Other') ?? _garmentQuantities.values.firstOrNull;
    _garmentQuantities[finalName] = qtyCtrl ?? TextEditingController(text: '1');

    _updateControllersAndState(currentSelected);
  }

  void _updateControllersAndState(List<String> updatedList) {
    setState(() {
      widget.itemTypeController.text = updatedList.join(', ');
      
      List<String> qtyBreakdown = [];
      for (var garment in updatedList) {
        if (!_garmentQuantities.containsKey(garment)) {
          _garmentQuantities[garment] = TextEditingController(text: '1');
        }
        String qty = _garmentQuantities[garment]?.text.trim().isEmpty ?? true ? '1' : _garmentQuantities[garment]!.text.trim();
        qtyBreakdown.add('$garment:$qty');
      }
      widget.quantityController.text = qtyBreakdown.join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    Color scaffoldBg = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = widget.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    Color subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color primaryColor = Color(0xFF2563EB);

    List<String> selectedGarments = _getCurrentSelectedGarments();

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.checkroom_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(_getText('step2Title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 18),

            // Order ID Field
            _buildTextField(
              controller: _orderIdController,
              label: _getText('orderNumber'),
              icon: Icons.confirmation_number_rounded,
              textColor: textColor, subTextColor: subTextColor, surfaceColor: scaffoldBg, borderColor: borderColor, primaryColor: primaryColor,
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Order Date Picker
            _buildTextField(
              controller: widget.orderDateController,
              label: _getText('orderDate'),
              icon: Icons.calendar_today_rounded,
              textColor: textColor, subTextColor: subTextColor, surfaceColor: scaffoldBg, borderColor: borderColor, primaryColor: primaryColor,
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    widget.orderDateController.text = "${picked.day}/${picked.month}/${picked.year}";
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            Text(_getText('garmentType'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _garmentOptions.map((item) {
                String garmentKey = item['key'];
                String displayLabel = _getDisplayLabel(garmentKey);
                bool isSelected = garmentKey == 'Other' 
                    ? _isOtherSelected 
                    : selectedGarments.contains(garmentKey);

                return FilterChip(
                  label: Text("${item['icon']} $displayLabel", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textColor)),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: scaffoldBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? primaryColor : borderColor),
                  ),
                  onSelected: (bool selected) {
                    _toggleGarmentSelection(garmentKey);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            if (_isOtherSelected) ...[
              TextField(
                controller: _otherGarmentController,
                onChanged: (val) => _updateCustomOtherName(val),
                style: TextStyle(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: _getText('otherGarmentHint'),
                  labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                  filled: true,
                  fillColor: scaffoldBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (selectedGarments.isNotEmpty) ...[
              Text(_getText('garmentQuantities'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedGarments.length,
                itemBuilder: (context, index) {
                  String garment = selectedGarments[index];
                  if (!_garmentQuantities.containsKey(garment)) {
                    _garmentQuantities[garment] = TextEditingController(text: '1');
                  }
                  String labelName = garment.startsWith('Other') ? garment : _getDisplayLabel(garment);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(labelName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        ),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 45,
                            child: TextField(
                              controller: _garmentQuantities[garment],
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                _updateControllersAndState(selectedGarments);
                              },
                              style: TextStyle(color: textColor, fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: _getText('qtyLabel'),
                                filled: true,
                                fillColor: scaffoldBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            Text(_getText('clothSource'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(_getText('customerCloth'), style: TextStyle(fontSize: 12, color: textColor)),
                    value: 'Customer Cloth',
                    groupValue: widget.clothSource,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => widget.onClothSourceChanged(val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(_getText('shopCloth'), style: TextStyle(fontSize: 12, color: textColor)),
                    value: 'Shop Cloth',
                    groupValue: widget.clothSource,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => widget.onClothSourceChanged(val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(_getText('clothDetails'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _clothDetailsList.map((clothKey) {
                String localizedCloth = _getDisplayLabel(clothKey);
                bool isSelected = widget.clothDetail == clothKey || widget.clothDetail == localizedCloth || (widget.clothDetail.isEmpty && clothKey == 'None');
                return ChoiceChip(
                  label: Text(localizedCloth, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textColor)),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: scaffoldBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? primaryColor : borderColor)),
                  onSelected: (selected) => widget.onClothDetailChanged(clothKey),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text(_getText('designStyle'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _designStyles.map((styleKey) {
                String localizedStyle = _getDisplayLabel(styleKey);
                bool isSelected = widget.designStyle == styleKey || widget.designStyle == localizedStyle || (widget.designStyle.isEmpty && styleKey == 'None');
                return ChoiceChip(
                  label: Text(localizedStyle, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textColor)),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: scaffoldBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? primaryColor : borderColor)),
                  onSelected: (selected) => widget.onDesignStyleChanged(styleKey),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Trial & Delivery Date Pickers
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: widget.trialDateController,
                    label: _getText('trialDate'),
                    icon: Icons.event_available_rounded,
                    textColor: textColor, subTextColor: subTextColor, surfaceColor: scaffoldBg, borderColor: borderColor, primaryColor: primaryColor,
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 2)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          widget.trialDateController.text = "${picked.day}/${picked.month}/${picked.year}";
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: widget.deliveryDateController,
                    label: _getText('deliveryDate'),
                    icon: Icons.event_rounded,
                    textColor: textColor, subTextColor: subTextColor, surfaceColor: scaffoldBg, borderColor: borderColor, primaryColor: primaryColor,
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 5)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          widget.deliveryDateController.text = "${picked.day}/${picked.month}/${picked.year}";
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(_getText('priority'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(_getText('normal'), style: TextStyle(fontSize: 12, color: textColor)),
                    value: 'Normal',
                    groupValue: widget.priority,
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => widget.onPriorityChanged(val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(_getText('urgent'), style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    value: 'Urgent',
                    groupValue: widget.priority,
                    activeColor: Colors.redAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => widget.onPriorityChanged(val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: widget.orderNotesController,
              label: _getText('specialInstructions'),
              icon: Icons.note_rounded,
              maxLines: 2,
              textColor: textColor, subTextColor: subTextColor, surfaceColor: scaffoldBg, borderColor: borderColor, primaryColor: primaryColor,
            ),
          ],
        ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 12),
        prefixIcon: Icon(icon, color: primaryColor, size: 18),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }
}