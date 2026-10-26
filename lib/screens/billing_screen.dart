import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import '../database.dart';

class BillingScreen extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String userEmail;

  const BillingScreen({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.userEmail,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _customerSearchController = TextEditingController();
  
  bool _isLoading = false;
  String? _searchError;
  
  String? _foundCustomerId;
  String? _customerName;
  List<Map<String, dynamic>> _allCustomerOrders = [];
  String? _selectedUndeliveredOrderId;

  Map<String, dynamic>? _invoiceData;
  List<Map<String, dynamic>> _matchedCustomerSuggestions = [];
  bool _showSuggestions = false;

  // --- Shop Information Variables ---
  Map<String, dynamic>? _shopInfoData;

  @override
  void initState() {
    super.initState();
    _loadShopInformation(); 
  }

  Future<void> _loadShopInformation() async {
    try {
      Map<String, dynamic>? shopData = await DatabaseService.fetchShopInformation(widget.userEmail);
      if (shopData != null && mounted) {
        setState(() {
          _shopInfoData = shopData;
        });
      }
    } catch (e) {
      debugPrint("Error loading shop info in billing: $e");
    }
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'billingTitle': 'Invoice & Billing',
        'customerSearchHint': 'Search by ID, Name or Mobile...',
        'searchCustomer': 'Search Customer',
        'selectOrderHint': 'Select Order ID',
        'noData': 'Search Customer to load orders.',
        'invoiceDetails': 'Invoice & Garment Details',
        'garmentDetails': 'Garments List',
        'grandTotal': 'Grand Total',
        'paidAmount': 'Paid Amount',
        'dueAmount': 'Due Amount',
        'print': 'Print',
        'share': 'Share',
        'download': 'Download PDF',
      },
      'Hindi': {
        'billingTitle': 'इनवॉइस और बिलिंग',
        'customerSearchHint': 'आईडी, नाम या मोबाइल नंबर से खोजें...',
        'searchCustomer': 'ग्राहक खोजें',
        'selectOrderHint': 'ऑर्डर आईडी चुनें',
        'noData': 'ऑर्डर देखने के लिए ग्राहक खोजें।',
        'invoiceDetails': 'इनवॉइस और गार्मेंट विवरण',
        'garmentDetails': 'गार्मेंट्स सूची',
        'grandTotal': 'कुल योग',
        'paidAmount': 'भुगतान राशि',
        'dueAmount': 'शेष राशि',
        'print': 'प्रिंट',
        'share': 'शेयर',
        'download': 'पीडीएफ डाउनलोड',
      },
      'Marathi': {
        'billingTitle': 'इनव्हॉइस आणि बिलिंग',
        'customerSearchHint': 'आयडी, नाव किंवा मोबाईल नंबर शोधा...',
        'searchCustomer': 'ग्राहक शोधा',
        'selectOrderHint': 'ऑर्डर आयडी निवडा',
        'noData': 'ऑर्डर लोड करण्यासाठी ग्राहक शोधा.',
        'invoiceDetails': 'इनव्हॉइस आणि कपडे तपशील',
        'garmentDetails': 'कपड्यांची सूची',
        'grandTotal': 'एकूण रक्कम',
        'paidAmount': 'भरलेली रक्कम',
        'dueAmount': 'बाकी रक्कम',
        'print': 'प्रिंट',
        'share': 'शेअर',
        'download': 'PDF डाउनलोड',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? key;
  }

  // --- HTML Special Character Escaper ---
  String _escapeHtml(Object? value) {
    if (value == null) return '';
    return value.toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _matchedCustomerSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      List<Map<String, dynamic>> customers = await DatabaseService.fetchCustomersFromFirebase(widget.userEmail);
      String cleanQuery = query.trim().toUpperCase();

      List<Map<String, dynamic>> matches = customers.where((cust) {
        String cId = (cust['id'] ?? '').toString().toUpperCase();
        String cName = (cust['full_name'] ?? cust['name'] ?? '').toString().toUpperCase();
        String cPhone = (cust['phone'] ?? cust['mobile'] ?? '').toString().toUpperCase();
        
        return cId.contains(cleanQuery) || cName.contains(cleanQuery) || cPhone.contains(cleanQuery);
      }).toList();

      setState(() {
        _matchedCustomerSuggestions = matches;
        _showSuggestions = matches.isNotEmpty;
      });
    } catch (e) {
      debugPrint("Error filtering customers: $e");
    }
  }

  void _selectCustomer(Map<String, dynamic> matchedCustomer) {
    String foundId = matchedCustomer['id'] ?? '';
    String foundName = matchedCustomer['full_name'] ?? matchedCustomer['name'] ?? 'Unknown';
    String foundPhone = matchedCustomer['phone'] ?? matchedCustomer['mobile'] ?? 'N/A';
    
    _customerSearchController.text = foundName;
    setState(() {
      _showSuggestions = false;
      _foundCustomerId = foundId;
      _customerName = foundName;
      _searchError = null;
      _selectedUndeliveredOrderId = null;
      _invoiceData = null;
    });

    var rawOrders = matchedCustomer['orderHistory'];
    List allOrders = [];
    if (rawOrders is List) {
      allOrders = rawOrders;
    } else if (rawOrders is Map) {
      allOrders = rawOrders.values.toList();
    }

    List<Map<String, dynamic>> loadedOrders = [];
    for (var ord in allOrders) {
      if (ord is Map) {
        var details = ord['order_details'] is Map ? ord['order_details'] : {};
        String orderId = (ord['id'] ?? details['order_id'] ?? 'ORD-UNKNOWN').toString();
        String status = (details['status'] ?? 'Pending').toString();
        
        loadedOrders.add({
          'id': orderId,
          'status': status,
          'isDelivered': status.toLowerCase() == 'delivered',
          'customerPhone': foundPhone,
          'order_details': details,
          'payment_details': ord['payment_details'] is Map ? ord['payment_details'] : {}
        });
      }
    }

    loadedOrders.sort((a, b) {
      bool aDelivered = a['isDelivered'];
      bool bDelivered = b['isDelivered'];
      if (aDelivered == bDelivered) return 0;
      return aDelivered ? 1 : -1;
    });

    setState(() {
      _allCustomerOrders = loadedOrders;
      if (loadedOrders.isEmpty) {
        _searchError = "Customer found, but orderHistory list is empty!";
      }
    });
  }

  Future<void> _searchCustomerDirect(String customerQuery) async {
    if (customerQuery.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      List<Map<String, dynamic>> customers = await DatabaseService.fetchCustomersFromFirebase(widget.userEmail);
      String cleanQuery = customerQuery.trim().toUpperCase();
      Map<String, dynamic>? matchedCustomer;

      for (var cust in customers) {
        String cId = (cust['id'] ?? '').toString().toUpperCase();
        String cName = (cust['full_name'] ?? cust['name'] ?? '').toString().toUpperCase();
        String cPhone = (cust['phone'] ?? cust['mobile'] ?? '').toString().toUpperCase();
        
        if (cId == cleanQuery || cName.contains(cleanQuery) || cPhone == cleanQuery) {
          matchedCustomer = cust;
          break;
        }
      }

      setState(() => _isLoading = false);

      if (matchedCustomer != null) {
        _selectCustomer(matchedCustomer);
      } else {
        setState(() {
          _searchError = "No customer found for '$customerQuery'";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchError = "Error: ${e.toString()}";
      });
    }
  }

  void _onOrderSelected(String? orderId) {
    if (orderId == null) return;
    setState(() {
      _selectedUndeliveredOrderId = orderId;
    });

    Map<String, dynamic>? selectedOrder;
    for (var ord in _allCustomerOrders) {
      if (ord['id'] == orderId) {
        selectedOrder = ord;
        break;
      }
    }

    if (selectedOrder != null) {
      var orderDetails = selectedOrder['order_details'] ?? {};
      var paymentDetails = selectedOrder['payment_details'] ?? {};
      var rawGarments = orderDetails['garments'];

      String orderDate = selectedOrder['order_date'] ?? orderDetails['order_date'] ?? selectedOrder['orderDate'] ?? orderDetails['orderDate'] ?? 'N/A';
      String deliveryDate = selectedOrder['delivery_date'] ?? orderDetails['delivery_date'] ?? selectedOrder['deliveryDate'] ?? orderDetails['deliveryDate'] ?? 'N/A';
      String customerPhone = selectedOrder['customerPhone'] ?? 'N/A';

      List<Map<String, dynamic>> safeGarmentsList = [];
      if (rawGarments is List) {
        for (var g in rawGarments) {
          if (g is Map) {
            var extractedRate = g['rate'] ?? g['price'] ?? g['amount'] ?? 0;
            safeGarmentsList.add({
              'name': g['name']?.toString() ?? g['item_name']?.toString() ?? 'Item',
              'qty': g['qty'] ?? g['quantity'] ?? 1,
              'rate': extractedRate,
            });
          } else {
            safeGarmentsList.add({'name': g.toString(), 'qty': 1, 'rate': 0});
          }
        }
      } else if (rawGarments is String) {
        List<String> splitGarments = rawGarments.split(',');
        for (var item in splitGarments) {
          safeGarmentsList.add({
            'name': item.trim(),
            'qty': 1,
            'rate': 0,
          });
        }
      } else if (rawGarments is Map) {
        var extractedRate = rawGarments['rate'] ?? rawGarments['price'] ?? 0;
        safeGarmentsList.add({
          'name': rawGarments['name']?.toString() ?? 'Item',
          'qty': rawGarments['qty'] ?? 1,
          'rate': extractedRate,
        });
      }

      double grossTotal = double.tryParse(
        paymentDetails['gross_total']?.toString() ?? 
        paymentDetails['total']?.toString() ?? '0'
      ) ?? 0;

      double discount = double.tryParse(
        paymentDetails['discount_amount']?.toString() ?? '0'
      ) ?? 0;

      double subtotal = double.tryParse(
        paymentDetails['subtotal']?.toString() ?? '0'
      ) ?? 0;
      
      if (subtotal == 0 && grossTotal > 0) {
        subtotal = grossTotal - discount;
      }

      setState(() {
        _invoiceData = {
          'invoiceNo': selectedOrder!['id'],
          'orderId': selectedOrder['id'],
          'customerName': _customerName,
          'customerId': _foundCustomerId,
          'customerPhone': customerPhone,
          'orderStatus': orderDetails['status'] ?? 'Pending',
          'order_date': orderDate,
          'delivery_date': deliveryDate,
          'subtotal': subtotal,
          'discount': discount,
          'grandTotal': grossTotal,
          'paidAmount': double.tryParse(paymentDetails['advance']?.toString() ?? '0') ?? 0,
          'dueAmount': double.tryParse(paymentDetails['due']?.toString() ?? '0') ?? 0,
          'garments': safeGarmentsList,
        };
      });
    }
  }

  // --- SAFE HTML BASED PDF GENERATOR ---
  Future<Uint8List> _generateHtmlPdfBytes({int copies = 1}) async {
    final orderDate = _escapeHtml(_invoiceData!['order_date'] ?? _invoiceData!['orderDate'] ?? 'N/A');
    final deliveryDate = _escapeHtml(_invoiceData!['delivery_date'] ?? _invoiceData!['deliveryDate'] ?? 'N/A');
    final customerId = _escapeHtml(_invoiceData!['customerId'] ?? 'N/A');
    final customerPhone = _escapeHtml(_invoiceData!['customerPhone'] ?? 'N/A');
    final customerName = _escapeHtml(_invoiceData!['customerName'] ?? 'N/A');

    final shopName = _escapeHtml(_shopInfoData?['shop_name'] ?? 'MY BOUTIQUE / SHOP');
    final shopAddress = _escapeHtml(_shopInfoData?['address'] ?? 'Shop Address Here');
    final shopPhone = _escapeHtml(_shopInfoData?['phone'] ?? '0000000000');
    final shopPhotoBase64 = _shopInfoData?['photo'] ?? '';

    String imagesHtmlTag = '';
    if (shopPhotoBase64.startsWith('data:image')) {
      imagesHtmlTag = '<img src="$shopPhotoBase64" width="55" height="55" style="object-fit: contain;" />';
    } else {
      imagesHtmlTag = '<div style="font-weight:bold; font-size:9px;">Scan & Pay via UPI</div>';
    }

    final garments = _invoiceData!['garments'] as List;
    final grandTotal = _invoiceData!['grandTotal'] ?? 0;
    final discount = _invoiceData!['discount'] ?? 0;
    final subtotal = _invoiceData!['subtotal'] ?? 0;
    final paidAmount = _invoiceData!['paidAmount'] ?? 0;
    final dueAmount = _invoiceData!['dueAmount'] ?? 0;
    final orderStatus = _escapeHtml(_invoiceData!['orderStatus'].toString().toUpperCase());
    final orderId = _escapeHtml(_invoiceData!['orderId'] ?? '');

    List<String> copyBlocks = [];
    for (int i = 0; i < copies; i++) {
      final isCopy = i > 0;
      final copyLabel = isCopy ? "DUPLICATE - MERCHANT COPY" : "ORIGINAL - CUSTOMER COPY";

      String garmentsRows = garments.map((g) {
        double qty = double.tryParse(g['qty'].toString()) ?? 1;
        double rate = double.tryParse(g['rate'].toString()) ?? 0;
        double amt = rate * qty;
        String itemName = _escapeHtml(g['name']);
        return '''
          <tr>
            <td style="width: 45%;">$itemName</td>
            <td style="width: 20%; text-align: center;">$rate</td>
            <td style="width: 10%; text-align: center;">${qty.toInt()}</td>
            <td style="width: 25%; text-align: right;">$amt</td>
          </tr>
        ''';
      }).join('');

      String cutLineHtml = (isCopy || (i < copies - 1)) 
          ? '<div class="cut-line">- - - - - - - - - - CUT HERE - - - - - - - - - -</div>' 
          : '';

      copyBlocks.add('''
        <div class="receipt-section">
          <div class="center">
            <span class="badge">$copyLabel</span>
            <div class="shop-title">$shopName</div>
            <div class="shop-info">$shopAddress</div>
            <div class="shop-info">Phone: $shopPhone</div>
          </div>
          
          <div class="line-equals">=======================================================================</div>
          <div class="center bold">INVOICE / CASH MEMO</div>
          <div class="line-equals">=======================================================================</div>

          <table class="meta-table">
            <tr>
              <td class="label-col">Customer ID</td>
              <td class="colon-col">:</td>
              <td class="val-col">$customerId</td>
            </tr>
            <tr>
              <td class="label-col">Order ID</td>
              <td class="colon-col">:</td>
              <td class="val-col">$orderId</td>
            </tr>
            <tr>
              <td class="label-col">Order Date</td>
              <td class="colon-col">:</td>
              <td class="val-col">$orderDate</td>
            </tr>
            <tr>
              <td class="label-col">Delivery Date</td>
              <td class="colon-col">:</td>
              <td class="val-col">$deliveryDate</td>
            </tr>
          </table>

          <div class="line-dash">-----------------------------------------------------------------------</div>
          
          <table class="meta-table">
            <tr>
              <td class="label-col">Customer</td>
              <td class="colon-col">:</td>
              <td class="val-col">$customerName</td>
            </tr>
            <tr>
              <td class="label-col">Mobile</td>
              <td class="colon-col">:</td>
              <td class="val-col">$customerPhone</td>
            </tr>
          </table>

          <div class="line-dash">-----------------------------------------------------------------------</div>

          <table class="items-table">
            <tr class="bold">
              <td style="width: 45%;">Item</td>
              <td style="width: 20%; text-align: center;">Rate</td>
              <td style="width: 10%; text-align: center;">Qty</td>
              <td style="width: 25%; text-align: right;">Amount</td>
            </tr>
          </table>
          
          <div class="line-dash">-----------------------------------------------------------------------</div>

          <table class="items-table">
            $garmentsRows
          </table>

          <div class="line-dash">-----------------------------------------------------------------------</div>

          <div class="grand-total-box">
            <span>GRAND TOTAL</span>
            <span style="float: right;">Rs. $grandTotal</span>
          </div>

          <table class="meta-table" style="margin-top: 4px;">
            <tr><td>Discount</td><td style="text-align: right;">- Rs. $discount</td></tr>
            <tr><td>Subtotal</td><td style="text-align: right;">Rs. $subtotal</td></tr>
          </table>

          <div class="line-dash">-----------------------------------------------------------------------</div>

          <table class="meta-table">
            <tr><td>Paid Amount</td><td style="text-align: right;">Rs. $paidAmount</td></tr>
            <tr><td>Due Amount</td><td style="text-align: right;">Rs. $dueAmount</td></tr>
          </table>

          <div class="line-dash">-----------------------------------------------------------------------</div>

          <table class="meta-table">
            <tr><td>Payment Status</td><td>: PARTIAL</td></tr>
            <tr><td>Order Status</td><td>: $orderStatus</td></tr>
          </table>

          <div class="center" style="margin-top: 8px;">
            $imagesHtmlTag
          </div>

          <div class="line-equals" style="margin-top: 6px;">=======================================================================</div>
          <div class="center bold" style="font-size: 8px;">Thank You! Visit Again.</div>
          <div class="center" style="font-size: 6px;">Terms & Conditions: Goods once sold will not taken back.</div>

          $cutLineHtml
        </div>
      ''');
    }

    String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;700&display=swap');
          body {
            font-family: 'Noto Sans Devanagari', Arial, sans-serif;
            width: 72mm;
            margin: 0 auto;
            padding: 2px;
            font-size: 9px;
            color: #000;
            background: #fff;
          }
          .center { text-align: center; }
          .bold { font-weight: bold; }
          .badge {
            border: 0.5px solid #000;
            padding: 1px 4px;
            font-size: 6px;
            font-weight: bold;
            display: inline-block;
          }
          .shop-title { font-size: 13px; font-weight: bold; margin-top: 2px; }
          .shop-info { font-size: 7px; }
          .line-equals { font-size: 7px; text-align: center; font-family: monospace; letter-spacing: -1px; margin: 2px 0; }
          .line-dash { font-size: 7px; text-align: center; font-family: monospace; letter-spacing: -1px; margin: 2px 0; color: #333; }
          .cut-line { font-size: 7px; text-align: center; color: #666; margin: 10px 0; font-family: monospace; }
          table { width: 100%; border-collapse: collapse; }
          td, th { font-size: 7px; padding: 1px 0; vertical-align: top; }
          
          /* 3-Column Alignment CSS for perfectly aligned colons */
          .meta-table td { padding: 1px 0px; }
          .meta-table .label-col { width: 72px; }
          .meta-table .colon-col { width: 12px; text-align: center; }
          .meta-table .val-col { text-align: left; }

          .items-table td { padding: 1px 2px; }
          .grand-total-box {
            background-color: #e0e0e0;
            padding: 3px 4px;
            font-weight: bold;
            font-size: 8px;
          }
        </style>
      </head>
      <body>
        ${copyBlocks.join('')}
      </body>
      </html>
    ''';

    Directory tempDir = await getTemporaryDirectory();
    final generatedPdfFile = await FlutterNativeHtmlToPdf().convertHtmlToPdf(
      html: htmlContent,
      targetDirectory: tempDir.path,
      targetName: 'Invoice_${_invoiceData!['orderId']}_SingleCopy',
    );

    return await generatedPdfFile!.readAsBytes();
  }

  Future<void> _printInvoice() async {
    if (_invoiceData == null) return;
    final pdfBytes = await _generateHtmlPdfBytes(copies: 1);
    await Printing.layoutPdf(
      onLayout: (pw.PdfPageFormat format) async => pdfBytes,
    );
  }

  Future<void> _shareInvoice() async {
    if (_invoiceData == null) return;
    final pdfBytes = await _generateHtmlPdfBytes(copies: 1);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${_invoiceData!['orderId']}_SingleCopy.pdf',
    );
  }

  Future<void> _downloadPdf() async {
    if (_invoiceData == null) return;
    try {
      final pdfBytes = await _generateHtmlPdfBytes(copies: 1);
      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String baseFileName = 'Invoice_${_invoiceData!['orderId']}_SingleCopy';
      String extension = '.pdf';
      String filePath = '${directory!.path}/$baseFileName$extension';
      
      int counter = 1;
      while (File(filePath).existsSync()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${directory.path}/${baseFileName}_$timestamp$extension';
        counter++;
        if (counter > 5) break;
      }

      final file = File(filePath);
      file.writeAsBytesSync(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Downloaded successfully to: ${file.path}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF18181B) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    Color textColor = widget.isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
    Color subTextColor = widget.isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    const Color primaryPurple = Color(0xFF673AB7);

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        title: Text(_getText('billingTitle'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Search Customer (ID / Name / Mobile)", style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF27272A) : const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _customerSearchController,
                            style: TextStyle(color: textColor, fontSize: 13),
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: _getText('customerSearchHint'),
                              hintStyle: TextStyle(color: subTextColor, fontSize: 12),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (val) => _searchCustomerDirect(val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _searchCustomerDirect(_customerSearchController.text),
                        icon: const Icon(Icons.search, size: 16),
                        label: Text(_getText('searchCustomer')),
                      ),
                    ],
                  ),
                  
                  if (_showSuggestions && _matchedCustomerSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF27272A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _matchedCustomerSuggestions.length,
                        itemBuilder: (context, index) {
                          var cust = _matchedCustomerSuggestions[index];
                          String name = cust['full_name'] ?? cust['name'] ?? 'Unknown';
                          String id = cust['id'] ?? '';
                          String mobile = cust['phone'] ?? cust['mobile'] ?? '';
                          return ListTile(
                            dense: true,
                            title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text("ID: $id | Mobile: $mobile", style: TextStyle(color: subTextColor, fontSize: 11)),
                            onTap: () => _selectCustomer(cust),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_foundCustomerId != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Customer: $_customerName", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("ID: $_foundCustomerId", style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 20),
                    Text("Select Order ID", style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF27272A) : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUndeliveredOrderId,
                          hint: Text(_getText('selectOrderHint'), style: TextStyle(color: subTextColor, fontSize: 12)),
                          isExpanded: true,
                          dropdownColor: widget.isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                          items: _allCustomerOrders.map((ord) {
                            var details = ord['order_details'] ?? {};
                            String status = (details['status'] ?? 'Pending').toString();
                            bool isDelivered = status.toLowerCase() == 'delivered';
                            
                            return DropdownMenuItem<String>(
                              value: ord['id'],
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Order ID: ${ord['id']}",
                                    style: TextStyle(color: textColor, fontSize: 13),
                                  ),
                                  Text(
                                    "[$status]",
                                    style: TextStyle(
                                      color: isDelivered ? Colors.green : Colors.amber.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _onOrderSelected,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: primaryPurple)))
            else if (_searchError != null)
              Center(child: Padding(padding: const EdgeInsets.all(15.0), child: Text(_searchError!, style: const TextStyle(color: Colors.redAccent))))
            else if (_invoiceData == null)
              Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text(_getText('noData'), style: TextStyle(color: subTextColor))))
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 18, color: primaryPurple),
                        const SizedBox(width: 6),
                        Text(_getText('invoiceDetails'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRowItem("Order ID", ": ${_invoiceData!['orderId']}", textColor),
                    const SizedBox(height: 6),
                    _buildRowItem("Order Status", ": ${_invoiceData!['orderStatus']}", Colors.amber.shade700),
                    
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.checkroom, size: 16, color: primaryPurple),
                        const SizedBox(width: 6),
                        Text(_getText('garmentDetails'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.isDarkMode ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: const BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(7),
                                topRight: Radius.circular(7),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text("Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text("Rate (Rs.)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 1, child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text("Amount (Rs.)", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ((_invoiceData!['garments'] is List ? _invoiceData!['garments'] : []) as List).length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: widget.isDarkMode ? const Color(0xFF27272A) : const Color(0xFFF1F3F5),
                            ),
                            itemBuilder: (context, index) {
                              var garmentsList = (_invoiceData!['garments'] is List ? _invoiceData!['garments'] : []) as List;
                              var garmentMap = garmentsList[index] is Map ? garmentsList[index] : {};
                              String itemName = garmentMap['name']?.toString() ?? 'Item';
                              double itemQty = double.tryParse(garmentMap['qty']?.toString() ?? '1') ?? 1;
                              double itemRate = double.tryParse(garmentMap['rate']?.toString() ?? '0') ?? 0;
                              double totalAmount = itemRate * itemQty;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.checkroom, size: 16, color: primaryPurple),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              itemName,
                                              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "$itemRate",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: textColor, fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        "${itemQty.toInt()}",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: textColor, fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "$totalAmount",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 24),
                    _buildAmountRow(_getText('grandTotal'), "Rs.${_invoiceData!['grandTotal']}", primaryPurple, primaryPurple, true),
                    const SizedBox(height: 6),
                    _buildAmountRow("Discount", "-Rs.${_invoiceData!['discount']}", Colors.redAccent, subTextColor, false),
                    const SizedBox(height: 6),
                    _buildAmountRow("Subtotal", "Rs.${_invoiceData!['subtotal']}", textColor, subTextColor, false),
                    
                    const Divider(height: 20),
                    _buildAmountRow(_getText('paidAmount'), "Rs.${_invoiceData!['paidAmount']}", Colors.green, subTextColor, false),
                    const SizedBox(height: 6),
                    _buildAmountRow(_getText('dueAmount'), "Rs.${_invoiceData!['dueAmount']}", Colors.red, subTextColor, true),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _printInvoice,
                      icon: const Icon(Icons.print, size: 16),
                      label: Text(_getText('print'), style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _shareInvoice,
                      icon: const Icon(Icons.share, size: 16),
                      label: Text(_getText('share'), style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceColor,
                        foregroundColor: textColor,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.download, size: 16, color: primaryPurple),
                      label: Text(_getText('download'), style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, String value, Color textColor) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Text(value, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAmountRow(String label, String amount, Color color, Color labelColor, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 13 : 12, color: labelColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(amount, style: TextStyle(fontSize: isBold ? 14 : 12, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}