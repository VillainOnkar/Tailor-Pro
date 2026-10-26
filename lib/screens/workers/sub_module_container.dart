import 'package:flutter/material.dart';
import 'modules/work_module.dart';
import 'modules/history_module.dart';
import 'modules/salary_module.dart';
 

class SubModuleContainerClass extends StatelessWidget {
  final String activeSubModule;
  final Map<String, dynamic> selectedWorker;
  final String userEmail; // 👈 Consistent Email variable added
  final String Function(String) getText;
  final Color textColor, subTextColor, cardColor, borderColor, primaryPurple, accentYellow;
  final Map<String, double> rates;
  final Map<String, int> todayQuantities;
  final bool isDesktop;
  final VoidCallback onBack;
  final VoidCallback onUpdate;

  const SubModuleContainerClass({
    super.key,
    required this.activeSubModule,
    required this.selectedWorker,
    required this.userEmail, // 👈 Required in constructor
    required this.getText,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
    required this.borderColor,
    required this.primaryPurple,
    required this.accentYellow,
    required this.rates,
    required this.todayQuantities,
    required this.isDesktop,
    required this.onBack,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    String translatedModuleName = getText(activeSubModule.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(icon: Icon(Icons.arrow_back_rounded, color: textColor), onPressed: onBack),
            Expanded(child: Text("$translatedModuleName - ${selectedWorker['name']}", style: TextStyle(color: textColor, fontSize: isDesktop ? 18 : 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor)),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return activeSubModule == 'Work'
        ? WorkModuleClass(
            rates: rates,
            todayQuantities: todayQuantities,
            getText: getText,
            textColor: textColor,
            primaryPurple: primaryPurple,
            accentYellow: accentYellow,
            onUpdate: onUpdate,
            userEmail: userEmail, // 👈 Passed consistent email here instead of empty or lookup
            workerId: selectedWorker['id'] ?? selectedWorker['workerId'] ?? 'WRK001',
          )
        : activeSubModule == 'History'
            ? HistoryModuleClass(
              userEmail: userEmail,
              workerId: selectedWorker['id'] ?? selectedWorker['workerId'] ?? 'WRK001',
              primaryPurple: primaryPurple,
              accentYellow: accentYellow,
              textColor: textColor,
              getText: getText, // 👈 Parent ka actual multi-language function yahan pass karein
            )
            : activeSubModule == 'Salary'
                ? SalaryModuleClass(
                    userEmail: userEmail,
                    workerId: selectedWorker['id'] ?? selectedWorker['workerId'] ?? 'WRK001',
                    getText: getText,
                    textColor: textColor,
                    accentYellow: accentYellow,
                  )
                  : const Center(child: Text("Data not found"));
  }
}