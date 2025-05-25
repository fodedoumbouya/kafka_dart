import 'package:test/test.dart';
import 'package:kafka_dart/src/domain/value_objects/topic.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

void main() {
  group('Topic', () {
    test('should create valid topic', () {
      final topic = Topic.create('test-topic');
      expect(topic.value, equals('test-topic'));
    });

    test('should throw exception for empty topic name', () {
      expect(
        () => Topic.create(''),
        throwsA(isA<InvalidTopicException>()),
      );
    });

    test('should throw exception for topic name exceeding 249 characters', () {
      final longName = 'a' * 250;
      expect(
        () => Topic.create(longName),
        throwsA(isA<InvalidTopicException>()),
      );
    });

    test('should accept topic name with valid characters', () {
      final validNames = [
        'test_topic',
        'test-topic',
        'test.topic',
        'TestTopic123',
        'topic_with_123-and.dots',
      ];

      for (final name in validNames) {
        expect(() => Topic.create(name), returnsNormally);
      }
    });

    test('should throw exception for invalid characters', () {
      final invalidNames = [
        'test topic', // space
        'test@topic', // @
        'test#topic', // #
        'test/topic', // /
        'test\\topic', // backslash
      ];

      for (final name in invalidNames) {
        expect(
          () => Topic.create(name),
          throwsA(isA<InvalidTopicException>()),
        );
      }
    });

    test('should have proper equality', () {
      final topic1 = Topic.create('test-topic');
      final topic2 = Topic.create('test-topic');
      final topic3 = Topic.create('different-topic');

      expect(topic1, equals(topic2));
      expect(topic1, isNot(equals(topic3)));
      expect(topic1.hashCode, equals(topic2.hashCode));
    });

    test('should have proper string representation', () {
      final topic = Topic.create('test-topic');
      expect(topic.toString(), equals('Topic(test-topic)'));
    });
  });
}