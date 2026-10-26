import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  // --- CONFIGURATION ---
  static const String API_KEY = "AIzaSyDJsV64gtTICx1sx28bL5vExaorz7pJWPI";
  static const String BASE_URL = "https://tailor-apk-default-rtdb.asia-southeast1.firebasedatabase.app/";

  // Firebase Auth Endpoints
  static const String AUTH_SIGNUP = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY";
  static const String AUTH_SIGNIN = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY";
  static const String AUTH_VERIFY_EMAIL = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$API_KEY";
  static const String AUTH_LOOKUP = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$API_KEY";
  static const String AUTH_RESET_PASSWORD = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$API_KEY";

  // Helper: Email ko Firebase-safe banana (Python wala get_safe_email)
  static String getSafeEmail(String email) => email.replaceAll('.', ',');

  // ======================1. REGISTER USER FUNCTION (Logic same as Python)==================
  static Future<Map<String, dynamic>> registerUserInDb(
    String email, String username, String password, String fullName, String phone) async {
  
  final client = http.Client(); 
  try {
    final uName = username.trim().toLowerCase();
    final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), ''); 

    // --- 1. Check if Username exists ---
    final usersRes = await client.get(Uri.parse("$cleanUrl/users.json"));
    if (usersRes.statusCode == 200 && usersRes.body != 'null') {
      Map<String, dynamic> users = json.decode(usersRes.body);
      for (var val in users.values) {
        if (val is Map && val['username'] == uName) {
          return {"status": false, "messageKey": "errUserExists"};
        }
      }
    }

    // --- 2. Firebase Auth Signup ---
    final authPayload = {
      "email": email,
      "password": password,
      "returnSecureToken": true
    };
    final authRes = await client.post(Uri.parse(AUTH_SIGNUP), body: json.encode(authPayload));
    final authData = json.decode(authRes.body);

    if (authData.containsKey('error')) {
      String firebaseErr = authData["error"]["message"] ?? "";
      String mappedKey = "errRegFailed";
      if (firebaseErr.contains("EMAIL_EXISTS")) {
        mappedKey = "errEmailExists";
      } else if (firebaseErr.contains("WEAK_PASSWORD")) {
        mappedKey = "errWeakPass";
      }
      return {"status": false, "messageKey": mappedKey};
    }

    String idToken = authData["idToken"];

    // --- 3. Save to Database PEHLE ---
    final sEmail = getSafeEmail(email);
    final userPayload = {
      "email": email,
      "username": uName,
      "password": password, // Latest plain text password sync rakhne ke liye
      "full_name": fullName,
      "phone": phone,
      "is_verified": false
    };

    final dbRes = await client.put(
      Uri.parse("$cleanUrl/users/$sEmail.json"),
      body: json.encode(userPayload),
    );

    if (dbRes.statusCode != 200) {
      return {"status": false, "messageKey": "errDbSave"};
    }

    // --- 4. Verification Link bhejein ---
    final verifyRes = await client.post(
      Uri.parse(AUTH_VERIFY_EMAIL),
      body: json.encode({"requestType": "VERIFY_EMAIL", "idToken": idToken}),
    );

    if (verifyRes.statusCode == 200) {
      return {"status": true, "messageKey": "regSuccess"};
    } else {
      return {"status": false, "messageKey": "errLinkSend"};
    }
  } catch (e) {
    return {"status": false, "messageKey": "errRegFailed"};
  } finally {
    client.close();
  }
}

  //============= 2. LOGIN USER FUNCTION (Logic same as Python)===========
  static Future<Map<String, dynamic>> loginUser(String identifier, String password) async {
  try {
    String email = identifier.trim();
    final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');

    // --- STEP 1: Agar identifier Username hai, toh pehle Email nikal lein ---
    if (!identifier.contains("@")) {
      final usersRes = await http.get(Uri.parse("$cleanUrl/users.json"));
      String? foundEmail;
      
      if (usersRes.statusCode == 200 && usersRes.body != 'null') {
        Map<String, dynamic> users = json.decode(usersRes.body);
        for (var entry in users.entries) {
          var val = entry.value;
          if (val is Map) {
            String dbUsername = val['username'] ?? '';
            String keyEmail = entry.key.replaceAll(',', '.');
            if (dbUsername.toLowerCase() == identifier.trim().toLowerCase()) {
              foundEmail = val['email'] ?? keyEmail;
              break;
            }
          }
        }
      }

      if (foundEmail == null) {
        return {"status": false, "messageKey": "errUserNotFound"};
      }
      email = foundEmail;
    }

    // --- STEP 2: Pehle Firebase Auth se login karke try karein ---
    final loginRes = await http.post(
      Uri.parse(AUTH_SIGNIN),
      body: json.encode({
        "email": email,
        "password": password,
        "returnSecureToken": true,
      }),
    );
    
    final loginData = json.decode(loginRes.body);

    // Agar Firebase Auth mein successfully login ho gaya
    if (!loginData.containsKey('error')) {
      String token = loginData["idToken"];
      final lookupRes = await http.post(
        Uri.parse(AUTH_LOOKUP),
        body: json.encode({"idToken": token}),
      );
      final lookupData = json.decode(lookupRes.body);

      if (lookupData.containsKey('users') && (lookupData['users'] as List).isNotEmpty) {
        bool firebaseVerified = lookupData['users'][0]['emailVerified'] ?? false;

        if (!firebaseVerified) {
          return {"status": false, "messageKey": "errVerifyEmail"};
        }

        // Database status update
        final sEmail = getSafeEmail(email);
        await http.patch(
          Uri.parse("$cleanUrl/users/$sEmail.json"),
          body: json.encode({"is_verified": true}),
        );
        return {"status": true, "messageKey": "success", "email": email};
      }
    }

    // --- STEP 3: Agar Firebase fail ho gaya, toh Database plain text password check karein ---
    final sEmail = getSafeEmail(email);
    final userRes = await http.get(Uri.parse("$cleanUrl/users/$sEmail.json"));

    if (userRes.statusCode == 200 && userRes.body != 'null') {
      Map<String, dynamic> userData = json.decode(userRes.body);
      String dbPassword = userData['password']?.toString() ?? '';

      // Plain text password match karein
      if (dbPassword == password.trim()) {
        bool isVerified = userData['is_verified'] ?? true;
        if (!isVerified) {
          return {"status": false, "messageKey": "errVerifyEmail"};
        }
        return {"status": true, "messageKey": "success", "email": email};
      } else {
        // Agar database mein user mila par password galat hai
        return {"status": false, "messageKey": "errWrongPass"};
      }
    }

    // Agar na Firebase mein chala aur na hi Database mein user/password match hua
    return {"status": false, "messageKey": "errWrongPass"};

  } catch (e) {
    print("Login Exception: ${e.toString()}"); // Debugging ke liye console me print hoga
    return {"status": false, "messageKey": "errLoginFailed"};
  }
}
  //================================== 3. RESET PASSWORD FUNCTION=====================
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final payload = {
        "requestType": "PASSWORD_RESET",
        "email": email
      };
      final res = await http.post(Uri.parse(AUTH_RESET_PASSWORD), body: json.encode(payload));
      final data = json.decode(res.body);
      
      if (data.containsKey('error')) {
        return {"status": false, "message": data["error"]["message"]};
      }
      
      return {"status": true, "messagekey": "Password reset email sent successfully!"};
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  //======================delete account ======================
  static Future<Map<String, dynamic>> deleteUserAccount(String email, String password) async {
  try {
    // 1. Auth Login
    final authRes = await http.post(
      Uri.parse(AUTH_SIGNIN),
      body: json.encode({"email": email, "password": password, "returnSecureToken": true}),
    );
    
    if (authRes.statusCode != 200) {
      return {"status": false, "message": "Login Failed: Check Credentials"};
    }

    final idToken = json.decode(authRes.body)['idToken'];

    // 2. Auth Delete
    final deleteAuthRes = await http.post(
      Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$API_KEY"),
      body: json.encode({"idToken": idToken}),
    );

    if (deleteAuthRes.statusCode != 200) {
      return {"status": false, "message": "Auth Delete Failed"};
    }

    // 3. Database Cleanup
    String safeEmail = email.replaceAll('.', ',');
    List<String> nodes = ["customers", "global_rates", "master_measurements", "settings", "users", "workers"];

    for (String node in nodes) {
      try {
        // URL format: BASE_URL + node + / + email.json
        await http.delete(Uri.parse("${BASE_URL}$node/$safeEmail.json"));
      } catch (e) {
        print("Error deleting $node: $e");
      }
    }
    
    return {"status": true, "message": "Success"}; 
    
  } catch (e) {
    return {"status": false, "message": "Error: ${e.toString()}"};
  }
}
//======================================Dashboard ============================================

  // ================== ADMIN DASHBOARD REAL DATA FUNCTION ==================
  static Future<Map<String, dynamic>> getAdminDashboardData(String userEmail) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Customers, Users (Full Name ke liye), aur Settings (Shop Name ke liye) parallel fetch karna
      final customersResponseFuture = client.get(Uri.parse("$cleanUrl/customers/$sEmail.json"));
      final userProfileResponseFuture = client.get(Uri.parse("$cleanUrl/users/$sEmail.json"));
      final shopDetailResponseFuture = client.get(Uri.parse("$cleanUrl/settings/$sEmail/shop_detail.json"));

      final responses = await Future.wait([
        customersResponseFuture, 
        userProfileResponseFuture,
        shopDetailResponseFuture,
      ]);
      
      final response = responses[0];
      final userProfileResponse = responses[1];
      final shopDetailResponse = responses[2];

      String shopName = "My Shop"; 
      String fullName = ""; // <-- Full Name variable

      // Step A: Shop Name ko 'settings/{email}/shop_detail' se lena
      if (shopDetailResponse.statusCode == 200 && shopDetailResponse.body != 'null') {
        try {
          var shopData = json.decode(shopDetailResponse.body);
          if (shopData is Map) {
            shopName = shopData['shop_name'] ?? shopData['shopName'] ?? 'My Shop';
          }
        } catch (e) {
          print("DEBUG Error parsing shop_detail JSON: $e");
        }
      }

      // Step B: Full Name ko 'users/{email}' node se lena
      if (userProfileResponse.statusCode == 200 && userProfileResponse.body != 'null') {
        try {
          var userData = json.decode(userProfileResponse.body);
          if (userData is Map) {
            fullName = userData['full_name'] ?? userData['fullName'] ?? userData['name'] ?? '';
          }
        } catch (e) {
          print("DEBUG Error parsing user profile JSON: $e");
        }
      }

      int totalCustomers = 0;
      int totalOrders = 0;
      int pendingOrders = 0;
      int readyOrders = 0;
      int deliveredOrders = 0;
      double totalRevenue = 0.0; 
      double pendingAmount = 0.0;
      double cashCollected = 0.0;
      double upiCollected = 0.0;

      List<Map<String, dynamic>> urgentAlerts = [];
      
      // Database ke format (dd/MM/yyyy aur d/M/yyyy) ke hisab se aaj ki date generate karna
      DateTime now = DateTime.now();
      String todayDate1 = DateFormat('d/M/yyyy').format(now);   // e.g. "21/8/2026"
      String todayDate2 = DateFormat('dd/MM/yyyy').format(now); // e.g. "21/08/2026"

      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> customersData = json.decode(response.body);
        totalCustomers = customersData.length;

        customersData.forEach((customerId, customerVal) {
          if (customerVal is Map) {
            String customerName = customerVal['name'] ?? 'Customer';
            
            if (customerVal.containsKey('orders') && customerVal['orders'] is Map) {
              Map<String, dynamic> ordersMap = customerVal['orders'];
              
              ordersMap.forEach((orderId, orderVal) {
                if (orderVal is Map) {
                  totalOrders++;

                  var orderDetails = orderVal['order_details'] ?? {};
                  var paymentDetails = orderVal['payment_details'] ?? {};

                  String status = (orderDetails['status'] ?? orderVal['status'] ?? 'Pending').toString().toLowerCase();
                  String deliveryDate = (orderDetails['delivery_date'] ?? orderDetails['deliveryDate'] ?? '').toString().trim();
                  String garmentType = (orderDetails['garment_type'] ?? orderDetails['item'] ?? 'Order').toString();

                  if (status.contains('ready')) {
                    readyOrders++;
                  } else if (status.contains('deliver') || status.contains('completed')) {
                    deliveredOrders++;
                  } else {
                    pendingOrders++;
                  }

                  double totalAmt = double.tryParse(paymentDetails['total']?.toString() ?? paymentDetails['totalAmount']?.toString() ?? '0') ?? 0.0;
                  double advanceAmt = double.tryParse(paymentDetails['advance']?.toString() ?? paymentDetails['advanceAmount']?.toString() ?? '0') ?? 0.0;
                  double dueAmt = double.tryParse(paymentDetails['due']?.toString() ?? paymentDetails['pending']?.toString() ?? (totalAmt - advanceAmt).toString()) ?? 0.0;

                  double lastPaidAmt = double.tryParse(paymentDetails['last_paid_amount']?.toString() ?? '0') ?? 0.0;
                  String lastPayMethod = (paymentDetails['last_payment_method'] ?? '').toString().toLowerCase();
                  String primaryPayMethod = (paymentDetails['payment_method'] ?? paymentDetails['mode'] ?? 'Cash').toString().toLowerCase();

                  pendingAmount += dueAmt;

                  double orderCash = 0.0;
                  double orderUpi = 0.0;

                  if (lastPaidAmt > 0 && (lastPayMethod.contains('upi') || lastPayMethod.contains('online') || lastPayMethod.contains('qr'))) {
                    orderUpi += lastPaidAmt;
                    double remainingAdvance = advanceAmt - lastPaidAmt;
                    if (remainingAdvance > 0) {
                      orderCash += remainingAdvance;
                    }
                  } else {
                    if (primaryPayMethod.contains('upi') || primaryPayMethod.contains('online') || primaryPayMethod.contains('qr')) {
                      orderUpi += advanceAmt;
                    } else {
                      orderCash += advanceAmt;
                    }
                    
                    if (lastPaidAmt > 0) {
                      orderCash += lastPaidAmt;
                    }
                  }

                  cashCollected += orderCash;
                  upiCollected += orderUpi;

                  // Today delivery alert check (dd/M/yyyy ya dd/MM/yyyy match karega)
                  if (deliveryDate == todayDate1 || deliveryDate == todayDate2) {
                    urgentAlerts.add({
                      'type': 'delivery',
                      'title': 'Today Delivery: $customerName ($garmentType)',
                      'tag': 'Due Today',
                      'icon': 'shipping',
                    });
                  }

                  // Pending due amount alert check
                  if (dueAmt > 0) {
                    urgentAlerts.add({
                      'type': 'payment',
                      'title': 'Pending Dues: $customerName has ₹${dueAmt.toStringAsFixed(0)} due',
                      'tag': 'Collect',
                      'icon': 'warning',
                    });
                  }
                }
              });
            }
          }
        });
      }

      totalRevenue = cashCollected + upiCollected;

      return {
        "status": true,
        "shopName": shopName,        
        "full_name": fullName, // <-- GUI me use karne ke liye Full Name return kiya
        "totalCustomers": totalCustomers,
        "totalOrders": totalOrders,
        "pendingOrdersCount": pendingOrders,
        "readyOrdersCount": readyOrders,
        "deliveredOrdersCount": deliveredOrders,
        "totalRevenue": totalRevenue,
        "pendingAmount": pendingAmount,
        "paymentModes": {
          "cash": cashCollected,
          "upi": upiCollected,
        },
        "alertsCount": urgentAlerts.length,
        "alertsList": urgentAlerts.take(3).toList(),
      };

    } catch (e) {
      print("DEBUG ERROR: $e");
      return {
        "status": false,
        "shopName": "My Shop",
        "full_name": "",
        "totalCustomers": 0,
        "totalOrders": 0,
        "pendingOrdersCount": 0,
        "readyOrdersCount": 0,
        "deliveredOrdersCount": 0,
        "totalRevenue": 0.0,
        "pendingAmount": 0.0,
        "paymentModes": {"cash": 0.0, "upi": 0.0},
        "alertsCount": 0,
        "alertsList": [],
      };
    } finally {
      client.close();
    }
  }
