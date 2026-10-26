import 'package:flutter/material.dart'; 
import '../../../database.dart';

class MasterRateViewClass extends StatefulWidget {
  final Map<String, double> rates;
  final String Function(String) getText;
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;
  final Color borderColor;
  final Color primaryPurple;
  final Color accentYellow;
  final String userEmail;
  final VoidCallback onBack;
  final VoidCallback onUpdate;

  const MasterRateViewClass({
    super.key,
    required this.rates,
    required this.getText,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
    required this.borderColor,
    required this.primaryPurple,
    required this.accentYellow,
    required this.userEmail,
    required this.onBack,
    required this.onUpdate,
  });

  @override
  State<MasterRateViewClass> createState() => _MasterRateViewClassState();
}

class _MasterRateViewClassState extends State<MasterRateViewClass> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  void _saveOrUpdateRate(String garmentName, double rateVal) async {
    if (garmentName.isEmpty) return;

    bool success = await DatabaseService.updateGlobalRate(
      userEmail: widget.userEmail,
      garmentName: garmentName,
      rate: rateVal,
    );

    if (success) {
      widget.rates[garmentName] = rateVal;
      _itemController.clear();
      _rateController.clear();
      widget.onUpdate();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rate updated successfully for $garmentName'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update rate'), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteRate(String garmentName) async {
    bool success = await DatabaseService.deleteGlobalRate(
      userEmail: widget.userEmail,
      garmentName: garmentName,
    );

    if (success) {
      setState(() {
        widget.rates.remove(garmentName);
      });
      widget.onUpdate();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $garmentName successfully'), backgroundColor: Colors.orange),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete rate from database'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation(String garmentName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          title: Text(
            'Delete Rate',
            style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "$garmentName"?',
            style: TextStyle(color: widget.subTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteRate(garmentName);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddOrEditRateDialog({String? existingKey, double? existingRate}) {
    if (existingKey != null) {
      _itemController.text = existingKey;
      _rateController.text = existingRate.toString();
    } else {
      _itemController.clear();
      _rateController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          title: Text(
            existingKey == null ? 'Add New Garment Rate' : 'Edit Rate: $existingKey',
            style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemController,
                readOnly: existingKey != null,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  labelText: 'Garment / Item Name',
                  labelStyle: TextStyle(color: widget.subTextColor),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryPurple)),
                  filled: existingKey != null,
                  fillColor: existingKey != null ? widget.borderColor.withValues(alpha: 0.2) : Colors.transparent,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  labelText: 'Rate (₹)',
                  labelStyle: TextStyle(color: widget.subTextColor),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryPurple)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentYellow,
                foregroundColor: Colors.black87,
              ),
              onPressed: () {
                String name = _itemController.text.trim();
                double? rate = double.tryParse(_rateController.text.trim());

                if (name.isNotEmpty && rate != null) {
                  Navigator.pop(context);
                  _saveOrUpdateRate(name, rate);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid item name and rate.')),
                  );
                }
              },
              child: const Text('Save Rate'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: widget.textColor),
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.getText('globalRates'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.textColor),
                  ),
                  Text(
                    widget.getText('globalRatesDesc'),
                    style: TextStyle(fontSize: 13, color: widget.subTextColor),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentYellow,
                foregroundColor: Colors.black87,
              ),
              onPressed: () => _showAddOrEditRateDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Rate'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: widget.rates.isEmpty
              ? Center(
                  child: Text(
                    'No global rates added yet. Click "Add Rate" to create one.',
                    style: TextStyle(color: widget.subTextColor),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.rates.keys.length,
                  itemBuilder: (context, index) {
                    String key = widget.rates.keys.elementAt(index);
                    double value = widget.rates[key]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: widget.primaryPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.checkroom, color: widget.primaryPurple, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: widget.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '₹$value',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.accentYellow,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.edit, size: 18, color: widget.subTextColor),
                                onPressed: () => _showAddOrEditRateDialog(existingKey: key, existingRate: value),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                onPressed: () => _showDeleteConfirmation(key),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}