import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

Future<void> showItemFormSheet(
  BuildContext context, {
  required List<Category> categories,
  Item? existing,
}) {
  final nameController = TextEditingController(text: existing?.itemName ?? '');
  final priceController = TextEditingController(text: existing != null ? existing.sellingPrice.toString() : '');
  final notesController = TextEditingController(text: existing?.notes ?? '');
  final formKey = GlobalKey<FormState>();
  int? selectedCategoryId = existing?.categoryId;

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
                    Text(
                      existing == null ? 'إضافة صنف' : 'تعديل الصنف',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryFont),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'اسم الصنف'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'التصنيف'),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.categoryName)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategoryId = v),
                      validator: (v) => v == null ? 'اختر تصنيفاً' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'سعر البيع'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        if (double.tryParse(v) == null) return 'رقم غير صحيح';
                        return null;
                      },
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
                        final price = double.parse(priceController.text);
                        final notes = notesController.text.trim();
                        if (existing == null) {
                          await SupabaseService.instance.addItem(
                            name: name,
                            categoryId: selectedCategoryId,
                            sellingPrice: price,
                            notes: notes.isEmpty ? null : notes,
                          );
                        } else {
                          await SupabaseService.instance.updateItem(
                            id: existing.itemId,
                            name: name,
                            categoryId: selectedCategoryId,
                            sellingPrice: price,
                            notes: notes.isEmpty ? null : notes,
                          );
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
    },
  );
}