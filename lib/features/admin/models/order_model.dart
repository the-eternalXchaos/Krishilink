class OrderModel {
  final String orderId;
  final String productId;
  final String productName; 
  final double productQuantity;
  final String unit; // (e.g., kg)
  final double totalPrice;
  final String orderStatus; // , pending, confirmed, shipped, delivered, cancelled
  final String paymentStatus; // e.g., pending, completed, failed
  final String? refundStatus; // e.g., requested, approved, rejected
  final String? buyerName; 
  final String? buyerContact; 
  final String? deliveryAddress; 
  final DateTime? createdAt;
  final DateTime? deliveredAt; 

  OrderModel({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productQuantity,
    required this.unit,
    required this.totalPrice,
    required this.orderStatus,
    required this.paymentStatus,
    this.refundStatus,
    this.buyerName,
    this.buyerContact,
    this.deliveryAddress,
    this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        orderId: (json['orderId'] ?? '').toString(),
        productId: (json['productId'] ?? '').toString(),
        productName: (json['productName'] ?? 'Unknown Product').toString(),
        productQuantity: (json['productQuantity'] ?? 0.0).toDouble(),
        unit: (json['unit'] ?? 'kg').toString(),
        totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
        orderStatus: json['orderStatus']?.toString() ?? 'pending',
        paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
        refundStatus: json['refundStatus']?.toString(),
        buyerName: json['buyerName']?.toString(),
        buyerContact: json['buyerContact']?.toString(),
        deliveryAddress: json['deliveryAddress']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.tryParse(json['deliveredAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'productId': productId,
        'productName': productName,
        'productQuantity': productQuantity,
        'unit': unit,
        'totalPrice': totalPrice,
        'orderStatus': orderStatus,
        'paymentStatus': paymentStatus,
        'refundStatus': refundStatus,
        'buyerName': buyerName,
        'buyerContact': buyerContact,
        'deliveryAddress': deliveryAddress,
        'createdAt': createdAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  OrderModel copyWith({
    String? orderId,
    String? productId,
    String? productName,
    double? productQuantity,
    String? unit,
    double? totalPrice,
    String? orderStatus,
    String? paymentStatus,
    String? refundStatus,
    String? buyerName,
    String? buyerContact,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) => OrderModel(
        orderId: orderId ?? this.orderId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        productQuantity: productQuantity ?? this.productQuantity,
        unit: unit ?? this.unit,
        totalPrice: totalPrice ?? this.totalPrice,
        orderStatus: orderStatus ?? this.orderStatus,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        refundStatus: refundStatus ?? this.refundStatus,
        buyerName: buyerName ?? this.buyerName,
        buyerContact: buyerContact ?? this.buyerContact,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        createdAt: createdAt ?? this.createdAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );
}