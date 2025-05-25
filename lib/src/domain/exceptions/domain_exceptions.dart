abstract class KafkaDomainException implements Exception {
  final String message;
  final Object? cause;

  const KafkaDomainException(this.message, [this.cause]);

  @override
  String toString() => 'KafkaDomainException: $message';
}

class InvalidTopicException extends KafkaDomainException {
  const InvalidTopicException(super.message, [super.cause]);

  @override
  String toString() => 'InvalidTopicException: $message';
}

class InvalidPartitionException extends KafkaDomainException {
  const InvalidPartitionException(super.message, [super.cause]);

  @override
  String toString() => 'InvalidPartitionException: $message';
}

class InvalidMessagePayloadException extends KafkaDomainException {
  const InvalidMessagePayloadException(super.message, [super.cause]);

  @override
  String toString() => 'InvalidMessagePayloadException: $message';
}

class InvalidConfigurationException extends KafkaDomainException {
  const InvalidConfigurationException(super.message, [super.cause]);

  @override
  String toString() => 'InvalidConfigurationException: $message';
}

class ProducerException extends KafkaDomainException {
  const ProducerException(super.message, [super.cause]);

  @override
  String toString() => 'ProducerException: $message';
}

class ConsumerException extends KafkaDomainException {
  const ConsumerException(super.message, [super.cause]);

  @override
  String toString() => 'ConsumerException: $message';
}