import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

class KafkaConfiguration {
  final Map<String, String> _properties;

  const KafkaConfiguration._(this._properties);

  factory KafkaConfiguration.create([Map<String, String>? properties]) {
    final config = Map<String, String>.from(properties ?? {});
    return KafkaConfiguration._(config);
  }

  factory KafkaConfiguration.producer({
    required String bootstrapServers,
    Map<String, String>? additionalProperties,
  }) {
    final properties = <String, String>{
      'bootstrap.servers': bootstrapServers,
      'client.id': 'kafka_dart_producer',
      'acks': 'all',
      'retries': '3',
      'retry.backoff.ms': '100',
      'delivery.timeout.ms': '30000',
      'request.timeout.ms': '5000',
      'max.in.flight.requests.per.connection': '1',
      'enable.idempotence': 'true',
      ...?additionalProperties,
    };

    _validateConfiguration(properties);
    return KafkaConfiguration._(properties);
  }

  factory KafkaConfiguration.consumer({
    required String bootstrapServers,
    required String groupId,
    Map<String, String>? additionalProperties,
  }) {
    final properties = <String, String>{
      'bootstrap.servers': bootstrapServers,
      'group.id': groupId,
      'client.id': 'kafka_dart_consumer',
      'auto.offset.reset': 'earliest',
      'enable.auto.commit': 'false',
      ...?additionalProperties,
    };

    _validateConfiguration(properties);
    return KafkaConfiguration._(properties);
  }

  static void _validateConfiguration(Map<String, String> properties) {
    if (!properties.containsKey('bootstrap.servers')) {
      throw InvalidConfigurationException('bootstrap.servers is required');
    }

    final bootstrapServers = properties['bootstrap.servers']!;
    if (bootstrapServers.isEmpty) {
      throw InvalidConfigurationException('bootstrap.servers cannot be empty');
    }

    if (properties.containsKey('group.id')) {
      final groupId = properties['group.id']!;
      if (groupId.isEmpty) {
        throw InvalidConfigurationException('group.id cannot be empty');
      }
    }
  }

  String? getProperty(String key) => _properties[key];

  void setProperty(String key, String value) {
    if (key.isEmpty) {
      throw InvalidConfigurationException('Configuration key cannot be empty');
    }
    _properties[key] = value;
  }

  Map<String, String> get allProperties => Map.unmodifiable(_properties);

  bool get isProducerConfig => !_properties.containsKey('group.id');
  bool get isConsumerConfig => _properties.containsKey('group.id');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KafkaConfiguration &&
          runtimeType == other.runtimeType &&
          _mapEquals(_properties, other._properties);

  @override
  int get hashCode {
    var result = 0;
    for (final entry in _properties.entries) {
      result ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return result;
  }

  @override
  String toString() => 'KafkaConfiguration($_properties)';

  static bool _mapEquals(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }
}