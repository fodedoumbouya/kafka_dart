import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'package:kafka_dart/src/domain/entities/kafka_message.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/repositories/kafka_producer_repository.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';
import 'package:kafka_dart/src/infrastructure/bindings/rdkafka_bindings.dart';

class RdKafkaProducerRepository implements KafkaProducerRepository {
  final RdkafkaBindings _bindings;
  ffi.Pointer? _kafka;
  ffi.Pointer? _conf;
  bool _isInitialized = false;

  RdKafkaProducerRepository(this._bindings);

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize(KafkaConfiguration configuration) async {
    if (_isInitialized) {
      throw ProducerException('Producer is already initialized');
    }

    _conf = _bindings.rd_kafka_conf_new();
    if (_conf == ffi.nullptr) {
      throw ProducerException('Failed to create configuration');
    }

    try {
      await _setConfiguration(configuration);
      await _createProducer();
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
          throw ProducerException('Failed to set configuration ${entry.key}: $error');
        }
      } finally {
        calloc.free(keyPtr);
        calloc.free(valuePtr);
        calloc.free(errstr);
      }
    }
  }

  Future<void> _createProducer() async {
    final errstr = calloc<ffi.Char>(512);

    try {
      _kafka = _bindings.rd_kafka_new(
        rd_kafka_type_t.RD_KAFKA_PRODUCER,
        _conf!.cast(),
        errstr,
        512,
      );

      if (_kafka == ffi.nullptr) {
        final error = _nativeUtf8ToString(errstr);
        throw ProducerException('Failed to create producer: $error');
      }
    } finally {
      calloc.free(errstr);
    }
  }

  @override
  Future<void> send(KafkaMessage message) async {
    if (!_isInitialized) {
      throw ProducerException('Producer is not initialized');
    }

    final topicPtr = _stringToNativeUtf8(message.topic.value);
    final topic = _bindings.rd_kafka_topic_new(_kafka!.cast(), topicPtr.cast(), ffi.nullptr);
    
    if (topic == ffi.nullptr) {
      calloc.free(topicPtr);
      throw ProducerException('Failed to create topic handle for ${message.topic.value}');
    }

    final payloadPtr = _stringToNativeUtf8(message.payload.value);
    ffi.Pointer<ffi.Char>? keyPtr;
    
    if (message.key.hasValue) {
      keyPtr = _stringToNativeUtf8(message.key.value!).cast<ffi.Char>();
    }

    try {
      final result = _bindings.rd_kafka_produce(
        topic,
        message.partition.isAnyPartition ? -1 : message.partition.value,
        0, // flags
        payloadPtr.cast(),
        message.payload.sizeInBytes,
        keyPtr?.cast() ?? ffi.nullptr,
        message.key.hasValue ? message.key.value!.length : 0,
        ffi.nullptr, // opaque
      );

      if (result == -1) {
        throw ProducerException('Failed to produce message to ${message.topic.value}');
      }

      // Poll for delivery reports
      _bindings.rd_kafka_poll(_kafka!.cast(), 0);
    } finally {
      calloc.free(topicPtr);
      calloc.free(payloadPtr);
      if (keyPtr != null) {
        calloc.free(keyPtr);
      }
      _bindings.rd_kafka_topic_destroy(topic);
    }
  }

  @override
  Future<void> flush([Duration? timeout]) async {
    if (!_isInitialized) {
      throw ProducerException('Producer is not initialized');
    }

    final timeoutMs = timeout?.inMilliseconds ?? 10000;
    final result = _bindings.rd_kafka_flush(_kafka!.cast(), timeoutMs);
    
    if (result != rd_kafka_resp_err_t.RD_KAFKA_RESP_ERR_NO_ERROR) {
      throw ProducerException('Failed to flush producer within timeout');
    }
  }

  @override
  Future<void> close() async {
    if (!_isInitialized) return;

    await flush();
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