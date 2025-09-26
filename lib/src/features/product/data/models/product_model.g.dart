// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

import 'package:hive/hive.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 5;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      productName: fields[1] as String,
      description: fields[2] as String,
      rate: fields[3] as double,
      unit: fields[4] as String,
      latitude: fields[5] as double,
      longitude: fields[6] as double,
      location: fields[7] as String?,
      address: fields[8] as String?,
      image: fields[9] as String,
      soldedQuantity: fields[10] as double?,
      availableQuantity: fields[11] as double,
      category: fields[12] as String,
      farmerId: fields[13] as String?,
      createdAt: fields[14] as DateTime?,
      updatedAt: fields[15] as DateTime?,
      farmerPhone: fields[16] as String?,
      farmerName: fields[17] as String?,
      isActive: fields[18] as bool,
      distance: fields[19] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.rate)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.address)
      ..writeByte(9)
      ..write(obj.image)
      ..writeByte(10)
      ..write(obj.soldedQuantity)
      ..writeByte(11)
      ..write(obj.availableQuantity)
      ..writeByte(12)
      ..write(obj.category)
      ..writeByte(13)
      ..write(obj.farmerId)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.farmerPhone)
      ..writeByte(17)
      ..write(obj.farmerName)
      ..writeByte(18)
      ..write(obj.isActive)
      ..writeByte(19)
      ..write(obj.distance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
