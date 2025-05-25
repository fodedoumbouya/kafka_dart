import 'dart:async';

import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_producer_repository.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_consumer_repository.dart';
import 'package:kafka_dart/src/domain/value_objects/topic.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

class SimpleKafkaProducerRepository implements KafkaProducerRepository {
  bool _isInitialized = false;
  late KafkaConfiguration _config;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize(KafkaConfiguration configuration) async {
    if (_isInitialized) {
      throw ProducerException('Producer is already initialized');
    }
    _config = configuration;
    _isInitialized = true;
  }

  @override
  Future<void> send(KafkaMessage message) async {
    if (!_isInitialized) {
      throw ProducerException('Producer is not initialized');
    }
    // Simulate sending message
    await Future.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<void> flush([Duration? timeout]) async {
    if (!_isInitialized) {
      throw ProducerException('Producer is not initialized');
    }
    // Simulate flush
    await Future.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<void> close() async {
    if (!_isInitialized) return;
    _isInitialized = false;
  }
}

class SimpleKafkaConsumerRepository implements KafkaConsumerRepository {
  bool _isInitialized = false;
  bool _isSubscribed = false;
  late KafkaConfiguration _config;
  List<Topic> _subscribedTopics = [];

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isSubscribed => _isSubscribed;

  @override
  Future<void> initialize(KafkaConfiguration configuration) async {
    if (_isInitialized) {
      throw ConsumerException('Consumer is already initialized');
    }
    _config = configuration;
    _isInitialized = true;
  }

  @override
  Future<void> subscribe(List<Topic> topics) async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }
    _subscribedTopics = List.from(topics);
    _isSubscribed = true;
  }

  @override
  Future<void> unsubscribe() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }
    _subscribedTopics.clear();
    _isSubscribed = false;
  }

  @override
  Future<KafkaMessage?> poll(Duration timeout) async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }
    if (!_isSubscribed) {
      throw ConsumerException('Consumer is not subscribed to any topics');
    }
    
    // Simulate polling - return null for timeout
    await Future.delayed(Duration(milliseconds: timeout.inMilliseconds.clamp(0, 100)));
    return null;
  }

  @override
  Future<void> commitSync() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }
    // Simulate commit
    await Future.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<void> commitAsync() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }
    // Simulate async commit
    await Future.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<void> close() async {
    if (!_isInitialized) return;
    if (_isSubscribed) {
      await unsubscribe();
    }
    _isInitialized = false;
  }
}