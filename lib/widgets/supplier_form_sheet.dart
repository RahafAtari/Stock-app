import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

Future<void> showSupplierFormSheet(BuildContext context, {Supplier? existing}) {
  final nameController = TextEditingController(text: existing?.supplierName ?? '');
  final phoneController = TextEditingController(text: existing?.phone ?? '');
  final notesController = TextEditingController(text: existing?.notes ?? '');
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet(
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
                Text(existing == null ? 'إضافة مورد' : 'تعديل المورد',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryFont)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المورد'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
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
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final notes = notesController.text.trim();
                    if (existing == null) {
                      await SupabaseService.instance.addSupplier(
                          name, phone.isEmpty ? null : phone, notes.isEmpty ? null : notes);
                    } else {
                      await SupabaseService.instance.updateSupplier(
                          existing.supplierId, name, phone.isEmpty ? null : phone, notes.isEmpty ? null : notes);
                    }
                    if (context.mounted) Navigator.pop(context);
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