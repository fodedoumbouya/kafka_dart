import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

class Topic {
  final String _value;

  const Topic._(this._value);

  factory Topic.create(String value) {
    if (value.isEmpty) {
      throw InvalidTopicException('Topic name cannot be empty');
    }
    
    if (value.length > 249) {
      throw InvalidTopicException('Topic name cannot exceed 249 characters');
    }
    
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
      throw InvalidTopicException(
        'Topic name can only contain alphanumeric characters, dots, underscores, and hyphens'
      );
    }
    
    return Topic._(value);
  }

  String get value => _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Topic($_value)';
}