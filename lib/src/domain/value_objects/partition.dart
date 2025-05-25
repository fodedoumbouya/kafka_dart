import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

class Partition {
  final int _value;

  const Partition._(this._value);

  factory Partition.create(int value) {
    if (value < 0) {
      throw InvalidPartitionException('Partition number cannot be negative');
    }
    
    return Partition._(value);
  }

  factory Partition.any() => const Partition._(-1);

  int get value => _value;
  bool get isAnyPartition => _value == -1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Partition && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => isAnyPartition ? 'Partition(ANY)' : 'Partition($_value)';
}