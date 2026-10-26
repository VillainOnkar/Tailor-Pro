import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import '../database.dart';

class ReportsScreen extends StatefulWidget {
  final String initialLanguage;
  final bool isDarkMode;
  final String userEmail;

  const ReportsScreen({
    super.key,
    required this.initialLanguage,
    required this.isDarkMode,
    required this.userEmail,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Yahan default filter ko 'आज' (Today) set kar diya gaya hai
  String _selectedDateFilter = 'आज';
  String _graphInterval = 'दिवस';

  bool _isLoading = true;
  String _errorMessage = '';

  // API Data Fields
  double _totalRevenue = 0.0;
  double _receivedAmount = 0.0;
  double _pendingAmount = 0.0;
  int _totalOrders = 0;
  int _totalCustomers = 0;
  double _avgOrderValue = 0.0;

  int _todayOrdersCount = 0;
  int _pendingOrdersCount = 0;
  int _readyOrdersCount = 0;
  int _deliveredOrdersCount = 0;

  Map<String, double> _paymentModes = {'Cash': 0.0, 'UPI': 0.0, 'Card': 0.0};
  List<Map<String, dynamic>> _workerList = [];
  Map<String, int> _garmentCounts = {};

  // Graph and Monthly Comparison Dynamic Data
  List<Map<String, dynamic>> _trendData = [];
  Map<String, dynamic> _monthlyComparison = {};

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await DatabaseService.fetchReportsSummaryData(widget.userEmail, filter: _selectedDateFilter);

      if (result['status'] == true) {
        if (mounted) {
          setState(() {
            _totalRevenue = (result['totalRevenue'] ?? 0.0).toDouble();
            _receivedAmount = (result['receivedAmount'] ?? 0.0).toDouble();
            _pendingAmount = (result['pendingAmount'] ?? 0.0).toDouble();
            _totalOrders = result['totalOrders'] ?? 0;
            _totalCustomers = result['totalCustomers'] ?? 0;
            _avgOrderValue = (result['avgOrderValue'] ?? 0.0).toDouble();
            _todayOrdersCount = result['todayOrdersCount'] ?? 0;
            _pendingOrdersCount = result['pendingOrdersCount'] ?? 0;
            _readyOrdersCount = result['readyOrdersCount'] ?? 0;
            _deliveredOrdersCount = result['deliveredOrdersCount'] ?? 0;
            _paymentModes = Map<String, double>.from(result['paymentModes'] ?? {'Cash': 0.0, 'UPI': 0.0, 'Card': 0.0});
            _workerList = List<Map<String, dynamic>>.from(result['workerList'] ?? []);
            _garmentCounts = Map<String, int>.from(result['garmentCounts'] ?? {});
            
            _trendData = List<Map<String, dynamic>>.from(result['trendData'] ?? []);
            _monthlyComparison = Map<String, dynamic>.from(result['monthlyComparison'] ?? {});
            
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = result['message'] ?? 'Unknown error occurred';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // --- HTML Special Character Escaper ---
  String _escapeHtml(Object? value) {
    if (value == null) return '';
    return value.toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // --- Professional A4 Size HTML Based PDF Generator ---
  Future<Uint8List> _generateReportHtmlPdfBytes() async {
    final reportTitle = _escapeHtml(_getText('reportsTitle'));
    final dateRange = _escapeHtml(_selectedDateFilter);
    final totalOrders = _escapeHtml(_totalOrders);
    final totalRevenue = _escapeHtml(_totalRevenue.toStringAsFixed(0));
    final receivedAmount = _escapeHtml(_receivedAmount.toStringAsFixed(0));
    final pendingAmount = _escapeHtml(_pendingAmount.toStringAsFixed(0));
    final totalCustomers = _escapeHtml(_totalCustomers);
    final avgOrderValue = _escapeHtml(_avgOrderValue.toStringAsFixed(0));

    // Order Overview Counts
    final todayOrders = _escapeHtml(_todayOrdersCount);
    final pendingOrders = _escapeHtml(_pendingOrdersCount);
    final readyOrders = _escapeHtml(_readyOrdersCount);
    final deliveredOrders = _escapeHtml(_deliveredOrdersCount);

    // Payment Modes
    final cashAmount = _escapeHtml((_paymentModes['Cash'] ?? 0.0).toStringAsFixed(0));
    final upiAmount = _escapeHtml((_paymentModes['UPI'] ?? 0.0).toStringAsFixed(0));
    final cardAmount = _escapeHtml((_paymentModes['Card'] ?? 0.0).toStringAsFixed(0));

    // Garment Rows
    String garmentRows = _garmentCounts.entries.map((entry) {
      String name = _escapeHtml(entry.key);
      String count = _escapeHtml(entry.value);
      return '''
        <tr>
          <td>$name</td>
          <td style="text-align: right;">$count pcs</td>
        </tr>
      ''';
    }).join('');

    if (garmentRows.isEmpty) {
      garmentRows = '<tr><td colspan="2" style="text-align: center; color: #71717a;">No garment data available</td></tr>';
    }

    // Worker Performance & Salary Rows
    double totalWorkerEarned = 0.0;
    double totalWorkerPaid = 0.0;
    double totalWorkerDue = 0.0;
    for (var w in _workerList) {
      totalWorkerEarned += (w['earned'] as num?)?.toDouble() ?? 0.0;
      totalWorkerPaid += (w['paid'] as num?)?.toDouble() ?? 0.0;
      totalWorkerDue += (w['due'] as num?)?.toDouble() ?? 0.0;
    }

    String workerRows = _workerList.map((w) {
      String name = _escapeHtml(w['name']);
      String pieces = _escapeHtml(w['pieces'] ?? '0');
      String earned = _escapeHtml(((w['earned'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
      String paid = _escapeHtml(((w['paid'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
      String due = _escapeHtml(((w['due'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
      return '''
        <tr>
          <td>$name</td>
          <td style="text-align: center;">$pieces</td>
          <td style="text-align: right;">Rs. $earned</td>
          <td style="text-align: right; color: #16a34a;">Rs. $paid</td>
          <td style="text-align: right; color: #dc2626;">Rs. $due</td>
        </tr>
      ''';
    }).join('');

    if (workerRows.isEmpty) {
      workerRows = '<tr><td colspan="5" style="text-align: center; color: #71717a;">No worker records found</td></tr>';
    }

    // Monthly Comparison data
    String prevMonthName = _escapeHtml(_monthlyComparison['prevMonthName'] ?? 'Prev');
    String currMonthName = _escapeHtml(_monthlyComparison['currMonthName'] ?? 'Current');
    String prevOrders = _escapeHtml(_monthlyComparison['prevOrders'] ?? '0');
    String prevRevenue = _escapeHtml(_monthlyComparison['prevRevenue'] ?? '0');
    String prevCustomers = _escapeHtml(_monthlyComparison['prevCustomers'] ?? '0');
    String prevAvgValue = _escapeHtml(_monthlyComparison['prevAvgValue'] ?? '0');

    String ordersTrend = _escapeHtml(_monthlyComparison['ordersTrend'] ?? '');
    String revenueTrend = _escapeHtml(_monthlyComparison['revenueTrend'] ?? '');
    String customersTrend = _escapeHtml(_monthlyComparison['customersTrend'] ?? '');
    String avgValueTrend = _escapeHtml(_monthlyComparison['avgValueTrend'] ?? '');

    // Trend Data points for Visual Bar Graph representation in PDF
    List<Map<String, dynamic>> filteredTrend = _trendData.where((item) => item['interval'] == _graphInterval).toList();
    if (filteredTrend.isEmpty) filteredTrend = _trendData;

    double maxTrendAmount = 1.0;
    for (var item in filteredTrend) {
      double amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
      if (amt > maxTrendAmount) maxTrendAmount = amt;
    }

    String graphicalBarsHtml = filteredTrend.map((item) {
      String label = _escapeHtml(item['label'] ?? '');
      double amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
      int heightPercent = ((amt / maxTrendAmount) * 100).toInt();
      if (heightPercent < 5 && amt > 0) heightPercent = 5;

      return '''
        <div style="display: inline-block; text-align: center; width: 45px; margin-right: 8px; vertical-align: bottom;">
          <div style="font-size: 9px; color: #71717a; margin-bottom: 4px;">Rs. ${amt.toStringAsFixed(0)}</div>
          <div style="height: 100px; display: flex; align-items: flex-end; justify-content: center; background: #f4f3f8; border-radius: 4px; padding: 2px;">
            <div style="width: 25px; height: ${heightPercent}%; background-color: #FFB300; border-radius: 3px;"></div>
          </div>
          <div style="font-size: 9px; color: #09090b; margin-top: 4px; font-weight: bold; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">$label</div>
        </div>
      ''';
    }).join('');

    if (graphicalBarsHtml.isEmpty) {
      graphicalBarsHtml = '<div style="text-align: center; color: #71717a; padding: 20px;">No graph trend data available</div>';
    }

    String trendRows = filteredTrend.map((item) {
      String label = _escapeHtml(item['label'] ?? '');
      String amt = _escapeHtml(((item['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
      return '''
        <tr>
          <td>$label</td>
          <td style="text-align: right; font-weight: bold;">Rs. $amt</td>
        </tr>
      ''';
    }).join('');

    if (trendRows.isEmpty) {
      trendRows = '<tr><td colspan="2" style="text-align: center; color: #71717a;">No trend history available</td></tr>';
    }

    String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;600;700&display=swap');
          body {
            font-family: 'Noto Sans Devanagari', Arial, sans-serif;
            margin: 0;
            padding: 20px;
            font-size: 12px;
            color: #09090b;
            background: #ffffff;
            line-height: 1.4;
          }
          .header {
            border-bottom: 2px solid #7c3aed;
            padding-bottom: 12px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
          }
          .shop-title { font-size: 20px; font-weight: bold; color: #7c3aed; margin-bottom: 4px; }
          .report-subtitle { font-size: 13px; font-weight: 600; color: #52525b; }
          .meta-info { text-align: right; font-size: 11px; color: #71717a; }
          
          .section-title {
            font-size: 14px;
            font-weight: bold;
            color: #18181b;
            margin-top: 20px;
            margin-bottom: 8px;
            border-left: 4px solid #7c3aed;
            padding-left: 8px;
          }

          .grid-container {
            display: table;
            width: 100%;
            margin-bottom: 15px;
          }
          .grid-row {
            display: table-row;
          }
          .grid-box {
            display: table-cell;
            background-color: #f4f3f8;
            border: 1px solid #e4e4e7;
            padding: 10px;
            width: 33.33%;
            border-radius: 6px;
          }
          .grid-box-label { font-size: 10px; color: #71717a; font-weight: 600; text-transform: uppercase; }
          .grid-box-value { font-size: 16px; font-weight: bold; color: #09090b; margin-top: 4px; }

          table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 6px;
            margin-bottom: 15px;
          }
          table.data-table th, table.data-table td {
            border: 1px solid #e4e4e7;
            padding: 8px 10px;
            text-align: left;
            font-size: 11px;
          }
          table.data-table th {
            background-color: #fafafa;
            color: #27272a;
            font-weight: bold;
          }
          .footer {
            margin-top: 30px;
            border-top: 1px solid #e4e4e7;
            padding-top: 10px;
            text-align: center;
            font-size: 10px;
            color: #a1a1aa;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div>
            <div class="shop-title">TAILOR SHOP MANAGEMENT</div>
            <div class="report-subtitle">$reportTitle</div>
          </div>
          <div class="meta-info">
            <div><b>Filter Period:</b> $dateRange</div>
            <div><b>Generated on:</b> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</div>
          </div>
        </div>

        <div class="section-title">Executive Summary</div>
        <div style="display: table; width: 100%; border-spacing: 8px; margin-left: -8px;">
          <div class="grid-row">
            <div class="grid-box">
              <div class="grid-box-label">Total Revenue</div>
              <div class="grid-box-value">Rs. $totalRevenue</div>
            </div>
            <div class="grid-box">
              <div class="grid-box-label">Received Amount</div>
              <div class="grid-box-value" style="color: #16a34a;">Rs. $receivedAmount</div>
            </div>
            <div class="grid-box">
              <div class="grid-box-label">Pending Amount</div>
              <div class="grid-box-value" style="color: #dc2626;">Rs. $pendingAmount</div>
            </div>
          </div>
          <div class="grid-row">
            <div class="grid-box">
              <div class="grid-box-label">Total Orders</div>
              <div class="grid-box-value">$totalOrders</div>
            </div>
            <div class="grid-box">
              <div class="grid-box-label">Total Customers</div>
              <div class="grid-box-value">$totalCustomers</div>
            </div>
            <div class="grid-box">
              <div class="grid-box-label">Avg Order Value</div>
              <div class="grid-box-value">Rs. $avgOrderValue</div>
            </div>
          </div>
        </div>

        <div class="section-title">Order Status Overview</div>
        <table class="data-table">
          <tr>
            <th>Today's Orders</th>
            <th>Pending Orders</th>
            <th>Ready Orders</th>
            <th>Delivered Orders</th>
          </tr>
          <tr>
            <td style="font-weight: bold;">$todayOrders</td>
            <td style="font-weight: bold; color: #ea580c;">$pendingOrders</td>
            <td style="font-weight: bold; color: #7c3aed;">$readyOrders</td>
            <td style="font-weight: bold; color: #16a34a;">$deliveredOrders</td>
          </tr>
        </table>

        <div class="section-title">Payment Collection Modes</div>
        <table class="data-table">
          <tr>
            <th>Cash Payment</th>
            <th>UPI Payment</th>
            <th>Card Payment</th>
          </tr>
          <tr>
            <td>Rs. $cashAmount</td>
            <td>Rs. $upiAmount</td>
            <td>Rs. $cardAmount</td>
          </tr>
        </table>

        <div class="section-title">Garment Production Summary</div>
        <table class="data-table">
          <tr>
            <th>Garment Type</th>
            <th style="text-align: right;">Total Pieces</th>
          </tr>
          $garmentRows
        </table>

        <div class="section-title">Worker Performance & Salary Payouts</div>
        <table class="data-table">
          <tr>
            <th>Worker Name</th>
            <th style="text-align: center;">Pieces Stitched</th>
            <th style="text-align: right;">Total Earned</th>
            <th style="text-align: right;">Total Paid</th>
            <th style="text-align: right;">Total Due</th>
          </tr>
          $workerRows
          <tr style="background-color: #fafafa; font-weight: bold;">
            <td>Total</td>
            <td style="text-align: center;">-</td>
            <td style="text-align: right;">Rs. ${totalWorkerEarned.toStringAsFixed(0)}</td>
            <td style="text-align: right; color: #16a34a;">Rs. ${totalWorkerPaid.toStringAsFixed(0)}</td>
            <td style="text-align: right; color: #dc2626;">Rs. ${totalWorkerDue.toStringAsFixed(0)}</td>
          </tr>
        </table>

        <div class="section-title">Monthly Business Comparison</div>
        <table class="data-table">
          <tr>
            <th>Metric</th>
            <th style="text-align: center;">$prevMonthName</th>
            <th style="text-align: right;">$currMonthName</th>
          </tr>
          <tr>
            <td>Total Orders</td>
            <td style="text-align: center;">$prevOrders</td>
            <td style="text-align: right;">$totalOrders ($ordersTrend)</td>
          </tr>
          <tr>
            <td>Total Revenue</td>
            <td style="text-align: center;">Rs. $prevRevenue</td>
            <td style="text-align: right;">Rs. $totalRevenue ($revenueTrend)</td>
          </tr>
          <tr>
            <td>Total Customers</td>
            <td style="text-align: center;">$prevCustomers</td>
            <td style="text-align: right;">$totalCustomers ($customersTrend)</td>
          </tr>
          <tr>
            <td>Avg Order Value</td>
            <td style="text-align: center;">Rs. $prevAvgValue</td>
            <td style="text-align: right;">Rs. $avgOrderValue ($avgValueTrend)</td>
          </tr>
        </table>

        <div class="section-title">Revenue Trend Graph ($_graphInterval wise)</div>
        <div style="background-color: #F3EEFC; border: 1px solid #e4e4e7; border-radius: 8px; padding: 15px; margin-bottom: 15px; overflow-x: auto;">
          <div style="white-space: nowrap;">
            $graphicalBarsHtml
          </div>
        </div>

        <div class="section-title">Revenue Trend Tabular Data</div>
        <table class="data-table">
          <tr>
            <th>Timeline Interval</th>
            <th style="text-align: right;">Revenue Amount</th>
          </tr>
          $trendRows
        </table>

        <div class="footer">
          Confidential Business Performance Report &bull; Generated Automatically via Tailor App
        </div>
      </body>
      </html>
    ''';

    Directory tempDir = await getTemporaryDirectory();
    final generatedPdfFile = await FlutterNativeHtmlToPdf().convertHtmlToPdf(
      html: htmlContent,
      targetDirectory: tempDir.path,
      targetName: 'Professional_Business_Report_${DateTime.now().millisecondsSinceEpoch}',
    );

    return await generatedPdfFile!.readAsBytes();
  }

  // --- Print Action ---
  Future<void> _printReport() async {
    setState(() => _isLoading = true);
    try {
      final pdfBytes = await _generateReportHtmlPdfBytes();
      await Printing.layoutPdf(
        onLayout: (pw.PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Share Action ---
  Future<void> _shareReport() async {
    setState(() => _isLoading = true);
    try {
      final pdfBytes = await _generateReportHtmlPdfBytes();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Professional_Business_Report.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Download Action ---
  Future<void> _downloadReportPdf() async {
    setState(() => _isLoading = true);
    try {
      final pdfBytes = await _generateReportHtmlPdfBytes();
      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String baseFileName = 'Professional_Business_Report';
      String filePath = '${directory!.path}/$baseFileName.pdf';
      
      int counter = 1;
      while (File(filePath).existsSync()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${directory.path}/${baseFileName}_$timestamp.pdf';
        counter++;
        if (counter > 5) break;
      }

      final file = File(filePath);
      file.writeAsBytesSync(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report downloaded to: ${file.path}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getText(String key) {
    Map<String, Map<String, String>> translations = {
      'English': {
        'reportsTitle': 'Reports & Analytics',
        'revenue': 'Total Revenue',
        'receivedAmount': 'Received Amount',
        'pendingAmount': 'Pending Amount',
        'orders': 'Total Orders',
        'customers': 'Total Customers',
        'avgOrderValue': 'Avg. Order Value',
        'incomeOverview': 'Revenue Overview',
        'orderOverview': 'Order Overview',
        'paymentOverview': 'Payment Overview',
        'workerPerformance': 'Worker Performance',
        'workerSalaryReport': 'Worker Salary & Payout Report',
        'garmentProduction': 'Garment Production',
        'monthlyComparison': 'Monthly Comparison',
        'exportReport': 'Export Reports',
        'today': 'Today',
        'pending': 'Pending Orders',
        'ready': 'Ready Orders',
        'delivered': 'Delivered Orders',
      },
      'Hindi': {
        'reportsTitle': 'अहवाल (Reports)',
        'revenue': 'कुल उत्पन्न',
        'receivedAmount': 'प्राप्त राशि',
        'pendingAmount': 'बाकी राशि',
        'orders': 'कुल ऑर्डर्स',
        'customers': 'कुल ग्राहक',
        'avgOrderValue': 'औसत ऑर्डर मूल्य',
        'incomeOverview': 'Revenue Overview',
        'orderOverview': 'ऑर्डरचा आढावा',
        'paymentOverview': 'पेमेंट आढावा',
        'workerPerformance': 'कामगार कामगिरी',
        'workerSalaryReport': 'कामगार वेतन और पगार अहवाल',
        'garmentProduction': 'गारमेंट उत्पादन',
        'monthlyComparison': 'मासिक तुलना',
        'exportReport': 'रिपोर्ट्स एक्सपोर्ट करें',
        'today': 'आज',
        'pending': 'प्रलंबित ऑर्डर्स',
        'ready': 'तयार ऑर्डर्स',
        'delivered': 'वितरित ऑर्डर्स',
      },
      'Marathi': {
        'reportsTitle': 'अहवाल आणि विश्लेषण',
        'revenue': 'एकूण उत्पन्न',
        'receivedAmount': 'प्राप्त रक्कम',
        'pendingAmount': 'बाकी रक्कम',
        'orders': 'एकूण ऑर्डर्स',
        'customers': 'एकूण ग्राहक',
        'avgOrderValue': 'सरासरी ऑर्डर मूल्य',
        'incomeOverview': 'Revenue Overview',
        'orderOverview': 'ऑर्डरचा आढावा',
        'paymentOverview': 'पेमेंट आढावा',
        'workerPerformance': 'कामगार कामगिरी',
        'workerSalaryReport': 'कामगार पगार आणि वेतन अहवाल',
        'garmentProduction': 'गारमेंट उत्पादन',
        'monthlyComparison': 'मासिक तुलना',
        'exportReport': 'अहवाल एक्सपोर्ट करा',
        'today': 'आज',
        'pending': 'प्रलंबित',
        'ready': 'तयार',
        'delivered': 'वितरित',
      }
    };
    return translations[widget.initialLanguage]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = widget.isDarkMode ? const Color(0xFF1E1B2E) : Colors.white;
    Color borderColor = widget.isDarkMode ? const Color(0xFF2E294E) : const Color(0xFFE4E4E7);
    Color textColor = widget.isDarkMode ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);
    Color subTextColor = widget.isDarkMode ? const Color(0xFFB4AEE8) : const Color(0xFF71717A);
    const Color violetAccent = Color(0xFF7C3AED);
    const Color goldAccent = Color(0xFFFFB300);

    double totalWorkerEarned = 0.0;
    double totalWorkerPaid = 0.0;
    double totalWorkerDue = 0.0;
    for (var w in _workerList) {
      totalWorkerEarned += (w['earned'] as num?)?.toDouble() ?? 0.0;
      totalWorkerPaid += (w['paid'] as num?)?.toDouble() ?? 0.0;
      totalWorkerDue += (w['due'] as num?)?.toDouble() ?? 0.0;
    }

    int totalGarmentPieces = 0;
    _garmentCounts.forEach((key, val) => totalGarmentPieces += val);

    List<Map<String, dynamic>> filteredTrend = _trendData.where((item) => item['interval'] == _graphInterval).toList();
    if (filteredTrend.isEmpty) {
      filteredTrend = _trendData; 
    }

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF13101E) : const Color(0xFFF7F5FC),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Text(_getText('reportsTitle'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: violetAccent),
            onPressed: _loadReportsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: violetAccent))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text("Failed to load reports", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_errorMessage, style: TextStyle(color: subTextColor, fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadReportsData,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Quick Filters & Calendar Button Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('दिवस', 'आज', textColor, subTextColor, violetAccent),
                              const SizedBox(width: 6),
                              _buildFilterChip('आठवडा', 'या आठवड्यात', textColor, subTextColor, violetAccent),
                              const SizedBox(width: 6),
                              _buildFilterChip('महिना', 'हा महिना', textColor, subTextColor, violetAccent),
                              const SizedBox(width: 6),
                              _buildFilterChip('वर्ष', 'या वर्षी', textColor, subTextColor, violetAccent),
                              const SizedBox(width: 6),
                              ActionChip(
                                avatar: const Icon(Icons.calendar_month_rounded, color: violetAccent, size: 16),
                                label: Text(
                                  (_selectedDateFilter.startsWith('Custom') || _selectedDateFilter.contains('-')) 
                                      ? _selectedDateFilter 
                                      : 'कॅलेंडर',
                                  style: TextStyle(
                                    color: (_selectedDateFilter.startsWith('Custom') || _selectedDateFilter.contains('-')) 
                                        ? Colors.white 
                                        : textColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: (_selectedDateFilter.startsWith('Custom') || _selectedDateFilter.contains('-'))
                                    ? violetAccent
                                    : (widget.isDarkMode ? const Color(0xFF26213B) : const Color(0xFFEFEBF9)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onPressed: () => _selectCustomDateRange(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Metrics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildAdvancedMetricCard(
                            title: _getText('revenue'),
                            value: "₹${_totalRevenue.toStringAsFixed(0)}",
                            trendText: _totalRevenue == 0 ? "No Record" : "Live Data",
                            isPositive: true,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            iconBgColor: const Color(0xFF7C3AED).withOpacity(0.15),
                            surface: surfaceColor,
                            border: borderColor,
                            text: textColor,
                          ),
                          _buildAdvancedMetricCard(
                            title: _getText('receivedAmount'),
                            value: "₹${_receivedAmount.toStringAsFixed(0)}",
                            trendText: _receivedAmount == 0 ? "No Record" : "Live Data",
                            isPositive: true,
                            icon: Icons.download_rounded,
                            iconColor: Colors.green,
                            iconBgColor: Colors.green.withOpacity(0.15),
                            surface: surfaceColor,
                            border: borderColor,
                            text: textColor,
                          ),
                          _buildAdvancedMetricCard(
                            title: _getText('pendingAmount'),
                            value: "₹${_pendingAmount.toStringAsFixed(0)}",
                            trendText: _pendingAmount == 0 ? "No Record" : "Live Data",
                            isPositive: false,
                            icon: Icons.access_time_rounded,
                            iconColor: Colors.orange,
                            iconBgColor: Colors.orange.withOpacity(0.15),
                            surface: surfaceColor,
                            border: borderColor,
                            text: textColor,
                          ),
                          _buildAdvancedMetricCard(
                            title: _getText('orders'),
                            value: "$_totalOrders",
                            trendText: _totalOrders == 0 ? "No Record" : "Live Data",
                            isPositive: true,
                            icon: Icons.description_rounded,
                            iconColor: Colors.blue,
                            iconBgColor: Colors.blue.withOpacity(0.15),
                            surface: surfaceColor,
                            border: borderColor,
                            text: textColor,
                          ),
                          _buildAdvancedMetricCard(
                            title: _getText('customers'),
                            value: "$_totalCustomers",
                            trendText: _totalCustomers == 0 ? "No Record" : "Live Data",
                            isPositive: true,
                            icon: Icons.group_rounded,
                            iconColor: Colors.purple,
                            iconBgColor: Colors.purple.withOpacity(0.15),
                            surface: surfaceColor,
                            border: borderColor,
                            text: textColor,
                          ),
                          _buildAdvancedMetricCard(
                            title: _getText('avgOrderValue'),
                            value: "₹${_avgOrderValue.toStringAsFixed(0)}",
                            trendText: _avgOrderValue == 0 ? "No Record" : "Live Data",
                            isPositive: true,
                            icon: Icons.currency_rupee_rounded,
                            iconColor: Colors.teal,
                            iconBgColor: Colors.teal.withOpacity(0.15),
                            surface: surfaceColor,
                            border: borderColor,
                            text: textColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3. Line Chart Section matching the reference image style
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
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
                                    const Icon(Icons.show_chart, color: goldAccent, size: 18),
                                    const SizedBox(width: 6),
                                    Text(_getText('incomeOverview'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 220,
                              padding: const EdgeInsets.only(top: 12, right: 12, left: 4, bottom: 4),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode ? const Color(0xFF1A162B) : const Color(0xFFF3EEFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: filteredTrend.isEmpty
                                  ? Center(child: Text("या कालावधीत कोणतीही आकडेवारी उपलब्ध नाही", style: TextStyle(color: subTextColor, fontSize: 12)))
                                  : LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: true,
                                          drawHorizontalLine: true,
                                          getDrawingHorizontalLine: (value) => FlLine(
                                            color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                                            strokeWidth: 1,
                                          ),
                                          getDrawingVerticalLine: (value) => FlLine(
                                            color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                                            strokeWidth: 1,
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 42,
                                              getTitlesWidget: (value, meta) {
                                                if (value <= 0) return const Text('₹0', style: TextStyle(color: Colors.grey, fontSize: 9));
                                                String textVal = value >= 1000 ? '₹${(value / 1000).toStringAsFixed(0)}K' : '₹${value.toInt()}';
                                                return Text(textVal, style: const TextStyle(color: Colors.grey, fontSize: 9));
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 24,
                                              interval: 1,
                                              getTitlesWidget: (value, meta) {
                                                int index = value.toInt();
                                                if (index >= 0 && index < filteredTrend.length) {
                                                  if (filteredTrend.length > 5 && index != 0 && index != filteredTrend.length - 1) {
                                                    return const Text('');
                                                  }
                                                  String rawLabel = filteredTrend[index]['label'] ?? '';
                                                  String displayLbl = rawLabel;
                                                  try {
                                                    DateTime? parsedDate = DateTime.tryParse(rawLabel);
                                                    if (parsedDate != null) {
                                                      displayLbl = "${parsedDate.day} ${_getMonthName(parsedDate.month)}";
                                                    }
                                                  } catch (_) {}
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(displayLbl, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(
                                            color: widget.isDarkMode ? Colors.white30 : Colors.black26,
                                            width: 1,
                                          ),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            isCurved: false,
                                            color: goldAccent,
                                            barWidth: 3.5,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: true,
                                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                                radius: 5,
                                                color: goldAccent,
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              ),
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              gradient: LinearGradient(
                                                colors: [
                                                  goldAccent.withOpacity(0.45),
                                                  goldAccent.withOpacity(0.0),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                            spots: List.generate(filteredTrend.length, (index) {
                                              double amt = (filteredTrend[index]['amount'] ?? 0.0).toDouble();
                                              return FlSpot(index.toDouble(), amt);
                                            }),
                                          ),
                                        ],
                                        lineTouchData: LineTouchData(
                                          touchTooltipData: LineTouchTooltipData(
                                            getTooltipColor: (_) => const Color(0xFF2C283B),
                                            tooltipPadding: const EdgeInsets.all(8),
                                            tooltipMargin: 8,
                                            getTooltipItems: (touchedSpots) {
                                              return touchedSpots.map((spot) {
                                                int idx = spot.x.toInt();
                                                String dateStr = '';
                                                if (idx >= 0 && idx < filteredTrend.length) {
                                                  dateStr = filteredTrend[idx]['label'] ?? '';
                                                  try {
                                                    DateTime? parsed = DateTime.tryParse(dateStr);
                                                    if (parsed != null) {
                                                      dateStr = "${parsed.day.toString().padLeft(2, '0')} ${_getMonthName(parsed.month)} ${parsed.year}";
                                                    }
                                                  } catch (_) {}
                                                }
                                                return LineTooltipItem(
                                                  '$dateStr\n',
                                                  const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w500),
                                                  children: [
                                                    TextSpan(
                                                      text: '₹${spot.y.toStringAsFixed(0)}\n',
                                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                    const TextSpan(
                                                      text: 'Live Revenue', 
                                                      style: TextStyle(color: goldAccent, fontSize: 9),
                                                    ),
                                                  ],
                                                );
                                              }).toList();
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Order Overview Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getText('orderOverview'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            _buildActionableRow('आजच्या ऑर्डर्स (Today)', '$_todayOrdersCount', textColor, subTextColor, () {}),
                            _buildActionableRow(_getText('pending'), '$_pendingOrdersCount', Colors.orange, subTextColor, () {}),
                            _buildActionableRow(_getText('ready'), '$_readyOrdersCount', violetAccent, subTextColor, () {}),
                            _buildActionableRow(_getText('delivered'), '$_deliveredOrdersCount', Colors.green, subTextColor, () {}),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Payment Report Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getText('paymentOverview'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _paymentMetric("एकूण बिल", "₹${_totalRevenue.toStringAsFixed(0)}", textColor, subTextColor),
                                _paymentMetric("प्राप्त रक्कम", "₹${_receivedAmount.toStringAsFixed(0)}", Colors.green, subTextColor),
                                _paymentMetric("बाकी रक्कम", "₹${_pendingAmount.toStringAsFixed(0)}", Colors.redAccent, subTextColor),
                              ],
                            ),
                            const Divider(height: 24),
                            Text("पेमेंट पद्धत (Payment Modes)", style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _buildPaymentModeRow("💵 Cash", "₹${(_paymentModes['Cash'] ?? 0.0).toStringAsFixed(0)}", textColor),
                            _buildPaymentModeRow("📱 UPI", "₹${(_paymentModes['UPI'] ?? 0.0).toStringAsFixed(0)}", textColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. Worker Performance Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_getText('workerPerformance'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text("View All →", style: TextStyle(color: violetAccent, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (_workerList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text("No worker records found.", style: TextStyle(color: subTextColor, fontSize: 12)),
                              )
                            else
                              ..._workerList.take(3).map((w) => _workerRow(
                                    w['name'] ?? '',
                                    w['pieces']?.toString() ?? '0',
                                    "₹${((w['earned'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}",
                                    textColor,
                                    subTextColor,
                                  )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 7. Worker Salary & Payout Report Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_getText('workerSalaryReport'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                const Icon(Icons.payments_rounded, color: violetAccent, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _paymentMetric("एकूण पगार (Total)", "₹${totalWorkerEarned.toStringAsFixed(0)}", textColor, subTextColor),
                                _paymentMetric("दिलेला पगार (Paid)", "₹${totalWorkerPaid.toStringAsFixed(0)}", Colors.green, subTextColor),
                                _paymentMetric("बाकी पगार (Due)", "₹${totalWorkerDue.toStringAsFixed(0)}", Colors.orange, subTextColor),
                              ],
                            ),
                            const Divider(height: 24),
                            Text("कामगारांची वेतन स्थिती (Worker Payout Status)", style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            if (_workerList.isEmpty)
                              Text("No workers data available for this filter period.", style: TextStyle(color: subTextColor, fontSize: 12))
                            else
                              ..._workerList.map((w) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Column(
                                      children: [
                                        _workerSalaryDetailRow(
                                          w['name'] ?? '',
                                          "₹${((w['earned'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}",
                                          "₹${((w['paid'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}",
                                          "₹${((w['due'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}",
                                          Colors.orange,
                                          textColor,
                                          subTextColor,
                                        ),
                                        const Divider(height: 12),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 8. Garment Production & Progress bars
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getText('garmentProduction'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 14),
                            if (_garmentCounts.isEmpty)
                              Text("No garment orders found.", style: TextStyle(color: subTextColor, fontSize: 12))
                            else
                              ..._garmentCounts.entries.map((entry) {
                                String garmentName = entry.key;
                                int count = entry.value;
                                double percentageVal = totalGarmentPieces > 0 ? (count / totalGarmentPieces) : 0.0;
                                String percentageStr = "${(percentageVal * 100).toStringAsFixed(0)}%";
                                return _garmentBar("👔 $garmentName", count, percentageStr, percentageVal, violetAccent, textColor, subTextColor);
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 9. Monthly Comparison Table
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getText('monthlyComparison'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Table(
                              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.2)},
                              children: [
                                TableRow(children: [
                                  Text("Metric", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                  Text(_monthlyComparison['prevMonthName'] ?? "Prev", textAlign: TextAlign.center, style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                  Text(_monthlyComparison['currMonthName'] ?? "Current", textAlign: TextAlign.right, style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                ]),
                                _comparisonRow(
                                  "Orders", 
                                  "${_monthlyComparison['prevOrders'] ?? 0}", 
                                  "$_totalOrders  ${_monthlyComparison['ordersTrend'] ?? ''}", 
                                  Colors.green, 
                                  textColor
                                ),
                                _comparisonRow(
                                  "Revenue", 
                                  "₹${_monthlyComparison['prevRevenue'] ?? 0}", 
                                  "₹${_totalRevenue.toStringAsFixed(0)}  ${_monthlyComparison['revenueTrend'] ?? ''}", 
                                  Colors.green, 
                                  textColor
                                ),
                                _comparisonRow(
                                  "Customers", 
                                  "${_monthlyComparison['prevCustomers'] ?? 0}", 
                                  "$_totalCustomers  ${_monthlyComparison['customersTrend'] ?? ''}", 
                                  Colors.green, 
                                  textColor
                                ),
                                _comparisonRow(
                                  "Avg Value", 
                                  "₹${_monthlyComparison['prevAvgValue'] ?? 0}", 
                                  "₹${_avgOrderValue.toStringAsFixed(0)}  ${_monthlyComparison['avgValueTrend'] ?? ''}", 
                                  Colors.green, 
                                  textColor
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 10. Export Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("अहवाल तयार करा (Export Section)", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _exportButton(Icons.picture_as_pdf_rounded, "PDF Report", Colors.redAccent, textColor, _downloadReportPdf)),
                                const SizedBox(width: 8),
                                Expanded(child: _exportButton(Icons.print_rounded, "Print Report", violetAccent, textColor, _printReport)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _exportButton(Icons.share_rounded, "Share", Colors.blue, textColor, _shareReport)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // --- Helper Methods ---

  String _getMonthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month] : '';
  }

  Widget _buildFilterChip(String label, String filterValue, Color textColor, Color subTextColor, Color violetAccent) {
    bool isSelected = _selectedDateFilter == filterValue;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: violetAccent,
      backgroundColor: widget.isDarkMode ? const Color(0xFF26213B) : const Color(0xFFEFEBF9),
      labelStyle: TextStyle(color: isSelected ? Colors.white : textColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedDateFilter = filterValue;
          });
          _loadReportsData();
        }
      },
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      String formattedStart = "${picked.start.day}/${picked.start.month}/${picked.start.year}";
      String formattedEnd = "${picked.end.day}/${picked.end.month}/${picked.end.year}";
      
      setState(() {
        _selectedDateFilter = "$formattedStart - $formattedEnd";
      });
      _loadReportsData();
    }
  }

  Widget _buildAdvancedMetricCard({
    required String title,
    required String value,
    required String trendText,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color surface,
    required Color border,
    required Color text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(value, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: isPositive ? Colors.green : Colors.red, size: 18),
              Text(trendText, style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionableRow(String title, String count, Color countColor, Color subText, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: subText, fontSize: 12, fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(count, style: TextStyle(color: countColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: subText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMetric(String label, String amount, Color color, Color subText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: subText, fontSize: 10)),
        const SizedBox(height: 2),
        Text(amount, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentModeRow(String mode, String amount, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(mode, style: TextStyle(color: textColor, fontSize: 12)),
          Text(amount, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _workerRow(String name, String pieces, String earning, Color textColor, Color subText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(pieces, style: TextStyle(color: subText, fontSize: 11)),
              Text(earning, style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workerSalaryDetailRow(String name, String total, String paid, String due, Color dueColor, Color textColor, Color subText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(flex: 2, child: Text(name, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text("Earned", style: TextStyle(color: subText, fontSize: 9)), Text(total, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600))])),
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text("Paid", style: TextStyle(color: subText, fontSize: 9)), Text(paid, style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600))])),
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("Due", style: TextStyle(color: subText, fontSize: 9)), Text(due, style: TextStyle(color: dueColor, fontSize: 11, fontWeight: FontWeight.bold))])),
      ],
    );
  }

  Widget _garmentBar(String name, int count, String percentage, double value, Color color, Color textColor, Color subText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
              Text("$count ($percentage)", style: TextStyle(color: subText, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  TableRow _comparisonRow(String metric, String july, String aug, Color trendColor, Color textColor) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(metric, style: TextStyle(color: textColor, fontSize: 11))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(july, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 11))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(aug, textAlign: TextAlign.right, style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _exportButton(IconData icon, String label, Color color, Color textColor, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}