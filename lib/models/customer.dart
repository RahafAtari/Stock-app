class Customer {
  final int customerId;
  final String customerName;
  final String? phone;
  final double amountOwed;
  final String? notes;

  Customer({
    required this.customerId,
    required this.customerName,
    required this.amountOwed,
    this.phone,
    this.notes,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customer_id'] as int,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String?,
      amountOwed: (map['amount_owed'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }
}
