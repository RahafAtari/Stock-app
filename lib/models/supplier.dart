class Supplier {
  final int supplierId;
  final String supplierName;
  final String? phone;
  final double amountOwed;
  final String? notes;

  Supplier({
    required this.supplierId,
    required this.supplierName,
    required this.amountOwed,
    this.phone,
    this.notes,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      supplierId: map['supplier_id'] as int,
      supplierName: map['supplier_name'] as String,
      phone: map['phone'] as String?,
      amountOwed: (map['amount_owed'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }
}