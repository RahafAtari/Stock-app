import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'category_form_sheet.dart';

/// A bottom sheet listing every category, with edit/delete on each
/// and a button to add a new one.
Future<void> showManageCategoriesSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ManageCategoriesContent(),
  );
}

class _ManageCategoriesContent extends StatefulWidget {
  const _ManageCategoriesContent();

  @override
  State<_ManageCategoriesContent> createState() => _ManageCategoriesContentState();
}

class _ManageCategoriesContentState extends State<_ManageCategoriesContent> {
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SupabaseService.instance.fetchCategories();
    if (mounted) {
      setState(() {
        _categories = data;
        _loading = false;
      });
    }
  }

  Future<void> _openAddOrEdit({Category? existing}) async {
    await showCategoryFormSheet(context, existing: existing);
    await _load(); // refresh this sheet's list after the form closes
  }

  Future<void> _confirmDelete(Category c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف "${c.categoryName}"؟\n'
          'سيتم إلغاء ربط أي أصناف تابعة له بهذا التصنيف.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteCategory(c.categoryId);
        await _load();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحذف: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'إدارة التصنيفات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryFont,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAddOrEdit(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                        ? const Center(
                            child: Text('لا توجد تصنيفات بعد',
                                style: TextStyle(color: AppColors.mutedFont)))
                        : ListView.separated(
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final c = _categories[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(c.categoryName,
                                    style: const TextStyle(color: AppColors.primaryFont)),
                                subtitle: c.notes != null && c.notes!.isNotEmpty
                                    ? Text(c.notes!, style: const TextStyle(color: AppColors.mutedFont))
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppColors.mutedFont, size: 20),
                                      onPressed: () => _openAddOrEdit(existing: c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.errorText, size: 20),
                                      onPressed: () => _confirmDelete(c),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}