import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kafka_dart/src/application/services/kafka_producer_service.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_producer_repository.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

class MockKafkaProducerRepository extends Mock implements KafkaProducerRepository {}

void main() {
  late KafkaProducerService service;
  late MockKafkaProducerRepository mockRepository;

  setUp(() {
    mockRepository = MockKafkaProducerRepository();
    service = KafkaProducerService(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(
      KafkaConfiguration.producer(bootstrapServers: 'localhost:9092'),
    );
    registerFallbackValue(
      KafkaMessage.create(topic: 'test', payload: 'test'),
    );
  });

  group('KafkaProducerService', () {
    test('should initialize with valid producer configuration', () async {
      final config = KafkaConfiguration.producer(
        bootstrapServers: 'localhost:9092',
      );

      when(() => mockRepository.initialize(any())).thenAnswer((_) async {});

      await service.initialize(config);

      expect(service.isInitialized, isTrue);
      verify(() => mockRepository.initialize(config)).called(1);
    });

    test('should throw exception when initializing with consumer configuration', () async {
      final config = KafkaConfiguration.consumer(
        bootstrapServers: 'localhost:9092',
        groupId: 'test-group',
      );

      expect(
        () => service.initialize(config),
        throwsA(isA<ProducerException>()),
      );
    });

    test('should throw exception when initializing already initialized service', () async {
      final config = KafkaConfiguration.producer(
        bootstrapServers: 'localhost:9092',
      );

      when(() => mockRepository.initialize(any())).thenAnswer((_) async {});

      await service.initialize(config);

      expect(
        () => service.initialize(config),
        throwsA(isA<ProducerException>()),
      );
    });

    test('should send message when initialized', () async {
      final config = KafkaConfiguration.producer(
        bootstrapServers: 'localhost:9092',
      );

      when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
      when(() => mockRepository.send(any())).thenAnswer((_) async {});

      await service.initialize(config);
      await service.sendMessage(
        topic: 'test-topic',
        payload: 'test payload',
        key: 'test-key',
      );

      verify(() => mockRepository.send(any())).called(1);
    });

    test('should throw exception when sending message without initialization', () async {
      expect(
        () => service.sendMessage(
          topic: 'test-topic',
          payload: 'test payload',
        ),
        throwsA(isA<ProducerException>()),
      );
    });

    test('should send multiple messages', () async {
      final config = KafkaConfiguration.producer(
        bootstrapServers: 'localhost:9092',
      );

      when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
      when(() => mockRepository.send(any())).thenAnswer((_) async {});

      await service.initialize(config);

      final messages = [
        KafkaMessage.create(topic: 'test', payload: 'message1'),
        KafkaMessage.create(topic: 'test', payload: 'message2'),
        KafkaMessage.create(topic: 'test', payload: 'message3'),
      ];

      await service.sendMessages(messages);

      verify(() => mockRepository.send(any())).called(3);
    });

    test('should handle empty message list', () async {
      final config = KafkaConfiguration.producer(
        bootstrapServers: 'localhost:9092',
      );

      when(() => mockRepository.initialize(any())).thenAnswer((_) async {});

      await service.initialize(config);
      await service.sendMessages([]);

      verifyNever(() => mockRepository.send(any()));
    });

    test('should flush messages', () async {
      final config = KafkaConfiguration.producer(
        bootstrapServers: 'localhost:9092',
      );

      when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
      when(() => mockRepository.flush(any())).thenAnswer((_) async {});

      await service.initialize(config);
      await service.flush(const Duration(seconds: 5));

      verify(() => mockRepository.flush(const Duration(seconds: 5))).called(1);
    });

    test('should close service and repository', () async {
      final config = KafkaConfiguration.producer(
        bootstrapServers: 'localhost:9092',
      );

      when(() => mockRepository.initialize(any())).thenAnswer((_) async {});
      when(() => mockRepository.close()).thenAnswer((_) async {});

      await service.initialize(config);
      await service.close();

      expect(service.isInitialized, isFalse);
      verify(() => mockRepository.close()).called(1);
    });

    test('should handle close when not initialized', () async {
      when(() => mockRepository.close()).thenAnswer((_) async {});

      await service.close();

      expect(service.isInitialized, isFalse);
      verifyNever(() => mockRepository.close());
    });
  });
}