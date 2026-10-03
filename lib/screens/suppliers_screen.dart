import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/supplier.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/supplier_form_sheet.dart';
import '../widgets/payment_form_sheet.dart';
import '../widgets/history_sheet.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _suppliers = [];
  bool _loading = true;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subs.add(SupabaseService.instance.watchSuppliers().listen((_) => _load()));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final data = await SupabaseService.instance.fetchSuppliers();
    if (mounted) {
      setState(() {
        _suppliers = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الموردون')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _suppliers.isEmpty
                ? const Center(
                    child: Text('لا يوجد موردون بعد',
                        style: TextStyle(color: AppColors.mutedFont)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _suppliers.length,
                    itemBuilder: (context, i) {
                      final s = _suppliers[i];
                      final owed = s.amountOwed > 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: owed
                                ? AppColors.errorText.withValues(alpha: 0.1)
                                : AppColors.primaryAccent.withValues(alpha: 0.1),
                            child: Icon(Icons.local_shipping_outlined,
                                color:
                                    owed ? AppColors.errorText : AppColors.primaryAccent),
                          ),
                          title: Text(s.supplierName,
                              style: const TextStyle(color: AppColors.primaryFont)),
                          subtitle: Text(
                            (s.phone ?? '') +
                                (owed
                                    ? '  •  مستحق له: ${s.amountOwed.toStringAsFixed(2)}'
                                    : '  •  لا يوجد مستحقات'),
                            style: TextStyle(
                                color: owed ? AppColors.errorText : AppColors.secondaryFont),
                          ),
                          // Tap the supplier to see every batch/item they supplied.
                          onTap: () => showHistorySheet(
                            context,
                            title: 'الأصناف الموردة من ${s.supplierName}',
                            loader: () async {
                              final rows = await SupabaseService.instance
                                  .fetchBatchesForSupplier(s.supplierId);
                              return rows.map((r) {
                                final item = r['items'] as Map<String, dynamic>?;
                                final date = DateFormat('yyyy/MM/dd').format(
                                    DateTime.parse(r['created_at'] as String).toLocal());
                                return HistoryRow(
                                  title: item?['item_name'] as String? ?? '',
                                  subtitle:
                                      '$date  •  سعر الشراء: ${(r['buying_price'] as num).toStringAsFixed(2)}  •  المتبقي: ${r['amount']}',
                                );
                              }).toList();
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history,
                                    color: AppColors.mutedFont, size: 20),
                                tooltip: 'سجل الدفعات',
                                onPressed: () => showHistorySheet(
                                  context,
                                  title: 'دفعات ${s.supplierName}',
                                  loader: () async {
                                    final rows = await SupabaseService.instance
                                        .fetchSupplierPayments(s.supplierId);
                                    return rows
                                        .map((r) => HistoryRow(
                                              title: DateFormat('yyyy/MM/dd  HH:mm').format(
                                                  DateTime.parse(r['payment_date'] as String)
                                                      .toLocal()),
                                              subtitle:
                                                  '${r['payment_method'] ?? ''}${r['notes'] != null ? '  •  ${r['notes']}' : ''}',
                                              trailing:
                                                  (r['amount'] as num).toStringAsFixed(2),
                                            ))
                                        .toList();
                                  },
                                ),
                              ),
                              if (owed)
                                IconButton(
                                  icon: const Icon(Icons.payments_outlined,
                                      color: AppColors.primaryAccent, size: 20),
                                  tooltip: 'تسجيل دفعة',
                                  onPressed: () => showPaymentFormSheet(
                                    context,
                                    entityName: s.supplierName,
                                    currentOwed: s.amountOwed,
                                    onSubmit: (amount, method, notes) =>
                                        SupabaseService.instance.addSupplierPayment(
                                      supplierId: s.supplierId,
                                      amount: amount,
                                      method: method,
                                      notes: notes,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.mutedFont, size: 20),
                                onPressed: () => showSupplierFormSheet(context, existing: s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.errorText, size: 20),
                                onPressed: () => _confirmDelete(s),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showSupplierFormSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('إضافة مورد'),
        ),
      ),
    );
  }

  void _confirmDelete(Supplier s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${s.supplierName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              await SupabaseService.instance.deleteSupplier(s.supplierId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
  }
}
