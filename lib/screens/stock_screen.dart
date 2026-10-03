import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/item_form_sheet.dart';
import '../widgets/restock_form_sheet.dart';
import '../widgets/manage_categories_sheet.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<Category> _categories = [];
  List<Item> _items = [];
  bool _loading = true;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    // Auto-refresh when data changes from any device (phone/Windows).
    _subs.addAll([
      SupabaseService.instance.watchItems().listen((_) => _loadData()),
      SupabaseService.instance.watchCategories().listen((_) => _loadData()),
      SupabaseService.instance.watchBatches().listen((_) => _loadData()),
    ]);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final categories = await SupabaseService.instance.fetchCategories();
    final items = await SupabaseService.instance.fetchItemsWithStock();
    if (mounted) {
      setState(() {
        _categories = categories;
        _items = items;
        _loading = false;
      });
    }
  }

  Map<String, List<Item>> get _grouped {
    final map = <String, List<Item>>{};
    for (final item in _items) {
      map.putIfAbsent(item.categoryName, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المخزون'),
          actions: [
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'إدارة التصنيفات',
              onPressed: () => showManageCategoriesSheet(context),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد أصناف بعد، اضغط + للإضافة',
                      style: TextStyle(color: AppColors.mutedFont),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: _grouped.entries.map((entry) {
                      return _CategoryGroup(
                        categoryName: entry.key,
                        items: entry.value,
                        categories: _categories,
                      );
                    }).toList(),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (_categories.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('أضف تصنيفاً أولاً')),
              );
              return;
            }
            showItemFormSheet(context, categories: _categories);
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة صنف'),
        ),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String categoryName;
  final List<Item> items;
  final List<Category> categories;

  const _CategoryGroup({
    required this.categoryName,
    required this.items,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(Icons.folder_open, color: AppColors.primaryAccent),
          title: Text(
            categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryFont,
            ),
          ),
          subtitle: Text('${items.length} صنف',
              style: const TextStyle(color: AppColors.mutedFont)),
          children:
              items.map((item) => _ItemTile(item: item, categories: categories)).toList(),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Item item;
  final List<Category> categories;

  const _ItemTile({required this.item, required this.categories});

  @override
  Widget build(BuildContext context) {
    final lowStock = item.totalStock <= 5;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: lowStock
            ? AppColors.errorText.withValues(alpha: 0.1)
            : AppColors.primaryAccent.withValues(alpha: 0.1),
        child: Icon(Icons.inventory_2_outlined,
            color: lowStock ? AppColors.errorText : AppColors.primaryAccent,
            size: 20),
      ),
      title: Text(item.itemName, style: const TextStyle(color: AppColors.primaryFont)),
      subtitle: Text(
        'الكمية: ${item.totalStock}  •  السعر: ${item.sellingPrice.toStringAsFixed(2)}',
        style: TextStyle(color: lowStock ? AppColors.errorText : AppColors.secondaryFont),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppColors.primaryAccent, size: 20),
            tooltip: 'إضافة كمية',
            onPressed: () => showRestockFormSheet(context, item: item),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.mutedFont, size: 20),
            onPressed: () =>
                showItemFormSheet(context, categories: categories, existing: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.errorText, size: 20),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${item.itemName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await SupabaseService.instance.deleteItem(item.itemId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
  }
}
