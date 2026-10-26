import 'package:flutter/material.dart';
import 'worker_list_view.dart';
import 'worker_profile_view.dart';
import 'sub_module_container.dart';
import 'master_rate_view.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../database.dart';


class WorkerScreen extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String userEmail;

  const WorkerScreen({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.userEmail,
  });

  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  int _navigationLevel = 0; // 0: List, 1: Profile, 2: Sub-module, 3: Master Rates
  Map<String, dynamic>? _selectedWorker;
  String _activeSubModule = '';

  // Updated Exact Color from your reference image
  final Color primaryPurple = const Color(0xFF8B31FF);
  final Color accentYellow = const Color(0xFFFFB300);

  // Dynamic Rates aur Quantities
  Map<String, double> _rates = {};
  Map<String, int> _todayQuantities = {};
  bool _isLoadingRates = true;

  List<Map<String, dynamic>> _workers = [];
  bool _isLoadingWorkers = true;

  @override
  void initState() {
    super.initState();
    _loadWorkersFromFirebase();
    _loadRatesFromFirebase();
  }

  Future<void> _loadWorkersFromFirebase() async {
    setState(() {
      _isLoadingWorkers = true;
    });

    List<Map<String, dynamic>> fetchedWorkers = await DatabaseService.fetchWorkersFromFirebase(widget.userEmail);

    setState(() {
      _workers = fetchedWorkers;
      _isLoadingWorkers = false;
    });
  }

  Future<void> _loadRatesFromFirebase() async {
    setState(() {
      _isLoadingRates = true;
    });

    Map<String, double> fetchedRates = await DatabaseService.fetchGlobalRates(widget.userEmail);

    setState(() {
      _rates = fetchedRates;
      _isLoadingRates = false;
    });
  }

  // Multi-Language Dictionary (Expanded with Work Module keys)
  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'workers': 'Workers Management',
        'subTitleWorkers': 'Manage tailors & staff performance',
        'addWorker': 'Add Worker',
        'workerProfile': 'Worker Profile',
        'searchHint': 'Search by name, phone or role...',
        'totalWorkers': 'Total Workers',
        'activeWorkers': 'Active Now',
        'todaysPieces': "Today's Pieces",
        'todaysEarnings': "Today's Earnings",
        'totalDays': 'Total Days',
        'rating': 'Rating',
        'thisMonthSummary': 'This Month Summary',
        'viewMore': 'View More',
        'totalPieces': 'Total Pieces',
        'totalEarnings': 'Total Earnings',
        'avgPerDay': 'Avg / Day',
        'attendance': 'Attendance',
        'actionCards': 'Quick Actions',
        'work': 'Work',
        'history': 'History',
        'salary': 'Salary',
        'rate': 'Rate',
        'report': 'Report',
        'details': 'Details',
        'globalRates': 'Master Rates',
        'globalRatesDesc': 'Manage and add new garment rates uniformly for all workers.',
        'recentEntries': 'Recent Work Entries',
        'viewAll': 'View All',
        'performance': 'Performance this Month',
        'target': 'Target',
        'average': 'Average',
        'achieved': 'Achieved',
        'active': 'Active',
        'selectPhotoSource': 'Select Photo Source',
        'takePhoto': 'Take Photo (Camera)',
        'chooseGallery': 'Choose from Gallery',
        'tapToAddPhoto': 'Tap to add photo',
        'workerIdAuto': 'Worker ID (Auto Generated)',
        'fullName': 'Full Name *',
        'mobileNumber': 'Mobile Number *',
        'address': 'Address (City, State)',
        'joiningDate': 'Joining Date (dd/mm/yyyy)',
        'roleSpeciality': 'Role / Speciality (e.g., Shirt Master)',
        'cancel': 'Cancel',
        'saveWorker': 'Save Worker',
        'fillMandatory': 'Please fill in Name and Mobile Number',
        'noWorkersFound': 'No workers found',
        'stepBasicInfo': '👤 Step 1: Basic Information',
        'netSalary': 'Net Salary',
        'performanceReport': '📊 Performance Report',
        'phone': 'Phone',
        'editRate': 'Edit Rate for',
        'newRate': 'New Rate (₹)',
        'save': 'Save',
        'pieces': 'Pieces',
        'earnings': 'Earnings',
        'days': 'Days',
        'masterRate': 'Master Rates',
        'work_date': 'Work Date',
        'change': 'Change',
        'total_pieces': 'Total Pieces',
        'total_earnings': 'Total Earnings',
        'avg_rate': 'Avg. Rate',
        'item': 'Item',
        'rate_symbol': 'Rate (₹)',
        'amount_symbol': 'Amount (₹)',
        'reset': 'RESET',
        'save_work': 'SAVE WORK',
        'saving': 'SAVING...',
        'enter_qty_warning': 'Please enter quantity for at least one garment!',
        'confirm_save_title': 'Confirm Save Entry',
      },
      'Hindi': {
        'workers': 'कर्मचारी प्रबंधन',
        'subTitleWorkers': 'दर्जियों और स्टाफ के प्रदर्शन का प्रबंधन करें',
        'addWorker': 'कर्मचारी जोड़ें',
        'workerProfile': 'कर्मचारी प्रोफाइल',
        'searchHint': 'नाम, फोन या रोल से खोजें...',
        'totalWorkers': 'कुल कर्मचारी',
        'activeWorkers': 'सक्रिय कर्मचारी',
        'todaysPieces': 'आज के पीस',
        'todaysEarnings': 'आज की कमाई',
        'totalDays': 'कुल दिन',
        'rating': 'रेटिंग',
        'thisMonthSummary': 'इस महीने का सारांश',
        'viewMore': 'और देखें',
        'totalPieces': 'कुल पीस',
        'totalEarnings': 'कुल कमाई',
        'avgPerDay': 'औसत / दिन',
        'attendance': 'उपस्थिति',
        'actionCards': 'त्वरित कार्य (Quick Actions)',
        'work': 'काम (Work)',
        'history': 'इतिहास (History)',
        'salary': 'वेतन (Salary)',
        'rate': 'रेट (Rate)',
        'report': 'रिपोर्ट (Report)',
        'details': 'विवरण (Details)',
        'globalRates': 'मास्टर रेट्स (Rates)',
        'globalRatesDesc': 'सभी वर्कर्स के लिए नए गारमेंट्स और रेट्स प्रबंधित करें।',
        'recentEntries': 'हाल के काम के रिकॉर्ड',
        'viewAll': 'सभी देखें',
        'performance': 'इस महीने का प्रदर्शन',
        'target': 'लक्ष्य',
        'average': 'औसत',
        'achieved': 'प्राप्त',
        'active': 'सक्रिय',
        'selectPhotoSource': 'फोटो स्रोत चुनें',
        'takePhoto': 'फोटो खींचें (कैमरा)',
        'chooseGallery': 'गैलरी से चुनें',
        'tapToAddPhoto': 'फोटो जोड़ने के लिए टैप करें',
        'workerIdAuto': 'कर्मचारी आईडी (ऑटो जनरेटेड)',
        'fullName': 'पूरा नाम *',
        'mobileNumber': 'मोबाइल नंबर *',
        'address': 'पता (शहर, राज्य)',
        'joiningDate': 'शामिल होने की तिथि (dd/mm/yyyy)',
        'roleSpeciality': 'पद / विशेषता (उदा., शर्ट मास्टर)',
        'cancel': 'रद्द करें',
        'saveWorker': 'कर्मचारी सहेजें',
        'fillMandatory': 'कृपया नाम और मोबाइल नंबर भरें',
        'noWorkersFound': 'कोई कर्मचारी नहीं मिला',
        'stepBasicInfo': '👤 चरण 1: बुनियादी जानकारी',
        'netSalary': 'शुद्ध वेतन',
        'performanceReport': '📊 प्रदर्शन रिपोर्ट',
        'phone': 'फ़ोन',
        'editRate': 'रेट संपादित करें:',
        'newRate': 'नया रेट (₹)',
        'save': 'सहेजें',
        'pieces': 'पीस',
        'earnings': 'कमाई',
        'days': 'दिन',
        'masterRate': 'मास्टर रेट्स',
        'work_date': 'काम की तारीख',
        'change': 'बदलें',
        'total_pieces': 'कुल पीस',
        'total_earnings': 'कुल कमाई',
        'avg_rate': 'औसत रेट',
        'item': 'आइटम',
        'rate_symbol': 'रेट (₹)',
        'amount_symbol': 'राशि (₹)',
        'reset': 'रीसेट',
        'save_work': 'काम सहेजें',
        'saving': 'सहेज रहा है...',
        'enter_qty_warning': 'कृपया कम से कम एक गारमेंट की मात्रा दर्ज करें!',
        'confirm_save_title': 'एंट्री सहेजने की पुष्टि करें',
      },
      'Marathi': {
        'workers': 'कामगार व्यवस्थापन',
        'subTitleWorkers': 'शिंपी आणि स्टाफच्या कामगिरीचे व्यवस्थापन करा',
        'addWorker': 'कामगार जोडा',
        'workerProfile': 'कामगार प्रोफाइल',
        'searchHint': 'नाव, फोन किंवा रोल शोधा...',
        'totalWorkers': 'एकूण कामगार',
        'activeWorkers': 'सक्रिय कामगार',
        'todaysPieces': 'आजचे नग',
        'todaysEarnings': 'आजची कमाई',
        'totalDays': 'एकूण दिवस',
        'rating': 'रेटींग',
        'thisMonthSummary': 'या महिन्याचा सारांश',
        'viewMore': 'आणखी पहा',
        'totalPieces': 'एकूण नग',
        'totalEarnings': 'एकूण कमाई',
        'avgPerDay': 'सरासरी / दिवस',
        'attendance': 'उपस्थिती',
        'actionCards': 'त्वरित कृती (Quick Actions)',
        'work': 'काम (Work)',
        'history': 'इतिहास (History)',
        'salary': 'पगार (Salary)',
        'rate': 'रेट (Rate)',
        'report': 'अहवाल (Report)',
        'details': 'तपशील (Details)',
        'globalRates': 'मास्टर रेट्स (Rates)',
        'globalRatesDesc': 'सर्व कामगारांसाठी नवीन कपडे आणि दर व्यवस्थापित करा.',
        'recentEntries': 'अलीकडील कामाची नोंद',
        'viewAll': 'सर्व पहा',
        'performance': 'या महिन्यातील कामगिरी',
        'target': 'ध्येय',
        'average': 'सरासरी',
        'achieved': 'पूर्ण झाले',
        'active': 'सक्रिय',
        'selectPhotoSource': 'फोटो स्त्रोत निवडा',
        'takePhoto': 'फोटो काढा (कॅ메라)',
        'chooseGallery': 'गैलरी मधून निवडा',
        'tapToAddPhoto': 'फोटो जोडण्यासाठी टॅप करा',
        'workerIdAuto': 'कामगार आयडी (स्वयंचलित)',
        'fullName': 'पूर्ण नाव *',
        'mobileNumber': 'मोबाईल नंबर *',
        'address': 'पत्ता (शहर, राज्य)',
        'joiningDate': 'सामील झाल्याची तारीख (dd/mm/yyyy)',
        'roleSpeciality': 'भूमिका / कौशल्य (उदा., शर्ट मास्टर)',
        'cancel': 'रद्द करा',
        'saveWorker': 'कामगार जतन करा',
        'fillMandatory': 'कृपया नाव आणि मोबाईल नंबर भरा',
        'noWorkersFound': 'कोणतेही कामगार आढळले नाहीत',
        'stepBasicInfo': '👤 पायरी 1: मूलभूत माहिती',
        'netSalary': 'निव्वळ पगार',
        'performanceReport': '📊 कामगिरीचा अहवाल',
        'phone': 'फोन',
        'editRate': 'दर संपादित करा:',
        'newRate': 'नवीन दर (₹)',
        'save': 'जतन करा',
        'pieces': 'नग',
        'earnings': 'कमाई',
        'days': 'दिवस',
        'masterRate': 'मास्टर रेट्स',
        'work_date': 'कामाची तारीख',
        'change': 'बदला',
        'total_pieces': 'एकूण नग',
        'total_earnings': 'एकूण कमाई',
        'avg_rate': 'सरासरी दर',
        'item': 'आयटम',
        'rate_symbol': 'दर (₹)',
        'amount_symbol': 'रक्कम (₹)',
        'reset': 'रीसेट',
        'save_work': 'काम जतन करा',
        'saving': 'जतन करत आहे...',
        'enter_qty_warning': 'कृपया किमान एका गारमेंटची संख्या प्रविष्ट करा!',
        'confirm_save_title': 'नोंद जतन करण्याची पुष्टी करा',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? translations['English']?[key] ?? key;
  }

  // Add Worker Dialog
  void _showAddWorkerDialog(BuildContext context, Color cardColor, Color textColor, Color borderColor, Color primaryPurple, Color accentYellow, Color subTextColor) {
    final String generatedId = 'WRK00${_workers.length + 1}';
    
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final joiningDateController = TextEditingController(text: '04/08/2026');
    final roleController = TextEditingController();
    
    File? selectedImageFile;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            Future<void> _pickImage(ImageSource source) async {
              try {
                final XFile? pickedFile = await picker.pickImage(
                  source: source,
                  maxWidth: 600,
                  imageQuality: 85,
                );

                if (pickedFile != null) {
                  setStateDialog(() {
                    selectedImageFile = File(pickedFile.path);
                  });
                }
              } catch (e) {
                print("Error picking image: $e");
              }
            }

            void _showImageSourceActionSheet() {
              showModalBottomSheet(
                context: context,
                backgroundColor: cardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getText('selectPhotoSource'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(Icons.camera_alt, color: primaryPurple),
                          title: Text(_getText('takePhoto'), style: TextStyle(color: textColor)),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.photo_library, color: accentYellow),
                          title: Text(_getText('chooseGallery'), style: TextStyle(color: textColor)),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            Future<void> _selectJoiningDate() async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );

              if (pickedDate != null) {
                String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}/"
                    "${pickedDate.month.toString().padLeft(2, '0')}/"
                    "${pickedDate.year}";
                
                setStateDialog(() {
                  joiningDateController.text = formattedDate;
                });
              }
            }

            return AlertDialog(
              backgroundColor: cardColor,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getText('addWorker'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_getText('stepBasicInfo'), style: TextStyle(color: accentYellow, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceActionSheet,
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: borderColor.withValues(alpha: 0.5),
                                border: Border.all(color: primaryPurple, width: 2),
                                image: selectedImageFile != null
                                    ? DecorationImage(
                                        image: FileImage(selectedImageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: selectedImageFile == null
                                  ? Icon(Icons.person, size: 50, color: subTextColor)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accentYellow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_getText('tapToAddPhoto'), style: TextStyle(color: subTextColor, fontSize: 12)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: TextEditingController(text: generatedId),
                      readOnly: true,
                      style: TextStyle(color: subTextColor),
                      decoration: InputDecoration(
                        labelText: _getText('workerIdAuto'),
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        filled: true,
                        fillColor: borderColor.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _getText('fullName'),
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryPurple)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _getText('mobileNumber'),
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryPurple)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _getText('address'),
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryPurple)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: joiningDateController,
                      readOnly: true,
                      onTap: _selectJoiningDate,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _getText('joiningDate'),
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryPurple)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today, size: 18, color: subTextColor),
                          onPressed: _selectJoiningDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _getText('roleSpeciality'),
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryPurple)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getText('cancel'), style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentYellow, foregroundColor: Colors.black87),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                      Map<String, dynamic> workerData = {
                        'name': nameController.text,
                        'phone': phoneController.text,
                        'joining': joiningDateController.text.isNotEmpty ? joiningDateController.text : '04/08/2026',
                        'role': roleController.text.isNotEmpty ? roleController.text : 'Tailor',
                        'address': addressController.text.isNotEmpty ? addressController.text : 'Local',
                        'experience': '1 Year',
                        'notes': '',
                        'status': 'Active',
                      };

                      Navigator.pop(context);

                      Map<String, dynamic> result = await DatabaseService.saveWorkerToFirebase(
                        userEmail: widget.userEmail,
                        workerId: generatedId,
                        workerData: workerData,
                        workerImage: selectedImageFile,
                      );

                      if (result['status'] == true) {
                        _loadWorkersFromFirebase();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'])),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_getText('fillMandatory'))),
                      );
                    }
                  },
                  child: Text(_getText('saveWorker')),
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
    bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    // UI Theme Colors mapping
    Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    Color subTextColor = widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    Color borderColor = widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

    return PopScope(
      canPop: _navigationLevel == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          if (_navigationLevel == 2) {
            _navigationLevel = 1; 
          } else if (_navigationLevel == 1 || _navigationLevel == 3) {
            _navigationLevel = 0; 
          }
        });
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _navigationLevel == 0
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: accentYellow.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddWorkerDialog(context, cardColor, textColor, borderColor, primaryPurple, accentYellow, subTextColor),
                  backgroundColor: accentYellow,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: Text(_getText('addWorker'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              )
            : null,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
              child: _isLoadingWorkers
                  ? const Center(child: CircularProgressIndicator())
                  : _navigationLevel == 0
                      ? WorkerListViewClass(
                        // 1. List.from का इस्तेमाल करें ताकि Flutter का विजेट नए इंस्टेंस को पहचान सके
                        workers: List.from(_workers), 
                        isDarkMode: widget.isDarkMode,
                        getText: _getText,
                        isDesktop: isDesktop,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        primaryPurple: primaryPurple,
                        accentYellow: accentYellow,
                        
                        // 2. जब यूजर किसी वर्कर पर क्लिक करे और प्रोफाइल से वापस लौटे
                        onWorkerSelected: (worker) async {
                          setState(() {
                            _selectedWorker = worker;
                            _navigationLevel = 1;
                          });

                          // जब यूजर प्रोफाइल पेज से वापस लिस्ट पर आएगा, तब यह सुनिश्चित करेगा कि डेटा ताज़ा (Fresh) हो
                          await _loadWorkersFromFirebase();
                        },

                        // 3. पुल-टू-रिफ्रेश (Pull-to-refresh) के लिए
                        onRefresh: () async {
                          await _loadWorkersFromFirebase();
                        },

                        onSubModuleOpen: (subModule) {
                          if (subModule == 'MasterRate') {
                            setState(() {
                              _navigationLevel = 3; 
                            });
                          }
                        },
                      )
                      : _navigationLevel == 1
                          ? WorkerProfileViewClass(
                              selectedWorker: _selectedWorker!,
                              isDarkMode: widget.isDarkMode,
                              getText: _getText,
                              isDesktop: isDesktop,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              primaryPurple: primaryPurple,
                              userEmail: widget.userEmail,
                              accentYellow: accentYellow,
                              onBack: () => setState(() => _navigationLevel = 0),
                              onSubModuleOpen: (moduleName) {
                                setState(() {
                                  _activeSubModule = moduleName;
                                  _navigationLevel = 2;
                                });
                              },
                              onOpenGlobalRates: () {
                                setState(() {
                                  _navigationLevel = 3;
                                });
                              },
                              onToggleStatus: (newStatus) async {
                                String workerId = _selectedWorker!['id'] ?? 'WRK001';
                                String userEmail = widget.userEmail;

                                Map<String, dynamic> result = await DatabaseService.updateWorkerStatus(
                                  userEmail: userEmail,
                                  workerId: workerId,
                                  newStatus: newStatus,
                                );

                                if (result['status'] == true) {
                                  setState(() {
                                    _selectedWorker!['status'] = newStatus;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
                                  );
                                }
                              },
                            )
                          : _navigationLevel == 2
                              ? SubModuleContainerClass(
                                  activeSubModule: _activeSubModule,
                                  selectedWorker: _selectedWorker!,
                                  userEmail: widget.userEmail, // 👈 Consistent email passed here
                                  getText: _getText,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  primaryPurple: primaryPurple,
                                  accentYellow: accentYellow,
                                  rates: _rates,
                                  todayQuantities: _todayQuantities,
                                  isDesktop: isDesktop,
                                  onBack: () => setState(() => _navigationLevel = 1),
                                  onUpdate: () => setState(() {}),
                                )
                              : MasterRateViewClass(
                                  rates: _rates,
                                  getText: _getText,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  primaryPurple: primaryPurple,
                                  accentYellow: accentYellow,
                                  userEmail: widget.userEmail,
                                  onBack: () => setState(() => _navigationLevel = 0),
                                  onUpdate: () {
                                    _loadRatesFromFirebase(); 
                                    setState(() {});
                                  },
                                ),
            ),
          ),
        ),
      ),
    );
  }
}