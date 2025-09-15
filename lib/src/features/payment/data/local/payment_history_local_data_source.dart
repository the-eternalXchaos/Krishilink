import 'package:krishi_link/src/features/payment/models/payment_history.dart';

/// Simple in-memory data source placeholder during migration.
class PaymentHistoryLocalDataSource {
  static final PaymentHistoryLocalDataSource instance =
      PaymentHistoryLocalDataSource._();
  PaymentHistoryLocalDataSource._();

  final List<PaymentHistory> _cache = [];

  List<PaymentHistory> getAll() => List.unmodifiable(_cache);

  Future<void> add(PaymentHistory history) async {
    _cache.removeWhere((h) => h.id == history.id);
    _cache.add(history);
  }

  Future<List<PaymentHistory>> getAllSortedDesc() async {
    final list = List<PaymentHistory>.from(_cache);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  void clear() => _cache.clear();
}
