import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/batch.dart';
import '../models/sale.dart';

/// One place that talks to Supabase. Every screen goes through this,
/// so the same code works identically on phone, tablet and Windows.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://mlmyjtpzzqyzsvmurkce.supabase.co', // e.g. https://xxxx.supabase.co
      publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sbXlqdHB6enF5enN2bXVya2NlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1MTY2ODIsImV4cCI6MjEwNjA5MjY4Mn0.ITth1G3e1wgd150D6_WaCs8XPhZ1WHfFgUdVT6qhCNI',
    );
  }

  // ---------------- Categories ----------------

  Future<List<Category>> fetchCategories() async {
    final data =
        await _client.from('categories').select().order('category_name');
    return (data as List).map((e) => Category.fromMap(e)).toList();
  }

  Future<void> addCategory(String name, String? notes) async {
    await _client.from('categories').insert({
      'category_name': name,
      'notes': notes,
    });
  }

  Future<void> updateCategory(int id, String name, String? notes) async {
    await _client.from('categories').update({
      'category_name': name,
      'notes': notes,
    }).eq('category_id', id);
  }

  Future<void> deleteCategory(int id) async {
    await _client.from('categories').delete().eq('category_id', id);
  }

  // ---------------- Items (with stock quantity) ----------------

  /// Fetches items with their category name and total stock quantity
  /// (sum of amount across all batches for that item).
  Future<List<Item>> fetchItemsWithStock() async {
    final data = await _client
        .from('items')
        .select('*, categories(category_name), item_batches(amount)')
        .order('item_name');

    return (data as List).map((e) => Item.fromMapWithJoins(e)).toList();
  }

  Future<void> addItem({
    required String name,
    required int? categoryId,
    required double sellingPrice,
    String? notes,
  }) async {
    await _client.from('items').insert({
      'item_name': name,
      'category_id': categoryId,
      'selling_price': sellingPrice,
      'notes': notes,
    });
  }

  Future<void> updateItem({
    required int id,
    required String name,
    required int? categoryId,
    required double sellingPrice,
    String? notes,
  }) async {
    await _client.from('items').update({
      'item_name': name,
      'category_id': categoryId,
      'selling_price': sellingPrice,
      'notes': notes,
    }).eq('item_id', id);
  }

  Future<void> deleteItem(int id) async {
    await _client.from('items').delete().eq('item_id', id);
  }

  Stream<List<Map<String, dynamic>>> watchItems() {
    return _client.from('items').stream(primaryKey: ['item_id']);
  }

  Stream<List<Map<String, dynamic>>> watchCategories() {
    return _client.from('categories').stream(primaryKey: ['category_id']);
  }

  // ---------------- Customers ----------------

  Future<List<Customer>> fetchCustomers() async {
    final data =
        await _client.from('customers').select().order('customer_name');
    return (data as List).map((e) => Customer.fromMap(e)).toList();
  }

  /// Returns the new customer's id, so a sale screen can select it
  /// immediately without a second fetch/round trip.
  Future<int> addCustomer(String name, String? phone, String? notes) async {
    final row = await _client
        .from('customers')
        .insert({
          'customer_name': name,
          'phone': phone,
          'notes': notes,
        })
        .select()
        .single();
    return row['customer_id'] as int;
  }

  Future<void> updateCustomer(
      int id, String name, String? phone, String? notes) async {
    await _client.from('customers').update({
      'customer_name': name,
      'phone': phone,
      'notes': notes,
    }).eq('customer_id', id);
  }

  Future<void> deleteCustomer(int id) async {
    await _client.from('customers').delete().eq('customer_id', id);
  }

  /// Records a payment from a customer and reduces what they owe.
  Future<void> addCustomerPayment({
    required int customerId,
    required double amount,
    String? method,
    String? notes,
  }) async {
    await _client.from('customer_payments').insert({
      'customer_id': customerId,
      'amount': amount,
      'payment_method': method,
      'notes': notes,
    });

    final current = await _client
        .from('customers')
        .select('amount_owed')
        .eq('customer_id', customerId)
        .single();
    final newOwed = (current['amount_owed'] as num).toDouble() - amount;

    await _client
        .from('customers')
        .update({'amount_owed': newOwed})
        .eq('customer_id', customerId);
  }

  Future<List<Map<String, dynamic>>> fetchCustomerPayments(
      int customerId) async {
    final data = await _client
        .from('customer_payments')
        .select()
        .eq('customer_id', customerId)
        .order('payment_date', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Stream<List<Map<String, dynamic>>> watchCustomers() {
    return _client.from('customers').stream(primaryKey: ['customer_id']);
  }

  // ---------------- Suppliers ----------------

  Future<List<Supplier>> fetchSuppliers() async {
    final data =
        await _client.from('suppliers').select().order('supplier_name');
    return (data as List).map((e) => Supplier.fromMap(e)).toList();
  }

  Future<void> addSupplier(String name, String? phone, String? notes) async {
    await _client.from('suppliers').insert({
      'supplier_name': name,
      'phone': phone,
      'notes': notes,
    });
  }

  Future<void> updateSupplier(
      int id, String name, String? phone, String? notes) async {
    await _client.from('suppliers').update({
      'supplier_name': name,
      'phone': phone,
      'notes': notes,
    }).eq('supplier_id', id);
  }

  Future<void> deleteSupplier(int id) async {
    await _client.from('suppliers').delete().eq('supplier_id', id);
  }

  /// Records a payment you made to a supplier and reduces what you owe them.
  Future<void> addSupplierPayment({
    required int supplierId,
    required double amount,
    String? method,
    String? notes,
  }) async {
    await _client.from('supplier_payments').insert({
      'supplier_id': supplierId,
      'amount': amount,
      'payment_method': method,
      'notes': notes,
    });

    final current = await _client
        .from('suppliers')
        .select('amount_owed')
        .eq('supplier_id', supplierId)
        .single();
    final newOwed = (current['amount_owed'] as num).toDouble() - amount;

    await _client
        .from('suppliers')
        .update({'amount_owed': newOwed})
        .eq('supplier_id', supplierId);
  }

  Future<List<Map<String, dynamic>>> fetchSupplierPayments(
      int supplierId) async {
    final data = await _client
        .from('supplier_payments')
        .select()
        .eq('supplier_id', supplierId)
        .order('payment_date', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Every batch ever supplied by this supplier, newest first.
  Future<List<Map<String, dynamic>>> fetchBatchesForSupplier(
      int supplierId) async {
    final data = await _client
        .from('item_batches')
        .select('amount, buying_price, created_at, items(item_name)')
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Stream<List<Map<String, dynamic>>> watchSuppliers() {
    return _client.from('suppliers').stream(primaryKey: ['supplier_id']);
  }

  // ---------------- Batches / Restocking ----------------

  Future<List<Batch>> fetchBatchesForItem(int itemId) async {
    final data = await _client
        .from('item_batches')
        .select('*, suppliers(supplier_name)')
        .eq('item_id', itemId)
        .gt('amount', 0)
        .order('expiry_date', ascending: true);
    return (data as List).map((e) => Batch.fromMap(e)).toList();
  }

  /// Adds a new batch of stock. If a supplier is given, links this item
  /// to that supplier for future reference, and adds whatever you didn't
  /// pay right away to what you owe them.
  Future<void> addBatch({
    required int itemId,
    required double buyingPrice,
    required int amount,
    int? supplierId,
    double? amountPaid, // null = paid in full
    DateTime? expiryDate,
  }) async {
    await _client.from('item_batches').insert({
      'item_id': itemId,
      'supplier_id': supplierId,
      'buying_price': buyingPrice,
      'amount': amount,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
    });

    if (supplierId != null) {
      await _client.from('supplier_items').upsert(
        {'supplier_id': supplierId, 'item_id': itemId},
        onConflict: 'supplier_id,item_id',
      );

      final cost = buyingPrice * amount;
      final owed = cost - (amountPaid ?? cost);
      if (owed > 0) {
        final s = await _client
            .from('suppliers')
            .select('amount_owed')
            .eq('supplier_id', supplierId)
            .single();
        await _client
            .from('suppliers')
            .update({'amount_owed': (s['amount_owed'] as num).toDouble() + owed})
            .eq('supplier_id', supplierId);
      }
    }
  }

  Stream<List<Map<String, dynamic>>> watchBatches() {
    return _client.from('item_batches').stream(primaryKey: ['batch_id']);
  }

  // ---------------- Sales ----------------

  Future<List<Sale>> fetchSales() async {
    final data = await _client
        .from('sales')
        .select('*, customers(customer_name)')
        .order('sale_date', ascending: false);
    return (data as List).map((e) => Sale.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchSaleLines(int saleId) async {
    final data = await _client
        .from('sale_items')
        .select('*, items(item_name)')
        .eq('sale_id', saleId);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Saves a full sale: header + lines, deducts stock from each batch,
  /// and adds any unpaid amount to the customer's balance.
  Future<void> saveSale({
    required int? customerId,
    required List<SaleLine> lines,
    required double amountPaid,
    required String paymentMethod,
    String? notes,
  }) async {
    final total = lines.fold<double>(0, (sum, l) => sum + l.totalPrice);
    final owed = (total - amountPaid).clamp(0, double.infinity);

    final saleRow = await _client
        .from('sales')
        .insert({
          'customer_id': customerId,
          'total_amount': total,
          'amount_paid': amountPaid,
          'amount_owed': owed,
          'payment_method': paymentMethod,
          'notes': notes,
        })
        .select()
        .single();

    final saleId = saleRow['sale_id'] as int;

    for (final line in lines) {
      await _client.from('sale_items').insert({
        'sale_id': saleId,
        'item_id': line.itemId,
        'batch_id': line.batchId,
        'quantity': line.quantity,
        'unit_price': line.unitPrice,
        'total_price': line.totalPrice,
      });

      final batch = await _client
          .from('item_batches')
          .select('amount')
          .eq('batch_id', line.batchId)
          .single();
      final newAmount = (batch['amount'] as int) - line.quantity;
      await _client
          .from('item_batches')
          .update({'amount': newAmount})
          .eq('batch_id', line.batchId);
    }

    if (customerId != null && owed > 0) {
      final customer = await _client
          .from('customers')
          .select('amount_owed')
          .eq('customer_id', customerId)
          .single();
      final newOwed = (customer['amount_owed'] as num).toDouble() + owed;
      await _client
          .from('customers')
          .update({'amount_owed': newOwed})
          .eq('customer_id', customerId);
    }
  }

  // ---------------- Profit ----------------

  /// Profit = selling price - buying price of the batch sold, for every
  /// sale line between [from] and [to] (inclusive). Dates are converted
  /// to UTC since that's how they're stored.
  Future<double> calculateProfit(
      {required DateTime from, required DateTime to}) async {
    final data = await _client
        .from('sale_items')
        .select(
            'quantity, unit_price, item_batches(buying_price), sales!inner(sale_date)')
        .gte('sales.sale_date', from.toUtc().toIso8601String())
        .lte('sales.sale_date', to.toUtc().toIso8601String());

    double profit = 0;
    for (final row in (data as List)) {
      final qty = row['quantity'] as int;
      final unitPrice = (row['unit_price'] as num).toDouble();
      final batch = row['item_batches'] as Map<String, dynamic>?;
      final buyingPrice = (batch?['buying_price'] as num?)?.toDouble() ?? 0;
      profit += (unitPrice - buyingPrice) * qty;
    }
    return profit;
  }

  Stream<List<Map<String, dynamic>>> watchSales() {
    return _client.from('sales').stream(primaryKey: ['sale_id']);
  }

  Stream<List<Map<String, dynamic>>> watchSaleItems() {
    return _client.from('sale_items').stream(primaryKey: ['sale_item_id']);
  }
}
