class Sale {
  final int saleId;
  final int? customerId;
  final String customerName;
  final DateTime saleDate;
  final double totalAmount;
  final double amountPaid;
  final double amountOwed;
  final String? paymentMethod;

  Sale({
    required this.saleId,
    required this.customerId,
    required this.customerName,
    required this.saleDate,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountOwed,
    this.paymentMethod,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    final customer = map['customers'] as Map<String, dynamic>?;
    return Sale(
      saleId: map['sale_id'] as int,
      customerId: map['customer_id'] as int?,
      customerName: customer?['customer_name'] as String? ?? 'زبون نقدي',
      saleDate: DateTime.parse(map['sale_date'] as String).toLocal(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      amountOwed: (map['amount_owed'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String?,
    );
  }
}

/// One line in a sale — used both while building a cart and when
/// showing a saved sale's details.
class SaleLine {
  final int itemId;
  final String itemName;
  final int batchId;
  final int quantity;
  final double unitPrice;
  double get totalPrice => quantity * unitPrice;

  SaleLine({
    required this.itemId,
    required this.itemName,
    required this.batchId,
    required this.quantity,
    required this.unitPrice,
  });
}
