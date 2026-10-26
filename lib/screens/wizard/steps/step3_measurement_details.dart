import 'package:flutter/material.dart';

class Step3MeasurementDetails extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String selectedGarments; 
  final ValueChanged<String> onGarmentsChanged;
  final TextEditingController measurementNotesController;
  final Map<String, TextEditingController> measurementControllers;

  const Step3MeasurementDetails({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.selectedGarments,
    required this.onGarmentsChanged,
    required this.measurementNotesController,
    required this.measurementControllers,
  });

  @override
  State<Step3MeasurementDetails> createState() => _Step3MeasurementDetailsState();
}

class _Step3MeasurementDetailsState extends State<Step3MeasurementDetails> {
  List<String> _activeSelectedGarments = [];
  bool _isOtherSelected = false;
  final TextEditingController _otherGarmentController = TextEditingController();
  
  final List<Map<String, String>> _customOtherFields = [];
  final TextEditingController _newFieldLabelController = TextEditingController();

  List<Map<String, String>> get _availableGarments => [
    {'key': 'Shirt', 'label': _getText('Shirt'), 'icon': '👔'},
    {'key': 'Pant', 'label': _getText('Pant'), 'icon': '👖'},
    {'key': 'Kurta', 'label': _getText('Kurta'), 'icon': '🥻'},
    {'key': 'Blazer', 'label': _getText('Blazer'), 'icon': '🤵'},
    {'key': 'Coat', 'label': _getText('Coat'), 'icon': '🧥'},
    {'key': 'Sherwani', 'label': _getText('Sherwani'), 'icon': '👘'},
    {'key': 'Ladies Suit', 'label': _getText('Ladies Suit'), 'icon': '👗'},
    {'key': 'Blouse', 'label': _getText('Blouse'), 'icon': '👚'},
    {'key': 'Jeans Alteration', 'label': _getText('Jeans Alteration'), 'icon': '👖'},
    {'key': 'Other', 'label': _getText('Other'), 'icon': '➕'},
  ];

