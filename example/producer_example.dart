import 'package:kafka_dart/kafka_dart.dart';

Future<void> main() async {
  final producer = await KafkaFactory.createAndInitializeProducer(
    bootstrapServers: 'localhost:9092',
    additionalProperties: {
      'client.id': 'dart_producer_example',
    },
  );

  try {
    // Send a single message
    await producer.sendMessage(
      topic: 'test-topic',
      payload: 'Hello, Kafka from Dart!',
      key: 'example-key',
    );

    // Send multiple messages
    for (int i = 0; i < 10; i++) {
      await producer.sendMessage(
        topic: 'test-topic',
        payload: 'Message $i',
        key: 'key-$i',
      );
    }

    // Ensure all messages are sent
    await producer.flush();
    
    print('All messages sent successfully!');
  } catch (e) {
    print('Error sending messages: $e');
  } finally {
    await producer.close();
  }
}