import 'package:kafka_dart/kafka_dart.dart';
import 'package:test/test.dart';

void main() {
  group('KafkaMessage Factory Tests', () {
    test('can create a basic message', () {
      final message = KafkaMessage.create(
        topic: 'test-topic',
        payload: 'test-payload',
      );
      
      expect(message.topic.value, equals('test-topic'));
      expect(message.payload.value, equals('test-payload'));
    });
  });
}
