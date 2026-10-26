import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:printing/printing.dart';
import '../../database.dart'; // Apne database service ka sahi path yahan dein

class MasterMeasurementPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  final bool isDarkMode;
  final Map<String, String> translations;
  final String? orderId;
  final String userEmail; // Shop details fetch karne ke liye email

  const MasterMeasurementPage({
    super.key,
    required this.customer,
    required this.isDarkMode,
    required this.translations,
    this.orderId,
    required this.userEmail,
  });

  @override
  State<MasterMeasurementPage> createState() => _MasterMeasurementPageState();
}

class _MasterMeasurementPageState extends State<MasterMeasurementPage> {
  Map<String, dynamic>? _shopInfoData;
  late String? _resolvedOrderId;

  @override
  void initState() {
    super.initState();
    _loadShopInformation();
    
    // Yahan orderId ko widget se ya customer map ke andar se dhoond kar secure kar rahe hain
    _resolvedOrderId = widget.orderId ?? widget.customer['order_id'] ?? widget.customer['orderId'];
  }

  Future<void> _loadShopInformation() async {
    try {
      Map<String, dynamic>? shopData = await DatabaseService.fetchShopInformation(widget.userEmail);
      if (shopData != null && mounted) {
        setState(() {
          _shopInfoData = shopData;
        });
      }
    } catch (e) {
      debugPrint("Error loading shop info in measurements: $e");
    }
  }

  String _t(String key) => widget.translations[key] ?? key;

