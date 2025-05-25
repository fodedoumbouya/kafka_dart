import 'dart:async';
import 'package:test/test.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

void main() {
  group('Domain Exceptions', () {
    group('KafkaDomainException', () {
      test('should create exception with message only', () {
        final exception = TestKafkaDomainException('Test message');

        expect(exception.message, equals('Test message'));
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('KafkaDomainException: Test message'));
      });

      test('should create exception with message and cause', () {
        final cause = Exception('Root cause');
        final exception = TestKafkaDomainException('Test message', cause);

        expect(exception.message, equals('Test message'));
        expect(exception.cause, equals(cause));
        expect(exception.toString(), equals('KafkaDomainException: Test message'));
      });

      test('should implement Exception interface', () {
        final exception = TestKafkaDomainException('Test message');
        expect(exception, isA<Exception>());
      });
    });

    group('InvalidTopicException', () {
      test('should create exception with message only', () {
        const exception = InvalidTopicException('Invalid topic name');

        expect(exception.message, equals('Invalid topic name'));
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('InvalidTopicException: Invalid topic name'));
      });

      test('should create exception with message and cause', () {
        final cause = ArgumentError('Topic name is null');
        const message = 'Topic validation failed';
        final exception = InvalidTopicException(message, cause);

        expect(exception.message, equals(message));
        expect(exception.cause, equals(cause));
        expect(exception.toString(), equals('InvalidTopicException: Topic validation failed'));
      });

      test('should inherit from KafkaDomainException', () {
        const exception = InvalidTopicException('Test');
        expect(exception, isA<KafkaDomainException>());
        expect(exception, isA<Exception>());
      });
    });

    group('InvalidPartitionException', () {
      test('should create exception with message only', () {
        const exception = InvalidPartitionException('Invalid partition number');

        expect(exception.message, equals('Invalid partition number'));
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('InvalidPartitionException: Invalid partition number'));
      });

      test('should create exception with message and cause', () {
        final cause = RangeError('Partition number out of range');
        const message = 'Partition validation failed';
        final exception = InvalidPartitionException(message, cause);

        expect(exception.message, equals(message));
        expect(exception.cause, equals(cause));
        expect(exception.toString(), equals('InvalidPartitionException: Partition validation failed'));
      });

      test('should inherit from KafkaDomainException', () {
        const exception = InvalidPartitionException('Test');
        expect(exception, isA<KafkaDomainException>());
        expect(exception, isA<Exception>());
      });
    });

    group('InvalidMessagePayloadException', () {
      test('should create exception with message only', () {
        const exception = InvalidMessagePayloadException('Payload too large');

        expect(exception.message, equals('Payload too large'));
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('InvalidMessagePayloadException: Payload too large'));
      });

      test('should create exception with message and cause', () {
        final cause = FormatException('Invalid JSON format');
        const message = 'Message payload validation failed';
        final exception = InvalidMessagePayloadException(message, cause);

        expect(exception.message, equals(message));
        expect(exception.cause, equals(cause));
        expect(exception.toString(), equals('InvalidMessagePayloadException: Message payload validation failed'));
      });

      test('should inherit from KafkaDomainException', () {
        const exception = InvalidMessagePayloadException('Test');
        expect(exception, isA<KafkaDomainException>());
        expect(exception, isA<Exception>());
      });
    });

    group('InvalidConfigurationException', () {
      test('should create exception with message only', () {
        const exception = InvalidConfigurationException('Missing bootstrap servers');

        expect(exception.message, equals('Missing bootstrap servers'));
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('InvalidConfigurationException: Missing bootstrap servers'));
      });

      test('should create exception with message and cause', () {
        final cause = ArgumentError('Invalid property value');
        const message = 'Configuration validation failed';
        final exception = InvalidConfigurationException(message, cause);

        expect(exception.message, equals(message));
        expect(exception.cause, equals(cause));
        expect(exception.toString(), equals('InvalidConfigurationException: Configuration validation failed'));
      });

      test('should inherit from KafkaDomainException', () {
        const exception = InvalidConfigurationException('Test');
        expect(exception, isA<KafkaDomainException>());
        expect(exception, isA<Exception>());
      });
    });

    group('ProducerException', () {
      test('should create exception with message only', () {
        const exception = ProducerException('Producer not initialized');

        expect(exception.message, equals('Producer not initialized'));
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('ProducerException: Producer not initialized'));
      });

      test('should create exception with message and cause', () {
        final cause = StateError('Producer already closed');
        const message = 'Producer operation failed';
        final exception = ProducerException(message, cause);

        expect(exception.message, equals(message));
        expect(exception.cause, equals(cause));
        expect(exception.toString(), equals('ProducerException: Producer operation failed'));
      });

      test('should inherit from KafkaDomainException', () {
        const exception = ProducerException('Test');
        expect(exception, isA<KafkaDomainException>());
        expect(exception, isA<Exception>());
      });
    });

    group('ConsumerException', () {
      test('should create exception with message only', () {
        const exception = ConsumerException('Consumer not subscribed');

        expect(exception.message, equals('Consumer not subscribed'));
        expect(exception.cause, isNull);
        expect(exception.toString(), equals('ConsumerException: Consumer not subscribed'));
      });

      test('should create exception with message and cause', () {
        final cause = TimeoutException('Poll timeout exceeded');
        const message = 'Consumer operation failed';
        final exception = ConsumerException(message, cause);

        expect(exception.message, equals(message));
        expect(exception.cause, equals(cause));
        expect(exception.toString(), equals('ConsumerException: Consumer operation failed'));
      });

      test('should inherit from KafkaDomainException', () {
        const exception = ConsumerException('Test');
        expect(exception, isA<KafkaDomainException>());
        expect(exception, isA<Exception>());
      });
    });

    group('Exception Hierarchy', () {
      test('all exceptions should be throwable', () {
        final exceptions = [
          const InvalidTopicException('Test'),
          const InvalidPartitionException('Test'),
          const InvalidMessagePayloadException('Test'),
          const InvalidConfigurationException('Test'),
          const ProducerException('Test'),
          const ConsumerException('Test'),
        ];

        for (final exception in exceptions) {
          expect(() => throw exception, throwsA(isA<KafkaDomainException>()));
          expect(() => throw exception, throwsA(isA<Exception>()));
        }
      });

      test('all exceptions should have unique toString implementations', () {
        final exceptions = [
          const InvalidTopicException('Test message'),
          const InvalidPartitionException('Test message'),
          const InvalidMessagePayloadException('Test message'),
          const InvalidConfigurationException('Test message'),
          const ProducerException('Test message'),
          const ConsumerException('Test message'),
        ];

        final toStringResults = exceptions.map((e) => e.toString()).toSet();
        expect(toStringResults.length, equals(exceptions.length), 
               reason: 'Each exception should have a unique toString implementation');
      });

      test('all exceptions should preserve message and cause', () {
        final cause = Exception('Original cause');
        const message = 'Test error message';
        
        final exceptions = [
          InvalidTopicException(message, cause),
          InvalidPartitionException(message, cause),
          InvalidMessagePayloadException(message, cause),
          InvalidConfigurationException(message, cause),
          ProducerException(message, cause),
          ConsumerException(message, cause),
        ];

        for (final exception in exceptions) {
          expect(exception.message, equals(message));
          expect(exception.cause, equals(cause));
        }
      });
    });
  });
}

class TestKafkaDomainException extends KafkaDomainException {
  const TestKafkaDomainException(super.message, [super.cause]);
}