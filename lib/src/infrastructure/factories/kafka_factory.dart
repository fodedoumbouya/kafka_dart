import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:kafka_dart/src/application/services/kafka_producer_service.dart';
import 'package:kafka_dart/src/application/services/kafka_consumer_service.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/infrastructure/repositories/simple_kafka_repository.dart';
import 'package:kafka_dart/src/infrastructure/repositories/rdkafka_producer_repository.dart';
import 'package:kafka_dart/src/infrastructure/repositories/rdkafka_consumer_repository.dart';
import 'package:kafka_dart/src/infrastructure/bindings/rdkafka_bindings.g.dart';

class KafkaFactory {
  static RdkafkaBindings? _bindings;

  /// Get the Homebrew prefix dynamically
  static String? _getHomebrewPrefix() {
    try {
      // Try common Homebrew installation paths
      final commonPaths = [
        Platform.environment['HOMEBREW_PREFIX'],
        '/opt/homebrew', // Apple Silicon Macs
        '/usr/local', // Intel Macs
        Platform.environment['HOME'] != null
            ? '${Platform.environment['HOME']}/homebrew'
            : null, // Custom installations
      ];

      for (final path in commonPaths) {
        if (path != null && Directory('$path/lib').existsSync()) {
          final librdkafkaPath = '$path/lib/librdkafka.dylib';
          if (File(librdkafkaPath).existsSync()) {
            return path;
          }
        }
      }
    } catch (_) {
      // Ignore errors and fallback
    }
    return null;
  }

  /// Try to find librdkafka in common Linux paths
  static String? _findLinuxLibrdkafka() {
    try {
      final pathsFromEnv =
          Platform.environment['LD_LIBRARY_PATH']?.split(':') ?? <String>[];
      final commonPaths = <String>[
        '/usr/lib/x86_64-linux-gnu',
        '/usr/lib64',
        '/usr/lib',
        '/usr/local/lib',
        ...pathsFromEnv,
      ];

      for (final path in commonPaths) {
        if (path.isNotEmpty && Directory(path).existsSync()) {
          // Try versioned first, then unversioned
          for (final libName in ['librdkafka.so.1', 'librdkafka.so']) {
            final libPath = '$path/$libName';
            if (File(libPath).existsSync()) {
              return libPath;
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors and fallback
    }
    return null;
  }

  /// Try to find librdkafka in common Windows paths
  static String? _findWindowsLibrdkafka() {
    try {
      final pathsFromEnv =
          Platform.environment['PATH']?.split(';') ?? <String>[];
      final commonPaths = <String>[
        'C:\\Program Files\\librdkafka\\bin',
        'C:\\Program Files (x86)\\librdkafka\\bin',
        'C:\\tools\\librdkafka\\bin',
        Platform.environment['LOCALAPPDATA'] != null
            ? '${Platform.environment['LOCALAPPDATA']}\\librdkafka\\bin'
            : '',
        ...pathsFromEnv,
      ];

      for (final path in commonPaths) {
        if (path.isNotEmpty && Directory(path).existsSync()) {
          final libPath = '$path\\rdkafka.dll';
          if (File(libPath).existsSync()) {
            return libPath;
          }
        }
      }
    } catch (_) {
      // Ignore errors and fallback
    }
    return null;
  }

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
          try {
            // Try to find librdkafka dynamically
            final libPath = _findLinuxLibrdkafka();
            if (libPath != null) {
              library = ffi.DynamicLibrary.open(libPath);
            } else {
              throw Exception(
                  'Could not find librdkafka in any known location');
            }
          } catch (_) {
            library = ffi.DynamicLibrary.process();
          }
        }
      }
    } else if (Platform.isMacOS) {
      try {
        library = ffi.DynamicLibrary.open('librdkafka.dylib');
      } catch (_) {
        try {
          // Try to find Homebrew installation dynamically
          final homebrewPrefix = _getHomebrewPrefix();
          if (homebrewPrefix != null) {
            library =
                ffi.DynamicLibrary.open('$homebrewPrefix/lib/librdkafka.dylib');
          } else {
            throw Exception('Could not find librdkafka in any known location');
          }
        } catch (_) {
          library = ffi.DynamicLibrary.process();
        }
      }
    } else if (Platform.isWindows) {
      try {
        library = ffi.DynamicLibrary.open('rdkafka.dll');
      } catch (_) {
        try {
          // Try to find rdkafka.dll dynamically
          final libPath = _findWindowsLibrdkafka();
          if (libPath != null) {
            library = ffi.DynamicLibrary.open(libPath);
          } else {
            throw Exception('Could not find rdkafka.dll in any known location');
          }
        } catch (_) {
          library = ffi.DynamicLibrary.process();
        }
      }
    } else {
      throw UnsupportedError(
          'Platform ${Platform.operatingSystem} is not supported');
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
