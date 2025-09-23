import 'package:hive/hive.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';

@HiveType(typeId: 3)
class PaymentHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String transactionId;

  @HiveField(2)
  final String pidx;

  @HiveField(3)
  final double totalAmount;

  @HiveField(4)
  final String status;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final double fee;

  @HiveField(7)
  final bool refunded;

  @HiveField(8)
  final String? purchaseOrderId;

  @HiveField(9)
  final String? purchaseOrderName;

  @HiveField(10)
  final List<CartItem> items;

  @HiveField(11)
  final String customerName;

  @HiveField(12)
  final String customerPhone;

  @HiveField(13)
  final String? customerEmail;

  @HiveField(14)
  final String deliveryAddress;

  @HiveField(15)
  final double latitude;

  @HiveField(16)
  final double longitude;

  PaymentHistory({
    required this.id,
    required this.transactionId,
    required this.pidx,
    required this.totalAmount,
    required this.status,
    required this.timestamp,
    required this.fee,
    required this.refunded,
    this.purchaseOrderId,
    this.purchaseOrderName,
    required this.items,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.deliveryAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) => PaymentHistory(
    id: json['id'] ?? '',
    transactionId: json['transactionId'] ?? '',
    pidx: json['pidx'] ?? '',
    totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
    status: json['status'] ?? '',
    timestamp: DateTime.parse(
      json['timestamp'] ?? DateTime.now().toIso8601String(),
    ),
    fee: (json['fee'] ?? 0.0).toDouble(),
    refunded: json['refunded'] ?? false,
    purchaseOrderId: json['purchaseOrderId'],
    purchaseOrderName: json['purchaseOrderName'],
    items:
        (json['items'] as List<dynamic>?)
            ?.map((item) => CartItem.fromJson(item))
            .toList() ??
        const [],
    customerName: json['customerName'] ?? '',
    customerPhone: json['customerPhone'] ?? '',
    customerEmail: json['customerEmail'],
    deliveryAddress: json['deliveryAddress'] ?? '',
    latitude: (json['latitude'] ?? 0.0).toDouble(),
    longitude: (json['longitude'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'pidx': pidx,
    'totalAmount': totalAmount,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'fee': fee,
    'refunded': refunded,
    'purchaseOrderId': purchaseOrderId,
    'purchaseOrderName': purchaseOrderName,
    'items': items.map((e) => e.toJson()).toList(),
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'deliveryAddress': deliveryAddress,
    'latitude': latitude,
    'longitude': longitude,
  };

  PaymentHistory copyWith({
    String? id,
    String? transactionId,
    String? pidx,
    double? totalAmount,
    String? status,
    DateTime? timestamp,
    double? fee,
    bool? refunded,
    String? purchaseOrderId,
    String? purchaseOrderName,
    List<CartItem>? items,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) => PaymentHistory(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    pidx: pidx ?? this.pidx,
    totalAmount: totalAmount ?? this.totalAmount,
    status: status ?? this.status,
    timestamp: timestamp ?? this.timestamp,
    fee: fee ?? this.fee,
    refunded: refunded ?? this.refunded,
    purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
    purchaseOrderName: purchaseOrderName ?? this.purchaseOrderName,
    items: items ?? this.items,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    customerEmail: customerEmail ?? this.customerEmail,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );

  @override
  String toString() =>
      'PaymentHistory(id: $id, total: $totalAmount, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PaymentHistory && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
