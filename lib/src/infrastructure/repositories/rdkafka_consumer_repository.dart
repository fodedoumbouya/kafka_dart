import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_consumer_repository.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';
import 'package:kafka_dart/src/domain/value_objects/topic.dart';
import 'package:kafka_dart/src/infrastructure/bindings/rdkafka_bindings.dart';

class RdKafkaConsumerRepository implements KafkaConsumerRepository {
  final RdkafkaBindings _bindings;
  ffi.Pointer? _kafka;
  ffi.Pointer? _conf;
  bool _isInitialized = false;
  bool _isSubscribed = false;

  RdKafkaConsumerRepository(this._bindings);

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isSubscribed => _isSubscribed;

  @override
  Future<void> initialize(KafkaConfiguration configuration) async {
    if (_isInitialized) {
      throw ConsumerException('Consumer is already initialized');
    }

    if (!configuration.isConsumerConfig) {
      throw ConsumerException('Configuration is not valid for consumer');
    }

    _conf = _bindings.rd_kafka_conf_new();
    if (_conf == ffi.nullptr) {
      throw ConsumerException('Failed to create configuration');
    }

    try {
      await _setConfiguration(configuration);
      await _createConsumer();
      _isInitialized = true;
    } catch (e) {
      await _cleanup();
      rethrow;
    }
  }

  Future<void> _setConfiguration(KafkaConfiguration configuration) async {
    for (final entry in configuration.allProperties.entries) {
      final keyPtr = _stringToNativeUtf8(entry.key);
      final valuePtr = _stringToNativeUtf8(entry.value);
      final errstr = calloc<ffi.Char>(256);

      try {
        final result = _bindings.rd_kafka_conf_set(
          _conf!.cast(),
          keyPtr.cast(),
          valuePtr.cast(),
          errstr,
          256,
        );

        if (result != rd_kafka_conf_res_t.RD_KAFKA_CONF_OK) {
          final error = _nativeUtf8ToString(errstr);
          throw ConsumerException('Failed to set configuration ${entry.key}: $error');
        }
      } finally {
        calloc.free(keyPtr);
        calloc.free(valuePtr);
        calloc.free(errstr);
      }
    }
  }

  Future<void> _createConsumer() async {
    final errstr = calloc<ffi.Char>(512);

    try {
      _kafka = _bindings.rd_kafka_new(
        rd_kafka_type_t.RD_KAFKA_CONSUMER,
        _conf!.cast(),
        errstr,
        512,
      );

      if (_kafka == ffi.nullptr) {
        final error = _nativeUtf8ToString(errstr);
        throw ConsumerException('Failed to create consumer: $error');
      }
    } finally {
      calloc.free(errstr);
    }
  }

  @override
  Future<void> subscribe(List<Topic> topics) async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }

    if (topics.isEmpty) {
      throw ConsumerException('Topic list cannot be empty');
    }

    final topicList = _bindings.rd_kafka_topic_partition_list_new(topics.length);
    if (topicList == ffi.nullptr) {
      throw ConsumerException('Failed to create topic partition list');
    }

    try {
      for (final topic in topics) {
        final topicPtr = _stringToNativeUtf8(topic.value);
        try {
          _bindings.rd_kafka_topic_partition_list_add(
            topicList,
            topicPtr.cast(),
            -1, // RD_KAFKA_PARTITION_UA (unassigned)
          );
        } finally {
          calloc.free(topicPtr);
        }
      }

      final result = _bindings.rd_kafka_subscribe(_kafka!.cast(), topicList);
      if (result != rd_kafka_resp_err_t.RD_KAFKA_RESP_ERR_NO_ERROR) {
        throw ConsumerException('Failed to subscribe to topics');
      }

      _isSubscribed = true;
    } finally {
      _bindings.rd_kafka_topic_partition_list_destroy(topicList);
    }
  }

  @override
  Future<void> unsubscribe() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }

    final result = _bindings.rd_kafka_unsubscribe(_kafka!.cast());
    if (result != rd_kafka_resp_err_t.RD_KAFKA_RESP_ERR_NO_ERROR) {
      throw ConsumerException('Failed to unsubscribe from topics');
    }

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

    final timeoutMs = timeout.inMilliseconds;
    final message = _bindings.rd_kafka_consumer_poll(_kafka!.cast(), timeoutMs);

    if (message == ffi.nullptr) {
      return null; // Timeout or no messages
    }

    try {
      return await _parseMessage(message);
    } finally {
      _bindings.rd_kafka_message_destroy(message);
    }
  }

  Future<KafkaMessage?> _parseMessage(ffi.Pointer message) async {
    // This is a simplified implementation
    // In a real implementation, you would parse the rd_kafka_message_t struct
    // to extract topic, partition, key, payload, timestamp, and offset
    
    // For now, return null as this requires detailed struct parsing
    // which would need the exact rd_kafka_message_t definition
    return null;
  }

  @override
  Future<void> commitSync() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }

    final result = _bindings.rd_kafka_commit(_kafka!.cast(), ffi.nullptr, 0);
    if (result != rd_kafka_resp_err_t.RD_KAFKA_RESP_ERR_NO_ERROR) {
      throw ConsumerException('Failed to commit offsets synchronously');
    }
  }

  @override
  Future<void> commitAsync() async {
    if (!_isInitialized) {
      throw ConsumerException('Consumer is not initialized');
    }

    final result = _bindings.rd_kafka_commit(_kafka!.cast(), ffi.nullptr, 1);
    if (result != rd_kafka_resp_err_t.RD_KAFKA_RESP_ERR_NO_ERROR) {
      throw ConsumerException('Failed to commit offsets asynchronously');
    }
  }

  @override
  Future<void> close() async {
    if (!_isInitialized) return;

    if (_isSubscribed) {
      await unsubscribe();
    }

    final result = _bindings.rd_kafka_consumer_close(_kafka!.cast());
    if (result != rd_kafka_resp_err_t.RD_KAFKA_RESP_ERR_NO_ERROR) {
      throw ConsumerException('Failed to close consumer gracefully');
    }

    await _cleanup();
    _isInitialized = false;
  }

  Future<void> _cleanup() async {
    if (_kafka != null) {
      _bindings.rd_kafka_destroy(_kafka!.cast());
      _kafka = null;
    }
    _conf = null; // Configuration is consumed by rd_kafka_new
  }

  ffi.Pointer<Utf8> _stringToNativeUtf8(String string) {
    return string.toNativeUtf8();
  }

  String _nativeUtf8ToString(ffi.Pointer<ffi.Char> ptr) {
    return ptr.cast<Utf8>().toDartString();
  }
}