import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/sale.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/customer_form_sheet.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  List<Item> _items = [];
  List<Customer> _customers = [];
  final List<SaleLine> _cart = [];
  int? _selectedCustomerId;
  String _paymentMethod = 'نقدي';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await SupabaseService.instance.fetchItemsWithStock();
    final customers = await SupabaseService.instance.fetchCustomers();
    if (mounted) {
      setState(() {
        _items = items;
        _customers = customers;
        _loading = false;
      });
    }
  }

  double get _total => _cart.fold(0, (sum, l) => sum + l.totalPrice);

  Future<void> _addCustomerInline() async {
    final newId = await showCustomerFormSheet(context);
    if (newId == null) return;
    final customers = await SupabaseService.instance.fetchCustomers();
    if (mounted) {
      setState(() {
        _customers = customers;
        _selectedCustomerId = newId;
      });
    }
  }

  Future<void> _addLine() async {
    final item = await showDialog<Item>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('اختر الصنف'),
        children: _items
            .where((i) => i.totalStock > 0)
            .map((i) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, i),
                  child: Text('${i.itemName}  (متوفر: ${i.totalStock})'),
                ))
            .toList(),
      ),
    );
    if (item == null) return;

    final batches = await SupabaseService.instance.fetchBatchesForItem(item.itemId);
    if (batches.isEmpty || !mounted) return;

    final batch = await showDialog<Batch>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('اختر الدفعة'),
        children: batches
            .map((b) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, b),
                  child: Text(
                    'متوفر: ${b.amount}'
                    '${b.supplierName != null ? '  •  المورد: ${b.supplierName}' : ''}'
                    '${b.expiryDate != null ? '  •  ينتهي: ${b.expiryDate!.toIso8601String().split('T').first}' : ''}',
                  ),
                ))
            .toList(),
      ),
    );
    if (batch == null || !mounted) return;

    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: item.sellingPrice.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.itemName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'الكمية (متوفر: ${batch.amount})'),
            ),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'سعر الوحدة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة')),
        ],
      ),
    );

    if (ok == true) {
      final qty = int.tryParse(qtyController.text) ?? 0;
      final price = double.tryParse(priceController.text) ?? item.sellingPrice;
      if (qty > 0 && qty <= batch.amount) {
        setState(() {
          _cart.add(SaleLine(
            itemId: item.itemId,
            itemName: item.itemName,
            batchId: batch.batchId,
            quantity: qty,
            unitPrice: price,
          ));
        });
      }
    }
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final paidController = TextEditingController(text: _total.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إتمام البيع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الإجمالي: ${_total.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              TextField(
                controller: paidController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المبلغ المدفوع'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                items: const [
                  DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
                  DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي')),
                  DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v ?? 'نقدي'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد البيع')),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final paid = double.tryParse(paidController.text) ?? _total;
      try {
        await SupabaseService.instance.saveSale(
          customerId: _selectedCustomerId,
          lines: _cart,
          amountPaid: paid,
          paymentMethod: _paymentMethod,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('تعذر إتمام البيع: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عملية بيع جديدة')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            key: ValueKey(_selectedCustomerId),
                            initialValue: _selectedCustomerId,
                            decoration: const InputDecoration(
                                labelText: 'العميل (اختياري - زبون نقدي)'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('زبون نقدي')),
                              ..._customers.map((c) =>
                                  DropdownMenuItem(value: c.customerId, child: Text(c.customerName))),
                            ],
                            onChanged: (v) => setState(() => _selectedCustomerId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addCustomerInline,
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          tooltip: 'إضافة عميل جديد',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(
                            child: Text('لم تتم إضافة أصناف بعد',
                                style: TextStyle(color: AppColors.mutedFont)))
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, i) {
                              final l = _cart[i];
                              return ListTile(
                                title: Text(l.itemName),
                                subtitle: Text('${l.quantity} × ${l.unitPrice.toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(l.totalPrice.toStringAsFixed(2)),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 18, color: AppColors.errorText),
                                      onPressed: () => setState(() => _cart.removeAt(i)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('الإجمالي: ${_total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة صنف'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _cart.isEmpty ? null : _checkout,
                          icon: const Icon(Icons.check),
                          label: const Text('إتمام البيع'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
