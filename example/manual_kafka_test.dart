// This demonstrates the current API with mock implementation
import 'package:kafka_dart/kafka_dart.dart';

Future<void> main() async {
  print('🚀 Testing Kafka Dart with Mock Implementation');
  print('📡 Kafka should be running at localhost:9092');
  
  // Test Producer
  print('\n📤 Testing Producer...');
  await testProducer();
  
  // Test Consumer  
  print('\n📥 Testing Consumer...');
  await testConsumer();
  
  print('\n✅ Tests completed!');
  print('ℹ️  Note: This uses mock implementation - messages are not actually sent to Kafka');
  print('🔧 To connect to real Kafka, implement RdkafkaConsumerRepository and RdkafkaProducerRepository');
}

Future<void> testProducer() async {
  final producer = await KafkaFactory.createAndInitializeProducer(
    bootstrapServers: 'localhost:9092',
    useMock: true, // Use mock for safe testing
  );

  try {
    for (int i = 0; i < 5; i++) {
      await producer.sendMessage(
        topic: 'test-topic',
        payload: 'Message $i from Dart at ${DateTime.now()}',
        key: 'key-$i',
      );
      print('  ✓ Sent message $i');
    }
    
    await producer.flush();
    print('  ✓ Messages flushed');
  } catch (e) {
    print('  ❌ Error: $e');
  } finally {
    await producer.close();
    print('  ✓ Producer closed');
  }
}

Future<void> testConsumer() async {
  final consumer = await KafkaFactory.createAndInitializeConsumer(
    bootstrapServers: 'localhost:9092',
    groupId: 'dart-test-group',
    useMock: true, // Use mock for safe testing
  );

  try {
    await consumer.subscribe(['test-topic']);
    print('  ✓ Subscribed to test-topic');
    
    for (int i = 0; i < 3; i++) {
      final message = await consumer.pollMessage();
      if (message != null) {
        print('  ✓ Received: ${message.payload.value}');
        await consumer.commitAsync();
      } else {
        print('  ℹ️ No message (poll $i)');
      }
    }
  } catch (e) {
    print('  ❌ Error: $e');
  } finally {
    await consumer.close();
    print('  ✓ Consumer closed');
  }
}