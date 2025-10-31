class OrderModel {
  final String orderId;
  final String orderItemId; // Individual order item ID for status updates
  final String productId;
  final String productName;
  final double productQuantity;
  final String unit; // (e.g., kg)
  final double totalPrice;
  final String
  orderStatus; // , pending, confirmed, shipped, delivered, cancelled
  final String paymentStatus; // e.g., pending, completed, failed
  final String? refundStatus; // e.g., requested, approved, rejected
  final String? buyerId;
  final String? buyerName;
  final String? buyerContact;
  final String? deliveryAddress;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final bool deliveryConfirmedByBuyer;

  OrderModel({
    required this.orderId,
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productQuantity,
    required this.unit,
    required this.totalPrice,
    required this.orderStatus,
    required this.paymentStatus,
    this.refundStatus,
    this.buyerId,
    this.buyerName,
    this.buyerContact,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.deliveredAt,
    this.deliveryConfirmedByBuyer = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Accept both flattened maps and raw API fragments (orderData + item)
    final orderItemId = (json['orderItemId'] ?? json['id'] ?? '').toString();
    if (orderItemId.isEmpty) {
      throw Exception('orderItemId is required and cannot be null or empty');
    }

    // Map status fields with normalization
    String status =
        (json['orderStatus'] ?? json['itemStatus'] ?? 'pending').toString();
    status = status.toLowerCase() == 'processing' ? 'pending' : status;
    status = status.toLowerCase();

    String payment = (json['paymentStatus'] ?? 'cod').toString();
    payment = payment.toLowerCase();

    // Quantity fallback
    final quantityNum =
        json.containsKey('productQuantity')
            ? json['productQuantity']
            : json['quantity'];

    // Date fallbacks
    final created = json['createdAt'] ?? json['orderDate'];
    final delivered = json['deliveredAt'] ?? json['updatedAt'];

    return OrderModel(
      orderId: (json['orderId'] ?? '').toString(),
      orderItemId: orderItemId,
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? 'Unknown Product').toString(),
      productQuantity: (quantityNum ?? 0.0 as num).toDouble(),
      unit: (json['unit'] ?? 'kg').toString(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      orderStatus: status,
      paymentStatus: payment,
      refundStatus: json['refundStatus']?.toString(),
      buyerId: json['buyerId']?.toString(),
      buyerName: json['buyerName']?.toString(),
      buyerContact: json['buyerContact']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString(),
      latitude:
          json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,
      longitude:
          json['longitude'] != null
              ? (json['longitude'] as num).toDouble()
              : null,
      createdAt: created != null ? DateTime.tryParse(created.toString()) : null,
      deliveredAt:
          delivered != null ? DateTime.tryParse(delivered.toString()) : null,
      deliveryConfirmedByBuyer:
          (json['deliveryConfirmedByBuyer'] ?? false) == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderItemId': orderItemId,
    'productId': productId,
    'productName': productName,
    'productQuantity': productQuantity,
    'unit': unit,
    'totalPrice': totalPrice,
    'orderStatus': orderStatus,
    'paymentStatus': paymentStatus,
    'refundStatus': refundStatus,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'buyerContact': buyerContact,
    'deliveryAddress': deliveryAddress,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
    'deliveryConfirmedByBuyer': deliveryConfirmedByBuyer,
  };

  OrderModel copyWith({
    String? orderId,
    String? orderItemId,
    String? productId,
    String? productName,
    double? productQuantity,
    String? unit,
    double? totalPrice,
    String? orderStatus,
    String? paymentStatus,
    String? refundStatus,
    String? buyerId,
    String? buyerName,
    String? buyerContact,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? deliveredAt,
    bool? deliveryConfirmedByBuyer,
  }) => OrderModel(
    orderId: orderId ?? this.orderId,
    orderItemId: orderItemId ?? this.orderItemId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    productQuantity: productQuantity ?? this.productQuantity,
    unit: unit ?? this.unit,
    totalPrice: totalPrice ?? this.totalPrice,
    orderStatus: orderStatus ?? this.orderStatus,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    refundStatus: refundStatus ?? this.refundStatus,
    buyerId: buyerId ?? this.buyerId,
    buyerName: buyerName ?? this.buyerName,
    buyerContact: buyerContact ?? this.buyerContact,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    createdAt: createdAt ?? this.createdAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    deliveryConfirmedByBuyer:
        deliveryConfirmedByBuyer ?? this.deliveryConfirmedByBuyer,
  );
}
