 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database.dart';

class WorkModuleClass extends StatefulWidget {
  final Map<String, double> rates;
  final Map<String, int> todayQuantities;
  final String Function(String) getText;
  final Color textColor, primaryPurple, accentYellow;
  final VoidCallback onUpdate;
  final Function(DateTime)? onDateChanged;
  
  final String userEmail;
  final String workerId;
  final Future<void> Function(DateTime selectedDate, Map<String, int> quantities, double totalEarnings)? onSave;

  const WorkModuleClass({
    super.key,
    required this.rates,
    required this.todayQuantities,
    required this.getText,
    required this.textColor,
    required this.primaryPurple,
    required this.accentYellow,
    required this.onUpdate,
    required this.userEmail,
    required this.workerId,
    this.onDateChanged,
    this.onSave,
  });

  @override
  State<WorkModuleClass> createState() => _WorkModuleClassState();
}

class _WorkModuleClassState extends State<WorkModuleClass> {
  final Map<String, TextEditingController> _controllers = {};
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (String garment in widget.rates.keys) {
      int initialQty = widget.todayQuantities[garment] ?? 0;
      _controllers[garment] = TextEditingController(text: initialQty.toString());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WorkModuleClass oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.todayQuantities.forEach((garment, qty) {
      if (_controllers.containsKey(garment)) {
        if (_controllers[garment]!.text != qty.toString()) {
          _controllers[garment]!.text = qty.toString();
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: widget.primaryPurple,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(picked);
      }
    }
  }

  void _updateQuantity(String garment, int newQty) {
    if (newQty < 0) return;
    setState(() {
      widget.todayQuantities[garment] = newQty;
      _controllers[garment]?.text = newQty.toString();
    });
    widget.onUpdate();
  }

  void _resetForm() {
    setState(() {
      widget.todayQuantities.updateAll((key, value) => 0);
      _controllers.forEach((key, controller) {
        controller.text = "0";
      });
    });
    widget.onUpdate();
  }

  Future<void> _showConfirmationDialog(double totalEarnings, int totalPieces) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(widget.getText("confirm_save_title")),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}"),
                Text("Total Pieces: $totalPieces"),
                Text("Total Earnings: ₹${totalEarnings.toStringAsFixed(0)}"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(widget.getText("cancel")),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.primaryPurple),
              child: Text(widget.getText("save"), style: const TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executeSave(totalEarnings);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSave() async {
    int totalPieces = 0;
    widget.todayQuantities.forEach((_, qty) => totalPieces += qty);

    if (totalPieces == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.getText("enter_qty_warning")),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    double totalEarnings = 0.0;
    widget.todayQuantities.forEach((garment, qty) {
      double rate = widget.rates[garment] ?? 0.0;
      totalEarnings += qty * rate;
    });

    await _showConfirmationDialog(totalEarnings, totalPieces);
  }

  Future<void> _executeSave(double totalEarnings) async {
    setState(() => _isSaving = true);

    if (widget.onSave != null) {
      await widget.onSave!(_selectedDate, widget.todayQuantities, totalEarnings);
    } else {
      await DatabaseService.saveWorkerDailyEntry(
        userEmail: widget.userEmail,
        workerId: widget.workerId,
        selectedDate: _selectedDate,
        quantities: widget.todayQuantities,
        rates: widget.rates,
        totalEarnings: totalEarnings,
      );
      // Yahan se ScaffoldMessenger (SnackBar) hata diya gaya hai taaki message na dikhe
    }

    if (mounted) {
      setState(() => _isSaving = false);
      // Form reset ho jayega aur quantities 0 ho jayengi bina koi message dikhaye
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    
    final borderColor = theme.dividerColor;
    final subTextColor = isDarkMode ? theme.colorScheme.onSurfaceVariant : widget.textColor.withValues(alpha: 0.7);
    final dynamicTextColor = isDarkMode ? theme.colorScheme.onSurface : widget.textColor;

    int totalPieces = 0;
    double totalEarnings = 0.0;

    widget.todayQuantities.forEach((garment, qty) {
      double rate = widget.rates[garment] ?? 0.0;
      totalPieces += qty;
      totalEarnings += qty * rate;
    });

    double avgRate = totalPieces == 0 ? 0.0 : totalEarnings / totalPieces;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: widget.primaryPurple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextColor, fontSize: 16),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.edit, size: 14),
                label: Text(widget.getText("change")),
                style: TextButton.styleFrom(foregroundColor: widget.primaryPurple),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: widget.primaryPurple.withValues(alpha: 0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${widget.getText('pieces')}: $totalPieces", style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextColor)),
              Text("${widget.getText('earnings')}: ₹${totalEarnings.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: widget.primaryPurple)),
              Text("Avg: ₹${avgRate.toStringAsFixed(1)}", style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: widget.rates.keys.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, index) {
              String garment = widget.rates.keys.elementAt(index);
              double rate = widget.rates[garment] ?? 0.0;
              int qty = widget.todayQuantities[garment] ?? 0;
              double amount = qty * rate;

              if (!_controllers.containsKey(garment)) {
                _controllers[garment] = TextEditingController(text: qty.toString());
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            garment,
                            style: TextStyle(fontWeight: FontWeight.w600, color: dynamicTextColor, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹$rate / pc",
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _updateQuantity(garment, qty - 1),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(Icons.remove, size: 18, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 40,
                          height: 34,
                          child: TextField(
                            controller: _controllers[garment],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.bold, fontSize: 14),
                            onChanged: (val) {
                              int parsedQty = int.tryParse(val) ?? 0;
                              widget.todayQuantities[garment] = parsedQty;
                              widget.onUpdate();
                            },
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _updateQuantity(garment, qty + 1),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(Icons.add, size: 18, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 60,
                      child: Text(
                        "₹${amount.toStringAsFixed(0)}",
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.accentYellow, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  child: Text(widget.getText('reset'), style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.getText('save_work'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}