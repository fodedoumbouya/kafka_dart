import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_consumer_repository.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';
import 'package:kafka_dart/src/domain/value_objects/topic.dart';

class KafkaConsumerService {
  final KafkaConsumerRepository _repository;
  bool _isInitialized = false;

  KafkaConsumerService(this._repository);

  bool get isInitialized => _isInitialized;
  bool get isSubscribed => _repository.isSubscribed;

  Future<void> initialize(KafkaConfiguration configuration) async {
    if (_isInitialized) {
      throw ConsumerException('Consumer service is already initialized');
    }

    if (!configuration.isConsumerConfig) {
      throw ConsumerException('Configuration is not valid for consumer');
    }

    await _repository.initialize(configuration);
    _isInitialized = true;
  }

  Future<void> subscribe(List<String> topics) async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer service is not initialized');
    }

    if (topics.isEmpty) {
      throw ConsumerException('Topic list cannot be empty');
    }

    final topicObjects = topics.map((topic) => Topic.create(topic)).toList();
    await _repository.subscribe(topicObjects);
  }

  Future<void> unsubscribe() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer service is not initialized');
    }

    await _repository.unsubscribe();
  }

  Future<KafkaMessage?> pollMessage([Duration? timeout]) async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer service is not initialized');
    }

    if (!isSubscribed) {
      throw ConsumerException('Consumer is not subscribed to any topics');
    }

    final effectiveTimeout = timeout ?? const Duration(milliseconds: 1000);
    return await _repository.poll(effectiveTimeout);
  }

  Stream<KafkaMessage> messageStream([Duration? pollTimeout]) async* {
    if (!_isInitialized) {
      throw ConsumerException('Consumer service is not initialized');
    }

    if (!isSubscribed) {
      throw ConsumerException('Consumer is not subscribed to any topics');
    }

    final effectiveTimeout = pollTimeout ?? const Duration(milliseconds: 1000);

    while (true) {
      final message = await _repository.poll(effectiveTimeout);
      if (message != null) {
        yield message;
      }
    }
  }

  Future<void> commitSync() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer service is not initialized');
    }

    await _repository.commitSync();
  }

  Future<void> commitAsync() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer service is not initialized');
    }

    await _repository.commitAsync();
  }

  Future<void> close() async {
    if (!_isInitialized) return;

    await _repository.close();
    _isInitialized = false;
  }
}