  String _escapeHtml(Object? value) {
    if (value == null) return '';
    return value.toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // HTML Content Generator for Thermal Receipt with Dynamic Shop Info & 72mm Auto Size
  String _generateHtmlContent(String garmentName, Map<String, dynamic> items, String customerName, String customerId, String? orderId) {
    final shopName = _escapeHtml(_shopInfoData?['shop_name'] ?? 'TAILORING SHOP');
    final shopAddress = _escapeHtml(_shopInfoData?['address'] ?? '');
    final shopPhone = _escapeHtml(_shopInfoData?['phone'] ?? '');

    // Debugging ke liye print statement
    debugPrint("Generating PDF/Thermal with Order ID: $orderId");

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;700&display=swap" rel="stylesheet">
        <style>
          @page {
            size: 72mm auto;
            margin: 0;
          }
          body {
            font-family: 'Noto Sans Devanagari', Arial, sans-serif;
            width: 72mm;
            margin: 0 auto;
            padding: 6px;
            font-size: 12px;
            color: #000;
            background: #fff;
          }
          .center { text-align: center; }
          .bold { font-weight: bold; }
          .shop-title { font-size: 16px; font-weight: bold; text-align: center; margin-bottom: 2px; }
          .shop-info { font-size: 9px; text-align: center; margin-bottom: 2px; }
          .divider { border-bottom: 1px dashed #000; margin: 5px 0; }
          .info-row { margin-bottom: 3px; font-size: 11px; }
          .item-row { display: flex; justify-content: space-between; margin-bottom: 4px; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="shop-title">$shopName</div>
        ${shopAddress.isNotEmpty ? '<div class="shop-info">$shopAddress</div>' : ''}
        ${shopPhone.isNotEmpty ? '<div class="shop-info">Phone: $shopPhone</div>' : ''}
        <div class="divider"></div>
        
        <div class="info-row"><span class="bold">Name:</span> $customerName</div>
        <div class="info-row"><span class="bold">Customer ID:</span> $customerId</div>
        ${orderId != null && orderId.toString().trim().isNotEmpty && orderId != 'null' ? '<div class="info-row"><span class="bold">Order ID:</span> $orderId</div>' : ''}
        
        <div class="divider"></div>
        <div class="center bold" style="font-size: 13px; margin: 4px 0;">${garmentName.toUpperCase()}</div>
        <div class="divider"></div>

        <div>
          ${items.entries.map((entry) {
            String rawKey = entry.key;
            String translatedKey = _t(rawKey) != rawKey ? _t(rawKey) : rawKey;
            String formattedKey = translatedKey.isNotEmpty 
                ? '${translatedKey[0].toUpperCase()}${translatedKey.substring(1)}' 
                : translatedKey;
            return '<div class="item-row"><span>$formattedKey:</span> <span class="bold">${entry.value}</span></div>';
          }).join('')}
        </div>

        <div class="divider"></div>
        <div class="center" style="font-size: 10px; margin-top: 6px;">Thank You! / धन्यवाद!</div>
      </body>
      </html>
    ''';
  }

  Future<void> _printThermalHtmlMeasurement(
      String garmentName, Map<String, dynamic> items, String customerName, String customerId, String? orderId) async {
    
    final String htmlContent = _generateHtmlContent(garmentName, items, customerName, customerId, orderId);

    try {
      final Directory? targetDirectory = Directory.systemTemp;
      if (targetDirectory == null) return;

      final htmlToPdfPlugin = FlutterNativeHtmlToPdf();
      
      final generatedPdfFile = await htmlToPdfPlugin.convertHtmlToPdf(
        html: htmlContent,
        targetDirectory: targetDirectory.path,
        targetName: "Measurement_$garmentName",
      );

      if (generatedPdfFile != null) {
        final pdfBytes = await generatedPdfFile.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'Measurement_$garmentName.pdf',
        );
      }
    } catch (e) {
      debugPrint("Error generating HTML PDF for print: $e");
    }
  }

  Future<void> _shareThermalHtmlMeasurement(
      String garmentName, Map<String, dynamic> items, String customerName, String customerId, String? orderId) async {
    
    final String htmlContent = _generateHtmlContent(garmentName, items, customerName, customerId, orderId);

    try {
      final Directory? targetDirectory = Directory.systemTemp;
      if (targetDirectory == null) return;

      final htmlToPdfPlugin = FlutterNativeHtmlToPdf();
      
      final generatedPdfFile = await htmlToPdfPlugin.convertHtmlToPdf(
        html: htmlContent,
        targetDirectory: targetDirectory.path,
        targetName: "Measurement_${customerName}_$garmentName",
      );

      if (generatedPdfFile != null) {
        final pdfBytes = await generatedPdfFile.readAsBytes();
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Measurement_${customerName}_$garmentName.pdf',
        );
      }
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = widget.isDarkMode ? const Color(0xFF09090B) : const Color(0xFFF4F4F5);
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF18181B) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    Color textColor = widget.isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
    Color subTextColor = widget.isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    const Color primaryThemeColor = Color(0xFF7C3AED);

    String customerName = widget.customer['name'] ?? widget.customer['full_name'] ?? 'Unknown';
    String customerId = widget.customer['customer_id'] ?? widget.customer['id'] ?? 'N/A';

    var rawMeasurements = widget.customer['master_measurement'] ?? widget.customer['measurements'] ?? {};
    
    Map<String, Map<String, dynamic>> groupedGarments = {};

    if (rawMeasurements is Map) {
      rawMeasurements.forEach((key, value) {
        String lowerKey = key.toLowerCase();
        
        if (lowerKey == 'notes' || lowerKey == 'updated_at' || lowerKey == 'created_at') {
          return;
        } else if (value is Map) {
          groupedGarments[key] = Map<String, dynamic>.from(value);
        } else {
          List<String> parts = key.split('_');
          String garmentName = parts.isNotEmpty ? parts[0] : 'General';
          String measurementKey = parts.length > 1 ? parts.sublist(1).join('_') : key;

          if (!groupedGarments.containsKey(garmentName)) {
            groupedGarments[garmentName] = {};
          }
          groupedGarments[garmentName]![measurementKey] = value;
        }
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryThemeColor,
        elevation: 0,
        title: Text(
          _t('masterMeasurement'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryThemeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryThemeColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Customer: $customerName',
                      style: const TextStyle(color: primaryThemeColor, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryThemeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ID: $customerId',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_resolvedOrderId != null && _resolvedOrderId!.isNotEmpty && _resolvedOrderId != 'null')
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Order ID: $_resolvedOrderId',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),

            if (groupedGarments.isEmpty || groupedGarments.values.every((v) => v.isEmpty))
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Text(
                    _t('noMeasurementsFound') != 'noMeasurementsFound' ? _t('noMeasurementsFound') : 'No measurements available.',
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ),
              )
            else
              ...groupedGarments.entries.map((garmentEntry) {
                String garmentName = garmentEntry.key;
                Map<String, dynamic> items = garmentEntry.value;

                items.removeWhere((k, _) => k.toLowerCase() == 'notes');
                if (items.isEmpty) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.checkroom, color: primaryThemeColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                garmentName.toUpperCase(),
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share, color: primaryThemeColor, size: 20),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                tooltip: 'Share Receipt',
                                onPressed: () {
                                  _shareThermalHtmlMeasurement(garmentName, items, customerName, customerId, _resolvedOrderId);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.print, color: primaryThemeColor, size: 20),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                tooltip: 'Print Thermal Receipt',
                                onPressed: () {
                                  _printThermalHtmlMeasurement(garmentName, items, customerName, customerId, _resolvedOrderId);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1),
                      ),
                      const SizedBox(height: 4),

                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: items.entries.map((entry) {
                          String rawKey = entry.key;
                          String translatedKey = _t(rawKey) != rawKey ? _t(rawKey) : rawKey;
                          
                          String formattedLabel = translatedKey.isNotEmpty 
                              ? '${translatedKey[0].toUpperCase()}${translatedKey.substring(1)}' 
                              : translatedKey;

                          return SizedBox(
                            width: 130,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('• ', style: TextStyle(color: primaryThemeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    '$formattedLabel: ${entry.value}',
                                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}