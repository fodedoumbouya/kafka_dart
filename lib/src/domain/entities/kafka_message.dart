import 'package:kafka_dart/src/domain/value_objects/topic.dart';
import 'package:kafka_dart/src/domain/value_objects/partition.dart';
import 'package:kafka_dart/src/domain/value_objects/message_key.dart';
import 'package:kafka_dart/src/domain/value_objects/message_payload.dart';

class KafkaMessage {
  final Topic topic;
  final Partition partition;
  final MessageKey key;
  final MessagePayload payload;
  final DateTime timestamp;
  final int? offset;

  const KafkaMessage({
    required this.topic,
    required this.partition,
    required this.key,
    required this.payload,
    required this.timestamp,
    this.offset,
  });

  factory KafkaMessage.create({
    required String topic,
    String? key,
    required String payload,
    int? partition,
    DateTime? timestamp,
    int? offset,
  }) {
    return KafkaMessage(
      topic: Topic.create(topic),
      partition: partition != null ? Partition.create(partition) : Partition.any(),
      key: key != null ? MessageKey.create(key) : MessageKey.none(),
      payload: MessagePayload.create(payload),
      timestamp: timestamp ?? DateTime.now(),
      offset: offset,
    );
  }

  KafkaMessage copyWith({
    Topic? topic,
    Partition? partition,
    MessageKey? key,
    MessagePayload? payload,
    DateTime? timestamp,
    int? offset,
  }) {
    return KafkaMessage(
      topic: topic ?? this.topic,
      partition: partition ?? this.partition,
      key: key ?? this.key,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KafkaMessage &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          partition == other.partition &&
          key == other.key &&
          payload == other.payload &&
          timestamp == other.timestamp &&
          offset == other.offset;

  @override
  int get hashCode =>
      topic.hashCode ^
      partition.hashCode ^
      key.hashCode ^
      payload.hashCode ^
      timestamp.hashCode ^
      offset.hashCode;

  @override
  String toString() {
    return 'KafkaMessage(topic: $topic, partition: $partition, key: $key, payload: $payload, timestamp: $timestamp, offset: $offset)';
  }
}