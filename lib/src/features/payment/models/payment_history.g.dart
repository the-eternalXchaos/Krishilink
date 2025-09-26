// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:hive/hive.dart';
import 'package:krishi_link/src/features/payment/models/payment_history.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentHistoryAdapter extends TypeAdapter<PaymentHistory> {
  @override
  final int typeId = 3;

  @override
  PaymentHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentHistory(
      id: fields[0] as String,
      transactionId: fields[1] as String,
      pidx: fields[2] as String,
      totalAmount: fields[3] as double,
      status: fields[4] as String,
      timestamp: fields[5] as DateTime,
      fee: fields[6] as double,
      refunded: fields[7] as bool,
      purchaseOrderId: fields[8] as String?,
      purchaseOrderName: fields[9] as String?,
      items: (fields[10] as List).cast<CartItem>(),
      customerName: fields[11] as String,
      customerPhone: fields[12] as String,
      customerEmail: fields[13] as String?,
      deliveryAddress: fields[14] as String,
      latitude: fields[15] as double,
      longitude: fields[16] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentHistory obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transactionId)
      ..writeByte(2)
      ..write(obj.pidx)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.fee)
      ..writeByte(7)
      ..write(obj.refunded)
      ..writeByte(8)
      ..write(obj.purchaseOrderId)
      ..writeByte(9)
      ..write(obj.purchaseOrderName)
      ..writeByte(10)
      ..write(obj.items)
      ..writeByte(11)
      ..write(obj.customerName)
      ..writeByte(12)
      ..write(obj.customerPhone)
      ..writeByte(13)
      ..write(obj.customerEmail)
      ..writeByte(14)
      ..write(obj.deliveryAddress)
      ..writeByte(15)
      ..write(obj.latitude)
      ..writeByte(16)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
