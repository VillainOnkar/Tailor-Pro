import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../../database.dart';

class SalaryModuleClass extends StatefulWidget {
  final String Function(String) getText;
  final String userEmail; 
  final String workerId;  
  final Color? textColor;
  final Color? accentYellow;

  const SalaryModuleClass({
    super.key,
    required this.getText,
    required this.userEmail,
    required this.workerId,
    this.textColor,
    this.accentYellow,
  });

  @override
  State<SalaryModuleClass> createState() => _SalaryModuleClassState();
}

class _SalaryModuleClassState extends State<SalaryModuleClass> {
  bool _isLoading = true;
  late DateTime _selectedMonth;

  Map<String, dynamic> _activeMonthData = {
    "pieceEarnings": 0.0,
    "isPaid": false,
    "paidAmount": 0.0, 
    "remainingAmount": 0.0, 
    "transactions": <Map<String, dynamic>>[],
  };

  List<Map<String, dynamic>> _salaryHistory = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _fetchRealFirebaseData();
  }

  String get _currentMonthKey {
    try {
      return DateFormat('yyyy-MM').format(_selectedMonth);
    } catch (_) {
      return DateFormat('yyyy-MM').format(DateTime.now());
    }
  }

  Future<void> _fetchRealFirebaseData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> entries = await DatabaseService.fetchWorkerEntries(
        userEmail: widget.userEmail,
        workerId: widget.workerId,
      );

      double calculatedPieceEarnings = 0.0;
      
      for (var entry in entries) {
        double earnings = (entry['total_earnings'] as num?)?.toDouble() ?? 0.0;
        String entryDateStr = entry['date']?.toString() ?? '';
        if (entryDateStr.startsWith(_currentMonthKey)) {
          calculatedPieceEarnings += earnings;
        }
      }

      Map<String, dynamic> savedData = {};
      try {
        savedData = await DatabaseService.fetchMonthlySalaryRecord(
          userEmail: widget.userEmail,
          workerId: widget.workerId,
          monthKey: _currentMonthKey,
        );
      } catch (e) {
        print("No existing monthly record found: $e");
      }

      setState(() {
        _activeMonthData = {
          "pieceEarnings": calculatedPieceEarnings,
          "isPaid": savedData['isPaid'] == true,
          "paidAmount": (savedData['paidAmount'] as num?)?.toDouble() ?? 0.0,
          "remainingAmount": (savedData['remainingAmount'] as num?)?.toDouble() ?? 0.0,
          "transactions": savedData['transactions'] ?? <Map<String, dynamic>>[],
        };

        double historyAmount = savedData['isPaid'] == true 
            ? ((savedData['paidAmount'] as num?)?.toDouble() ?? _netSalary)
            : _netSalary;

        _salaryHistory = [
          {
            "monthKey": _currentMonthKey,
            "month": DateFormat('MMMM yyyy').format(_selectedMonth),
            "amount": historyAmount,
            "paid": _activeMonthData['isPaid']
          }
        ];
        _isLoading = false;
      });
    } catch (e) {
      print("Firebase Salary Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncToFirebase() async {
    try {
      double net = _netSalary;
      double paid = (_activeMonthData['paidAmount'] as num?)?.toDouble() ?? 0.0;
      _activeMonthData['remainingAmount'] = net - paid > 0 ? net - paid : 0.0;

      await DatabaseService.saveMonthlySalaryRecord(
        userEmail: widget.userEmail,
        workerId: widget.workerId,
        monthKey: _currentMonthKey,
        salaryData: _activeMonthData,
      );
      
      _fetchRealFirebaseData();
    } catch (e) {
      print("Firebase Salary Sync Error: $e");
    }
  }

  double get _netSalary {
    try {
      // शुद्ध रूप से केवल पीस अर्निंग ही नेट सैलरी बनेगी (क्योंकि बाकी बोनस/एडवांस हटा दिए गए हैं)
      double piece = (_activeMonthData['pieceEarnings'] as num?)?.toDouble() ?? 0.0;
      return piece;
    } catch (_) {
      return 0.0;
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      try {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
      } catch (_) {}
    });
    _fetchRealFirebaseData();
  }

  void _showPaySalaryDialog() {
    String paymentMode = "Cash";
    double currentNet = _netSalary;
    double currentPaid = (_activeMonthData['paidAmount'] as num?)?.toDouble() ?? 0.0;
    double defaultPayable = currentNet - currentPaid;
    if (defaultPayable < 0) defaultPayable = 0;

    final TextEditingController payAmountController = TextEditingController(text: defaultPayable.toStringAsFixed(0));
    final mainContext = context;

    showDialog(
      context: mainContext,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                widget.getText("Pay Salary"),
                style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: payAmountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: widget.getText("Amount to Pay (₹)"),
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${widget.getText("Payment Mode")}:", 
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500)
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 8.0,
                          children: ["Cash", "UPI", "Bank"].map((mode) {
                            return SizedBox(
                              width: constraints.maxWidth > 300 ? (constraints.maxWidth - 16) / 3 : constraints.maxWidth,
                              child: RadioListTile<String>(
                                title: Text(widget.getText(mode), style: TextStyle(color: colorScheme.onSurface, fontSize: 12)),
                                value: mode,
                                groupValue: paymentMode,
                                activeColor: colorScheme.primary,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => paymentMode = val);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(widget.getText("Cancel"), style: TextStyle(color: colorScheme.primary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    double customPaidAmount = double.tryParse(payAmountController.text) ?? 0.0;
                    if (customPaidAmount <= 0) return;

                    if (customPaidAmount > defaultPayable) {
                      Navigator.pop(dialogContext);
                      if (mainContext.mounted) {
                        ScaffoldMessenger.of(mainContext).showSnackBar(
                          SnackBar(
                            content: Text(widget.getText("Cannot pay more than remaining salary!")),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      }
                      return;
                    }

                    showDialog(
                      context: mainContext,
                      builder: (confirmContext) {
                        return AlertDialog(
                          backgroundColor: colorScheme.surface,
                          title: Text(widget.getText("Confirm Payment"), style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                          content: Text(
                            "${widget.getText("Are you sure you want to pay")} ₹${customPaidAmount.toStringAsFixed(0)} ${widget.getText("via")} ${widget.getText(paymentMode)}?",
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(confirmContext),
                              child: Text(widget.getText("Cancel"), style: TextStyle(color: colorScheme.primary)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () async {
                                Navigator.pop(confirmContext); 
                                Navigator.pop(dialogContext); 

                                setState(() {
                                  _activeMonthData['isPaid'] = true;
                                  double updatedPaid = ((_activeMonthData['paidAmount'] as num?)?.toDouble() ?? 0.0) + customPaidAmount;
                                  _activeMonthData['paidAmount'] = updatedPaid;
                                  
                                  double rem = _netSalary - updatedPaid;
                                  _activeMonthData['remainingAmount'] = rem > 0 ? rem : 0.0;
                                  _activeMonthData['paymentMode'] = paymentMode; 

                                  List txList = (_activeMonthData['transactions'] is List) ? List.from(_activeMonthData['transactions']) : [];
                                  txList.insert(0, {
                                    "date": DateFormat('dd MMM').format(DateTime.now()),
                                    "type": "Salary Paid ($paymentMode)",
                                    "amount": customPaidAmount,
                                    "note": "Paid via App",
                                    "isAdd": false
                                  });
                                  _activeMonthData['transactions'] = txList;
                                });
                                
                                await _syncToFirebase();

                                if (mainContext.mounted) {
                                  ScaffoldMessenger.of(mainContext).showSnackBar(
                                    SnackBar(content: Text(widget.getText("Salary Paid Successfully")), backgroundColor: Colors.green),
                                  );
                                }
                              },
                              child: Text(widget.getText("Confirm")),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(widget.getText("Pay Now")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSalaryHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final accentColor = widget.accentYellow ?? colorScheme.secondary;

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "📜 ${widget.getText("Salary History")}",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  Divider(color: colorScheme.outlineVariant),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _salaryHistory.length,
                      itemBuilder: (context, index) {
                        var history = _salaryHistory[index];
                        String monthKey = history['monthKey']?.toString() ?? '';
                        String monthTitle = history['month']?.toString() ?? '';
                        double amount = (history['amount'] as num?)?.toDouble() ?? 0.0;
                        bool paid = history['paid'] == true;

                        return InkWell(
                          onTap: () {
                            if (monthKey.isNotEmpty) {
                              try {
                                final parsedDate = DateFormat('yyyy-MM').parse(monthKey);
                                setState(() {
                                  _selectedMonth = parsedDate;
                                });
                                _fetchRealFirebaseData();
                              } catch (_) {}
                            }
                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(widget.getText(monthTitle), style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 15)),
                                Row(
                                  children: [
                                    Text("₹${amount.toStringAsFixed(0)}", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 12),
                                    Text(
                                      paid ? widget.getText("Paid ✅") : widget.getText("Pending ⏳"),
                                      style: TextStyle(color: paid ? Colors.green : Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final primaryColor = colorScheme.primary;
    final dynamicTextColor = widget.textColor ?? colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurfaceVariant;
    
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    final double pieceEarnings = (_activeMonthData['pieceEarnings'] as num?)?.toDouble() ?? 0.0;
    final double totalPaidAmount = (_activeMonthData['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final double remainingSalary = _netSalary - totalPaidAmount;
    
    final List transactions = (_activeMonthData['transactions'] is List) ? _activeMonthData['transactions'] as List : [];

    String formattedMonthHeader;
    try {
      formattedMonthHeader = DateFormat('MMMM yyyy').format(_selectedMonth);
    } catch (_) {
      formattedMonthHeader = "August 2026";
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "💰 ${widget.getText("Salary Management")}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: primaryColor),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, size: 18, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            formattedMonthHeader,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dynamicTextColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: primaryColor),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showSalaryHistorySheet,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.history, size: 18),
                      label: Text(
                        widget.getText("Salary History"),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const Divider(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📅 $formattedMonthHeader", style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("🧵 ${widget.getText("Piece Earnings")}: ₹${pieceEarnings.toStringAsFixed(0)}", style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 24),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.getText("Total Net Salary"), style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text("₹${_netSalary.toStringAsFixed(0)}", style: TextStyle(color: dynamicTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.getText("Total Paid Amount"), style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text("₹${totalPaidAmount.toStringAsFixed(0)}", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.getText("Remaining Salary to Pay"), style: TextStyle(color: remainingSalary > 0 ? colorScheme.error : Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
                            Text("₹${remainingSalary > 0 ? remainingSalary.toStringAsFixed(0) : "0"}", style: TextStyle(color: remainingSalary > 0 ? colorScheme.error : Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: remainingSalary <= 0 ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showPaySalaryDialog,
                      icon: const Icon(Icons.payments, size: 18),
                      label: Text(
                        widget.getText(remainingSalary <= 0 ? "Fully Paid" : "Pay Salary"),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text("📝 ${widget.getText("Transactions")}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dynamicTextColor)),
                  const SizedBox(height: 10),
                  transactions.isEmpty
                      ? Text(widget.getText("No transactions found"), style: TextStyle(color: secondaryTextColor))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            var tx = transactions[index];
                            if (tx is! Map) return const SizedBox.shrink();
                            
                            String dateStr = tx['date']?.toString() ?? '';
                            String typeStr = tx['type']?.toString() ?? '';
                            String noteStr = tx['note']?.toString() ?? '';
                            double amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                            bool isAdd = tx['isAdd'] == true;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(dateStr, style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.getText(typeStr), style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.w600)),
                                          if (noteStr.isNotEmpty)
                                            Text(noteStr, style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${isAdd ? '+' : '-'} ₹${amt.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: isAdd ? primaryColor : colorScheme.error,
                                      fontWeight: FontWeight.bold,
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
          ),
        );
      },
    );
  }
}