//==============================================add customer=================================
  // ====================== SAVE COMPLETE CUSTOMER, ORDER & MEASUREMENTS ===================
  static Future<Map<String, dynamic>> saveCompleteCustomerOrder({
    required String userEmail,
    required String customerId,
    required String orderId,
    required Map<String, dynamic> customerData,
    required Map<String, dynamic> orderDetails,
    required Map<String, dynamic> measurementDetails,
    required Map<String, dynamic> paymentDetails,
    required Map<String, dynamic> masterMeasurements,
    bool isNewCustomer = true, // Naya parameter: Agar false hoga toh customer details update nahi hongi
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Agar naya customer hai tabhi customer info save/patch karein
      if (isNewCustomer) {
        final customerRes = await client.patch(
          Uri.parse("$cleanUrl/customers/$sEmail/$customerId.json"),
          body: json.encode({
            ...customerData,
            "created_at": DateTime.now().toIso8601String(),
          }),
        );
        if (customerRes.statusCode != 200) {
          return {"status": false, "message": "Customer details save nahi ho payin."};
        }
      }

      // 2. Prepare Order Payload with nested sub-nodes (order_details, measurement_details, payment_details)
      final orderPayload = {
        "order_details": orderDetails,
        "measurement_details": measurementDetails,
        "payment_details": paymentDetails,
        "created_at": DateTime.now().toIso8601String(),
      };

      // Save inside: customers -> sEmail -> customerId -> orders -> orderId
      final orderRes = await client.put(
        Uri.parse("$cleanUrl/customers/$sEmail/$customerId/orders/$orderId.json"),
        body: json.encode(orderPayload),
      );
      if (orderRes.statusCode != 200) {
        return {"status": false, "message": "Order details save nahi ho payin."};
      }

      // 3. Save Master Measurements under master_measurements -> sEmail -> customerId
      final masterPayload = {
        ...masterMeasurements,
        "updated_at": DateTime.now().toIso8601String(),
      };

      final masterRes = await client.put(
        Uri.parse("$cleanUrl/master_measurements/$sEmail/$customerId.json"),
        body: json.encode(masterPayload),
      );
      if (masterRes.statusCode != 200) {
        return {"status": false, "message": "Master measurements save nahi ho payin."};
      }

      return {"status": true, "message": "Data successfully save ho gaya!"};
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }


  // ================== UPDATE CUSTOMER DETAILS (Customer ID छोड़कर बाकी सब अपडेट करने के लिए) ==================
  static Future<Map<String, dynamic>> updateCustomer(
    String userEmail,
    String customerId,
    Map<String, dynamic> updatedData,
  ) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Firebase Realtime Database में specific customer node पर PATCH रिक्वेस्ट भेजना
      final response = await client.patch(
        Uri.parse("$cleanUrl/customers/$sEmail/$customerId.json"),
        body: json.encode({
          ...updatedData,
          "updated_at": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return {"status": true, "message": "Customer details successfully update ho gayin!"};
      } else {
        return {"status": false, "message": "Customer update nahi ho paya."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  // ================== DELETE CUSTOMER COMPLETELY ==================
  static Future<Map<String, dynamic>> deleteCustomer({
    required String userEmail,
    required String customerId,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Customers node se customer ka data delete karna
      final customerDeleteRes = await client.delete(
        Uri.parse("$cleanUrl/customers/$sEmail/$customerId.json"),
      );

      // 2. Master measurements node se bhi us customer ka data delete karna
      final masterDeleteRes = await client.delete(
        Uri.parse("$cleanUrl/master_measurements/$sEmail/$customerId.json"),
      );

      if (customerDeleteRes.statusCode == 200) {
        return {"status": true, "message": "Customer successfully delete ho gaya!"};
      } else {
        return {"status": false, "message": "Customer delete nahi ho paya."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }
  //============================================= Customer Screen ===================================
  // --- REAL FIREBASE SE CUSTOMERS AUR ORDERS FETCH KARNE KA FUNCTION ---
  // --- REAL FIREBASE SE CUSTOMERS, ORDERS AUR MASTER MEASUREMENTS FETCH KARNE KA FUNCTION ---
  static Future<List<Map<String, dynamic>>> fetchCustomersFromFirebase(String userEmail) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Customers aur Master Measurements dono ko ek sath fetch karna
      final customersFuture = client.get(Uri.parse("$cleanUrl/customers/$sEmail.json"));
      final masterMeasFuture = client.get(Uri.parse("$cleanUrl/master_measurements/$sEmail.json"));

      final responses = await Future.wait([customersFuture, masterMeasFuture]);
      
      final customersRes = responses[0];
      final masterMeasRes = responses[1];

      Map<String, dynamic> masterMeasurementsData = {};
      if (masterMeasRes.statusCode == 200 && masterMeasRes.body != 'null') {
        masterMeasurementsData = json.decode(masterMeasRes.body);
      }

      if (customersRes.statusCode == 200 && customersRes.body != 'null') {
        Map<String, dynamic> data = json.decode(customersRes.body);
        List<Map<String, dynamic>> loadedCustomers = [];

        data.forEach((customerId, customerValue) {
          if (customerValue is Map) {
            var custMap = Map<String, dynamic>.from(customerValue);
            custMap['id'] = customerId;

            // Firebase me 'photo' key hai, usko properly handle karna
            custMap['photo'] = custMap['photo'] ?? custMap['image'] ?? custMap['image_url'] ?? '';

            // 2. Is customer ka master measurement attach karna (agar available ho)
            if (masterMeasurementsData.containsKey(customerId)) {
              custMap['master_measurement'] = masterMeasurementsData[customerId];
            } else {
              custMap['master_measurement'] = {};
            }

            // Orders ko list me convert karna
            var ordersMap = custMap['orders'];
            List<Map<String, dynamic>> ordersList = [];
            if (ordersMap is Map) {
              ordersMap.forEach((orderId, orderValue) {
                if (orderValue is Map) {
                  var ordMap = Map<String, dynamic>.from(orderValue);
                  ordMap['id'] = orderId;
                  ordersList.add(ordMap);
                }
              });
            }
            custMap['orderHistory'] = ordersList;
            loadedCustomers.add(custMap);
          }
        });
        return loadedCustomers;
      }
      return [];
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    } finally {
      client.close();
    }
  }

  //================= GET NEXT ORDER SEQUENCE FOR CUSTOMER =================
  static Future<int> getNextOrderSequenceForCustomer({
    required String userEmail, 
    required String customerId,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Specific customer ke orders node ko fetch karna
      final response = await client.get(
        Uri.parse("$cleanUrl/customers/$sEmail/$customerId/orders.json"),
      );

      if (response.statusCode == 200 && response.body != 'null') {
        final data = json.decode(response.body);
        if (data is Map) {
          // Jitne orders pehle se stored hain, unki count nikal kar +1 kar denge
          return data.keys.length + 1;
        }
      }
      // Agar koi order nahi mila ya pehla order hai, toh sequence 1 se shuru hoga
      return 1;
    } catch (e) {
      print("Error getting next order sequence: $e");
      return 1;
    } finally {
      client.close();
    }
  }

  //================= FETCH MASTER MEASUREMENTS FOR CUSTOMER =================
  // Master measurements fetch karte waqt specific garments ke hisaब se filter karne ke liye
  static Future<Map<String, String>> fetchCustomerMasterMeasurements({
    required String userEmail,
    required String customerId,
    String? currentGarmentType, // Naya optional parameter
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      final response = await client.get(
        Uri.parse("$cleanUrl/master_measurements/$sEmail/$customerId.json"),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null') {
        Map<dynamic, dynamic> data = json.decode(response.body);
        Map<String, String> measurements = {};
        
        // Garment ke hisaab se keywords map kar sakte hain ya exact match kar sakte hain
        // Jaise agar 'Shirt' select hai toh chest, length, sleeve wale hi keys aayein
        data.forEach((key, value) {
          if (key != 'updated_at') {
            measurements[key.toString()] = value.toString();
          }
        });

        // Agar aapko specific garment ke hisaab se keys filter karni hain toh yahan logic laga sakte hain
        return measurements;
      }
      return {};
    } catch (e) {
      print("Error fetching master measurements: $e");
      return {};
    } finally {
      client.close();
    }
  }
//==============================due payment==========================================
  static Future<Map<String, dynamic>> payCustomerDue({
    required String userEmail,
    required String customerId,
    required String orderId,
    required double paidAmount,
    required String paymentMethod,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Order ke payment details fetch karein
      final paymentRefUrl = "$cleanUrl/customers/$sEmail/$customerId/orders/$orderId/payment_details.json";
      final response = await client.get(Uri.parse(paymentRefUrl));

      if (response.statusCode != 200 || response.body == 'null') {
        return {"status": false, "message": "Order payment details nahi milin!"};
      }

      Map<String, dynamic> paymentData = json.decode(response.body);
      double currentDue = double.tryParse(paymentData['due']?.toString() ?? '0') ?? 0;
      double currentAdvance = double.tryParse(paymentData['advance']?.toString() ?? '0') ?? 0;

      // 2. Strict Validation: Paid amount due se zyada nahi hona chahiye
      if (paidAmount > currentDue) {
        return {
          "status": false, 
          "message": "Error: Paid amount (₹$paidAmount) current due (₹$currentDue) se zyada nahi ho sakta!"
        };
      }

      if (paidAmount <= 0) {
        return {"status": false, "message": "Kripya valid amount enter karein!"};
      }

      // 3. New Due aur Advance calculate karein
      double newDue = currentDue - paidAmount;
      double newAdvance = currentAdvance + paidAmount;

      // 4. Firebase me update karein
      final updateRes = await client.patch(
        Uri.parse(paymentRefUrl),
        body: json.encode({
          "due": newDue.toStringAsFixed(2),
          "advance": newAdvance.toStringAsFixed(2),
          "last_payment_method": paymentMethod,
          "last_paid_amount": paidAmount.toStringAsFixed(2),
        }),
      );

      if (updateRes.statusCode == 200) {
        return {"status": true, "message": "Payment successfully record ho gaya!"};
      } else {
        return {"status": false, "message": "Database update fail ho gaya."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  //================= FETCH SINGLE CUSTOMER =================
  static Future<Map<String, dynamic>?> fetchSingleCustomer(String userEmail, String customerId) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Specific customer aur uska master measurement ek sath fetch karna
      final customerFuture = client.get(Uri.parse("$cleanUrl/customers/$sEmail/$customerId.json"));
      final masterMeasFuture = client.get(Uri.parse("$cleanUrl/master_measurements/$sEmail/$customerId.json"));

      final responses = await Future.wait([customerFuture, masterMeasFuture]);
      
      final customerRes = responses[0];
      final masterMeasRes = responses[1];

      if (customerRes.statusCode == 200 && customerRes.body != 'null') {
        Map<String, dynamic> custMap = Map<String, dynamic>.from(json.decode(customerRes.body));
        custMap['id'] = customerId;

        // Firebase me 'photo' key ko properly handle karna
        custMap['photo'] = custMap['photo'] ?? custMap['image'] ?? custMap['image_url'] ?? '';

        // 2. Master measurement attach karna (agar available ho)
        if (masterMeasRes.statusCode == 200 && masterMeasRes.body != 'null') {
          custMap['master_measurement'] = json.decode(masterMeasRes.body);
        } else {
          custMap['master_measurement'] = {};
        }

        // 3. Orders ko list me convert karna
        var ordersMap = custMap['orders'];
        List<Map<String, dynamic>> ordersList = [];
        if (ordersMap is Map) {
          ordersMap.forEach((orderId, orderValue) {
            if (orderValue is Map) {
              var ordMap = Map<String, dynamic>.from(orderValue);
              ordMap['id'] = orderId;
              ordersList.add(ordMap);
            }
          });
        }
        custMap['orderHistory'] = ordersList;

        return custMap;
      }
      return null;
    } catch (e) {
      print("Fetch Single Customer Error: $e");
      return null;
    } finally {
      client.close();
    }
  }

  // ================== UPDATE ORDER STATUS IN FIREBASE ==================
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String userEmail,
    required String customerId,
    required String orderId,
    required String newStatus,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Order details aur root order node dono jagah status update karna taaki mismatch na ho
      final orderDetailsUrl = "$cleanUrl/customers/$sEmail/$customerId/orders/$orderId/order_details.json";
      
      final response = await client.patch(
        Uri.parse(orderDetailsUrl),
        body: json.encode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        // Root level par bhi status update kar dete hain safety ke liye
        await client.patch(
          Uri.parse("$cleanUrl/customers/$sEmail/$customerId/orders/$orderId.json"),
          body: json.encode({"status": newStatus}),
        );
        
        return {"status": true, "message": "Order status successfully update ho gaya!"};
      } else {
        return {"status": false, "message": "Order status update nahi ho paya."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> deleteOrder({
    required String userEmail,
    required String customerId,
    required String orderId,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Customers node se specific order ko delete karna
      final response = await client.delete(
        Uri.parse("$cleanUrl/customers/$sEmail/$customerId/orders/$orderId.json"),
      );

      if (response.statusCode == 200) {
        return {"status": true, "message": "Order successfully delete ho gaya!"};
      } else {
        return {"status": false, "message": "Order delete nahi ho paya."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

//===================================== Worker Page ===================================
  //===================================== Worker Page ===================================
  // 1. Save Worker to Firebase (With Image Support)
  static Future<Map<String, dynamic>> saveWorkerToFirebase({
    required String userEmail,
    required String workerId,
    required Map<String, dynamic> workerData,
    File? workerImage, // <-- Optional image parameter add kiya gaya hai
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Agar user ne image select ki hai, toh use Base64 string me convert karke workerData me daal denge
      if (workerImage != null) {
        List<int> imageBytes = await workerImage.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        workerData['photo'] = "data:image/jpeg;base64,$base64Image";
      }

      final response = await client.put(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId.json"),
        body: json.encode({
          ...workerData,
          "created_at": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return {"status": true, "message": "Worker successfully save ho gaya!"};
      } else {
        return {"status": false, "message": "Worker save nahi ho paya."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  // 2. Fetch Workers from Firebase (With Image/Photo Mapping)
  static Future<List<Map<String, dynamic>>> fetchWorkersFromFirebase(String userEmail) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      final response = await client.get(Uri.parse("$cleanUrl/workers/$sEmail.json"));

      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> loadedWorkers = [];

        data.forEach((workerId, workerValue) {
          if (workerValue is Map) {
            var wrkMap = Map<String, dynamic>.from(workerValue);
            wrkMap['id'] = workerId;
            
            // Photo/Image key ko safely map karna taaki fetch me missing na ho
            wrkMap['photo'] = wrkMap['photo'] ?? wrkMap['image'] ?? wrkMap['image_url'] ?? '';

            loadedWorkers.add(wrkMap);
          }
        });
        return loadedWorkers;
      }
      return [];
    } catch (e) {
      print("Fetch Workers Error: $e");
      return [];
    } finally {
      client.close();
    }
  }

  // 3. Delete Worker from Firebase
  // ================== DELETE WORKER COMPLETELY WITH ID ==================
  static Future<Map<String, dynamic>> deleteWorker({
    required String userEmail,
    required String workerId,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. workers -> sEmail -> workerId वाले पाथ पर DELETE रिक्वेस्ट भेजें
      // इससे उस वर्कर का पूरा डेटा (डिटेल्स, एंट्रीज़, मंथली रिकॉर्ड्स आदि) हमेशा के लिए डिलीट हो जाएगा
      final response = await client.delete(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId.json"),
      );

      if (response.statusCode == 200) {
        return {"status": true, "message": "Worker successfully delete ho gaya!"};
      } else {
        return {"status": false, "message": "Worker delete nahi ho paya."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  // ================== UPDATE WORKER STATUS IN FIREBASE ==================
  static Future<Map<String, dynamic>> updateWorkerStatus({
    required String userEmail,
    required String workerId,
    required String newStatus,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      final response = await client.patch(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId.json"),
        body: json.encode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        return {"status": true, "message": "Worker status successfully updated!"};
      } else {
        return {"status": false, "message": "Failed to update worker status."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }
  
// ================== FETCH WORKER RATES ==================
  // ================== FETCH WORKER RATES ==================
  // ================== FETCH GLOBAL / MASTER RATES ==================
  static Future<Map<String, double>> fetchGlobalRates(String userEmail) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Path: global_rates -> sEmail.json (Without workerId)
      final response = await client.get(Uri.parse("$cleanUrl/global_rates/$sEmail.json"));

      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> rawData = json.decode(response.body);
        Map<String, double> parsedRates = {};
        
        rawData.forEach((key, value) {
          parsedRates[key] = double.tryParse(value.toString()) ?? 0.0;
        });
        
        return parsedRates;
      }
      return {};
    } catch (e) {
      print("Fetch Global Rates Error: $e");
      return {};
    } finally {
      client.close();
    }
  }

  // ================== SAVE GLOBAL RATES (PUT) ==================
  static Future<Map<String, dynamic>> saveGlobalRates({
    required String userEmail,
    required Map<String, dynamic> ratesData,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Path: global_rates -> sEmail.json
      final response = await client.put(
        Uri.parse("$cleanUrl/global_rates/$sEmail.json"),
        body: json.encode(ratesData),
      );

      if (response.statusCode == 200) {
        return {"status": true, "message": "Global rates successfully saved!"};
      } else {
        return {"status": false, "message": "Failed to save global rates."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  // ================== UPDATE GLOBAL RATE (PATCH) ==================
  static Future<bool> updateGlobalRate({
    required String userEmail,
    required String garmentName,
    required double rate,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Path: global_rates -> sEmail.json
      final response = await client.patch(
        Uri.parse("$cleanUrl/global_rates/$sEmail.json"),
        body: json.encode({garmentName: rate}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Update Global Rate Error: $e");
      return false;
    } finally {
      client.close();
    }
  }

  // ================== DELETE GLOBAL RATE ==================
  static Future<bool> deleteGlobalRate({
    required String userEmail,
    required String garmentName,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Firebase Realtime Database me kisi specific key ko delete karne ke liye 
      // us key par null value ka http.put ya http.patch request bheja jata hai.
      final response = await client.patch(
        Uri.parse("$cleanUrl/global_rates/$sEmail.json"),
        body: json.encode({garmentName: null}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Delete Global Rate Error: $e");
      return false;
    } finally {
      client.close();
    }
  }

  // ================== SAVE WORKER DAILY ENTRY ==================
  // ================== SAVE WORKER DAILY ENTRY (EASY WAY) ==================
  static Future<bool> saveWorkerDailyEntry({
    required String userEmail,
    required String workerId,
    required DateTime selectedDate,
    required Map<String, int> quantities,
    required Map<String, double> rates,
    required double totalEarnings,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);
      
      String dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
      int totalPieces = 0;
      quantities.forEach((_, qty) => totalPieces += qty);

      final entryPayload = {
        "date": dateKey,
        "quantities": quantities,
        "rates": rates,
        "total_pieces": totalPieces,
        "total_earnings": totalEarnings,
        "updated_at": DateTime.now().toIso8601String(),
      };

      // Direct exact path: workers -> email -> workerId -> entries -> dateKey.json
      final response = await client.put(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId/entries/$dateKey.json"),
        body: json.encode(entryPayload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Save Worker Entry Error: $e");
      return false;
    } finally {
      client.close();
    }
  }

  // ================== FETCH WORKER DAILY ENTRIES ==================
  static Future<List<Map<String, dynamic>>> fetchWorkerEntries({
    required String userEmail,
    required String workerId,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      final response = await client.get(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId/entries.json"),
      );

      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> entriesList = [];

        data.forEach((dateKey, entryValue) {
          if (entryValue is Map) {
            var entryMap = Map<String, dynamic>.from(entryValue);
            entryMap['date'] = dateKey; // Date key ko ensure karein
            entriesList.add(entryMap);
          }
        });

        // Newest date pehle sort karein
        entriesList.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
        return entriesList;
      }
      return [];
    } catch (e) {
      print("Fetch Worker Entries Error: $e");
      return [];
    } finally {
      client.close();
    }
  }

  // ================== DELETE WORKER DAILY ENTRY ==================
  static Future<bool> deleteWorkerDailyEntry({
    required String userEmail,
    required String workerId,
    required String dateKey, // Jaise "2026-06-05"
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Firebase Realtime Database me specific date ki entry delete karne ke liye DELETE request
      final response = await client.delete(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId/entries/$dateKey.json"),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Delete Worker Entry Error: $e");
      return false;
    } finally {
      client.close();
    }
  }

  //===================================Salary Button ==========================================
  static Future<bool> saveMonthlySalaryRecord({
    required String userEmail,
    required String workerId,
    required String monthKey, // Jaise "2026-08"
    required Map<String, dynamic> salaryData,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Path: workers -> email -> workerId -> monthly_records -> 2026-08.json
      final response = await client.put(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId/monthly_records/$monthKey.json"),
        body: json.encode({
          ...salaryData,
          "updated_at": DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Save Monthly Salary Error: $e");
      return false;
    } finally {
      client.close();
    }
  }


  static Future<Map<String, dynamic>> fetchMonthlySalaryRecord({
    required String userEmail,
    required String workerId,
    required String monthKey,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      final response = await client.get(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId/monthly_records/$monthKey.json"),
      );

      if (response.statusCode == 200 && response.body != 'null') {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
      return {};
    } catch (e) {
      print("Fetch Monthly Salary Error: $e");
      return {};
    } finally {
      client.close();
    }
  }

  // ================== FETCH SINGLE WORKER DETAILS ==================
  static Future<Map<String, dynamic>?> fetchWorkerDetails({
    required String userEmail,
    required String workerId,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      final response = await client.get(
        Uri.parse("$cleanUrl/workers/$sEmail/$workerId.json"),
      );

      if (response.statusCode == 200 && response.body != 'null') {
        var workerData = Map<String, dynamic>.from(json.decode(response.body));
        workerData['id'] = workerId;
        workerData['photo'] = workerData['photo'] ?? workerData['image'] ?? workerData['image_url'] ?? '';
        return workerData;
      }
      return null;
    } catch (e) {
      print("Fetch Worker Details Error: $e");
      return null;
    } finally {
      client.close();
    }
  }

//=========================================setting Page ======================================

  // ================== 16. SAVE / SHOP INFORMATION (Settings Structure) ==================
  static Future<Map<String, dynamic>> saveShopInformation({
    required String userEmail,
    required String shopName,
    required String ownerName,
    required String phone,
    required String address,
    File? shopImage, // Optional shop/QR image
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Base Payload tayar karein
      Map<String, dynamic> shopPayload = {
        "shop_name": shopName.trim(),
        "owner_name": ownerName.trim(),
        "phone": phone.trim(),
        "address": address.trim(),
        "updated_at": DateTime.now().toIso8601String(),
      };

      // 2. Agar image di gayi hai toh use Base64 mein convert karein
      if (shopImage != null) {
        List<int> imageBytes = await shopImage.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        shopPayload['photo'] = "data:image/jpeg;base64,$base64Image";
      }

      // 3. Path change karke settings -> email -> shop_detail kar diya gaya hai
      final response = await client.patch(
        Uri.parse("$cleanUrl/settings/$sEmail/shop_detail.json"),
        body: json.encode(shopPayload),
      );

      if (response.statusCode == 200) {
        return {"status": true, "message": "Shop information successfully save ho gayi!"};
      } else {
        return {"status": false, "message": "Shop information save nahi ho payi."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  // ================== FETCH USER PROFILE ==================
  static Future<Map<String, dynamic>?> fetchUserProfile(String userEmail) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Path: users -> sEmail.json
      final response = await client.get(
        Uri.parse("$cleanUrl/users/$sEmail.json"),
      );

      if (response.statusCode == 200 && response.body != 'null') {
        var userData = Map<String, dynamic>.from(json.decode(response.body));
        return userData;
      }
      return null;
    } catch (e) {
      debugPrint("Fetch User Profile Error: $e");
      return null;
    } finally {
      client.close();
    }
  }

  // 2. Update User Profile (Name, Phone, and Optional Profile Image - Email is safe)
  static Future<bool> updateUserProfile({
    required String email,
    required String fullName,
    required String phone,
    required String username,
    File? imageFile, // Image file yahan accept ki ja rahi hai
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(email);

      // Update data map (Email ko include nahi kiya gaya hai taaki overwrite na ho)
      final Map<String, dynamic> updateData = {
        'full_name': fullName,
        'phone': phone,
        'username': username,
      };

      // Agar image file di gayi hai toh use base64 mein convert karke add karein
      if (imageFile != null) {
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        updateData['profile_image'] = 'data:image/jpeg;base64,$base64Image';
      }

      // Firebase Realtime Database / API ke mutabiq PATCH request
      final response = await client.patch(
        Uri.parse("$cleanUrl/users/$sEmail.json"),
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Update User Profile Error: $e");
      return false;
    } finally {
      client.close();
    }
  }

  // ================== UPDATE PASSWORD ONLY (Dedicated Function) ==================
  // ================== UPDATE PASSWORD WITH INTERNAL VERIFICATION ==================
  static Future<Map<String, dynamic>> updatePasswordOnly({
    required String userEmail,
    required String currentPassword, // Naya parameter current password ke liye
    required String newPassword,
  }) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // 1. Pehle user ka data fetch karein taaki current password check kar sakein
      final getResponse = await client.get(Uri.parse("$cleanUrl/users/$sEmail.json"));

      if (getResponse.statusCode == 200 && getResponse.body != 'null') {
        final data = json.decode(getResponse.body);

        // 2. Check karein ki password field milti hai ya nahi aur current password sahi hai ya nahi
        if (data is Map && data.containsKey('password')) {
          String storedPassword = data['password'].toString();

          if (storedPassword != currentPassword.trim()) {
            return {"status": false, "message": "Current password galat hai!"};
          }
        } else {
          return {"status": false, "message": "User data nahi mila."};
        }

        // 3. Agar current password match ho jaye, tab PATCH request se naya password update karein
        final response = await client.patch(
          Uri.parse("$cleanUrl/users/$sEmail.json"),
          body: json.encode({
            'password': newPassword.trim(),
          }),
        );

        if (response.statusCode == 200) {
          return {"status": true, "message": "Password successfully update ho gaya!"};
        } else {
          return {"status": false, "message": "Password update nahi ho paya."};
        }
      } else {
        return {"status": false, "message": "User nahi mila."};
      }
    } catch (e) {
      return {"status": false, "message": "Error: ${e.toString()}"};
    } finally {
      client.close();
    }
  }

  // ================== 17. FETCH SHOP INFORMATION ==================
  static Future<Map<String, dynamic>?> fetchShopInformation(String userEmail) async {
    final client = http.Client();
    try {
      final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
      final sEmail = getSafeEmail(userEmail);

      // Yahan bhi wahi exact path fetch karne ke liye diya gaya hai
      final response = await client.get(
        Uri.parse("$cleanUrl/settings/$sEmail/shop_detail.json"),
      );

      if (response.statusCode == 200 && response.body != 'null') {
        var shopData = Map<String, dynamic>.from(json.decode(response.body));
        shopData['photo'] = shopData['photo'] ?? shopData['image'] ?? '';
        return shopData;
      }
      return null;
    } catch (e) {
      debugPrint("Fetch Shop Info Error: $e");
      return null;
    } finally {
      client.close();
    }
  }

//=================================Report Page =============================================
  // ================== FETCH REPORTS SUMMARY DATA FROM FIREBASE ==================
  static Future<Map<String, dynamic>> fetchReportsSummaryData(String userEmail, {String filter = 'हा महिना'}) async {
  final client = http.Client();
  try {
    final cleanUrl = BASE_URL.replaceAll(RegExp(r'/$'), '');
    final sEmail = getSafeEmail(userEmail);

    // 1. Fetch Orders, Customers, and Workers concurrently
    final ordersFuture = client.get(Uri.parse("$cleanUrl/customers/$sEmail.json"));
    final workersFuture = client.get(Uri.parse("$cleanUrl/workers/$sEmail.json"));

    final responses = await Future.wait([ordersFuture, workersFuture]);
    
    final customersRes = responses[0];
    final workersRes = responses[1];

    // Calculate Start Date and End Date based on the selected filter
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (filter == 'आज') {
      startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    } else if (filter == 'या आठवड्यात') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    } else if (filter == 'हा महिना') {
      startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    } else if (filter == 'या वर्षी') {
      startDate = DateTime(now.year, 1, 1, 0, 0, 0);
    } else if (filter.contains('-')) {
      try {
        if (filter.length == 4 && int.tryParse(filter) != null) {
          int year = int.parse(filter);
          startDate = DateTime(year, 1, 1, 0, 0, 0);
          endDate = DateTime(year, 12, 31, 23, 59, 59);
        } else {
          List<String> parts = filter.split(' - ');
          List<String> startParts = parts[0].trim().split('/');
          List<String> endParts = parts[1].trim().split('/');
          
          startDate = DateTime(int.parse(startParts[2]), int.parse(startParts[1]), int.parse(startParts[0]), 0, 0, 0);
          endDate = DateTime(int.parse(endParts[2]), int.parse(endParts[1]), int.parse(endParts[0]), 23, 59, 59);
        }
      } catch (e) {
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
      }
    } else {
      startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    }

    // पिछले महीने की शुरुआत और अंत की तारीख कैलकुलेट करें (Real Comparison के लिए)
    DateTime prevStartDate = DateTime(startDate.year, startDate.month - 1, 1, 0, 0, 0);
    DateTime prevEndDate = DateTime(startDate.year, startDate.month, 0, 23, 59, 59);

    double totalRevenue = 0.0;
    double receivedAmount = 0.0;
    double pendingAmount = 0.0;
    int totalOrdersCount = 0;
    int totalCustomersCount = 0;

    // पिछले महीने के आंकड़े स्टोर करने के लिए वेरिएल्स
    double prevRevenue = 0.0;
    int prevOrdersCount = 0;
    Set<String> prevActiveCustomerIds = {};

    int todayOrdersCount = 0;
    int pendingOrdersCount = 0;
    int readyOrdersCount = 0;
    int deliveredOrdersCount = 0;

    Map<String, double> paymentModes = {'Cash': 0.0, 'UPI': 0.0, 'Card': 0.0};
    Map<String, int> garmentCounts = {};
    Set<String> activeCustomerIds = {};

    // Real Trend Data Collection Map
    Map<String, double> rawTrendMap = {};

    // Helper method to clean and unify garment names completely
    String getNormalizedGarmentName(String rawName) {
      String lowerName = rawName.toLowerCase().trim();
      
      // शर्ट के सभी रूपों को एक करना
      if (lowerName.contains('shirt') || lowerName.contains('शर्ट')) {
        return 'Shirt';
      } 
      // पैंट के सभी रूपों (Pant, Pants, पॅंट, पैँट, पेंट, trouser आदि) को एक करना
      else if (lowerName.contains('pant') || 
               lowerName.contains('पॅंट') || 
               lowerName.contains('पैँट') || 
               lowerName.contains('पेंट') || 
               lowerName.contains('trouser')) {
        return 'Pant';
      }
      
      return rawName;
    }

    // 2. Process Customers and Orders Data
    if (customersRes.statusCode == 200 && customersRes.body != 'null') {
      Map<String, dynamic> customersData = json.decode(customersRes.body);

      customersData.forEach((customerId, customerVal) {
        if (customerVal is Map && customerVal.containsKey('orders')) {
          var ordersMap = customerVal['orders'];
          if (ordersMap is Map) {
            ordersMap.forEach((orderId, orderVal) {
              if (orderVal is Map) {
                String? createdAt = orderVal['created_at'] ?? orderVal['order_details']?['created_at'];
                DateTime? orderDate;
                if (createdAt != null) {
                  orderDate = DateTime.tryParse(createdAt);
                }

                if (orderDate == null) return;

                var paymentDetails = orderVal['payment_details'] ?? {};
                double totalAmt = double.tryParse(paymentDetails['total']?.toString() ?? paymentDetails['totalAmount']?.toString() ?? '0') ?? 0.0;
                double advanceAmt = double.tryParse(paymentDetails['advance']?.toString() ?? '0') ?? 0.0;

                // --- 1. Current Period Data Calculation ---
                if (!orderDate.isBefore(startDate) && !orderDate.isAfter(endDate)) {
                  totalOrdersCount++;
                  activeCustomerIds.add(customerId);

                  var orderDetails = orderVal['order_details'] ?? {};
                  String status = (orderDetails['status'] ?? '').toString().toLowerCase();
                  if (status.contains('pending') || status.contains('प्रलंबित')) {
                    pendingOrdersCount++;
                  } else if (status.contains('ready') || status.contains('तयार')) {
                    readyOrdersCount++;
                  } else if (status.contains('delivered') || status.contains('वितरित')) {
                    deliveredOrdersCount++;
                  }

                  // --- गारमेंट्स को प्रोसेस और मर्ज करने का सही तरीका ---
                  var garmentsData = orderVal['garments'] ?? orderDetails['garments'];
                  if (garmentsData != null) {
                    if (garmentsData is Map) {
                      garmentsData.forEach((gKey, gVal) {
                        if (gVal is Map) {
                          String rawName = (gVal['name'] ?? gVal['garment_type'] ?? 'Shirt').toString().trim();
                          String garmentName = getNormalizedGarmentName(rawName);

                          int qty = int.tryParse(gVal['qty']?.toString() ?? gVal['quantity']?.toString() ?? '1') ?? 1;
                          garmentCounts[garmentName] = (garmentCounts[garmentName] ?? 0) + qty;
                        }
                      });
                    } else if (garmentsData is List) {
                      for (var gVal in garmentsData) {
                        if (gVal is Map) {
                          String rawName = (gVal['name'] ?? gVal['garment_type'] ?? 'Shirt').toString().trim();
                          String garmentName = getNormalizedGarmentName(rawName);

                          int qty = int.tryParse(gVal['qty']?.toString() ?? gVal['quantity']?.toString() ?? '1') ?? 1;
                          garmentCounts[garmentName] = (garmentCounts[garmentName] ?? 0) + qty;
                        }
                      }
                    }
                  } else {
                    String rawName = (orderDetails['garment_type'] ?? orderDetails['item'] ?? 'Shirt').toString().trim();
                    String garmentName = getNormalizedGarmentName(rawName);
                    garmentCounts[garmentName] = (garmentCounts[garmentName] ?? 0) + 1;
                  }

                  if (orderDate.year == now.year && orderDate.month == now.month && orderDate.day == now.day) {
                    todayOrdersCount++;
                  }

                  double dueAmt = double.tryParse(paymentDetails['due']?.toString() ?? '0') ?? (totalAmt - advanceAmt);

                  totalRevenue += totalAmt;
                  receivedAmount += advanceAmt;
                  pendingAmount += dueAmt;

                  String dayKey = "${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}";
                  rawTrendMap[dayKey] = (rawTrendMap[dayKey] ?? 0.0) + totalAmt;

                  // --- UPDATED PAYMENT MODE LOGIC (Advance & Last Paid Split) ---
                  double lastPaidAmt = double.tryParse(paymentDetails['last_paid_amount']?.toString() ?? '0') ?? 0.0;
                  String initialPayMode = (paymentDetails['payment_method'] ?? 'Cash').toString().trim();
                  String lastPayMode = (paymentDetails['last_payment_method'] ?? initialPayMode).toString().trim();

                  if (lastPaidAmt > 0 && lastPayMode != initialPayMode) {
                    double cashPart = advanceAmt - lastPaidAmt;
                    if (cashPart < 0) cashPart = 0;

                    if (cashPart > 0) {
                      paymentModes[initialPayMode] = (paymentModes[initialPayMode] ?? 0.0) + cashPart;
                    }
                    paymentModes[lastPayMode] = (paymentModes[lastPayMode] ?? 0.0) + lastPaidAmt;
                  } else {
                    if (advanceAmt > 0) {
                      paymentModes[initialPayMode] = (paymentModes[initialPayMode] ?? 0.0) + advanceAmt;
                    }
                  }
                }

                // --- 2. Previous Period Data Calculation (For Real Comparison) ---
                if (!orderDate.isBefore(prevStartDate) && !orderDate.isAfter(prevEndDate)) {
                  prevOrdersCount++;
                  prevActiveCustomerIds.add(customerId);
                  prevRevenue += totalAmt;
                }
              }
            });
          }
        }
      });
    }

    totalCustomersCount = activeCustomerIds.length;
    int prevCustomersCount = prevActiveCustomerIds.length;

    // 3. Process Workers Data
    List<Map<String, dynamic>> workerList = [];
    if (workersRes.statusCode == 200 && workersRes.body != 'null') {
      Map<String, dynamic> workersData = json.decode(workersRes.body);
      workersData.forEach((workerId, workerVal) {
        if (workerVal is Map) {
          String name = workerVal['name'] ?? 'Worker';
          
          double earned = 0.0;
          int totalPieces = 0;
          
          var entriesMap = workerVal['entries'];
          if (entriesMap is Map) {
            entriesMap.forEach((dateKey, entryVal) {
              DateTime? entryDate = DateTime.tryParse(dateKey);
              if (entryDate != null) {
                if (entryDate.isBefore(startDate) || entryDate.isAfter(endDate)) {
                  return;
                }
              }

              if (entryVal is Map) {
                earned += double.tryParse(entryVal['total_earnings']?.toString() ?? '0') ?? 0.0;
                totalPieces += int.tryParse(entryVal['total_pieces']?.toString() ?? '0') ?? 0;
              }
            });
          }

          double paid = 0.0;
          var monthlyRecordsMap = workerVal['monthly_records'];
          if (monthlyRecordsMap is Map) {
            monthlyRecordsMap.forEach((monthKey, monthVal) {
              if (monthVal is Map) {
                try {
                  List<String> parts = monthKey.split('-');
                  int recordYear = int.parse(parts[0]);
                  int recordMonth = int.parse(parts[1]);
                  
                  DateTime monthStart = DateTime(recordYear, recordMonth, 1);
                  DateTime monthEnd = DateTime(recordYear, recordMonth + 1, 0, 23, 59, 59);

                  if (!(monthEnd.isBefore(startDate) || monthStart.isAfter(endDate))) {
                    if (monthVal['isPaid'] == true || monthVal['isPaid'].toString() == 'true') {
                      paid += double.tryParse(monthVal['paidAmount']?.toString() ?? '0') ?? 0.0;
                    }
                  }
                } catch (e) {
                  // Fallback
                }
              }
            });
          }

          double due = earned - paid;

          workerList.add({
            'name': name,
            'pieces': "$totalPieces Pieces",
            'earned': earned,
            'paid': paid,
            'due': due < 0 ? 0.0 : due,
          });
        }
      });
    }

    double avgOrderValue = totalOrdersCount > 0 ? (totalRevenue / totalOrdersCount) : 0.0;
    double prevAvgOrderValue = prevOrdersCount > 0 ? (prevRevenue / prevOrdersCount) : 0.0;

    if (totalOrdersCount == 0) {
      paymentModes.updateAll((key, value) => 0.0);
    }

    // 4. Convert Real Trend Map into List for UI Graph
    List<Map<String, dynamic>> trendData = [];
    rawTrendMap.forEach((dateStr, amount) {
      trendData.add({
        'label': dateStr,
        'amount': amount,
        'interval': filter,
      });
    });

    trendData.sort((a, b) => a['label'].compareTo(b['label']));

    // --- 5. Real Percentage Trend Calculations ---
    String calculateTrend(num current, num previous) {
      if (previous == 0) {
        return current > 0 ? '▲ 100%' : '0%';
      }
      double percent = ((current - previous) / previous) * 100;
      if (percent > 0) {
        return '▲ ${percent.toStringAsFixed(0)}%';
      } else if (percent < 0) {
        return '▼ ${percent.abs().toStringAsFixed(0)}%';
      } else {
        return '0%';
      }
    }

    Map<String, dynamic> monthlyComparison = {
      'prevMonthName': 'मागील महिना',
      'currMonthName': 'चालू महिना',
      'prevOrders': prevOrdersCount,
      'prevRevenue': prevRevenue.toStringAsFixed(0),
      'prevCustomers': prevCustomersCount,
      'prevAvgValue': prevAvgOrderValue.toStringAsFixed(0),
      'ordersTrend': calculateTrend(totalOrdersCount, prevOrdersCount),
      'revenueTrend': calculateTrend(totalRevenue, prevRevenue),
      'customersTrend': calculateTrend(totalCustomersCount, prevCustomersCount),
      'avgValueTrend': calculateTrend(avgOrderValue, prevAvgOrderValue),
    };

    return {
      "status": true,
      "totalRevenue": totalRevenue,
      "receivedAmount": receivedAmount,
      "pendingAmount": pendingAmount,
      "totalOrders": totalOrdersCount,
      "totalCustomers": totalCustomersCount,
      "avgOrderValue": avgOrderValue,
      "todayOrdersCount": todayOrdersCount,
      "pendingOrdersCount": pendingOrdersCount,
      "readyOrdersCount": readyOrdersCount,
      "deliveredOrdersCount": deliveredOrdersCount,
      "paymentModes": paymentModes,
      "workerList": workerList,
      "garmentCounts": garmentCounts,
      "trendData": trendData,
      "monthlyComparison": monthlyComparison,
    };
  } catch (e) {
    print("Error fetching reports summary: $e");
    return {"status": false, "message": e.toString()};
  } finally {
    client.close();
  }
}
  

  
}