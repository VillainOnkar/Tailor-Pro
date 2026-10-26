import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WorkerListViewClass extends StatefulWidget {
  final List<Map<String, dynamic>> workers;
  final bool isDarkMode;
  final String Function(String) getText;
  final bool isDesktop;
  final Color cardColor, borderColor, textColor, subTextColor, primaryPurple, accentYellow;
  final Function(Map<String, dynamic>) onWorkerSelected;
  final Function(String) onSubModuleOpen;
  final Future<void> Function()? onRefresh;

  const WorkerListViewClass({
    super.key,
    required this.workers,
    required this.isDarkMode,
    required this.getText,
    required this.isDesktop,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryPurple,
    required this.accentYellow,
    required this.onWorkerSelected,
    required this.onSubModuleOpen,
    this.onRefresh,
  });

  @override
  State<WorkerListViewClass> createState() => _WorkerListViewClassState();
}

class _WorkerListViewClassState extends State<WorkerListViewClass> {
  String _searchQuery = '';
  
  // 🚀 Caching map taaki baar-बार base64 decode na karna pade aur photo instant load ho
  final Map<String, Uint8List> _imageCache = {};

  @override
  void didUpdateWidget(covariant WorkerListViewClass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workers != widget.workers) {
      // Jab bhi list badle, cache ko update ya clean kar sakte hain
      setState(() {});
    }
  }

  // Fast Avatar Builder with Local Caching
  Widget _buildWorkerAvatar(Map<String, dynamic> worker) {
    final photoStr = worker['photo'];
    final workerId = worker['id'] ?? worker['workerId'] ?? worker.hashCode.toString();
    
    if (photoStr != null && photoStr.toString().startsWith('data:image')) {
      try {
        // Agar cache me pehle se decoded bytes hain toh wahi se uthao (Instant load)
        if (_imageCache.containsKey(workerId)) {
          return CircleAvatar(
            backgroundColor: widget.primaryPurple.withValues(alpha: 0.2),
            backgroundImage: MemoryImage(_imageCache[workerId]!),
          );
        }

        // Agar cache me nahi hai toh decode karke cache me save kar lo
        final base64String = photoStr.split(',').last;
        final bytes = base64Decode(base64String);
        _imageCache[workerId] = bytes;

        return CircleAvatar(
          backgroundColor: widget.primaryPurple.withValues(alpha: 0.2),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        print("Error decoding image: $e");
      }
    }
    
    return CircleAvatar(
      backgroundColor: widget.primaryPurple.withValues(alpha: 0.2),
      child: Text(
        (worker['name'] ?? 'W').isNotEmpty ? (worker['name'] ?? 'W')[0].toUpperCase() : 'W',
        style: TextStyle(color: widget.primaryPurple, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredWorkers = widget.workers.where((worker) {
      final name = (worker['name'] ?? '').toLowerCase();
      final phone = (worker['phone'] ?? '').toLowerCase();
      final role = (worker['role'] ?? '').toLowerCase();
      final id = (worker['id'] ?? worker['workerId'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query) || role.contains(query) || id.contains(query);
    }).toList();

    Widget listViewContent = filteredWorkers.isEmpty
        ? Center(child: Text(widget.getText('noWorkersFound'), style: TextStyle(color: widget.subTextColor)))
        : ListView.builder(
            itemCount: filteredWorkers.length,
            itemBuilder: (context, index) {
              final worker = filteredWorkers[index];
              final workerIdText = worker['id'] ?? worker['workerId'] ?? 'N/A';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: widget.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.borderColor),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await widget.onWorkerSelected(worker);
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _buildWorkerAvatar(worker),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        worker['name'] ?? '',
                                        style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: widget.primaryPurple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "ID: $workerIdText",
                                        style: TextStyle(color: widget.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text("${worker['role']} • ${worker['phone']}", style: TextStyle(color: widget.subTextColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: widget.subTextColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [widget.primaryPurple, widget.primaryPurple.withValues(alpha: 0.6)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.group_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.getText('workers'),
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: widget.isDesktop ? 22 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.getText('subTitleWorkers'),
                      style: TextStyle(color: widget.subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => widget.onSubModuleOpen('MasterRate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.settings_suggest_rounded, size: 18),
              label: Text(
                widget.getText('masterRate'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildStatCard(widget.getText('totalWorkers'), widget.workers.length.toString(), Icons.people_outline_rounded)),
            const SizedBox(width: 14),
            Expanded(child: _buildStatCard(widget.getText('activeWorkers'), widget.workers.where((w) => w['status'] == 'Active').length.toString(), Icons.verified_rounded)),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(color: widget.textColor),
          decoration: InputDecoration(
            hintText: widget.getText('searchHint'),
            hintStyle: TextStyle(color: widget.subTextColor, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: widget.primaryPurple),
            filled: true,
            fillColor: widget.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: widget.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: widget.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: widget.primaryPurple, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.onRefresh != null
              ? RefreshIndicator(
                  color: widget.primaryPurple,
                  onRefresh: widget.onRefresh!,
                  child: listViewContent,
                )
              : listViewContent,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: widget.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.borderColor)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: widget.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: widget.primaryPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: widget.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: widget.subTextColor, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}