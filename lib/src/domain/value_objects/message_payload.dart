import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

class MessagePayload {
  final String _value;

  const MessagePayload._(this._value);

  factory MessagePayload.create(String value) {
    if (value.isEmpty) {
      throw InvalidMessagePayloadException('Message payload cannot be empty');
    }
    
    return MessagePayload._(value);
  }

  String get value => _value;
  int get sizeInBytes => _value.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagePayload && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'MessagePayload(${_value.length} bytes)';
}