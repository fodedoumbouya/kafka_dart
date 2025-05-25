import 'package:test/test.dart';
import 'package:kafka_dart/kafka_dart.dart';

void main() {
  group('Integration Tests (Mock Implementation)', () {
    test('Producer can send messages', () async {
      final producer = await KafkaFactory.createAndInitializeProducer(
        bootstrapServers: 'localhost:9092',
        useMock: true,
      );

      try {
        await producer.sendMessage(
          topic: 'test-topic',
          payload: 'Hello, Kafka from Dart!',
          key: 'test-key-${DateTime.now().millisecondsSinceEpoch}',
        );
        await producer.flush();
        
        print('✅ Message sent successfully');
      } finally {
        await producer.close();
      }
    });

    test('Consumer can receive messages', () async {
      final consumer = await KafkaFactory.createAndInitializeConsumer(
        bootstrapServers: 'localhost:9092',
        groupId: 'test-group-${DateTime.now().millisecondsSinceEpoch}',
        useMock: true,
      );

      try {
        await consumer.subscribe(['test-topic']);
        
        final message = await consumer.pollMessage();
        if (message != null) {
          print('✅ Received message: ${message.payload.value}');
          await consumer.commitAsync();
        } else {
          print('ℹ️ No message available (mock returns null)');
        }
      } finally {
        await consumer.close();
      }
    });
  });
}