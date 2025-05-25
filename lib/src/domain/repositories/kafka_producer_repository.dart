import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';

abstract class KafkaProducerRepository {
  Future<void> initialize(KafkaConfiguration configuration);
  Future<void> send(KafkaMessage message);
  Future<void> flush([Duration? timeout]);
  Future<void> close();
  bool get isInitialized;
}