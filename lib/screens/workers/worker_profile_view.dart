import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../database.dart';

class WorkerProfileViewClass extends StatefulWidget {
  final Map<String, dynamic> selectedWorker;
  final bool isDarkMode;
  final String Function(String) getText;
  final bool isDesktop;
  final Color cardColor, borderColor, textColor, subTextColor, primaryPurple, accentYellow;
  final VoidCallback onBack;
  final Function(String) onSubModuleOpen;
  final VoidCallback onOpenGlobalRates;
  final Function(String newStatus) onToggleStatus;
  final Function(Map<String, dynamic> updatedData)? onSaveWorker;
  final String userEmail;

  const WorkerProfileViewClass({
    super.key,
    required this.selectedWorker,
    required this.isDarkMode,
    required this.getText,
    required this.isDesktop,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryPurple,
    required this.accentYellow,
    required this.onBack,
    required this.onSubModuleOpen,
    required this.onOpenGlobalRates,
    required this.onToggleStatus,
    this.onSaveWorker,
    required this.userEmail,
  });

  @override
  State<WorkerProfileViewClass> createState() => _WorkerProfileViewClassState();
}

class _WorkerProfileViewClassState extends State<WorkerProfileViewClass> {
  late Map<String, dynamic> currentWorkerData;
  bool _isLoading = false;
  
  int _todaysPieces = 0;
  double _todaysEarnings = 0.0;
  List<Map<String, dynamic>> _recentEntries = [];
  double _averagePieces = 0.0;
  double _achievementPercentage = 0.0;
  final double _targetPieces = 30.0;

  // Accurate Salary Breakdown Metrics
  double _totalEarned = 0.0; 
  double _totalPaid = 0.0;   
  double _balanceDue = 0.0;

