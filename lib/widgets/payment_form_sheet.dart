import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Generic "record a payment" sheet, used for both customers and suppliers.
Future<void> showPaymentFormSheet(
  BuildContext context, {
  required String entityName,
  required double currentOwed,
  required Future<void> Function(double amount, String? method, String? notes) onSubmit,
}) {
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  String method = 'نقدي';
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('تسجيل دفعة - $entityName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryFont)),
                    const SizedBox(height: 4),
                    Text('المبلغ المستحق حالياً: ${currentOwed.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.mutedFont)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'مبلغ الدفعة'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        if (double.tryParse(v) == null) return 'رقم غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                      items: const [
                        DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
                        DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي')),
                        DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
                      ],
                      onChanged: (v) => setState(() => method = v ?? 'نقدي'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final amount = double.parse(amountController.text);
                        final notes = notesController.text.trim();
                        await onSubmit(amount, method, notes.isEmpty ? null : notes);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('حفظ الدفعة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}