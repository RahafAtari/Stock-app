class Item {
  final int itemId;
  final String itemName;
  final int? categoryId;
  final String categoryName;
  final double sellingPrice;
  final String? notes;
  final int totalStock;

  Item({
    required this.itemId,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
    required this.sellingPrice,
    required this.totalStock,
    this.notes,
  });

  factory Item.fromMapWithJoins(Map<String, dynamic> map) {
    final category = map['categories'] as Map<String, dynamic>?;
    final batches = (map['item_batches'] as List?) ?? [];
    final totalStock = batches.fold<int>(
      0,
      (sum, b) => sum + ((b['amount'] as num?)?.toInt() ?? 0),
    );

    return Item(
      itemId: map['item_id'] as int,
      itemName: map['item_name'] as String,
      categoryId: map['category_id'] as int?,
      categoryName: category?['category_name'] as String? ?? 'بدون تصنيف',
      sellingPrice: (map['selling_price'] as num).toDouble(),
      notes: map['notes'] as String?,
      totalStock: totalStock,
    );
  }
}