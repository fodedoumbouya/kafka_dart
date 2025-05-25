import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:kafka_dart/src/application/services/kafka_producer_service.dart';
import 'package:kafka_dart/src/application/services/kafka_consumer_service.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/infrastructure/repositories/simple_kafka_repository.dart';
import 'package:kafka_dart/src/infrastructure/repositories/rdkafka_producer_repository.dart';
import 'package:kafka_dart/src/infrastructure/repositories/rdkafka_consumer_repository.dart';
import 'package:kafka_dart/src/infrastructure/bindings/rdkafka_bindings.dart';

class KafkaFactory {
  static RdkafkaBindings? _bindings;

  static RdkafkaBindings _getBindings() {
    if (_bindings != null) return _bindings!;

    late ffi.DynamicLibrary library;

    if (Platform.isLinux) {
      try {
        library = ffi.DynamicLibrary.open('librdkafka.so.1');
      } catch (_) {
        try {
          library = ffi.DynamicLibrary.open('librdkafka.so');
        } catch (_) {
          library = ffi.DynamicLibrary.process();
        }
      }
    } else if (Platform.isMacOS) {
      try {
        library = ffi.DynamicLibrary.open('librdkafka.dylib');
      } catch (_) {
        library = ffi.DynamicLibrary.process();
      }
    } else if (Platform.isWindows) {
      try {
        library = ffi.DynamicLibrary.open('rdkafka.dll');
      } catch (_) {
        library = ffi.DynamicLibrary.process();
      }
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }

    _bindings = RdkafkaBindings(library);
    return _bindings!;
  }

  static KafkaProducerService createProducer({
    required String bootstrapServers,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) {
    final repository = useMock 
        ? SimpleKafkaProducerRepository()
        : RdKafkaProducerRepository(_getBindings());
    final service = KafkaProducerService(repository);
    return service;
  }

  static KafkaConsumerService createConsumer({
    required String bootstrapServers,
    required String groupId,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) {
    final repository = useMock 
        ? SimpleKafkaConsumerRepository()
        : RdKafkaConsumerRepository(_getBindings());
    final service = KafkaConsumerService(repository);
    return service;
  }

  static Future<KafkaProducerService> createAndInitializeProducer({
    required String bootstrapServers,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) async {
    final producer = createProducer(
      bootstrapServers: bootstrapServers,
      additionalProperties: additionalProperties,
      useMock: useMock,
    );

    final config = KafkaConfiguration.producer(
      bootstrapServers: bootstrapServers,
      additionalProperties: additionalProperties,
    );

    await producer.initialize(config);
    return producer;
  }

  static Future<KafkaConsumerService> createAndInitializeConsumer({
    required String bootstrapServers,
    required String groupId,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) async {
    final consumer = createConsumer(
      bootstrapServers: bootstrapServers,
      groupId: groupId,
      additionalProperties: additionalProperties,
      useMock: useMock,
    );

    final config = KafkaConfiguration.consumer(
      bootstrapServers: bootstrapServers,
      groupId: groupId,
      additionalProperties: additionalProperties,
    );

    await consumer.initialize(config);
    return consumer;
  }
}