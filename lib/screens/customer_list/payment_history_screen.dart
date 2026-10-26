import 'package:flutter/material.dart';
import '../../database.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  final bool isDarkMode;
  final Map<String, String> translations;
  final String userEmail; 
  final Function(String orderId, double paidAmount, String paymentMethod)? onPayDue;

  const PaymentHistoryScreen({
    super.key, 
    required this.customer, 
    required this.isDarkMode, 
    required this.translations,
    required this.userEmail, 
    this.onPayDue,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  String _t(String key) => widget.translations[key] ?? key;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPayDueDialog(String orderId, double currentDue) {
    final TextEditingController amountController = TextEditingController(text: currentDue.toString());
    String selectedPaymentMethod = 'Cash'; 

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.isDarkMode ? const Color(0xFF18181B) : Colors.white,
              title: Text(_t('payDueAmount') != 'payDueAmount' ? _t('payDueAmount') : 'Pay Due Amount', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_t('orderId') != 'orderId' ? _t('orderId') : 'Order ID'}: $orderId', style: TextStyle(color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text('${_t('currentDue') != 'currentDue' ? _t('currentDue') : 'Current Due'}: ₹$currentDue', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: _t('enterAmountToPay') != 'enterAmountToPay' ? _t('enterAmountToPay') : 'Enter Amount to Pay',
                      labelStyle: TextStyle(color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedPaymentMethod,
                    dropdownColor: widget.isDarkMode ? const Color(0xFF18181B) : Colors.white,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: _t('paymentMethod') != 'paymentMethod' ? _t('paymentMethod') : 'Payment Method',
                      labelStyle: TextStyle(color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
                    ),
                    items: ['Cash','UPI',]
                        .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_t('cancel') != 'cancel' ? _t('cancel') : 'Cancel', style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                  onPressed: () async {
                    double paidAmount = double.tryParse(amountController.text) ?? 0;
                    if (paidAmount <= 0 || paidAmount > currentDue) {
                      Navigator.pop(dialogContext);
                      return;
                    }

                    Navigator.pop(dialogContext); 
                    
                    setState(() => _isLoading = true);

                    String customerId = widget.customer['customer_id']?.toString() ?? widget.customer['id']?.toString() ?? '';

                    Map<String, dynamic> result = {};
                    try {
                      result = await DatabaseService.payCustomerDue(
                        userEmail: widget.userEmail,
                        customerId: customerId,
                        orderId: orderId,
                        paidAmount: paidAmount,
                        paymentMethod: selectedPaymentMethod,
                      );
                    } catch (e) {
                      result = {'status': false, 'message': 'Connection error: $e'};
                    }

                    if (!mounted) return;

                    setState(() => _isLoading = false);

                    if (result['status'] == true) {
                      if (widget.onPayDue != null) {
                        widget.onPayDue!(orderId, paidAmount, selectedPaymentMethod);
                      }

                      setState(() {
                        var rawOrders = widget.customer['orders'] ?? widget.customer['orderHistory'];
                        if (rawOrders is List) {
                          for (var ord in rawOrders) {
                            if (ord is Map) {
                              var ordMap = Map<String, dynamic>.from(ord);
                              String curOrdId = ordMap['id']?.toString() ?? ordMap['order_details']?['order_id']?.toString() ?? '';
                              if (curOrdId == orderId) {
                                var payDetails = ordMap['payment_details'];
                                if (payDetails is Map) {
                                  double oldDue = double.tryParse(payDetails['due']?.toString() ?? '0') ?? 0;
                                  double oldAdv = double.tryParse(payDetails['advance']?.toString() ?? '0') ?? 0;
                                  payDetails['due'] = (oldDue - paidAmount).toStringAsFixed(2);
                                  payDetails['advance'] = (oldAdv + paidAmount).toStringAsFixed(2);
                                }
                              }
                            }
                          }
                        } else if (rawOrders is Map) {
                          rawOrders.forEach((key, val) {
                            if (val is Map) {
                              var ordMap = Map<String, dynamic>.from(val);
                              String curOrdId = ordMap['id']?.toString() ?? ordMap['order_details']?['order_id']?.toString() ?? key;
                              if (curOrdId == orderId) {
                                var payDetails = ordMap['payment_details'];
                                if (payDetails is Map) {
                                  double oldDue = double.tryParse(payDetails['due']?.toString() ?? '0') ?? 0;
                                  double oldAdv = double.tryParse(payDetails['advance']?.toString() ?? '0') ?? 0;
                                  payDetails['due'] = (oldDue - paidAmount).toStringAsFixed(2);
                                  payDetails['advance'] = (oldAdv + paidAmount).toStringAsFixed(2);
                                }
                              }
                            }
                          });
                        }
                      });
                    }
                  },
                  child: Text(_t('confirmPayment') != 'confirmPayment' ? _t('confirmPayment') : 'Confirm Payment', style: const TextStyle(color: Colors.white)),
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
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF18181B) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    Color textColor = widget.isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
    Color subTextColor = widget.isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    const Color primaryThemeColor = Color(0xFF7C3AED);

    String customerName = widget.customer['name']?.toString() ?? 'Unknown';
    String customerId = widget.customer['customer_id']?.toString() ?? widget.customer['id']?.toString() ?? 'N/A';

    var rawOrders = widget.customer['orders'] ?? widget.customer['orderHistory'] ?? [];
    List<Map<String, dynamic>> orders = [];

    if (rawOrders is Map) {
      rawOrders.forEach((key, value) {
        if (value is Map) {
          var orderMap = Map<String, dynamic>.from(value);
          orderMap['firebase_key'] = key.toString();
          orders.add(orderMap);
        }
      });
    } else if (rawOrders is List) {
      for (var item in rawOrders) {
        if (item is Map) {
          orders.add(Map<String, dynamic>.from(item));
        }
      }
    }

    List<Map<String, dynamic>> filteredOrders = orders.where((orderNode) {
      var orderDetails = orderNode['order_details'] is Map 
          ? Map<String, dynamic>.from(orderNode['order_details']) 
          : orderNode;
      var paymentDetails = orderNode['payment_details'] is Map 
          ? Map<String, dynamic>.from(orderNode['payment_details']) 
          : {};

      String orderId = orderDetails['order_id']?.toString() ?? orderNode['firebase_key']?.toString() ?? orderDetails['id']?.toString() ?? '';
      String paymentMethod = paymentDetails['payment_method']?.toString() ?? '';
      String notes = paymentDetails['notes']?.toString() ?? '';
      String grossTotal = paymentDetails['gross_total']?.toString() ?? '';
      String total = paymentDetails['total']?.toString() ?? '';
      String due = paymentDetails['due']?.toString() ?? '';

      String query = _searchQuery.toLowerCase();
      return orderId.toLowerCase().contains(query) ||
             paymentMethod.toLowerCase().contains(query) ||
             notes.toLowerCase().contains(query) ||
             grossTotal.toLowerCase().contains(query) ||
             total.toLowerCase().contains(query) ||
             due.toLowerCase().contains(query);
    }).toList();

    double grossTotalSum = 0;
    double totalSum = 0;
    double advanceSum = 0;
    double dueSum = 0;

    for (var orderNode in orders) {
      var paymentDetails = orderNode['payment_details'] is Map 
          ? Map<String, dynamic>.from(orderNode['payment_details']) 
          : {};

      grossTotalSum += double.tryParse(paymentDetails['gross_total']?.toString() ?? '0') ?? 0;
      totalSum += double.tryParse(paymentDetails['total']?.toString() ?? '0') ?? 0;
      advanceSum += double.tryParse(paymentDetails['advance']?.toString() ?? '0') ?? 0;
      dueSum += double.tryParse(paymentDetails['due']?.toString() ?? '0') ?? 0;
    }

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: primaryThemeColor,
        title: Text(_t('paymentHistory'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryThemeColor))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: primaryThemeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_t('customer')} : $customerName ($customerId)', 
                      style: const TextStyle(color: primaryThemeColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _t('searchPlaceholder') != 'searchPlaceholder' ? _t('searchPlaceholder') : 'Search by Order ID, Gross Total, Total...',
                      hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: subTextColor, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: subTextColor, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryThemeColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? Center(child: Text(_t('noPaymentsFound'), style: TextStyle(color: subTextColor)))
                        : ListView.builder(
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              var orderNode = filteredOrders[index];
                              
                              var orderDetails = orderNode['order_details'] is Map 
                                  ? Map<String, dynamic>.from(orderNode['order_details']) 
                                  : orderNode;

                              String orderId = orderDetails['order_id']?.toString() ?? orderNode['firebase_key']?.toString() ?? orderDetails['id']?.toString() ?? 'ORD000${index + 1}';
                              
                              var paymentDetails = orderNode['payment_details'] is Map 
                                  ? Map<String, dynamic>.from(orderNode['payment_details']) 
                                  : {};

                              String grossTotal = paymentDetails['gross_total']?.toString() ?? '';
                              String advance = paymentDetails['advance']?.toString() ?? '';
                              String discountAmount = paymentDetails['discount_amount']?.toString() ?? '';
                              String discountPercent = paymentDetails['discount_percent']?.toString() ?? '';
                              String due = paymentDetails['due']?.toString() ?? '0';
                              String notes = paymentDetails['notes']?.toString() ?? '';
                              String paymentMethod = paymentDetails['payment_method']?.toString() ?? 'Cash';
                              String total = paymentDetails['total']?.toString() ?? '0';

                              double dueVal = double.tryParse(due) ?? 0;
                              bool hasDue = dueVal > 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: surfaceColor, 
                                  borderRadius: BorderRadius.circular(16), 
                                  border: Border.all(color: borderColor),
                                ),
                                child: ExpansionTile(
                                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                                  collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: primaryThemeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.payment, color: primaryThemeColor, size: 24),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(orderId, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: hasDue ? Colors.deepOrange.withOpacity(0.15) : Colors.teal.withOpacity(0.15), 
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          hasDue ? '${_t('due')} : ₹$due' : _t('paid'), 
                                          style: TextStyle(color: hasDue ? Colors.deepOrange : Colors.teal, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${_t('total')} : ₹$total  |  ${_t('method')} : $paymentMethod', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Divider(height: 1),
                                          const SizedBox(height: 10),
                                          _detailLine(_t('orderId'), orderId, textColor, subTextColor),
                                          _detailLine(_t('paymentMethod'), paymentMethod, textColor, subTextColor),
                                          if (grossTotal.isNotEmpty) _detailLine(_t('grossTotal'), '₹$grossTotal', textColor, subTextColor),
                                          if (discountAmount.isNotEmpty) _detailLine(_t('discountAmount'), '₹$discountAmount', textColor, subTextColor),
                                          if (discountPercent.isNotEmpty) _detailLine(_t('discountPercent'), '$discountPercent%', textColor, subTextColor),
                                          _detailLine(_t('netTotal'), '₹$total', primaryThemeColor, subTextColor),
                                          if (advance.isNotEmpty) _detailLine(_t('advance'), '₹$advance', textColor, subTextColor),            
                                          _detailLine(_t('dueAmount'), '₹$due', hasDue ? Colors.deepOrange : textColor, subTextColor),
                                          if (notes.isNotEmpty) _detailLine(_t('notes'), notes, textColor, subTextColor),
                                          
                                          if (hasDue) ...[
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.deepOrange,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                icon: const Icon(Icons.account_balance_wallet, size: 16),
                                                label: Text(_t('payDueAmount'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                onPressed: () => _showPayDueDialog(orderId, dueVal),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryCol(_t('grandTotal'), '₹${totalSum.toStringAsFixed(0)}', primaryThemeColor, subTextColor),
                        _summaryCol(_t('totalAdvance'), '₹${advanceSum.toStringAsFixed(0)}', Colors.teal, subTextColor),
                        _summaryCol(_t('totalDue'), '₹${dueSum.toStringAsFixed(0)}', Colors.deepOrange, subTextColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _detailLine(String label, String value, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _summaryCol(String title, String val, Color color, Color subTextColor) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: subTextColor)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}