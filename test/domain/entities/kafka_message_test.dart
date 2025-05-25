import 'package:test/test.dart';
import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/value_objects/topic.dart';
import 'package:kafka_dart/src/domain/value_objects/partition.dart';
import 'package:kafka_dart/src/domain/value_objects/message_key.dart';
import 'package:kafka_dart/src/domain/value_objects/message_payload.dart';

void main() {
  group('KafkaMessage', () {
    test('should create message with factory method', () {
      final message = KafkaMessage.create(
        topic: 'test-topic',
        payload: 'test payload',
        key: 'test-key',
        partition: 1,
      );

      expect(message.topic.value, equals('test-topic'));
      expect(message.payload.value, equals('test payload'));
      expect(message.key.value, equals('test-key'));
      expect(message.partition.value, equals(1));
    });

    test('should create message without key and partition', () {
      final message = KafkaMessage.create(
        topic: 'test-topic',
        payload: 'test payload',
      );

      expect(message.topic.value, equals('test-topic'));
      expect(message.payload.value, equals('test payload'));
      expect(message.key.hasValue, isFalse);
      expect(message.partition.isAnyPartition, isTrue);
    });

    test('should create message with constructor', () {
      final timestamp = DateTime.now();
      final message = KafkaMessage(
        topic: Topic.create('test-topic'),
        partition: Partition.create(1),
        key: MessageKey.create('test-key'),
        payload: MessagePayload.create('test payload'),
        timestamp: timestamp,
        offset: 100,
      );

      expect(message.topic.value, equals('test-topic'));
      expect(message.partition.value, equals(1));
      expect(message.key.value, equals('test-key'));
      expect(message.payload.value, equals('test payload'));
      expect(message.timestamp, equals(timestamp));
      expect(message.offset, equals(100));
    });

    test('should copy message with modifications', () {
      final original = KafkaMessage.create(
        topic: 'original-topic',
        payload: 'original payload',
        key: 'original-key',
      );

      final copied = original.copyWith(
        topic: Topic.create('new-topic'),
        payload: MessagePayload.create('new payload'),
      );

      expect(copied.topic.value, equals('new-topic'));
      expect(copied.payload.value, equals('new payload'));
      expect(copied.key.value, equals('original-key')); // unchanged
      expect(copied.partition.isAnyPartition, isTrue); // unchanged
    });

    test('should have proper equality', () {
      final timestamp = DateTime.now();
      
      final message1 = KafkaMessage(
        topic: Topic.create('test-topic'),
        partition: Partition.create(1),
        key: MessageKey.create('test-key'),
        payload: MessagePayload.create('test payload'),
        timestamp: timestamp,
        offset: 100,
      );

      final message2 = KafkaMessage(
        topic: Topic.create('test-topic'),
        partition: Partition.create(1),
        key: MessageKey.create('test-key'),
        payload: MessagePayload.create('test payload'),
        timestamp: timestamp,
        offset: 100,
      );

      final message3 = KafkaMessage(
        topic: Topic.create('different-topic'),
        partition: Partition.create(1),
        key: MessageKey.create('test-key'),
        payload: MessagePayload.create('test payload'),
        timestamp: timestamp,
        offset: 100,
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
      expect(message1.hashCode, equals(message2.hashCode));
    });

    test('should have proper string representation', () {
      final message = KafkaMessage.create(
        topic: 'test-topic',
        payload: 'test payload',
        key: 'test-key',
        partition: 1,
      );

      final stringRep = message.toString();
      expect(stringRep, contains('KafkaMessage'));
      expect(stringRep, contains('test-topic'));
      expect(stringRep, contains('MessagePayload'));
      expect(stringRep, contains('test-key'));
    });
  });
}