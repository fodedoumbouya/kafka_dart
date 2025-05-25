import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kafka_dart/src/application/services/kafka_consumer_service.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_consumer_repository.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';
import 'package:kafka_dart/src/domain/value_objects/topic.dart';
import 'package:kafka_dart/src/domain/value_objects/message_key.dart';
import 'package:kafka_dart/src/domain/value_objects/message_payload.dart';
import 'package:kafka_dart/src/domain/value_objects/partition.dart';

class MockKafkaConsumerRepository extends Mock implements KafkaConsumerRepository {}
void main() {
  setUpAll(() {
    registerFallbackValue(KafkaConfiguration.create());
    registerFallbackValue(<Topic>[]);
    registerFallbackValue(const Duration(milliseconds: 1000));
  });

  group('KafkaConsumerService', () {
    late KafkaConsumerService service;
    late MockKafkaConsumerRepository mockRepository;
    late KafkaConfiguration validConfig;

    setUp(() {
      mockRepository = MockKafkaConsumerRepository();
      service = KafkaConsumerService(mockRepository);
      validConfig = KafkaConfiguration.create()
        ..setProperty('bootstrap.servers', 'localhost:9092')
        ..setProperty('group.id', 'test-group');
    });

    group('Initialization', () {
      test('should initialize with valid consumer configuration', () async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});

        await service.initialize(validConfig);

        expect(service.isInitialized, isTrue);
        verify(() => mockRepository.initialize(validConfig)).called(1);
      });

      test('should throw exception when already initialized', () async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});

        await service.initialize(validConfig);

        expect(
          () => service.initialize(validConfig),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('already initialized'))),
        );
      });

      test('should throw exception with invalid consumer configuration', () async {
        final invalidConfig = KafkaConfiguration.producer(
          bootstrapServers: 'localhost:9092'
        );

        expect(
          () => service.initialize(invalidConfig),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not valid for consumer'))),
        );
      });

      test('should not be initialized initially', () {
        expect(service.isInitialized, isFalse);
      });
    });

    group('Subscription', () {
      setUp(() async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
        await service.initialize(validConfig);
      });

      test('should subscribe to valid topics', () async {
        when(() => mockRepository.subscribe(any())).thenAnswer((_) async {});
        final topics = ['topic1', 'topic2'];

        await service.subscribe(topics);

        verify(() => mockRepository.subscribe(any())).called(1);
      });

      test('should throw exception when not initialized', () async {
        final uninitializedService = KafkaConsumerService(mockRepository);

        expect(
          () => uninitializedService.subscribe(['topic1']),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not initialized'))),
        );
      });

      test('should throw exception with empty topic list', () async {
        expect(
          () => service.subscribe([]),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('cannot be empty'))),
        );
      });

      test('should convert strings to Topic objects correctly', () async {
        when(() => mockRepository.subscribe(any())).thenAnswer((_) async {});
        final topics = ['test-topic'];

        await service.subscribe(topics);

        final captured = verify(() => mockRepository.subscribe(captureAny())).captured.first as List<Topic>;
        expect(captured.first.value, equals('test-topic'));
      });
    });

    group('Unsubscribe', () {
      setUp(() async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
        await service.initialize(validConfig);
      });

      test('should unsubscribe when initialized', () async {
        when(() => mockRepository.unsubscribe()).thenAnswer((_) async {});

        await service.unsubscribe();

        verify(() => mockRepository.unsubscribe()).called(1);
      });

      test('should throw exception when not initialized', () async {
        final uninitializedService = KafkaConsumerService(mockRepository);

        expect(
          () => uninitializedService.unsubscribe(),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not initialized'))),
        );
      });
    });

    group('Message Polling', () {
      setUp(() async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
        when(() => mockRepository.isSubscribed).thenReturn(true);
        await service.initialize(validConfig);
      });

      test('should poll message with default timeout', () async {
        final message = KafkaMessage(
          topic: Topic.create('test-topic'),
          partition: Partition.create(0),
          offset: 123,
          key: MessageKey.create('key'),
          payload: MessagePayload.create('payload'),
          timestamp: DateTime.now(),
        );
        when(() => mockRepository.poll(any())).thenAnswer((_) async => message);

        final result = await service.pollMessage();

        expect(result, equals(message));
        verify(() => mockRepository.poll(const Duration(milliseconds: 1000))).called(1);
      });

      test('should poll message with custom timeout', () async {
        final customTimeout = const Duration(milliseconds: 500);
        when(() => mockRepository.poll(any())).thenAnswer((_) async => null);

        await service.pollMessage(customTimeout);

        verify(() => mockRepository.poll(customTimeout)).called(1);
      });

      test('should throw exception when not initialized', () async {
        final uninitializedService = KafkaConsumerService(mockRepository);

        expect(
          () => uninitializedService.pollMessage(),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not initialized'))),
        );
      });

      test('should throw exception when not subscribed', () async {
        when(() => mockRepository.isSubscribed).thenReturn(false);

        expect(
          () => service.pollMessage(),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not subscribed'))),
        );
      });
    });

    group('Message Stream', () {
      setUp(() async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
        when(() => mockRepository.isSubscribed).thenReturn(true);
        await service.initialize(validConfig);
      });

      test('should yield messages from stream', () async {
        final message1 = KafkaMessage(
          topic: Topic.create('test-topic'),
          partition: Partition.create(0),
          offset: 123,
          key: MessageKey.create('key1'),
          payload: MessagePayload.create('payload1'),
          timestamp: DateTime.now(),
        );
        final message2 = KafkaMessage(
          topic: Topic.create('test-topic'),
          partition: Partition.create(0),
          offset: 124,
          key: MessageKey.create('key2'),
          payload: MessagePayload.create('payload2'),
          timestamp: DateTime.now(),
        );

        var callCount = 0;
        when(() => mockRepository.poll(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return message1;
          if (callCount == 2) return message2;
          return null;
        });

        final stream = service.messageStream();
        final messages = await stream.take(2).toList();

        expect(messages, hasLength(2));
        expect(messages[0], equals(message1));
        expect(messages[1], equals(message2));
      });

      // TODO: Fix this hanging test - issue with infinite stream
      // test('should use custom poll timeout in stream', () async {
      //   final customTimeout = const Duration(milliseconds: 300);
      //   var callCount = 0;
      //   when(() => mockRepository.poll(any())).thenAnswer((_) async {
      //     callCount++;
      //     if (callCount >= 2) return null; // Stop after 2 calls
      //     await Future.delayed(const Duration(milliseconds: 10));
      //     return null;
      //   });

      //   final stream = service.messageStream(customTimeout);
      //   await stream.take(1).toList(); // Take only 1 (which will be null) and stop

      //   verify(() => mockRepository.poll(customTimeout)).called(greaterThan(0));
      // });

      test('should throw exception when not initialized', () async {
        final uninitializedService = KafkaConsumerService(mockRepository);

        final stream = uninitializedService.messageStream();
        expect(
          () async => await stream.first,
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not initialized'))),
        );
      });

      test('should throw exception when not subscribed', () async {
        when(() => mockRepository.isSubscribed).thenReturn(false);

        final stream = service.messageStream();
        expect(
          () async => await stream.first,
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not subscribed'))),
        );
      });
    });

    group('Commit Operations', () {
      setUp(() async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
        await service.initialize(validConfig);
      });

      test('should commit synchronously', () async {
        when(() => mockRepository.commitSync()).thenAnswer((_) async {});

        await service.commitSync();

        verify(() => mockRepository.commitSync()).called(1);
      });

      test('should commit asynchronously', () async {
        when(() => mockRepository.commitAsync()).thenAnswer((_) async {});

        await service.commitAsync();

        verify(() => mockRepository.commitAsync()).called(1);
      });

      test('should throw exception for sync commit when not initialized', () async {
        final uninitializedService = KafkaConsumerService(mockRepository);

        expect(
          () => uninitializedService.commitSync(),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not initialized'))),
        );
      });

      test('should throw exception for async commit when not initialized', () async {
        final uninitializedService = KafkaConsumerService(mockRepository);

        expect(
          () => uninitializedService.commitAsync(),
          throwsA(isA<ConsumerException>()
              .having((e) => e.message, 'message', contains('not initialized'))),
        );
      });
    });

    group('Close Operations', () {
      test('should close when initialized', () async {
        when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
        when(() => mockRepository.close()).thenAnswer((_) async {});

        await service.initialize(validConfig);
        await service.close();

        expect(service.isInitialized, isFalse);
        verify(() => mockRepository.close()).called(1);
      });

      test('should not throw when closing uninitialized service', () async {
        when(() => mockRepository.close()).thenAnswer((_) async {});

        await service.close();

        verifyNever(() => mockRepository.close());
        expect(service.isInitialized, isFalse);
      });
    });

    group('State Properties', () {
      test('should delegate isSubscribed to repository', () {
        when(() => mockRepository.isSubscribed).thenReturn(true);

        expect(service.isSubscribed, isTrue);

        when(() => mockRepository.isSubscribed).thenReturn(false);

        expect(service.isSubscribed, isFalse);
      });
    });
  });
}