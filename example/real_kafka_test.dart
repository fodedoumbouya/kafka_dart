// Test with REAL Kafka using librdkafka FFI bindings
import 'package:kafka_dart/kafka_dart.dart';

Future<void> main() async {
  print('🚀 Testing Kafka Dart with REAL Kafka Connection!');
  print('📡 Connecting to Kafka at localhost:9092');
  
  // Test Producer with real Kafka
  print('\n📤 Testing Real Producer...');
  await testRealProducer();
  
  // Wait a bit for messages to be available
  await Future.delayed(Duration(seconds: 2));
  
  // Test Consumer with real Kafka
  print('\n📥 Testing Real Consumer...');
  await testRealConsumer();
  
  print('\n✅ Real Kafka tests completed!');
}

Future<void> testRealProducer() async {
  final producer = await KafkaFactory.createAndInitializeProducer(
    bootstrapServers: 'localhost:9092',
    useMock: false, // Use REAL Kafka!
  );

  try {
    for (int i = 0; i < 3; i++) {
      await producer.sendMessage(
        topic: 'test-topic',
        payload: 'Real message $i from Dart at ${DateTime.now()}',
        key: 'real-key-$i',
      );
      print('  ✅ Sent real message $i to Kafka');
    }
    
    await producer.flush();
    print('  ✅ Messages flushed to Kafka broker');
  } catch (e) {
    print('  ❌ Producer Error: $e');
    rethrow;
  } finally {
    await producer.close();
    print('  ✅ Producer closed');
  }
}

Future<void> testRealConsumer() async {
  final consumer = await KafkaFactory.createAndInitializeConsumer(
    bootstrapServers: 'localhost:9092',
    groupId: 'dart-real-group-${DateTime.now().millisecondsSinceEpoch}',
    useMock: false, // Use REAL Kafka!
  );

  try {
    await consumer.subscribe(['test-topic']);
    print('  ✅ Subscribed to test-topic');
    
    for (int i = 0; i < 5; i++) {
      print('  🔍 Polling for messages (attempt ${i + 1})...');
      final message = await consumer.pollMessage();
      if (message != null) {
        print('  🎉 Received real message from Kafka:');
        print('    📄 Topic: ${message.topic.value}');
        print('    🔑 Key: ${message.key.hasValue ? message.key.value : 'null'}');
        print('    💬 Payload: ${message.payload.value}');
        print('    📍 Partition: ${message.partition.value}');
        
        await consumer.commitAsync();
        print('  ✅ Committed message offset');
      } else {
        print('  ⏰ No message available (timeout)');
      }
      
      // Small delay between polls
      await Future.delayed(Duration(milliseconds: 500));
    }
  } catch (e) {
    print('  ❌ Consumer Error: $e');
    rethrow;
  } finally {
    await consumer.close();
    print('  ✅ Consumer closed');
  }
}