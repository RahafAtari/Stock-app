import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Returns the customer's id on save (new or existing), or null if
/// the sheet was dismissed without saving.
Future<int?> showCustomerFormSheet(BuildContext context,
    {Customer? existing}) {
  final nameController = TextEditingController(text: existing?.customerName ?? '');
  final phoneController = TextEditingController(text: existing?.phone ?? '');
  final notesController = TextEditingController(text: existing?.notes ?? '');
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
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
                Text(
                  existing == null ? 'إضافة عميل' : 'تعديل العميل',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryFont),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم العميل'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final notes = notesController.text.trim();
                    try {
                      int id;
                      if (existing == null) {
                        id = await SupabaseService.instance.addCustomer(
                          name,
                          phone.isEmpty ? null : phone,
                          notes.isEmpty ? null : notes,
                        );
                      } else {
                        await SupabaseService.instance.updateCustomer(
                          existing.customerId,
                          name,
                          phone.isEmpty ? null : phone,
                          notes.isEmpty ? null : notes,
                        );
                        id = existing.customerId;
                      }
                      if (context.mounted) Navigator.pop(context, id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
                      }
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
