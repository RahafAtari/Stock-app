class Batch {
  final int batchId;
  final int itemId;
  final int? supplierId;
  final String? supplierName;
  final DateTime? expiryDate;
  final double buyingPrice;
  final int amount;

  Batch({
    required this.batchId,
    required this.itemId,
    required this.buyingPrice,
    required this.amount,
    this.supplierId,
    this.supplierName,
    this.expiryDate,
  });

  factory Batch.fromMap(Map<String, dynamic> map) {
    final supplier = map['suppliers'] as Map<String, dynamic>?;
    return Batch(
      batchId: map['batch_id'] as int,
      itemId: map['item_id'] as int,
      supplierId: map['supplier_id'] as int?,
      supplierName: supplier?['supplier_name'] as String?,
      buyingPrice: (map['buying_price'] as num).toDouble(),
      amount: map['amount'] as int,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
    );
  }
}
