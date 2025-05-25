import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/value_objects/topic.dart';

abstract class KafkaConsumerRepository {
  Future<void> initialize(KafkaConfiguration configuration);
  Future<void> subscribe(List<Topic> topics);
  Future<void> unsubscribe();
  Future<KafkaMessage?> poll(Duration timeout);
  Future<void> commitSync();
  Future<void> commitAsync();
  Future<void> close();
  bool get isInitialized;
  bool get isSubscribed;
}