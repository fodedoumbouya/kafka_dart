import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_producer_repository.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

class KafkaProducerService {
  final KafkaProducerRepository _repository;
  bool _isInitialized = false;

  KafkaProducerService(this._repository);

  bool get isInitialized => _isInitialized;

  Future<void> initialize(KafkaConfiguration configuration) async {
    if (_isInitialized) {
      throw ProducerException('Producer service is already initialized');
    }

    if (!configuration.isProducerConfig) {
      throw ProducerException('Configuration is not valid for producer');
    }

    await _repository.initialize(configuration);
    _isInitialized = true;
  }

  Future<void> sendMessage({
    required String topic,
    required String payload,
    String? key,
    int? partition,
  }) async {
    if (!_isInitialized) {
      throw ProducerException('Producer service is not initialized');
    }

    final message = KafkaMessage.create(
      topic: topic,
      payload: payload,
      key: key,
      partition: partition,
    );

    await _repository.send(message);
  }

  Future<void> sendMessages(List<KafkaMessage> messages) async {
    if (!_isInitialized) {
      throw ProducerException('Producer service is not initialized');
    }

    if (messages.isEmpty) {
      return;
    }

    for (final message in messages) {
      await _repository.send(message);
    }
  }

  Future<void> flush([Duration? timeout]) async {
    if (!_isInitialized) {
      throw ProducerException('Producer service is not initialized');
    }

    await _repository.flush(timeout);
  }

  Future<void> close() async {
    if (!_isInitialized) return;

    await _repository.close();
    _isInitialized = false;
  }
}