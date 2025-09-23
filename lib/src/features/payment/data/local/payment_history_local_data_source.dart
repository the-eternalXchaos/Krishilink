import 'package:hive_flutter/hive_flutter.dart';
import 'package:krishi_link/src/features/payment/models/payment_history.dart';

class PaymentHistoryLocalDataSource {
  static final PaymentHistoryLocalDataSource instance =
      PaymentHistoryLocalDataSource._();
  PaymentHistoryLocalDataSource._();

  late Box<PaymentHistory> _box;

  Future<void> init() async {
    _box = await Hive.openBox<PaymentHistory>('payment_history');
  }

  List<PaymentHistory> getAll() => _box.values.toList();

  Future<void> add(PaymentHistory history) async {
    await _box.put(history.id, history);
  }

  Future<List<PaymentHistory>> getAllSortedDesc() async {
    final list = _box.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> clear() async => await _box.clear();
}