import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database.dart';

class OrderHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  final bool isDarkMode;
  final Map<String, String> translations;
  final String userEmail; 
  final Function(String firebaseKey, String newStatus)? onUpdateStatus;
  final Function(String firebaseKey)? onDeleteOrder;

  const OrderHistoryScreen({
    super.key, 
    required this.customer, 
    required this.isDarkMode, 
    required this.translations,
    required this.userEmail, 
    this.onUpdateStatus,
    this.onDeleteOrder,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _t(String key) => widget.translations[key] ?? key;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString();
  }

  String _formatGarmentText(dynamic garmentData) {
    if (garmentData == null) return 'Custom Order';

    if (garmentData is List) {
      List<String> formattedItems = [];
      for (var item in garmentData) {
        if (item is Map) {
          String name = item['name']?.toString() ?? item['garment']?.toString() ?? '';
          var qtyVal = item['qty'] ?? item['quantity'];
          String qty = '';
          if (qtyVal != null) {
            double? parsedQty = double.tryParse(qtyVal.toString());
            if (parsedQty != null) {
              qty = parsedQty == parsedQty.roundToDouble() 
                  ? parsedQty.toInt().toString() 
                  : parsedQty.toString();
            } else {
              qty = qtyVal.toString();
            }
          }
          if (name.isNotEmpty) {
            formattedItems.add(qty.isNotEmpty ? '$name $qty' : name);
          }
        } else if (item != null) {
          formattedItems.add(item.toString());
        }
      }
      if (formattedItems.isNotEmpty) {
        return formattedItems.join(', ');
      }
    }

    if (garmentData is Map) {
      List<String> items = [];
      garmentData.forEach((key, value) {
        if (value != null && value is! Map && value is! List) {
          items.add("$key $value");
        } else if (value != null) {
          items.add(key.toString());
        }
      });
      if (items.isNotEmpty) {
        return items.join(', ');
      }
      return 'Custom Order';
    }

    String text = garmentData.toString().trim();
    if (text.isEmpty || text == '{}') return 'Custom Order';
    
    text = text.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
    return text;
  }

  Future<void> _sendCustomerNotification(String newStatus, Map<String, dynamic> orderNode) async {
    String customerPhone = _safeString(widget.customer['phone'] ?? widget.customer['mobile'] ?? '');
    String customerName = _safeString(widget.customer['name'] ?? 'Customer');
    var orderDetails = orderNode['order_details'] is Map 
        ? Map<String, dynamic>.from(orderNode['order_details']) 
        : orderNode;
    String orderId = _safeString(orderDetails['order_id'] ?? orderNode['firebase_key'] ?? 'N/A');

    if (customerPhone.isEmpty) return;

    String message = '';
    if (newStatus == 'Ready') {
      message = "नमस्कार $customerName,\n\n"
      "✂️ आपली ऑर्डर ($orderId) आता तयार आहे.\n"
      "आपण आपली ऑर्डर दुकानातून घेऊन जाऊ शकता.\n\n"
      "आपल्या भेटीची आम्हाला प्रतीक्षा आहे. 🙏";
    } else if (newStatus == 'Delivered') {
      message = "नमस्कार $customerName,\n\n"
      "✅ आपली ऑर्डर ($orderId) यशस्वीरित्या वितरित करण्यात आली आहे.\n\n"
      "आपल्या विश्वासाबद्दल मनःपूर्वक धन्यवाद! 🙏\n"
      "पुन्हा आपली सेवा करण्याची आम्हाला आनंदाने प्रतीक्षा आहे.\n\n";
    }

    if (message.isNotEmpty) {
      final Uri smsUri = Uri.parse("sms:$customerPhone?body=${Uri.encodeComponent(message)}");
      
      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        debugPrint("Error launching notification URL: $e");
      }
    }
  }

  void _confirmAndAdvanceStatus(Map<String, dynamic> orderNode) {
    var orderDetails = orderNode['order_details'] is Map 
        ? Map<String, dynamic>.from(orderNode['order_details']) 
        : orderNode;

    String currentStatus = _safeString(orderDetails['status'] ?? orderNode['status'] ?? 'Pending');
    String nextStatus = 'Pending';
    String actionTitle = '';
    String actionMessage = '';

    if (currentStatus == 'Pending') {
      nextStatus = 'Ready';
      actionTitle = _t('markReadyTitle') != 'markReadyTitle' ? _t('markReadyTitle') : 'Mark as Ready';
      actionMessage = _t('markReadyConfirm') != 'markReadyConfirm' ? _t('markReadyConfirm') : 'Are you sure you want to mark this order as Ready?';
    } else if (currentStatus == 'Ready') {
      nextStatus = 'Delivered';
      actionTitle = _t('markDeliveredTitle') != 'markDeliveredTitle' ? _t('markDeliveredTitle') : 'Mark as Delivered';
      actionMessage = _t('markDeliveredConfirm') != 'markDeliveredConfirm' ? _t('markDeliveredConfirm') : 'Are you sure you want to mark this order as Delivered?';
    } else {
      return;
    }

    Color surfaceColor = widget.isDarkMode ? const Color(0xFF18181B) : Colors.white;
    Color textColor = widget.isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
    Color subTextColor = widget.isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    const Color primaryThemeColor = Color(0xFF7C3AED);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            actionTitle,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            actionMessage,
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _t('no') != 'no' ? _t('no') : 'No',
                style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                
                String customerId = _safeString(widget.customer['customer_id'] ?? widget.customer['id']);
                String firebaseKey = _safeString(orderNode['firebase_key'] ?? orderDetails['order_id'] ?? orderNode['id']);

                if (customerId.isNotEmpty && firebaseKey.isNotEmpty) {
                  var result = await DatabaseService.updateOrderStatus(
                    userEmail: widget.userEmail,
                    customerId: customerId,
                    orderId: firebaseKey,
                    newStatus: nextStatus,
                  );

                  if (result['status'] == true) {
                    setState(() {
                      if (orderNode['order_details'] is Map) {
                        orderNode['order_details']['status'] = nextStatus;
                      } else {
                        orderNode['status'] = nextStatus;
                      }
                    });

                    await _sendCustomerNotification(nextStatus, orderNode);

                    if (widget.onUpdateStatus != null) {
                      widget.onUpdateStatus!(firebaseKey, nextStatus);
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'])),
                      );
                    }
                  }
                }
              },
              child: Text(
                _t('yes') != 'yes' ? _t('yes') : 'Yes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmAndDeleteOrder(Map<String, dynamic> orderNode) {
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF18181B) : Colors.white;
    Color textColor = widget.isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
    Color subTextColor = widget.isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _t('deleteOrderTitle') != 'deleteOrderTitle' ? _t('deleteOrderTitle') : 'Delete Order',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            _t('deleteOrderConfirm') != 'deleteOrderConfirm' ? _t('deleteOrderConfirm') : 'Are you sure you want to delete this order? This action cannot be undone.',
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _t('no') != 'no' ? _t('no') : 'No',
                style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                String customerId = _safeString(widget.customer['customer_id'] ?? widget.customer['id']);
                String firebaseKey = _safeString(orderNode['firebase_key'] ?? orderNode['id']);

                if (customerId.isNotEmpty && firebaseKey.isNotEmpty) {
                  var result = await DatabaseService.deleteOrder(
                    userEmail: widget.userEmail,
                    customerId: customerId,
                    orderId: firebaseKey,
                  );

                  if (result['status'] == true) {
                    setState(() {
                      if (widget.customer['orders'] is Map) {
                        (widget.customer['orders'] as Map).remove(firebaseKey);
                      } else if (widget.customer['orders'] is List) {
                        (widget.customer['orders'] as List).removeWhere((o) => o['firebase_key'] == firebaseKey || o['id'] == firebaseKey);
                      }
                    });

                    if (widget.onDeleteOrder != null) {
                      widget.onDeleteOrder!(firebaseKey);
                    }
                  }

                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                }
              },
              child: Text(
                _t('yes') != 'yes' ? _t('yes') : 'Yes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
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

    var rawOrders = widget.customer['orders'] ?? widget.customer['orderHistory'] ?? [];
    List<Map<String, dynamic>> orders = [];

    if (rawOrders is Map) {
      rawOrders.forEach((key, value) {
        if (value is Map) {
          var orderMap = Map<String, dynamic>.from(value);
          orderMap['firebase_key'] = key;
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

      String orderId = _safeString(orderDetails['order_id'] ?? orderNode['firebase_key'] ?? orderDetails['id']);
      String garment = _formatGarmentText(orderDetails['garments'] ?? orderDetails['item']);
      String designStyle = _safeString(orderDetails['design_style']);
      String clothDetail = _safeString(orderDetails['cloth_detail']);
      String notes = _safeString(orderDetails['notes']);
      String status = _safeString(orderDetails['status'] ?? orderNode['status']);

      String query = _searchQuery.toLowerCase();
      return orderId.toLowerCase().contains(query) ||
             garment.toLowerCase().contains(query) ||
             designStyle.toLowerCase().contains(query) ||
             clothDetail.toLowerCase().contains(query) ||
             notes.toLowerCase().contains(query) ||
             status.toLowerCase().contains(query);
    }).toList();

    // ─── UPDATED COUNT LOGIC ───────────────────────────────────────────
    int pendingCount = orders.where((o) {
      var details = o['order_details'] is Map ? o['order_details'] : o;
      String status = _safeString(details['status'] ?? o['status'] ?? 'Pending');
      return status == 'Pending';
    }).length;
    
    int readyCount = orders.where((o) {
      var details = o['order_details'] is Map ? o['order_details'] : o;
      String status = _safeString(details['status'] ?? o['status'] ?? 'Pending');
      return status == 'Ready';
    }).length;

    int completedCount = orders.where((o) {
      var details = o['order_details'] is Map ? o['order_details'] : o;
      String status = _safeString(details['status'] ?? o['status'] ?? 'Pending');
      return status == 'Delivered';
    }).length;
    // ───────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: primaryThemeColor,
        title: Text(_t('orderHistory'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
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
                  '${_t('customer')} : ${_safeString(widget.customer['name']).isNotEmpty ? widget.customer['name'] : 'Unknown'} (${_safeString(widget.customer['customer_id'] ?? widget.customer['id']).isNotEmpty ? widget.customer['customer_id'] ?? widget.customer['id'] : 'N/A'})', 
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
                  hintText: _t('searchOrders') != 'searchOrders' ? _t('searchOrders') : 'Search by Order ID, Garment, Status...',
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
                    ? Center(child: Text(_t('noOrdersFound'), style: TextStyle(color: subTextColor)))
                    : ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          var orderNode = filteredOrders[index];
                          
                          var orderDetails = orderNode['order_details'] is Map 
                              ? Map<String, dynamic>.from(orderNode['order_details']) 
                              : orderNode;

                          String orderId = _safeString(orderDetails['order_id'] ?? orderNode['firebase_key'] ?? orderDetails['id']);
                          if (orderId.isEmpty) orderId = 'ORD000${index + 1}';

                          String garment = _formatGarmentText(orderDetails['garments'] ?? orderDetails['item']);

                          String designStyle = _safeString(orderDetails['design_style']);
                          String clothDetail = _safeString(orderDetails['cloth_detail']);
                          String clothSource = _safeString(orderDetails['cloth_source']);
                          
                          String itemName = designStyle.isNotEmpty && clothDetail.isNotEmpty 
                              ? '$garment ($designStyle - $clothDetail)' 
                              : (designStyle.isNotEmpty ? '$garment ($designStyle)' : garment);

                          String orderDate = _safeString(orderDetails['order_date'] ?? orderDetails['date']);
                          String trialDate = _safeString(orderDetails['trial_date']);
                          String deliveryDate = _safeString(orderDetails['delivery_date']);
                          String priority = _safeString(orderDetails['priority']);
                          if (priority.isEmpty) priority = 'Normal';

                          String notes = _safeString(orderDetails['notes']);
                          String status = _safeString(orderDetails['status'] ?? orderNode['status']);
                          if (status.isEmpty) status = 'Pending';
                          
                          Color statusColor = Colors.deepOrange;
                          if (status == 'Ready') statusColor = Colors.blue;
                          if (status == 'Delivered') statusColor = Colors.teal;
                          
                          int colorCode = 0xFF7C3AED;
                          if (orderDetails['imageColorCode'] is int) {
                            colorCode = orderDetails['imageColorCode'];
                          } else if (orderNode['imageColorCode'] is int) {
                            colorCode = orderNode['imageColorCode'];
                          }
                          Color itemColor = Color(colorCode);

                          var measurementDetails = orderNode['measurement_details'];
                          Map<String, Map<String, dynamic>> orderGroupedGarments = {};

                          if (measurementDetails is Map) {
                            measurementDetails.forEach((mKey, mVal) {
                              String lowerKey = mKey.toLowerCase();
                              if (lowerKey == 'updated_at' || lowerKey == 'created_at' || lowerKey == 'notes') {
                                return;
                              } else if (mVal is Map) {
                                orderGroupedGarments[mKey] = Map<String, dynamic>.from(mVal);
                              } else {
                                List<String> parts = mKey.split('_');
                                String gName = parts.isNotEmpty ? parts[0] : garment;
                                String mField = parts.length > 1 ? parts.sublist(1).join('_') : mKey;

                                if (!orderGroupedGarments.containsKey(gName)) {
                                  orderGroupedGarments[gName] = {};
                                }
                                orderGroupedGarments[gName]![mField] = mVal;
                              }
                            });
                          }

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
                                decoration: BoxDecoration(color: itemColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.checkroom, color: itemColor, size: 24),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(orderId, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15), 
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(_t(status.toLowerCase()), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete Order',
                                        onPressed: () => _confirmAndDeleteOrder(orderNode),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(itemName, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('${_t('delivery')}: ${deliveryDate.isNotEmpty ? deliveryDate : 'N/A'}', style: TextStyle(color: subTextColor, fontSize: 11)),
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
                                      _detailLine(_t('garment'), garment, textColor, subTextColor),
                                      if (designStyle.isNotEmpty) _detailLine(_t('designStyle'), designStyle, textColor, subTextColor),
                                      if (clothDetail.isNotEmpty) _detailLine(_t('clothDetail'), clothDetail, textColor, subTextColor),
                                      if (clothSource.isNotEmpty) _detailLine(_t('clothSource'), clothSource, textColor, subTextColor),
                                      if (priority.isNotEmpty) _detailLine(_t('priority'), priority, textColor, subTextColor),
                                      if (orderDate.isNotEmpty) _detailLine(_t('orderDate'), orderDate, textColor, subTextColor),
                                      if (trialDate.isNotEmpty) _detailLine(_t('trialDate'), trialDate, textColor, subTextColor),
                                      if (deliveryDate.isNotEmpty) _detailLine(_t('deliveryDate'), deliveryDate, textColor, subTextColor),
                                      if (notes.isNotEmpty) _detailLine(_t('notes'), notes, textColor, subTextColor),

                                      if (orderGroupedGarments.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          _t('measurementDetails') != 'measurementDetails' ? _t('measurementDetails') : 'Measurement Details',
                                          style: TextStyle(color: primaryThemeColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        const SizedBox(height: 8),
                                        ...orderGroupedGarments.entries.map((gEntry) {
                                          String gName = gEntry.key;
                                          Map<String, dynamic> mItems = gEntry.value;

                                          return Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: primaryThemeColor.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: primaryThemeColor.withOpacity(0.2)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  gName.toUpperCase(),
                                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 6,
                                                  children: mItems.entries.map((mEntry) {
                                                    String mFieldKey = mEntry.key;
                                                    String tFieldKey = _t(mFieldKey) != mFieldKey ? _t(mFieldKey) : mFieldKey;
                                                    String formattedLabel = tFieldKey.isNotEmpty 
                                                        ? '${tFieldKey[0].toUpperCase()}${tFieldKey.substring(1)}' 
                                                        : tFieldKey;

                                                    return SizedBox(
                                                      width: 120,
                                                      child: Text(
                                                        '$formattedLabel: ${_safeString(mEntry.value)}',
                                                        style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],

                                      if (status != 'Delivered') ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: status == 'Pending' ? Colors.blue : Colors.teal,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: () => _confirmAndAdvanceStatus(orderNode),
                                            icon: Icon(
                                              status == 'Pending' ? Icons.hourglass_top : Icons.local_shipping,
                                              size: 16,
                                            ),
                                            label: Text(
                                              status == 'Pending' 
                                                  ? '🚚 ${_t('markReady') != 'markReady' ? 'Mark Ready' : 'Mark Ready'}' 
                                                  : '🚚 ${_t('markDelivered') != 'markDelivered' ? 'Mark Delivered' : 'Mark Delivered'}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
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
                    _summaryCol(_t('totalOrders'), orders.length.toString(), primaryThemeColor, subTextColor),
                    _summaryCol(_t('pendingOrders'), pendingCount.toString(), Colors.deepOrange, subTextColor),
                    _summaryCol(_t('readyOrders') != 'readyOrders' ? _t('readyOrders') : 'Ready', readyCount.toString(), Colors.blue, subTextColor),
                    _summaryCol(_t('completedOrders'), completedCount.toString(), Colors.teal, subTextColor),
                  ],
                ),
              ),
            ],
          ),
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
            width: 100,
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