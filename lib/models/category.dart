class Category {
  final int categoryId;
  final String categoryName;
  final String? notes;

  Category({required this.categoryId, required this.categoryName, this.notes});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      notes: map['notes'] as String?,
    );
  }
}