// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

import 'package:hive/hive.dart';
import 'package:krishi_link/features/admin/models/cart_item.dart';
import 'package:krishi_link/features/admin/models/product_model.dart'
    show Product;

class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 4;

  @override
  CartItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItem(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as String,
      productId: fields[3] as String,
      quantity: fields[4] as int,
      image: fields[5] as String,
      product: fields[6] as Product?,
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.productId)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.image)
      ..writeByte(6)
      ..write(obj.product);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
