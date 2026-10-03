import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/customer_form_sheet.dart';
import '../widgets/payment_form_sheet.dart';
import '../widgets/history_sheet.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  bool _loading = true;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subs.add(SupabaseService.instance.watchCustomers().listen((_) => _load()));
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final data = await SupabaseService.instance.fetchCustomers();
    if (!mounted) return;

    setState(() {
      _customers = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('العملاء')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _customers.isEmpty
                ? const Center(
                    child: Text(
                      'لا يوجد عملاء بعد',
                      style: TextStyle(color: AppColors.mutedFont),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      final owes = customer.amountOwed > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: owes
                                ? AppColors.errorText.withValues(alpha: 0.1)
                                : AppColors.primaryAccent.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person_outline,
                              color: owes ? AppColors.errorText : AppColors.primaryAccent,
                            ),
                          ),
                          title: Text(
                            customer.customerName,
                            style: const TextStyle(color: AppColors.primaryFont),
                          ),
                          subtitle: Text(
                            (customer.phone ?? '') +
                                (owes
                                    ? '  •  مستحق عليه: ${customer.amountOwed.toStringAsFixed(2)}'
                                    : '  •  لا يوجد مستحقات'),
                            style: TextStyle(
                              color: owes ? AppColors.errorText : AppColors.secondaryFont,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.history,
                                  color: AppColors.mutedFont,
                                  size: 20,
                                ),
                                tooltip: 'سجل الدفعات',
                                onPressed: () => showHistorySheet(
                                  context,
                                  title: 'دفعات ${customer.customerName}',
                                  loader: () async {
                                    final rows = await SupabaseService.instance
                                        .fetchCustomerPayments(customer.customerId);

                                    return rows
                                        .map(
                                          (row) => HistoryRow(
                                            title: DateFormat('yyyy/MM/dd  HH:mm').format(
                                              DateTime.parse(row['payment_date'] as String)
                                                  .toLocal(),
                                            ),
                                            subtitle:
                                                '${row['payment_method'] ?? ''}${row['notes'] != null ? '  •  ${row['notes']}' : ''}',
                                            trailing: (row['amount'] as num).toStringAsFixed(2),
                                          ),
                                        )
                                        .toList();
                                  },
                                ),
                              ),
                              if (owes)
                                IconButton(
                                  icon: const Icon(
                                    Icons.payments_outlined,
                                    color: AppColors.primaryAccent,
                                    size: 20,
                                  ),
                                  tooltip: 'تسجيل دفعة',
                                  onPressed: () => showPaymentFormSheet(
                                    context,
                                    entityName: customer.customerName,
                                    currentOwed: customer.amountOwed,
                                    onSubmit: (amount, method, notes) =>
                                        SupabaseService.instance.addCustomerPayment(
                                      customerId: customer.customerId,
                                      amount: amount,
                                      method: method,
                                      notes: notes,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.mutedFont,
                                  size: 20,
                                ),
                                onPressed: () => showCustomerFormSheet(context, existing: customer),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.errorText,
                                  size: 20,
                                ),
                                onPressed: () => _confirmDelete(customer),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showCustomerFormSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('إضافة عميل'),
        ),
      ),
    );
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${customer.customerName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await SupabaseService.instance.deleteCustomer(customer.customerId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
  }
}
