import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database.dart';

class HistoryModuleClass extends StatefulWidget {
  final String userEmail; 
  final String workerId;  
  final Color primaryPurple, accentYellow, textColor;
  final String Function(String) getText;

  const HistoryModuleClass({
    super.key,
    required this.userEmail,
    required this.workerId,
    required this.primaryPurple,
    required this.accentYellow,
    required this.textColor,
    required this.getText,
  });

  @override
  State<HistoryModuleClass> createState() => _HistoryModuleClassState();
}

class _HistoryModuleClassState extends State<HistoryModuleClass> {
  String? _selectedMonth;
  Map<String, dynamic>? _selectedDayEntry;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  late Future<List<Map<String, dynamic>>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _loadHistoryData(); // Initial load
  }

  // 🔄 Data reload karne ke liye function
  void _loadHistoryData() {
    setState(() {
      _entriesFuture = DatabaseService.fetchWorkerEntries(
        userEmail: widget.userEmail,
        workerId: widget.workerId,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<Map<String, dynamic>>> _groupEntriesByMonth(List<Map<String, dynamic>> allEntries) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var entry in allEntries) {
      DateTime date = DateTime.tryParse(entry['date'].toString()) ?? DateTime.now();
      String monthKey = DateFormat('MMMM yyyy').format(date);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final dynamicTextColor = widget.textColor;
    final secondaryTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final searchFillColor = isDarkMode ? const Color(0xFF1E1E2C) : Colors.grey.shade100;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          constraints: const BoxConstraints(minHeight: 300),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: widget.primaryPurple,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    widget.getText("Error loading history"), 
                    style: TextStyle(color: dynamicTextColor),
                  ),
                );
              }

              List<Map<String, dynamic>> allEntries = snapshot.data ?? [];

              return Column(
                children: [
                  // STEP 3: Day Details View
                  if (_selectedDayEntry != null) () {
                    DateTime date = DateTime.tryParse(_selectedDayEntry!['date'].toString()) ?? DateTime.now();
                    Map<String, dynamic> quantities = Map<String, dynamic>.from(_selectedDayEntry!['quantities'] ?? {});
                    Map<String, dynamic> prices = Map<String, dynamic>.from(_selectedDayEntry!['prices'] ?? _selectedDayEntry!['rates'] ?? {});
                    
                    double totalEarnings = double.tryParse(_selectedDayEntry!['total_earnings']?.toString() ?? '0') ?? 0.0;
                    int totalPieces = quantities.values.fold(0, (sum, q) => sum + (int.tryParse(q.toString()) ?? 0));

                    return Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                  color: widget.primaryPurple,
                                  onPressed: () => setState(() => _selectedDayEntry = null),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(date),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // 🗑️ Delete Button with Reload Logic Added
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                    Color dialogTextColor = isDarkMode ? Colors.white : Colors.black87;

                                    bool? confirmDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: Theme.of(context).cardColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16.0),
                                          ),
                                          title: Text(
                                            widget.getText("Delete Entry"),
                                            style: TextStyle(color: dialogTextColor, fontWeight: FontWeight.bold),
                                          ),
                                          content: Text(
                                            widget.getText("Are you sure you want to delete this day's record?"),
                                            style: TextStyle(color: dialogTextColor),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: Text(
                                                widget.getText("Cancel"),
                                                style: TextStyle(color: widget.primaryPurple),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: Text(
                                                widget.getText("Delete"),
                                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmDelete == true && _selectedDayEntry != null) {
                                      String dateKey = _selectedDayEntry!['date']?.toString() ?? '';
                                      
                                      if (dateKey.isNotEmpty) {
                                        bool success = await DatabaseService.deleteWorkerDailyEntry(
                                          userEmail: widget.userEmail,
                                          workerId: widget.workerId,
                                          dateKey: dateKey,
                                        );

                                        if (success) {
                                          setState(() {
                                            _selectedDayEntry = null; // Detail view se wapas bhej dein
                                          });

                                          // 🔄 Yahan data ko dubara fetch/reload kiya gaya hai
                                          _loadHistoryData();

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(widget.getText("Record deleted successfully")),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(widget.getText("Error deleting record")),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: borderColor),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                ...quantities.entries.map((e) {
                                  String garment = e.key;
                                  int qty = int.tryParse(e.value.toString()) ?? 0;
                                  if (qty <= 0) return const SizedBox.shrink();

                                  double unitPrice = double.tryParse(prices[garment]?.toString() ?? '0') ?? 0.0;
                                  double itemTotalPrice = unitPrice * qty;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: borderColor)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                garment, 
                                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: dynamicTextColor),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (unitPrice > 0)
                                                Text(
                                                  "${widget.getText("Rate")}: ₹${unitPrice.toStringAsFixed(0)} / ${widget.getText("Pc")}",
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "$qty ${widget.getText("Pcs")}", 
                                              style: TextStyle(fontWeight: FontWeight.bold, color: widget.accentYellow, fontSize: 16),
                                            ),
                                            if (itemTotalPrice > 0)
                                              Text(
                                                "₹${itemTotalPrice.toStringAsFixed(0)}",
                                                style: TextStyle(fontWeight: FontWeight.w600, color: dynamicTextColor, fontSize: 13),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${widget.getText("Total Pieces")}: $totalPieces", 
                                        style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextColor, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${widget.getText("Total Earnings")}: ₹${totalEarnings.toStringAsFixed(0)}", 
                                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.accentYellow, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }()

                  // STEP 2: Days List View (For a Selected Month)
                  else if (_selectedMonth != null) () {
                    var grouped = _groupEntriesByMonth(allEntries);
                    var monthEntries = grouped[_selectedMonth] ?? [];

                    if (_searchQuery.isNotEmpty) {
                      monthEntries = monthEntries.where((entry) {
                        DateTime d = DateTime.tryParse(entry['date'].toString()) ?? DateTime.now();
                        String formattedDate = DateFormat('dd MMM yyyy').format(d).toLowerCase();
                        return formattedDate.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    return Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                  color: widget.primaryPurple,
                                  onPressed: () {
                                    setState(() {
                                      _selectedMonth = null;
                                      _searchQuery = "";
                                      _searchController.clear();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedMonth!,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: borderColor),
                          
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: TextStyle(color: dynamicTextColor),
                              decoration: InputDecoration(
                                hintText: widget.getText("Search date (e.g., 15 Jun)..."),
                                hintStyle: TextStyle(color: secondaryTextColor),
                                prefixIcon: Icon(Icons.search, color: widget.primaryPurple),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: secondaryTextColor),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = "";
                                            _searchController.clear();
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: searchFillColor,
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
                                  borderSide: BorderSide(color: widget.primaryPurple, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              ),
                            ),
                          ),

                          Expanded(
                            child: monthEntries.isEmpty
                                ? Center(
                                    child: Text(
                                      widget.getText("No matching dates found"),
                                      style: TextStyle(color: secondaryTextColor, fontSize: 16),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: monthEntries.length,
                                    itemBuilder: (context, index) {
                                      var entry = monthEntries[index];
                                      DateTime date = DateTime.tryParse(entry['date'].toString()) ?? DateTime.now();
                                      Map<String, dynamic> quantities = Map<String, dynamic>.from(entry['quantities'] ?? {});
                                      int pieces = quantities.values.fold(0, (sum, q) => sum + (int.tryParse(q.toString()) ?? 0));
                                      double earnings = double.tryParse(entry['total_earnings']?.toString() ?? '0') ?? 0.0;

                                      return InkWell(
                                        onTap: () => setState(() => _selectedDayEntry = entry),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: borderColor)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      DateFormat('dd MMM yyyy').format(date), 
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dynamicTextColor),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "$pieces ${widget.getText("Pieces Stitched")}", 
                                                      style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "₹${earnings.toStringAsFixed(0)}", 
                                                    style: TextStyle(color: widget.accentYellow, fontWeight: FontWeight.bold, fontSize: 15),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(Icons.arrow_forward_ios, size: 14, color: secondaryTextColor),
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
                  }()

                  // STEP 1: Month List View (Main Screen)
                  else () {
                    var groupedEntries = _groupEntriesByMonth(allEntries);

                    if (_searchQuery.isNotEmpty) {
                      var filteredMap = <String, List<Map<String, dynamic>>>{};
                      groupedEntries.forEach((monthName, entriesList) {
                        if (monthName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                          filteredMap[monthName] = entriesList;
                        }
                      });
                      groupedEntries = filteredMap;
                    }

                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text("📜 ", style: TextStyle(fontSize: 20)),
                                    Text(
                                      widget.getText("Work History"),
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dynamicTextColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: borderColor),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: TextStyle(color: dynamicTextColor),
                              decoration: InputDecoration(
                                hintText: widget.getText("Search month (e.g., June 2026)..."),
                                hintStyle: TextStyle(color: secondaryTextColor),
                                prefixIcon: Icon(Icons.search, color: widget.primaryPurple),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: secondaryTextColor),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = "";
                                            _searchController.clear();
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: searchFillColor,
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
                                  borderSide: BorderSide(color: widget.primaryPurple, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              ),
                            ),
                          ),

                          Expanded(
                            child: groupedEntries.isEmpty
                                ? Center(
                                    child: Text(
                                      widget.getText("No history found"), 
                                      style: TextStyle(color: secondaryTextColor, fontSize: 16),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: groupedEntries.keys.length,
                                    itemBuilder: (context, index) {
                                      String monthName = groupedEntries.keys.elementAt(index);
                                      var entries = groupedEntries[monthName]!;

                                      int totalPieces = 0;
                                      double totalEarnings = 0.0;
                                      Set<String> workingDaysSet = {};

                                      for (var entry in entries) {
                                        DateTime d = DateTime.tryParse(entry['date'].toString()) ?? DateTime.now();
                                        workingDaysSet.add(DateFormat('yyyy-MM-dd').format(d));
                                        Map<String, dynamic> qMap = Map<String, dynamic>.from(entry['quantities'] ?? {});
                                        totalPieces += qMap.values.fold(0, (sum, q) => sum + (int.tryParse(q.toString()) ?? 0));
                                        totalEarnings += double.tryParse(entry['total_earnings']?.toString() ?? '0') ?? 0.0;
                                      }

                                      int workingDays = workingDaysSet.length;
                                      double avgPieces = workingDays == 0 ? 0 : totalPieces / workingDays;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                                        decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: borderColor)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "📅 $monthName", 
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicTextColor),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "🧵 ${widget.getText("Total Pieces")} : $totalPieces", 
                                                    style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
                                                ),
                                                Text(
                                                  "💰 ${widget.getText("Earnings")} : ₹${totalEarnings.toStringAsFixed(0)}", 
                                                  style: TextStyle(color: widget.accentYellow, fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "📆 ${widget.getText("Working Days")} : $workingDays", 
                                                  style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  "📈 ${widget.getText("Avg. Pcs/Day")} : ${avgPieces.toStringAsFixed(1)}", 
                                                  style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(
                                                onPressed: () => setState(() => _selectedMonth = monthName),
                                                icon: Text(widget.getText("View Days"), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                label: const Icon(Icons.arrow_forward, size: 16),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: widget.accentYellow,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  }()
                ],
              );
            },
          ),
        );
      },
    );
  }
}
