class BuyerOrderItem {
  final String orderItemId;
  final String productId;
  final int quantity;
  final double rate;
  final double totalPrice;
  final String itemStatus;
  final bool deliveryConfirmedByBuyer;
  final String paymentStatus;
  final String refundStatus;

  BuyerOrderItem({
    required this.orderItemId,
    required this.productId,
    required this.quantity,
    required this.rate,
    required this.totalPrice,
    required this.itemStatus,
    required this.deliveryConfirmedByBuyer,
    required this.paymentStatus,
    required this.refundStatus,
  });

  factory BuyerOrderItem.fromJson(Map<String, dynamic> json) => BuyerOrderItem(
        orderItemId: (json['orderItemId'] ?? '').toString(),
        productId: (json['productId'] ?? '').toString(),
        quantity: (json['quantity'] ?? 0) is int
            ? (json['quantity'] as int)
            : int.tryParse(json['quantity'].toString()) ?? 0,
        rate: (json['rate'] ?? 0.0).toDouble(),
        totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
        itemStatus: (json['itemStatus'] ?? '').toString(),
        deliveryConfirmedByBuyer:
            (json['deliveryConfirmedByBuyer'] ?? false) == true,
        paymentStatus: (json['paymentStatus'] ?? '').toString(),
        refundStatus: (json['refundStatus'] ?? '').toString(),
      );
}

class BuyerOrder {
  final String orderId;
  final String buyerId;
  final double totalAmount;
  final DateTime? orderDate;
  final DateTime? updatedAt;
  final String overallStatus;
  final List<BuyerOrderItem> items;

  BuyerOrder({
    required this.orderId,
    required this.buyerId,
    required this.totalAmount,
    required this.orderDate,
    required this.updatedAt,
    required this.overallStatus,
    required this.items,
  });

  factory BuyerOrder.fromJson(Map<String, dynamic> json) => BuyerOrder(
        orderId: (json['orderId'] ?? '').toString(),
        buyerId: (json['buyerId'] ?? '').toString(),
        totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
        orderDate: json['orderDate'] != null
            ? DateTime.tryParse(json['orderDate'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
        overallStatus: (json['overallStatus'] ?? '').toString(),
        items: (json['orderItems'] is List)
            ? (json['orderItems'] as List)
                .whereType<Map>()
                .map((e) => BuyerOrderItem.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const <BuyerOrderItem>[],
      );
}