  Map<String, List<Map<String, String>>> get _garmentFieldMapping => {
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
    'Other': [
      {'key': 'length', 'label': _getText('lengthLabel')},
      {'key': 'chest', 'label': _getText('chestSizeLabel')},
      {'key': 'waist', 'label': _getText('waistLabel')},
      ..._customOtherFields,
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.selectedGarments.isNotEmpty) {
      _activeSelectedGarments = widget.selectedGarments
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      for (var garment in _activeSelectedGarments) {
        if (garment.startsWith('${_getText('Other')}:') || garment.contains(_getText('Other')) || garment.contains('अन्य') || garment.contains('इतर')) {
          _isOtherSelected = true;
          if (garment.contains(':')) {
            _otherGarmentController.text = garment.split(':').last.trim();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _otherGarmentController.dispose();
    _newFieldLabelController.dispose();
    super.dispose();
  }

  String _normalizeGarmentKey(String rawGarment) {
    String clean = rawGarment.toLowerCase();
    if (clean.contains('shirt') || clean.contains('शर्ट')) return 'Shirt';
    if (clean.contains('pant') || clean.contains('पैंट') || clean.contains('पँट')) return 'Pant';
    if (clean.contains('kurta') || clean.contains('कुर्ता')) return 'Kurta';
    if (clean.contains('blazer') || clean.contains('ब्लेज़र') || clean.contains('ब्लेझर')) return 'Blazer';
    if (clean.contains('coat') || clean.contains('कोट')) return 'Coat';
    if (clean.contains('sherwani') || clean.contains('शेरवानी')) return 'Sherwani';
    if (clean.contains('suit') || clean.contains('सूट') || clean.contains('लेडीज सूट')) return 'Ladies Suit';
    if (clean.contains('blouse') || clean.contains('ब्लाउज')) return 'Blouse';
    if (clean.contains('jeans') || clean.contains('अल्टरेशन')) return 'Jeans Alteration';
    if (clean.contains('other') || clean.contains('अन्य') || clean.contains('इतर')) return 'Other';
    return 'Shirt';
  }

  void _clearGarmentControllers(String normalizedKey) {
    List<Map<String, String>> fields = _garmentFieldMapping[normalizedKey] ?? [];
    for (var fieldInfo in fields) {
      String fieldKey = "${normalizedKey}_${fieldInfo['key']}";
      if (widget.measurementControllers.containsKey(fieldKey)) {
        widget.measurementControllers[fieldKey]?.clear();
        widget.measurementControllers.remove(fieldKey);
      }
    }

    widget.onGarmentsChanged(_activeSelectedGarments.join(', '));
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'title': 'Choose Garments & Measurements',
        'selectPrompt': 'Tap on garment buttons below to open their measurements:',
        'noGarment': '⚠️ Please tap and select at least one garment button above to open measurement fields.',
        'notesLabel': 'Measurement Special Notes (e.g., Tight fitting, loose sleeves)',
        'otherGarmentHint': 'Enter custom garment name (e.g., Kurti, Jodhpuri)',
        'addFieldHint': 'Add new measurement name (e.g., Pocket, Wrist)',
        'addFieldButton': 'Add Field',
        'measurementSuffix': 'Measurements',
        'Shirt': 'Shirt', 'Pant': 'Pant', 'Kurta': 'Kurta', 'Blazer': 'Blazer',
        'Coat': 'Coat', 'Sherwani': 'Sherwani', 'Ladies Suit': 'Ladies Suit',
        'Blouse': 'Blouse', 'Jeans Alteration': 'Jeans Alteration', 'Other': 'Other',
        'chestLabel': 'Chest', 'lengthLabel': 'Length', 'shoulderLabel': 'Shoulder',
        'sleeveLabel': 'Sleeve', 'collarLabel': 'Collar', 'cuffLabel': 'Cuff',
        'stomachLabel': 'Stomach', 'frontLabel': 'Front',
        'waistLabel': 'Waist', 'pantLengthLabel': 'Length', 'seatLabel': 'Seat',
        'thighLabel': 'Thigh', 'kneeLabel': 'Knee', 'bottomLabel': 'Bottom',
        'hipLabel': 'Hip', 'inseamLabel': 'Inseam', 'riseLabel': 'Rise', 'kurtaLengthLabel': 'Kurta Length',
        'damanLabel': 'Daman', 'blazerLengthLabel': 'Blazer Length', 'backLengthLabel': 'Back Length',
        'coatLengthLabel': 'Coat Length', 'sherwaniLengthLabel': 'Sherwani Length',
        'suitLengthLabel': 'Suit Length', 'blouseLengthLabel': 'Blouse Length',
        'upperChestLabel': 'Upper Chest', 'frontNeckLabel': 'Front Neck', 'backNeckLabel': 'Back Neck',
        'apexPointLabel': 'Apex Point', 'chestSizeLabel': 'Chest / Size', 'bicepsLabel': 'Biceps', 'armholeLabel': 'Armhole',
      },
      'Hindi': {
        'title': 'गार्मेंट और माप चुनें',
        'selectPrompt': 'माप (Measurements) खोलने के लिए नीचे दिए गए गार्मेंट बटन पर क्लिक करें:',
        'noGarment': '⚠️ माप भरने के लिए कृपया ऊपर दिए गए गार्मेंट बटनों में से कम से कम एक चुनें।',
        'notesLabel': 'माप से संबंधित विशेष नोट्स (जैसे: टाइट फिटिंग, ढीली बाजू)',
        'otherGarmentHint': 'अन्य गार्मेंट का नाम लिखें (जैसे: कुर्ती, जोधपुरी)',
        'addFieldHint': 'नया माप नाम जोड़ें (जैसे: कफ, पॉकेट)',
        'addFieldButton': 'माप जोड़ें',
        'measurementSuffix': 'माप (Measurements)',
        'Shirt': 'शर्ट', 'Pant': 'पैंट', 'Kurta': 'कुर्ता', 'Blazer': 'ब्लेज़र',
        'Coat': 'कोट', 'Sherwani': 'शेरवानी', 'Ladies Suit': 'लेडीज सूट',
        'Blouse': 'ब्लाउज', 'Jeans Alteration': 'जींस अल्टरेशन', 'Other': 'अन्य',
        'chestLabel': 'छाती (Chest)', 'lengthLabel': 'लंबाई (Length)', 'shoulderLabel': 'कंधा (Shoulder)',
        'sleeveLabel': 'बाजू (Sleeve)', 'collarLabel': 'कॉलर (Collar)', 'cuffLabel': 'कफ (Cuff)',
        'stomachLabel': 'पेट (Stomach)', 'frontLabel': 'सामने का भाग (Front)',
        'waistLabel': 'कमर (Waist)', 'pantLengthLabel': 'लंबाई (Length)', 'seatLabel': 'सीट (Seat)',
        'thighLabel': 'जांघ (Thigh)', 'kneeLabel': 'घुटना (Knee)', 'bottomLabel': 'बॉटम (Bottom)',
        'hipLabel': 'हिप (Hip)', 'inseamLabel': 'इनसीम (Inseam)', 'riseLabel': 'राइज (Rise)', 'kurtaLengthLabel': 'कुर्ता लंबाई (Kurta Length)',
        'damanLabel': 'दामन (Daman)', 'blazerLengthLabel': 'ब्लेज़र लंबाई (Blazer Length)', 'backLengthLabel': 'पीठ लंबाई (Back Length)',
        'coatLengthLabel': 'कोट लंबाई (Coat Length)', 'sherwaniLengthLabel': 'शेरवानी लंबाई (Sherwani Length)',
        'suitLengthLabel': 'सूट लंबाई (Suit Length)', 'blouseLengthLabel': 'ब्लाउज लंबाई (Blouse Length)',
        'upperChestLabel': 'ऊपरी छाती (Upper Chest)', 'frontNeckLabel': 'अगला गला (Front Neck)', 'backNeckLabel': 'पिछला गला (Back Neck)',
        'apexPointLabel': 'एपेक्स पॉइंट (Apex Point)', 'chestSizeLabel': 'छाती / साइज़ (Chest / Size)', 'bicepsLabel': 'बाइसेप्स (Biceps)', 'armholeLabel': 'आर्महोल (Armhole)',
      },
      'Marathi': {
        'title': 'परिधान आणि मापे निवडा',
        'selectPrompt': 'माप (Measurements) उघडण्यासाठी खालील परिधान बटनांवर क्लिक करा:',
        'noGarment': '⚠️ मापे भरण्यासाठी कृपया वर दिलेल्या परिधान बटनांपैकी किमान एक निवडा.',
        'notesLabel': 'मापाशी संबंधित विशेष नोंदी (उदा. घट्ट फिटिंग, सैल बाह्या)',
        'otherGarmentHint': 'इतर परिधानाचे नाव प्रविष्ट करा (उदा. कुर्ती, जोधपुरी)',
        'addFieldHint': 'नवीन मापाचे नाव जोडा (उदा. पॉकेट, मनगट)',
        'addFieldButton': 'माप जोडा',
        'measurementSuffix': 'मापे (Measurements)',
        'Shirt': 'शर्ट', 'Pant': 'पँट', 'Kurta': 'कुर्ता', 'Blazer': 'ब्लेझर',
        'Coat': 'कोट', 'Sherwani': 'शेरवानी', 'Ladies Suit': 'लेडीज सूट',
        'Blouse': 'ब्लाउज', 'Jeans Alteration': 'जीन्स अल्टरेशन', 'Other': 'इतर',
        'chestLabel': 'Chest (छाती)', 'lengthLabel': 'Length (लांबी)', 'shoulderLabel': 'Shoulder (खांदा)',
        'sleeveLabel': 'Sleeves (बाही)', 'collarLabel': 'Collar (कॉलर)', 'cuffLabel': 'Cuff (कफ)',
        'stomachLabel': 'Stomach (पोट)', 'frontLabel': 'Front (समोरील भाग)',
        'waistLabel': 'Waist (कमर)', 'pantLengthLabel': 'Length (लांबी)', 'seatLabel': 'Seat (सिट/सीट)',
        'thighLabel': 'Thigh (मंडी)', 'kneeLabel': 'Knee (गुडघा)', 'bottomLabel': 'Bottom (बॉटम)',
        'hipLabel': 'Hip (हिप)', 'inseamLabel': 'Inseam', 'riseLabel': 'Rise', 'kurtaLengthLabel': 'Kurta Length (कुर्ता लांबी)',
        'damanLabel': 'Daman (दामन)', 'blazerLengthLabel': 'Blazer Length', 'backLengthLabel': 'Back Length',
        'coatLengthLabel': 'Coat Length', 'sherwaniLengthLabel': 'Sherwani Length',
        'suitLengthLabel': 'Suit Length', 'blouseLengthLabel': 'Blouse Length',
        'upperChestLabel': 'Upper Chest', 'frontNeckLabel': 'Front Neck', 'backNeckLabel': 'Back Neck',
        'apexPointLabel': 'Apex Point', 'chestSizeLabel': 'Chest / Size', 'bicepsLabel': 'Biceps', 'armholeLabel': 'Armhole',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? translations['English']?[key] ?? key;
  }

  void _updateCustomOtherName(String value) {
    setState(() {
      String otherText = _getText('Other');
      _activeSelectedGarments.removeWhere((item) => item.startsWith(otherText) || item.contains('अन्य') || item.contains('इतर'));
      String finalName = value.trim().isEmpty ? otherText : '$otherText: ${value.trim()}';
      _activeSelectedGarments.add(finalName);
      widget.onGarmentsChanged(_activeSelectedGarments.join(', '));
    });
  }

  void _addNewCustomField() {
    String fieldText = _newFieldLabelController.text.trim();
    if (fieldText.isNotEmpty) {
      setState(() {
        String uniqueKey = 'custom_${DateTime.now().millisecondsSinceEpoch}';
        _customOtherFields.add({'key': uniqueKey, 'label': fieldText});
        _newFieldLabelController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = widget.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    Color subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color primaryColor = Color(0xFF2563EB);

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24 : 14),
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
                      child: const Icon(Icons.straighten_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getText('title'), 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: constraints.maxWidth > 600 ? 18 : 16, color: primaryColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _getText('selectPrompt'), 
                  style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _availableGarments.map((item) {
                    String gKey = item['key']!;
                    String gLabel = item['label']!;
                    String gIcon = item['icon']!;
                    
                    bool isSelected = gKey == 'Other' 
                        ? _isOtherSelected 
                        : _activeSelectedGarments.any((g) => _normalizeGarmentKey(g) == gKey);

                    return FilterChip(
                      label: Text("$gIcon $gLabel", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textColor, fontWeight: FontWeight.w600)),
                      selected: isSelected,
                      selectedColor: primaryColor,
                      backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? primaryColor : borderColor),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (gKey == 'Other') {
                            _isOtherSelected = selected;
                            if (!_isOtherSelected) {
                              _otherGarmentController.clear();
                              _customOtherFields.clear();
                              _activeSelectedGarments.removeWhere((g) => g.startsWith(_getText('Other')) || g.contains('अन्य') || g.contains('इतर'));
                              _clearGarmentControllers('Other');
                            } else {
                              String otherText = _getText('Other');
                              String customName = _otherGarmentController.text.trim().isEmpty 
                                  ? otherText 
                                  : '$otherText: ${_otherGarmentController.text.trim()}';
                              _activeSelectedGarments.add(customName);
                              widget.onGarmentsChanged(_activeSelectedGarments.join(', '));
                            }
                          } else {
                            if (selected) {
                              if (!_activeSelectedGarments.contains(gLabel)) {
                                _activeSelectedGarments.add(gLabel);
                                widget.onGarmentsChanged(_activeSelectedGarments.join(', '));
                              }
                            } else {
                              _activeSelectedGarments.removeWhere((g) => _normalizeGarmentKey(g) == gKey);
                              _clearGarmentControllers(gKey);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

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
                      fillColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newFieldLabelController,
                          style: TextStyle(color: textColor, fontSize: 12),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: _getText('addFieldHint'),
                            labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                            filled: true,
                            fillColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addNewCustomField,
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: Text(_getText('addFieldButton'), style: const TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                const Divider(),
                const SizedBox(height: 10),

                if (_activeSelectedGarments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                    child: Center(
                      child: Text(
                        _getText('noGarment'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent.shade200, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  ..._activeSelectedGarments.map((garment) {
                    String normalizedKey = _normalizeGarmentKey(garment);
                    List<Map<String, String>> fields = _garmentFieldMapping[normalizedKey] ?? _garmentFieldMapping['Shirt']!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
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
                                    const Icon(Icons.checkroom, size: 16, color: primaryColor),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "$garment ${_getText('measurementSuffix')}",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    if (normalizedKey == 'Other') {
                                      _isOtherSelected = false;
                                      _otherGarmentController.clear();
                                      _customOtherFields.clear();
                                    }
                                    _activeSelectedGarments.remove(garment);
                                    _clearGarmentControllers(normalizedKey);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 2.6,
                            ),
                            itemCount: fields.length,
                            itemBuilder: (context, index) {
                              var fieldInfo = fields[index];
                              String fieldKey = "${normalizedKey}_${fieldInfo['key']}";

                              if (!widget.measurementControllers.containsKey(fieldKey)) {
                                widget.measurementControllers[fieldKey] = TextEditingController();
                              }

                              return TextField(
                                controller: widget.measurementControllers[fieldKey],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: textColor, fontSize: 12),
                                decoration: InputDecoration(
                                  labelText: fieldInfo['label'],
                                  labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                                  isDense: true,
                                  filled: true,
                                  fillColor: surfaceColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 10),
                TextField(
                  controller: widget.measurementNotesController,
                  maxLines: 2,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: _getText('notesLabel'),
                    labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                    prefixIcon: const Icon(Icons.note_alt_outlined, color: primaryColor, size: 18),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}