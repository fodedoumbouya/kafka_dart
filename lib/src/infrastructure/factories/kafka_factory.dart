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

  /// Diagnose librdkafka installation and provide troubleshooting information
  static Map<String, dynamic> diagnoseLibrdkafkaInstallation() {
    final result = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'architecture': Platform.localeName,
      'searchPaths': <String>[],
      'foundLibraries': <String>[],
      'errors': <String>[],
      'recommendations': <String>[],
    };

    if (Platform.isMacOS) {
      result['recommendations'].add('Install using: brew install librdkafka');

      // Check Homebrew paths
      final homebrewPrefix = _getHomebrewPrefix();
      if (homebrewPrefix != null) {
        final libPath = '$homebrewPrefix/lib/librdkafka.dylib';
        result['searchPaths'].add(libPath);
        if (File(libPath).existsSync()) {
          result['foundLibraries'].add(libPath);
        }
      } else {
        result['errors']
            .add('Homebrew not found or librdkafka not installed via Homebrew');
      }

      // Check system path
      final systemPath = '/usr/local/lib/librdkafka.dylib';
      result['searchPaths'].add(systemPath);
      if (File(systemPath).existsSync()) {
        result['foundLibraries'].add(systemPath);
      }
    } else if (Platform.isLinux) {
      result['recommendations'].add(
          'Install using: sudo apt-get install librdkafka-dev (Ubuntu/Debian)');
      result['recommendations']
          .add('Or: sudo yum install librdkafka-devel (Red Hat/CentOS)');

      final linuxPath = _findLinuxLibrdkafka();
      if (linuxPath != null) {
        result['foundLibraries'].add(linuxPath);
      } else {
        result['errors'].add('librdkafka not found in common Linux paths');
      }
    } else if (Platform.isWindows) {
      result['recommendations']
          .add('Download and install librdkafka for Windows');

      final windowsPath = _findWindowsLibrdkafka();
      if (windowsPath != null) {
        result['foundLibraries'].add(windowsPath);
      } else {
        result['errors'].add('rdkafka.dll not found in common Windows paths');
      }
    }

    return result;
  }

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

      // Try to detect Homebrew installation via brew command
      try {
        final result = Process.runSync('brew', ['--prefix']);
        if (result.exitCode == 0) {
          final brewPrefix = result.stdout.toString().trim();
          if (brewPrefix.isNotEmpty &&
              Directory('$brewPrefix/lib').existsSync()) {
            final librdkafkaPath = '$brewPrefix/lib/librdkafka.dylib';
            if (File(librdkafkaPath).existsSync()) {
              return brewPrefix;
            }
          }
        }
      } catch (_) {
        // brew command not available or failed
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
    String? attemptedPaths = '';

    if (Platform.isLinux) {
      Exception? lastException;
      try {
        library = ffi.DynamicLibrary.open('librdkafka.so.1');
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attemptedPaths += 'librdkafka.so.1, ';
        try {
          library = ffi.DynamicLibrary.open('librdkafka.so');
        } catch (e2) {
          lastException = e2 is Exception ? e2 : Exception(e2.toString());
          attemptedPaths += 'librdkafka.so, ';
          // Try to find librdkafka dynamically
          final libPath = _findLinuxLibrdkafka();
          if (libPath != null) {
            try {
              library = ffi.DynamicLibrary.open(libPath);
            } catch (e3) {
              lastException = e3 is Exception ? e3 : Exception(e3.toString());
              attemptedPaths += '$libPath, ';
              throw Exception(
                  'Could not load librdkafka. Attempted paths: $attemptedPaths. Last error: $lastException. Please install librdkafka using: sudo apt-get install librdkafka-dev (Ubuntu/Debian) or equivalent for your distribution.');
            }
          } else {
            throw Exception(
                'Could not find librdkafka in any known location. Attempted paths: $attemptedPaths. Please install librdkafka using: sudo apt-get install librdkafka-dev (Ubuntu/Debian) or equivalent for your distribution.');
          }
        }
      }
    } else if (Platform.isMacOS) {
      Exception? lastException;
      try {
        library = ffi.DynamicLibrary.open('librdkafka.dylib');
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attemptedPaths += 'librdkafka.dylib, ';
        // Try to find Homebrew installation dynamically
        final homebrewPrefix = _getHomebrewPrefix();
        if (homebrewPrefix != null) {
          final homebrewPath = '$homebrewPrefix/lib/librdkafka.dylib';
          try {
            library = ffi.DynamicLibrary.open(homebrewPath);
          } catch (e2) {
            lastException = e2 is Exception ? e2 : Exception(e2.toString());
            attemptedPaths += '$homebrewPath, ';
            throw Exception(
                'Could not load librdkafka. Attempted paths: $attemptedPaths. Last error: $lastException. Please install librdkafka using: brew install librdkafka');
          }
        } else {
          throw Exception(
              'Could not find librdkafka in any known location. Attempted paths: $attemptedPaths. Please install librdkafka using: brew install librdkafka');
        }
      }
    } else if (Platform.isWindows) {
      Exception? lastException;
      try {
        library = ffi.DynamicLibrary.open('rdkafka.dll');
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attemptedPaths += 'rdkafka.dll, ';
        // Try to find rdkafka.dll dynamically
        final libPath = _findWindowsLibrdkafka();
        if (libPath != null) {
          try {
            library = ffi.DynamicLibrary.open(libPath);
          } catch (e2) {
            lastException = e2 is Exception ? e2 : Exception(e2.toString());
            attemptedPaths += '$libPath, ';
            throw Exception(
                'Could not load rdkafka.dll. Attempted paths: $attemptedPaths. Last error: $lastException. Please install librdkafka for Windows.');
          }
        } else {
          throw Exception(
              'Could not find rdkafka.dll in any known location. Attempted paths: $attemptedPaths. Please install librdkafka for Windows.');
        }
      }
    } else {
      throw UnsupportedError(
          'Platform ${Platform.operatingSystem} is not supported');
    }

    _bindings = RdkafkaBindings(library);

    // Validate that the bindings work by testing a basic function
    try {
      // Try to access a basic rd_kafka function to verify the library is loaded correctly
      _bindings!.rd_kafka_version();
    } catch (e) {
      throw Exception(
          'librdkafka library loaded but symbols are not accessible. This might indicate a version mismatch or corrupted installation. Error: $e');
    }

    return _bindings!;
  }

  static KafkaProducerService createProducer({
    required String bootstrapServers,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) {
    if (useMock) {
      final repository = SimpleKafkaProducerRepository();
      return KafkaProducerService(repository);
    }

    try {
      final repository = RdKafkaProducerRepository(_getBindings());
      return KafkaProducerService(repository);
    } catch (e) {
      throw Exception(
          'Failed to create Kafka producer: $e\n\nTroubleshooting:\n${_formatDiagnostics(diagnoseLibrdkafkaInstallation())}');
    }
  }

  static KafkaConsumerService createConsumer({
    required String bootstrapServers,
    required String groupId,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) {
    if (useMock) {
      final repository = SimpleKafkaConsumerRepository();
      return KafkaConsumerService(repository);
    }

    try {
      final repository = RdKafkaConsumerRepository(_getBindings());
      return KafkaConsumerService(repository);
    } catch (e) {
      throw Exception(
          'Failed to create Kafka consumer: $e\n\nTroubleshooting:\n${_formatDiagnostics(diagnoseLibrdkafkaInstallation())}');
    }
  }

  static String _formatDiagnostics(Map<String, dynamic> diagnostics) {
    final buffer = StringBuffer();
    buffer.writeln('Platform: ${diagnostics['platform']}');

    if (diagnostics['foundLibraries'].isNotEmpty) {
      buffer.writeln(
          'Found libraries: ${diagnostics['foundLibraries'].join(', ')}');
    } else {
      buffer.writeln('No librdkafka libraries found');
    }

    if (diagnostics['errors'].isNotEmpty) {
      buffer.writeln('Errors: ${diagnostics['errors'].join(', ')}');
    }

    if (diagnostics['recommendations'].isNotEmpty) {
      buffer.writeln(
          'Recommendations: ${diagnostics['recommendations'].join(', ')}');
    }

    return buffer.toString();
  }

  static Future<KafkaProducerService> createAndInitializeProducer({
    required String bootstrapServers,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) async {
    try {
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
    } catch (e) {
      throw Exception('Failed to create and initialize Kafka producer: $e');
    }
  }

  static Future<KafkaConsumerService> createAndInitializeConsumer({
    required String bootstrapServers,
    required String groupId,
    Map<String, String>? additionalProperties,
    bool useMock = false,
  }) async {
    try {
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
    } catch (e) {
      throw Exception('Failed to create and initialize Kafka consumer: $e');
    }
  }
}