  // 🚀 Caching map to avoid repeated base64 decoding and eliminate blinking/lag
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    currentWorkerData = Map<String, dynamic>.from(widget.selectedWorker);
    _loadWorkerMetrics();
  }

  Future<void> _loadWorkerMetrics() async {
    final workerId = (currentWorkerData['id'] ?? currentWorkerData['workerId'] ?? '').toString();
    print("🚀 [TRIGGER CHECK] Worker ID found: $workerId");

    if (workerId.isEmpty) {
      print("❌ [ERROR] Worker ID is empty, skipping metrics load.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final freshWorkerData = await DatabaseService.fetchWorkerDetails(
        userEmail: widget.userEmail,
        workerId: workerId,
      );

      if (freshWorkerData != null) {
        setState(() {
          currentWorkerData = freshWorkerData;
        });
      }

      final entries = await DatabaseService.fetchWorkerEntries(
        userEmail: widget.userEmail,
        workerId: workerId,
      );

      double calculatedTotalEarned = 0.0;
      int totalSumPieces = 0;
      
      for (var entry in entries) {
        double earnings = (entry['total_earnings'] as num?)?.toDouble() ?? 0.0;
        calculatedTotalEarned += earnings;
        totalSumPieces += int.tryParse(entry['total_pieces']?.toString() ?? '0') ?? 0;
      }

      double calculatedTotalPaid = 0.0;
      final monthlyRecords = currentWorkerData['monthly_records'];
      if (monthlyRecords is Map) {
        monthlyRecords.forEach((key, value) {
          if (value is Map) {
            calculatedTotalPaid += (value['paidAmount'] as num?)?.toDouble() ?? 0.0;
          }
        });
      }

      double calculatedBalanceDue = calculatedTotalEarned - calculatedTotalPaid;
      if (calculatedBalanceDue < 0) calculatedBalanceDue = 0.0;

      final todayKey = DateTime.now().toIso8601String().split('T').first;
      
      int tPieces = 0;
      double tEarnings = 0.0;
      
      for (var entry in entries) {
        String entryDate = (entry['date'] ?? '').toString().split('T').first;
        if (entryDate == todayKey) {
          tPieces += int.tryParse(entry['total_pieces']?.toString() ?? '0') ?? 0;
          tEarnings += double.tryParse(entry['total_earnings']?.toString() ?? '0') ?? 0.0;
        }
      }

      double avg = entries.isNotEmpty ? totalSumPieces / entries.length : 0.0;
      double achievement = (_targetPieces > 0) ? (avg / _targetPieces) : 0.0;
      if (achievement > 1.0) achievement = 1.0;

      if (mounted) {
        setState(() {
          _todaysPieces = tPieces;
          _todaysEarnings = tEarnings;
          _recentEntries = entries.take(4).toList();
          _averagePieces = avg;
          _achievementPercentage = achievement;
          
          _totalEarned = calculatedTotalEarned;
          _totalPaid = calculatedTotalPaid;
          _balanceDue = calculatedBalanceDue;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading worker metrics: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // ⚡ Fast and Stable Profile Avatar with Caching and gaplessPlayback
  Widget _buildProfileAvatar({String? photoOverride, double radius = 34}) {
    final photoStr = photoOverride ?? currentWorkerData['photo'];
    final workerId = (currentWorkerData['id'] ?? currentWorkerData['workerId'] ?? 'profile').toString();
    
    if (photoStr != null && photoStr.toString().startsWith('data:image')) {
      try {
        if (_imageCache.containsKey(workerId)) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: widget.primaryPurple.withValues(alpha: 0.2),
            backgroundImage: MemoryImage(_imageCache[workerId]!),
          );
        }

        final base64String = photoStr.split(',').last;
        final bytes = base64Decode(base64String);
        _imageCache[workerId] = bytes;

        return CircleAvatar(
          radius: radius,
          backgroundColor: widget.primaryPurple.withValues(alpha: 0.2),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        debugPrint("Error decoding profile image: $e");
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: widget.primaryPurple.withValues(alpha: 0.2),
      child: Icon(Icons.person, size: radius * 1.2, color: widget.primaryPurple),
    );
  }

  void _showEditWorkerDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: currentWorkerData['name'] ?? '');
    final TextEditingController phoneController = TextEditingController(text: currentWorkerData['phone'] ?? '');
    final TextEditingController addressController = TextEditingController(text: currentWorkerData['address'] ?? '');
    final TextEditingController roleController = TextEditingController(text: currentWorkerData['role'] ?? currentWorkerData['designation'] ?? '');
    
    String? tempPhoto = currentWorkerData['photo'];
    final mainContext = context;

    showDialog(
      context: mainContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: widget.borderColor),
              ),
              title: Text(
                widget.getText('editWorker'),
                style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          InkWell(
                            onTap: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                              
                              if (image != null) {
                                final Uint8List bytes = await image.readAsBytes();
                                final String base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                
                                // Clear cache for this worker so new photo loads instantly
                                final workerId = (currentWorkerData['id'] ?? currentWorkerData['workerId'] ?? '').toString();
                                _imageCache.remove(workerId);

                                if (dialogContext.mounted) {
                                  setDialogState(() {
                                    tempPhoto = base64String;
                                  });
                                }
                              }
                            },
                            child: _buildProfileAvatar(photoOverride: tempPhoto, radius: 40),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.getText('tapToChangePhoto'),
                      style: TextStyle(color: widget.subTextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: widget.textColor),
                      decoration: InputDecoration(
                        labelText: widget.getText('name'),
                        labelStyle: TextStyle(color: widget.subTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.borderColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryPurple, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: widget.textColor),
                      decoration: InputDecoration(
                        labelText: widget.getText('phone'),
                        labelStyle: TextStyle(color: widget.subTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.borderColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryPurple, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      style: TextStyle(color: widget.textColor),
                      decoration: InputDecoration(
                        labelText: widget.getText('address'),
                        labelStyle: TextStyle(color: widget.subTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.borderColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryPurple, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roleController,
                      style: TextStyle(color: widget.textColor),
                      decoration: InputDecoration(
                        labelText: widget.getText('role'),
                        labelStyle: TextStyle(color: widget.subTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.borderColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryPurple, width: 2)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(widget.getText('cancel'), style: TextStyle(color: widget.primaryPurple)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    setState(() {
                      currentWorkerData['name'] = nameController.text.trim();
                      currentWorkerData['phone'] = phoneController.text.trim();
                      currentWorkerData['address'] = addressController.text.trim();
                      currentWorkerData['role'] = roleController.text.trim();
                      if (tempPhoto != null) {
                        currentWorkerData['photo'] = tempPhoto;
                      }
                    });

                    final workerId = currentWorkerData['id'] ?? '';
                    if (workerId.isNotEmpty) {
                      await DatabaseService.saveWorkerToFirebase(
                        userEmail: widget.userEmail,
                        workerId: workerId,
                        workerData: currentWorkerData,
                      );
                    }

                    if (widget.onSaveWorker != null) {
                      widget.onSaveWorker!(currentWorkerData);
                    }

                    if (mainContext.mounted) {
                      ScaffoldMessenger.of(mainContext).showSnackBar(
                        SnackBar(
                          content: Text(widget.getText('updatedSuccessfully')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text(widget.getText('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final workerId = (currentWorkerData['id'] ?? currentWorkerData['workerId'] ?? '').toString();
    final mainContext = context;

    showDialog(
      context: mainContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: widget.borderColor),
          ),
          title: const Text(
            "Delete Worker",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to delete this worker? This action cannot be undone.",
            style: TextStyle(color: widget.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(widget.getText('cancel'), style: TextStyle(color: widget.primaryPurple)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);

                try {
                  await DatabaseService.deleteWorker(
                    userEmail: widget.userEmail,
                    workerId: workerId,
                  );

                  if (mainContext.mounted) {
                    widget.onBack(); 
                  }
                } catch (e) {
                  debugPrint("Error deleting worker: $e");
                  if (mainContext.mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = currentWorkerData['status'] != 'Deactive';
    final String role = currentWorkerData['role'] ?? currentWorkerData['designation'] ?? 'Worker';

    double calculatedRating = 1.0 + (_achievementPercentage * 4.0);
    if (calculatedRating > 5.0) calculatedRating = 5.0;
    if (calculatedRating < 1.0) calculatedRating = 1.0;
    int fullStars = calculatedRating.floor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: widget.textColor), onPressed: widget.onBack),
        title: Text(widget.getText('workerProfile'), style: TextStyle(color: widget.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.primaryPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: widget.cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: widget.borderColor)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            _buildProfileAvatar(radius: 34),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2), 
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? widget.getText('active') : "Deactive", 
                                style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentWorkerData['name'] ?? '', 
                                style: TextStyle(color: widget.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text("💼 $role", style: TextStyle(color: widget.accentYellow, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text("ID: ${currentWorkerData['id'] ?? 'WRK001'}", style: TextStyle(color: widget.primaryPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text("📞 ${currentWorkerData['phone'] ?? ''}", style: TextStyle(color: widget.subTextColor, fontSize: 12)),
                              Text("📍 ${currentWorkerData['address'] ?? ''}", style: TextStyle(color: widget.subTextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: widget.primaryPurple, size: 20),
                              tooltip: widget.getText('edit'),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () => _showEditWorkerDialog(context),
                            ),
                            const SizedBox(height: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              tooltip: "Delete Worker",
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () => _showDeleteConfirmationDialog(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Salary Ledger Summary", 
                          style: TextStyle(color: widget.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _salarySummaryColumn("Total Earned", "₹ ${_totalEarned.toStringAsFixed(0)}", Colors.blue, "All-time work earnings"),
                            _salarySummaryColumn("Total Paid", "₹ ${_totalPaid.toStringAsFixed(0)}", Colors.green, "Amount given to worker"),
                            _salarySummaryColumn("Balance Due", "₹ ${_balanceDue.toStringAsFixed(0)}", Colors.orange, "Remaining to be paid"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                        foregroundColor: isActive ? Colors.red : Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(isActive ? Icons.cancel_outlined : Icons.check_circle_outline),
                      label: Text(
                        isActive ? "Deactivate Worker" : "Activate Worker", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () {
                        String newStatus = isActive ? "Deactive" : "Active";
                        setState(() {
                          currentWorkerData['status'] = newStatus;
                        });
                        widget.onToggleStatus(newStatus);
                        if (widget.onSaveWorker != null) {
                          widget.onSaveWorker!(currentWorkerData);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _topMiniCard(widget.getText('todaysPieces'), "$_todaysPieces", widget.getText('pieces'), widget.cardColor, widget.borderColor, widget.textColor, widget.subTextColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _topMiniCard(widget.getText('todaysEarnings'), "₹ ${_todaysEarnings.toStringAsFixed(0)}", widget.getText('earnings'), widget.cardColor, widget.borderColor, widget.textColor, widget.subTextColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _ratingMiniCard(widget.getText('rating'), calculatedRating.toStringAsFixed(1), fullStars, widget.cardColor, widget.borderColor, widget.textColor, widget.subTextColor)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.getText('actionCards'), style: TextStyle(color: widget.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: widget.isDesktop ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: [
                      _actionButton("🧵 ${widget.getText('work')}", () => widget.onSubModuleOpen('Work'), widget.cardColor, widget.borderColor, widget.textColor),
                      _actionButton("📜 ${widget.getText('history')}", () => widget.onSubModuleOpen('History'), widget.cardColor, widget.borderColor, widget.textColor),
                      _actionButton("💰 ${widget.getText('salary')}", () => widget.onSubModuleOpen('Salary'), widget.cardColor, widget.borderColor, widget.textColor),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.getText('recentEntries'), style: TextStyle(color: widget.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(widget.getText('viewAll'), style: TextStyle(color: widget.primaryPurple, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: widget.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.borderColor)),
                    child: _recentEntries.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                "No recent entries found.",
                                style: TextStyle(color: widget.subTextColor, fontSize: 13),
                              ),
                            ),
                          )
                        : Column(
                            children: _recentEntries.map((entry) {
                              final dateStr = entry['date'] ?? '';
                              final piecesStr = "${entry['total_pieces'] ?? 0} ${widget.getText('pieces')}";
                              final earningsStr = "₹ ${entry['total_earnings'] ?? 0}";
                              return Column(
                                children: [
                                  _recentEntryRow(dateStr, piecesStr, earningsStr, widget.textColor, widget.subTextColor, widget.primaryPurple),
                                  if (entry != _recentEntries.last) Divider(height: 1, color: widget.borderColor),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(widget.getText('performance'), style: TextStyle(color: widget.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: widget.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.borderColor)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.getText('target'), style: TextStyle(color: widget.subTextColor, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text("${_targetPieces.toInt()} ${widget.getText('pieces')}/Day", style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.getText('average'), style: TextStyle(color: widget.subTextColor, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text("${_averagePieces.toStringAsFixed(1)} ${widget.getText('pieces')}/Day", style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(widget.getText('achieved'), style: TextStyle(color: widget.subTextColor, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text("${(_achievementPercentage * 100).toStringAsFixed(0)}%", style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _achievementPercentage,
                            minHeight: 6,
                            backgroundColor: widget.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.primaryPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _salarySummaryColumn(String title, String amount, Color color, String subtitle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: widget.subTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            subtitle, 
            style: TextStyle(color: widget.subTextColor.withValues(alpha: 0.7), fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _topMiniCard(String title, String val1, String val2, Color cardColor, Color borderColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(val1, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(val2, style: TextStyle(color: subTextColor, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _ratingMiniCard(String title, String val, int ratingStars, Color cardColor, Color borderColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => Icon(
              Icons.star, 
              size: 8, 
              color: index < ratingStars ? Colors.amber : widget.subTextColor.withValues(alpha: 0.3),
            )),
          )
        ],
      ),
    );
  }

  Widget _actionButton(String title, VoidCallback onTap, Color cardColor, Color borderColor, Color textColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  Widget _recentEntryRow(String date, String pieces, String amount, Color textColor, Color subTextColor, Color primaryPurple) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: primaryPurple), // Safe
              const SizedBox(width: 8),
              Text(date, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(pieces, style: TextStyle(color: subTextColor, fontSize: 13)),
          Row(
            children: [
              Text(amount, style: TextStyle(color: primaryPurple, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: subTextColor),
            ],
          ),
        ],
      ),
    );
  }
}