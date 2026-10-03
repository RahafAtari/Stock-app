import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/pdf_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'new_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subs.add(SupabaseService.instance.watchSales().listen((_) => _load()));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final data = await SupabaseService.instance.fetchSales();
    if (mounted) {
      setState(() {
        _sales = data;
        _loading = false;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedIds.clear();
    });
  }

  Future<void> _printSelected() async {
    final selectedSales = _sales.where((s) => _selectedIds.contains(s.saleId)).toList();
    if (selectedSales.isEmpty) return;
    await PdfService.printMultipleSales(selectedSales);
    _toggleSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectionMode ? 'محدد: ${_selectedIds.length}' : 'المبيعات'),
          actions: [
            if (_selectionMode) ...[
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'طباعة المحدد',
                onPressed: _selectedIds.isEmpty ? null : _printSelected,
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: _toggleSelectionMode),
            ] else
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'تحديد للطباعة',
                onPressed: _toggleSelectionMode,
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sales.isEmpty
                ? const Center(
                    child: Text('لا توجد مبيعات بعد',
                        style: TextStyle(color: AppColors.mutedFont)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _sales.length,
                    itemBuilder: (context, i) {
                      final s = _sales[i];
                      final selected = _selectedIds.contains(s.saleId);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: _selectionMode
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (v) => setState(() {
                                    if (v == true) {
                                      _selectedIds.add(s.saleId);
                                    } else {
                                      _selectedIds.remove(s.saleId);
                                    }
                                  }),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.receipt_long_outlined,
                                      color: AppColors.primaryAccent)),
                          title: Text(s.customerName),
                          subtitle: Text(
                            '${s.saleDate.toIso8601String().split('T').first}  •  ${s.paymentMethod ?? ''}'
                            '${s.amountOwed > 0 ? '  •  متبقي: ${s.amountOwed.toStringAsFixed(2)}' : ''}',
                            style: TextStyle(
                                color: s.amountOwed > 0 ? AppColors.errorText : AppColors.secondaryFont),
                          ),
                          trailing: _selectionMode
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(s.totalAmount.toStringAsFixed(2),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, color: AppColors.primaryFont)),
                                    IconButton(
                                      icon: const Icon(Icons.print_outlined,
                                          size: 20, color: AppColors.primaryAccent),
                                      onPressed: () => PdfService.printSingleSale(s),
                                    ),
                                  ],
                                ),
                          onTap: _selectionMode
                              ? () => setState(() {
                                    if (selected) {
                                      _selectedIds.remove(s.saleId);
                                    } else {
                                      _selectedIds.add(s.saleId);
                                    }
                                  })
                              : () => _showDetails(s),
                        ),
                      );
                    },
                  ),
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSaleScreen())),
                icon: const Icon(Icons.add),
                label: const Text('بيع جديد'),
              ),
      ),
    );
  }

  Future<void> _showDetails(Sale s) async {
    final lines = await SupabaseService.instance.fetchSaleLines(s.saleId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل البيع - ${s.customerName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: lines.map((l) {
              final item = l['items'] as Map<String, dynamic>?;
              return ListTile(
                title: Text(item?['item_name'] as String? ?? ''),
                subtitle: Text('${l['quantity']} × ${l['unit_price']}'),
                trailing: Text('${l['total_price']}'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => PdfService.printSingleSale(s),
            child: const Text('طباعة'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}
