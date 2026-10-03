import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

Future<void> showRestockFormSheet(BuildContext context,
    {required Item item}) async {
  final suppliers = await SupabaseService.instance.fetchSuppliers();
  if (!context.mounted) return;

  final amountController = TextEditingController();
  final priceController = TextEditingController();
  final paidController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime? expiryDate;
  int? supplierId;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'إضافة كمية - ${item.itemName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryFont,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        initialValue: supplierId,
                        decoration: const InputDecoration(labelText: 'المورد'),
                        items: [
                          const DropdownMenuItem<int?>(
                              value: null, child: Text('بدون مورد')),
                          ...suppliers.map((s) => DropdownMenuItem<int?>(
                                value: s.supplierId,
                                child: Text(s.supplierName),
                              )),
                        ],
                        onChanged: (v) => setState(() => supplierId = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'الكمية المضافة'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'مطلوب';
                          if (int.tryParse(v) == null) return 'رقم غير صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'سعر شراء الوحدة'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'مطلوب';
                          if (double.tryParse(v) == null) return 'رقم غير صحيح';
                          return null;
                        },
                      ),
                      if (supplierId != null) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: paidController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'المبلغ المدفوع للمورد الآن',
                            helperText: 'اتركه فارغاً إذا دفعت كامل المبلغ',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(expiryDate == null
                            ? 'تاريخ الانتهاء (اختياري)'
                            : 'ينتهي في: ${expiryDate!.toIso8601String().split('T').first}'),
                        trailing: const Icon(Icons.calendar_today_outlined,
                            color: AppColors.primaryAccent),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) setState(() => expiryDate = picked);
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          try {
                            await SupabaseService.instance.addBatch(
                              itemId: item.itemId,
                              buyingPrice: double.parse(priceController.text),
                              amount: int.parse(amountController.text),
                              supplierId: supplierId,
                              amountPaid:
                                  double.tryParse(paidController.text.trim()),
                              expiryDate: expiryDate,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تعذر الحفظ: $e')));
                            }
                          }
                        },
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
