import 'dart:io';
import 'dart:convert'; // Added for base64Decode
import 'dart:typed_data'; // Added for Uint8List
import 'package:flutter/material.dart';
import '../../database.dart';
import '../wizard/add_customer_screen.dart';
import 'master_measurement_page.dart';
import 'order_history_screen.dart';
import 'payment_history_screen.dart';
import 'package:image_picker/image_picker.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  final bool isDarkMode;
  final Map<String, String> translations;
  final String userEmail;
  final Function(String customerId)? onDeleteCustomer;

  const CustomerProfileScreen({
    super.key, 
    required this.customer, 
    required this.isDarkMode, 
    required this.translations,
    required this.userEmail,
    this.onDeleteCustomer,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late Map<String, dynamic> _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = Map<String, dynamic>.from(widget.customer);
  }

  String _t(String key) => widget.translations[key] ?? key;

  void _refreshCustomerData(Map<String, dynamic> newCustomerIdData) {
    setState(() {
      _currentCustomer = Map<String, dynamic>.from(newCustomerIdData);
    });
  }

  Future<void> _reloadLatestCustomerData() async {
    String customerId = _currentCustomer['customer_id']?.toString() ?? _currentCustomer['id']?.toString() ?? '';
    if (customerId.isNotEmpty) {
      try {
        Map<String, dynamic>? freshData = await DatabaseService.fetchSingleCustomer(widget.userEmail, customerId);
        if (freshData != null && mounted) {
          setState(() {
            _currentCustomer = Map<String, dynamic>.from(freshData);
          });
        }
      } catch (e) {
        print("Error reloading customer: $e");
      }
    }
  }

  // 🚀 Helper to parse Image Provider safely (handles File, Network, and Raw/Prefixed Base64)
  ImageProvider? _getCustomerImageProvider(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;

    try {
      if (photoPath.startsWith('http')) {
        return NetworkImage(photoPath);
      } else if (photoPath.startsWith('data:image')) {
        final base64String = photoPath.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } else if (File(photoPath).existsSync()) {
        return FileImage(File(photoPath));
      } else {
        // Agar yeh raw base64 string hai (jaise screenshot me hai)
        final cleanBase64 = photoPath.contains(',') ? photoPath.split(',').last : photoPath;
        Uint8List bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
        return MemoryImage(bytes);
      }
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }

  // ==========================================
  // 📝 EDIT POPUP DIALOG WITH IMAGE PICKER
  // ==========================================
  void _showEditCustomerPopup() {
    final nameController = TextEditingController(text: _currentCustomer['name'] ?? '');
    final mobileController = TextEditingController(text: _currentCustomer['mobile'] ?? '');
    final altMobileController = TextEditingController(text: _currentCustomer['alt_mobile'] ?? '');
    final addressController = TextEditingController(text: _currentCustomer['address'] ?? '');
    final cityController = TextEditingController(text: _currentCustomer['city'] ?? '');
    final dobController = TextEditingController(text: _currentCustomer['dob'] ?? '');
    final notesController = TextEditingController(text: _currentCustomer['notes'] ?? '');

    String selectedGender = _currentCustomer['gender'] ?? 'Male';
    String selectedCustomerType = _currentCustomer['customer_type'] ?? 'Standard';
    
    String? tempPhotoPath = _currentCustomer['photo'] ?? _currentCustomer['imageUrl'] ?? _currentCustomer['image'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isDark = widget.isDarkMode;
        Color dialogBg = isDark ? const Color(0xFF18181B) : Colors.white;
        Color textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
        const Color primaryColor = Color(0xFF7C3AED);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            Future<void> pickNewImage() async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) {
                  // Optional: Agar aap image ko direct base64 string me convert karke save karna chahte hain toh yahan kar sakte hain
                  final bytes = await image.readAsBytes();
                  String base64String = base64Encode(bytes);
                  setStateDialog(() {
                    tempPhotoPath = base64String; // Base64 string set kar rahe hain
                  });
                }
              } catch (e) {
                print("Error picking image: $e");
              }
            }

            return AlertDialog(
              backgroundColor: dialogBg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _t('editCustomer'), 
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: primaryColor.withOpacity(0.2),
                              backgroundImage: _getCustomerImageProvider(tempPhotoPath),
                              child: (tempPhotoPath == null || tempPhotoPath.toString().isEmpty)
                                  ? Text(
                                      nameController.text.isNotEmpty ? nameController.text[0].toUpperCase() : 'C',
                                      style: const TextStyle(color: primaryColor, fontSize: 30, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: pickNewImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Customer ID: ${_currentCustomer['customer_id'] ?? _currentCustomer['id'] ?? 'N/A'}",
                                style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: nameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('customerName') != 'customerName' ? _t('customerName') : 'Customer Name',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('mobileNumber') != 'mobileNumber' ? _t('mobileNumber') : 'Mobile Number',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: altMobileController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('altMobile') != 'altMobile' ? _t('altMobile') : 'Alternate Mobile (Optional)',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: addressController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('address') != 'address' ? _t('address') : 'Address',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: cityController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('city') != 'city' ? _t('city') : 'City',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        dropdownColor: dialogBg,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('gender') != 'gender' ? _t('gender') : 'Gender',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female', 'Other'].map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender, style: TextStyle(color: textColor)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setStateDialog(() {
                              selectedGender = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedCustomerType,
                        dropdownColor: dialogBg,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('customerType') != 'customerType' ? _t('customerType') : 'Customer Type',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['Standard', 'VIP', 'Regular'].map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type, style: TextStyle(color: textColor)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setStateDialog(() {
                              selectedCustomerType = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: dobController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('dob') != 'dob' ? _t('dob') : 'Date of Birth (DD-MM-YYYY)',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('notes') != 'notes' ? _t('notes') : 'Notes',
                          labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(_t('cancel') != 'cancel' ? _t('cancel') : 'Cancel', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: Text(_t('saveChanges') != 'saveChanges' ? _t('saveChanges') : 'Save Changes', style: const TextStyle(color: Colors.white)),
                  onPressed: () async {
                    Map<String, dynamic> updatedData = Map<String, dynamic>.from(_currentCustomer);
                    updatedData['name'] = nameController.text.trim();
                    updatedData['mobile'] = mobileController.text.trim();
                    updatedData['alt_mobile'] = altMobileController.text.trim();
                    updatedData['address'] = addressController.text.trim();
                    updatedData['city'] = cityController.text.trim();
                    updatedData['gender'] = selectedGender;
                    updatedData['customer_type'] = selectedCustomerType;
                    updatedData['dob'] = dobController.text.trim();
                    updatedData['notes'] = notesController.text.trim();
                    updatedData['photo'] = tempPhotoPath ?? '';

                    String customerId = updatedData['customer_id']?.toString() ?? updatedData['id']?.toString() ?? '';

                    try {
                      await DatabaseService.updateCustomer(widget.userEmail, customerId, updatedData);
                      
                      _refreshCustomerData(updatedData);
                      Navigator.of(dialogContext).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_t('customerUpdatedSuccess') != 'customerUpdatedSuccess' ? _t('customerUpdatedSuccess') : 'Customer details updated successfully!')),
                      );
                    } catch (e) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  },
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

    String custName = _currentCustomer['name'] ?? 'Unknown';
    String customerId = _currentCustomer['customer_id']?.toString() ?? _currentCustomer['id']?.toString() ?? 'N/A';
    String mobile = _currentCustomer['mobile'] ?? '';
    String altMobile = _currentCustomer['alt_mobile'] ?? '';
    String address = _currentCustomer['address'] ?? '';
    String city = _currentCustomer['city'] ?? '';
    String gender = _currentCustomer['gender'] ?? 'N/A';
    String dob = _currentCustomer['dob'] ?? 'N/A';
    String customerType = _currentCustomer['customer_type'] ?? 'Standard';
    String notes = _currentCustomer['notes'] ?? '';
    String createdAt = _currentCustomer['created_at'] ?? '';
    
    String formattedMemberSince = 'N/A';
    if (createdAt.isNotEmpty) {
      try {
        String datePart = createdAt.split('T')[0];
        List<String> parts = datePart.split('-');
        if (parts.length == 3) {
          formattedMemberSince = '${parts[2]}-${parts[1]}-${parts[0]}';
        } else {
          formattedMemberSince = datePart;
        }
      } catch (e) {
        formattedMemberSince = createdAt;
      }
    }
    
    String? photoPath = _currentCustomer['photo'] ?? _currentCustomer['imageUrl'] ?? _currentCustomer['image'];
    
    var rawOrders = _currentCustomer['orders'] ?? _currentCustomer['orderHistory'] ?? [];
    List<Map<String, dynamic>> ordersList = [];
    if (rawOrders is Map) {
      rawOrders.forEach((key, value) {
        if (value is Map) {
          ordersList.add(Map<String, dynamic>.from(value));
        }
      });
    } else if (rawOrders is List) {
      for (var item in rawOrders) {
        if (item is Map) {
          ordersList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    double calculatedTotalDue = 0;
    String latestOrderDate = 'N/A';

    for (var order in ordersList) {
      var paymentDetails = order['payment_details'] is Map ? order['payment_details'] : {};
      double dueVal = double.tryParse(paymentDetails['due']?.toString() ?? order['due']?.toString() ?? '0') ?? 0;
      calculatedTotalDue += dueVal;

      var orderDetails = order['order_details'] is Map ? order['order_details'] : order;
      String orderDate = orderDetails['date'] ?? order['date'] ?? order['created_at'] ?? '';
      if (orderDate.isNotEmpty && (latestOrderDate == 'N/A' || orderDate.compareTo(latestOrderDate) > 0)) {
        latestOrderDate = orderDate;
      }
    }

    String displayDue = _currentCustomer['due']?.toString() ?? '₹${calculatedTotalDue.toStringAsFixed(0)}';
    if (!displayDue.startsWith('₹') && double.tryParse(displayDue) != null) {
      displayDue = '₹$displayDue';
    }

    if (latestOrderDate != 'N/A' && latestOrderDate.length >= 10) {
      try {
        String datePart = latestOrderDate.split('T')[0];
        List<String> parts = datePart.split('-');
        if (parts.length == 3) {
          latestOrderDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      } catch (_) {}
    } else {
      latestOrderDate = _currentCustomer['lastVisit'] ?? _currentCustomer['last_order_date'] ?? 'N/A';
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_currentCustomer);
      },
      child: Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
        appBar: AppBar(
          backgroundColor: primaryThemeColor,
          title: Text(_t('customerProfile'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop(_currentCustomer);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: primaryThemeColor.withOpacity(0.2),
                          backgroundImage: _getCustomerImageProvider(photoPath),
                          child: (photoPath == null || photoPath.toString().isEmpty)
                              ? Text(
                                  custName.isNotEmpty ? custName[0].toUpperCase() : 'C',
                                  style: const TextStyle(color: primaryThemeColor, fontSize: 26, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      custName, 
                                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: customerType == 'VIP' ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.15), 
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      customerType, 
                                      style: TextStyle(
                                        color: customerType == 'VIP' ? Colors.amber.shade800 : Colors.green, 
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('ID : $customerId', style: TextStyle(color: primaryThemeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.phone_iphone, size: 13, color: subTextColor),
                                  const SizedBox(width: 4),
                                  Text(mobile, style: TextStyle(color: subTextColor, fontSize: 12)),
                                  if (altMobile.isNotEmpty) ...[
                                    Text(' / ', style: TextStyle(color: subTextColor)),
                                    Text(altMobile, style: TextStyle(color: subTextColor, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildDetailRow(Icons.location_on_outlined, _t('address') != 'address' ? _t('address') : 'Address', '$address, $city', textColor, subTextColor),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow(Icons.person_outline, _t('gender') != 'gender' ? _t('gender') : 'Gender', gender, textColor, subTextColor)),
                        Expanded(child: _buildDetailRow(Icons.cake_outlined, _t('dob') != 'dob' ? _t('dob') : 'DOB', dob, textColor, subTextColor)),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.note_alt_outlined, _t('notes') != 'notes' ? _t('notes') : 'Notes', notes, textColor, subTextColor),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem(_t('totalOrders'), ordersList.length.toString(), primaryThemeColor, subTextColor),
                    _metricItem(_t('totalDue'), displayDue, Colors.deepOrangeAccent, subTextColor),
                    _metricItem(_t('lastOrder'), latestOrderDate, textColor, subTextColor),
                    _metricItem(_t('memberSince') != 'memberSince' ? _t('memberSince') : 'Member Since', formattedMemberSince, textColor, subTextColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                child: Column(
                  children: [
                    _menuItem(
                      Icons.shopping_bag, 
                      Colors.teal, 
                      _t('newOrder'), 
                      () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddCustomerScreen(
                              initialLanguage: widget.translations['title'] == 'ग्राहक हब' ? 'Hindi' : 'English',
                              isDarkMode: widget.isDarkMode,
                              userEmail: widget.userEmail,
                              prefilledCustomer: _currentCustomer,
                              startAtStep: 2,
                            ),
                          ),
                        );
                        if (updated != null && updated is Map<String, dynamic>) {
                          _refreshCustomerData(updated);
                        } else {
                          await _reloadLatestCustomerData();
                        }
                      }, 
                      textColor, 
                      subTextColor, 
                      borderColor,
                    ),
                    _menuItem(
                      Icons.straighten, 
                      primaryThemeColor, 
                      _t('masterMeasurement'), 
                      () async {
                        String? latestOrderId;
                        if (ordersList.isNotEmpty) {
                          latestOrderId = ordersList.first['order_id']?.toString() ?? ordersList.first['id']?.toString();
                        }

                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MasterMeasurementPage(
                              customer: _currentCustomer,
                              isDarkMode: widget.isDarkMode,
                              translations: widget.translations,
                              orderId: latestOrderId ?? '',
                              userEmail: widget.userEmail,
                            ),
                          ),
                        );
                        if (updated != null && updated is Map<String, dynamic>) {
                          _refreshCustomerData(updated);
                        } else {
                          await _reloadLatestCustomerData();
                        }
                      }, 
                      textColor, 
                      subTextColor, 
                      borderColor,
                    ),
                    _menuItem(
                      Icons.list_alt, 
                      Colors.deepPurple, 
                      _t('orderHistory'), 
                      () async {
                        var formattedCustomer = Map<String, dynamic>.from(_currentCustomer);
                        if (formattedCustomer['orderHistory'] == null && formattedCustomer['orders'] != null) {
                          if (formattedCustomer['orders'] is Map) {
                            formattedCustomer['orderHistory'] = (formattedCustomer['orders'] as Map).values.toList();
                          } else {
                            formattedCustomer['orderHistory'] = formattedCustomer['orders'];
                          }
                        }
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderHistoryScreen(
                              customer: formattedCustomer,
                              isDarkMode: widget.isDarkMode,
                              translations: widget.translations,
                              userEmail: widget.userEmail,
                            ),
                          ),
                        );
                        if (updated != null && updated is Map<String, dynamic>) {
                          _refreshCustomerData(updated);
                        } else {
                          await _reloadLatestCustomerData();
                        }
                      }, 
                      textColor, 
                      subTextColor, 
                      borderColor,
                    ),
                    _menuItem(
                      Icons.payment, 
                      Colors.amber.shade800, 
                      _t('paymentHistory'), 
                      () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentHistoryScreen(
                              customer: _currentCustomer,
                              isDarkMode: widget.isDarkMode,
                              translations: widget.translations,
                              userEmail: widget.userEmail,
                            ),
                          ),
                        );
                        if (updated != null && updated is Map<String, dynamic>) {
                          _refreshCustomerData(updated);
                        } else {
                          await _reloadLatestCustomerData();
                        }
                      }, 
                      textColor, 
                      subTextColor, 
                      borderColor,
                    ),
                    _menuItem(
                      Icons.edit, 
                      Colors.blueGrey, 
                      _t('editCustomer'), 
                      () {
                        _showEditCustomerPopup();
                      }, 
                      textColor, 
                      subTextColor, 
                      borderColor,
                    ),
                    _menuItem(
                      Icons.delete, 
                      Colors.redAccent, 
                      _t('deleteCustomer'), 
                      () {
                        _showDeleteConfirmationDialog(context, customerId, custName, widget.isDarkMode);
                      }, 
                      textColor, 
                      subTextColor, 
                      borderColor, 
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String customerId, String customerName, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF18181B) : Colors.white,
          title: Text(
            _t('deleteCustomer'),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete $customerName? This action cannot be undone.',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800),
          ),
          actions: [
            TextButton(
              child: Text(_t('cancel') != 'cancel' ? _t('cancel') : 'Cancel', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(_t('delete') != 'delete' ? _t('delete') : 'Delete', style: const TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                try {
                  var result = await DatabaseService.deleteCustomer(
                    userEmail: widget.userEmail,
                    customerId: customerId,
                  );

                  if (result['status'] == true) {
                    if (widget.onDeleteCustomer != null) {
                      widget.onDeleteCustomer!(customerId);
                    }

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$customerName has been deleted successfully.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? 'Delete fail ho gaya.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color textColor, Color subTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: subTextColor),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value, 
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _metricItem(String title, String value, Color valColor, Color subTextColor) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: subTextColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, Color color, String title, VoidCallback onTap, Color textColor, Color subTextColor, Color borderColor, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
          title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subTextColor),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),
      ],
    );
  }
}