import 'package:flutter/material.dart';

class Step4PaymentDetails extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String customerName;
  final String mobile;
  final String customerId; 
  final String orderNo; 
  final List<Map<String, dynamic>> orderedItems; 
  final Map<String, TextEditingController> itemPriceControllers; 
  final TextEditingController discountAmountController;
  final TextEditingController discountPercentController;
  final TextEditingController advanceAmountController;
  final TextEditingController paymentNotesController;
  final TextEditingController? totalAmountController;
  final String selectedPaymentMethod;
  final Function(String) onPaymentMethodChanged;

  const Step4PaymentDetails({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.customerName,
    required this.mobile,
    required this.customerId,
    required this.orderNo,
    required this.orderedItems,
    required this.itemPriceControllers,
    required this.discountAmountController,
    required this.discountPercentController,
    required this.advanceAmountController,
    required this.paymentNotesController,
    this.totalAmountController,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
  });

  @override
  State<Step4PaymentDetails> createState() => _Step4PaymentDetailsState();
}

class _Step4PaymentDetailsState extends State<Step4PaymentDetails> {
  String _paymentStatus = 'Due';
  bool _isManualStatusSelected = false; 

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'sec1Title': 'Section 1 – Customer & Order Details (Read Only)',
        'customerName': 'Customer Name',
        'mobile': 'Mobile',
        'customerId': 'Customer ID',
        'orderNo': 'Order ID',
        'sec2Title': 'Section 2 – Order Summary (Read Only)',
        'items': 'Items',
        'sec3Title': 'Section 3 – Price Entry',
        'price': 'Price',
        'qty': 'Quantity',
        'total': 'Total',
        'sec4Title': 'Section 4 – Total Amount Breakdown',
        'grossTotal': 'Gross Total',
        'discount': 'Discount',
        'grandTotal': 'Grand Total',
        'sec5Title': 'Section 5 – Discount (Optional)',
        'discountAmount': 'Discount Amount (₹)',
        'discountPercent': 'Discount (%)',
        'sec6Title': 'Section 6 – Advance Payment',
        'advance': 'Advance Paid',
        'sec7Title': 'Section 7 – Remaining Amount',
        'remaining': 'Remaining',
        'sec8Title': 'Section 8 – Payment Method',
        'cash': 'Cash',
        'upi': 'UPI',
        'card': 'Card',
        'bankTransfer': 'Bank Transfer',
        'sec9Title': 'Section 9 – Payment Status',
        'paid': 'Paid',
        'partial': 'Partial',
        'due': 'Due',
        'sec10Title': 'Section 10 – Notes',
        'notesHint': 'e.g., Remaining delivery ke time lega.',
      },
      'Hindi': {
        'sec1Title': 'भाग 1 – ग्राहक और ऑर्डर विवरण',
        'customerName': 'ग्राहक का नाम',
        'mobile': 'मोबाइल',
        'customerId': 'ग्राहक आईडी (Customer ID)',
        'orderNo': 'ऑर्डर आईडी (Order ID)',
        'sec2Title': 'भाग 2 – ऑर्डर सारांश',
        'items': 'आइटम',
        'sec3Title': 'भाग 3 – कीमत दर्ज करें',
        'price': 'मूल्य',
        'qty': 'मात्रा',
        'total': 'कुल',
        'sec4Title': 'भाग 4 – कुल राशि विवरण',
        'grossTotal': 'कुल योग (Gross Total)',
        'discount': 'छूट (Discount)',
        'grandTotal': 'अंतिम देय राशि (Grand Total)',
        'sec5Title': 'भाग 5 – छूट (वैकल्पिक)',
        'discountAmount': 'छूट राशि (₹)',
        'discountPercent': 'छूट (%)',
        'sec6Title': 'भाग 6 – एडवांस भुगतान',
        'advance': 'एडवांस भुगतान',
        'sec7Title': 'भाग 7 – शेष राशि',
        'remaining': 'शेष राशि (Remaining)',
        'sec8Title': 'भाग 8 – भुगतान का तरीका',
        'cash': 'नकद (Cash)',
        'upi': 'UPI',
        'card': 'कार्ड (Card)',
        'bankTransfer': 'बैंक ट्रांसफर',
        'sec9Title': 'भाग 9 – भुगतान स्थिति',
        'paid': 'भुगतान किया गया (Paid)',
        'partial': 'आंशिक (Partial)',
        'due': 'बाकी (Due)',
        'sec10Title': 'भाग 10 – नोट्स',
        'notesHint': 'जैसे: शेष राशि डिलीवरी के समय लेगा।',
      },
      'Marathi': {
        'sec1Title': 'विभाग 1 – ग्राहक आणि ऑर्डर तपशील',
        'customerName': 'ग्राहकाचे नाव',
        'mobile': 'मोबाईल',
        'customerId': 'ग्राहक आयडी (Customer ID)',
        'orderNo': 'ऑर्डर आयडी (Order ID)',
        'sec2Title': 'विभाग 2 – ऑर्डर सारांश',
        'items': 'वस्तू',
        'sec3Title': 'विभाग 3 – किंमत प्रविष्ट करा',
        'price': 'किंमत',
        'qty': 'प्रमाण',
        'total': 'एकूण',
        'sec4Title': 'विभाग 4 – एकूण रक्कम तपशील',
        'grossTotal': 'एकूण ग्रॉस टोटल (Gross Total)',
        'discount': 'सूट (Discount)',
        'grandTotal': 'अंतिम एकूण रक्कम (Grand Total)',
        'sec5Title': 'विभाग 5 – सूट (पर्यायी)',
        'discountAmount': 'सूट रक्कम (₹)',
        'discountPercent': 'सूट (%)',
        'sec6Title': 'विभाग 6 – अग्रिम पेमेंट',
        'advance': 'एडवान्स रक्कम',
        'sec7Title': 'विभाग 7 – शिल्लक रक्कम',
        'remaining': 'शिल्लक (Remaining)',
        'sec8Title': 'विभाग 8 – पेमेंट पद्धत',
        'cash': 'रोख (Cash)',
        'upi': 'UPI',
        'card': 'कार्ड (Card)',
        'bankTransfer': 'बँक ट्रान्सफर',
        'sec9Title': 'विभाग 9 – पेमेंट स्थिती',
        'paid': 'पूर्ण (Paid)',
        'partial': 'अर्धे/आंशिक (Partial)',
        'due': 'बाकी (Due)',
        'sec10Title': 'विभाग 10 – टीपा (Notes)',
        'notesHint': 'उदा. उरलेली रक्कम डिलिव्हरीच्या वेळी मिळेल.',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? translations['English']?[key] ?? key;
  }

  int _getItemQty(Map<String, dynamic> item) {
    var rawQty = item['qty'] ?? item['quantity'] ?? 1;
    if (rawQty is int) return rawQty;
    return int.tryParse(rawQty.toString()) ?? 1;
  }

  String _getGarmentIcon(String itemName) {
    String name = itemName.toLowerCase();
    if (name.contains('shirt') || name.contains('शर्ट')) return '👔';
    if (name.contains('pant') || name.contains('पैंट') || name.contains('पँट') || name.contains('jeans')) return '👖';
    if (name.contains('kurta') || name.contains('कुर्ता')) return '🥻';
    if (name.contains('blazer') || name.contains('ब्लेज़र')) return '🤵';
    if (name.contains('coat') || name.contains('कोट')) return '🧥';
    if (name.contains('sherwani') || name.contains('शेरवानी')) return '👘';
    if (name.contains('blouse') || name.contains('ब्लाउज')) return '👚';
    if (name.contains('suit') || name.contains('लेडीज')) return '👗';
    return '✂️';
  }

  double _calculateSubtotalFor(String itemKey, int qty) {
    double price = double.tryParse(widget.itemPriceControllers[itemKey]?.text ?? '0') ?? 0.0;
    return price * qty;
  }

  double _calculateGrossTotal() {
    double gross = 0;
    for (var item in widget.orderedItems) {
      String key = item['name'] ?? '';
      int qty = _getItemQty(item);
      gross += _calculateSubtotalFor(key, qty);
    }
    return gross;
  }

  double _calculateDiscountAmount(double gross) {
    double discAmount = double.tryParse(widget.discountAmountController.text) ?? 0.0;
    double discPercent = double.tryParse(widget.discountPercentController.text) ?? 0.0;

    if (discPercent > 0) {
      discAmount = (gross * discPercent) / 100;
    }
    return discAmount;
  }

  double _calculateGrandTotal() {
    double gross = _calculateGrossTotal();
    double discAmount = _calculateDiscountAmount(gross);

    double finalTotal = gross - discAmount;
    
    if (widget.totalAmountController != null) {
      widget.totalAmountController!.text = finalTotal.toStringAsFixed(0);
    }

    return finalTotal < 0 ? 0 : finalTotal;
  }

  double _calculateRemaining() {
    double grandTotal = _calculateGrandTotal();
    double advance = double.tryParse(widget.advanceAmountController.text) ?? 0.0;
    double rem = grandTotal - advance;
    return rem < 0 ? 0 : rem;
  }

  void _autoUpdateStatus(double grandTotal, double advance) {
    if (_isManualStatusSelected) return; // Do not auto-update if manually overridden

    setState(() {
      if (advance <= 0) {
        _paymentStatus = 'Due';
      } else if (advance >= grandTotal) {
        _paymentStatus = 'Paid';
      } else {
        _paymentStatus = 'Partial';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    Color scaffoldBg = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = widget.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    Color subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color primaryColor = Color(0xFF2563EB);

    double grossTotal = _calculateGrossTotal();
    double discountVal = _calculateDiscountAmount(grossTotal);
    double grandTotal = _calculateGrandTotal();
    double advance = double.tryParse(widget.advanceAmountController.text) ?? 0.0;
    double remaining = _calculateRemaining();

    // Auto update status logic integration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isManualStatusSelected) {
        double currentGrandTotal = _calculateGrandTotal();
        double currentAdvance = double.tryParse(widget.advanceAmountController.text) ?? 0.0;
        String expectedStatus = 'Due';
        if (currentAdvance <= 0) {
          expectedStatus = 'Due';
        } else if (currentAdvance >= currentGrandTotal) {
          expectedStatus = 'Paid';
        } else {
          expectedStatus = 'Partial';
        }
        if (_paymentStatus != expectedStatus) {
          setState(() {
            _paymentStatus = expectedStatus;
          });
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 400;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1 – Customer & Order Details
                _buildSectionHeader(_getText('sec1Title'), primaryColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scaffoldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("👤 ${_getText('customerName')} : ${widget.customerName}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text("📱 ${_getText('mobile')} : ${widget.mobile}", style: TextStyle(color: subTextColor, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("🆔 ${_getText('customerId')} : ${widget.customerId}", style: TextStyle(color: subTextColor, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("🔖 ${_getText('orderNo')} : ${widget.orderNo}", style: TextStyle(color: subTextColor, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2 – Order Summary
                _buildSectionHeader(_getText('sec2Title'), primaryColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scaffoldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getText('items'), style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      ...widget.orderedItems.map((item) {
                        String itemName = item['name'] ?? '';
                        int qty = _getItemQty(item);
                        String garmentIcon = _getGarmentIcon(itemName);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text("$garmentIcon $itemName × $qty", style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 3 – Price Entry
                _buildSectionHeader(_getText('sec3Title'), primaryColor),
                const SizedBox(height: 8),
                ...widget.orderedItems.map((item) {
                  String itemName = item['name'] ?? '';
                  int qty = _getItemQty(item);
                  String garmentIcon = _getGarmentIcon(itemName);
                  
                  if (!widget.itemPriceControllers.containsKey(itemName)) {
                    widget.itemPriceControllers[itemName] = TextEditingController();
                  }
                  double subtotal = _calculateSubtotalFor(itemName, qty);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: scaffoldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$garmentIcon $itemName", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: isSmallScreen ? double.infinity : 140,
                              child: TextFormField(
                                controller: widget.itemPriceControllers[itemName],
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {});
                                },
                                style: TextStyle(color: textColor, fontSize: 12),
                                decoration: InputDecoration(
                                  labelText: '${_getText('price')} (₹)',
                                  labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                                  isDense: true,
                                  filled: true,
                                  fillColor: surfaceColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                                ),
                              ),
                            ),
                            Text("${_getText('qty')} : $qty", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text("${_getText('total')} : ₹${subtotal.toStringAsFixed(0)}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Section 4 – Total Amount Breakdown
                _buildSectionHeader(_getText('sec4Title'), primaryColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scaffoldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getText('grossTotal'), style: TextStyle(color: subTextColor, fontSize: 12)),
                          Text("₹${grossTotal.toStringAsFixed(0)}", style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (discountVal > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("- ${_getText('discount')}", style: TextStyle(color: Colors.green, fontSize: 12)),
                            Text("- ₹${discountVal.toStringAsFixed(0)}", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getText('grandTotal'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("₹${grandTotal.toStringAsFixed(0)}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 5 – Discount
                _buildSectionHeader(_getText('sec5Title'), primaryColor),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: isSmallScreen ? double.infinity : (constraints.maxWidth / 2 - 24),
                      child: TextFormField(
                        controller: widget.discountAmountController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          if (val.isNotEmpty) widget.discountPercentController.clear();
                          setState(() {});
                        },
                        style: TextStyle(color: textColor, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: _getText('discountAmount'),
                          labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                          isDense: true,
                          filled: true,
                          fillColor: scaffoldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        ),
                      ),
                    ),
                    if (!isSmallScreen)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12), 
                        child: Text("OR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
                      ),
                    SizedBox(
                      width: isSmallScreen ? double.infinity : (constraints.maxWidth / 2 - 24),
                      child: TextFormField(
                        controller: widget.discountPercentController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          if (val.isNotEmpty) widget.discountAmountController.clear();
                          setState(() {});
                        },
                        style: TextStyle(color: textColor, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: _getText('discountPercent'),
                          labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                          isDense: true,
                          filled: true,
                          fillColor: scaffoldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 6 – Advance Payment
                _buildSectionHeader(_getText('sec6Title'), primaryColor),
                const SizedBox(height: 8),
                TextFormField(
                  controller: widget.advanceAmountController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _isManualStatusSelected = false; 
                    setState(() {});
                  },
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: _getText('advance'),
                    labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                    prefixIcon: const Icon(Icons.payment_rounded, color: primaryColor, size: 18),
                    filled: true,
                    fillColor: scaffoldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 7 – Remaining Amount
                _buildSectionHeader(_getText('sec7Title'), primaryColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scaffoldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getText('grandTotal'), style: TextStyle(color: subTextColor, fontSize: 12)),
                          Text("₹${grandTotal.toStringAsFixed(0)}", style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getText('advance'), style: TextStyle(color: subTextColor, fontSize: 12)),
                          Text("₹${advance.toStringAsFixed(0)}", style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getText('remaining'), style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("₹${remaining.toStringAsFixed(0)}", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 8 – Payment Method
                _buildSectionHeader(_getText('sec8Title'), primaryColor),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: widget.selectedPaymentMethod,
                  dropdownColor: surfaceColor,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: scaffoldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                  items: ['Cash', 'UPI', 'Card', 'Bank Transfer'].map((method) {
                    String translatedLabel = method == 'Cash'
                        ? _getText('cash')
                        : method == 'UPI'
                            ? _getText('upi')
                            : method == 'Card'
                                ? _getText('card')
                                : _getText('bankTransfer');
                    return DropdownMenuItem(value: method, child: Text(translatedLabel));
                  }).toList(),
                  onChanged: (val) => widget.onPaymentMethodChanged(val!),
                ),
                const SizedBox(height: 16),

                // Section 9 – Payment Status
                _buildSectionHeader(_getText('sec9Title'), primaryColor),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentStatus = 'Paid';
                            _isManualStatusSelected = true;
                          });
                        },
                        child: _buildStatusChip('Paid', _getText('paid'), Colors.green),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentStatus = 'Partial';
                            _isManualStatusSelected = true;
                          });
                        },
                        child: _buildStatusChip('Partial', _getText('partial'), Colors.orange),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentStatus = 'Due';
                            _isManualStatusSelected = true;
                          });
                        },
                        child: _buildStatusChip('Due', _getText('due'), Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 10 – Notes
                _buildSectionHeader(_getText('sec10Title'), primaryColor),
                const SizedBox(height: 8),
                TextFormField(
                  controller: widget.paymentNotesController,
                  maxLines: 2,
                  style: TextStyle(color: textColor, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: _getText('notesHint'),
                    hintStyle: TextStyle(color: subTextColor, fontSize: 11),
                    filled: true,
                    fillColor: scaffoldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
    );
  }

  Widget _buildStatusChip(String statusKey, String label, Color color) {
    bool isSelected = _paymentStatus == statusKey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? color : Colors.grey.shade400, width: isSelected ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 14, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}