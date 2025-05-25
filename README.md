# Kafka Dart

[![Pub Version](https://img.shields.io/pub/v/kafka_dart.svg)](https://pub.dev/packages/kafka_dart)
[![Dart SDK](https://img.shields.io/badge/Dart-3.8%2B-blue.svg)](https://dart.dev)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square)](LICENSE)
[![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen.svg)](https://github.com/stefanoamorelli/kafka_dart)
[![FFI Support](https://img.shields.io/badge/FFI-librdkafka-orange.svg)](https://github.com/confluentinc/librdkafka)

A high-performance Kafka client for Dart using `librdkafka` with _Domain-Driven Design_ architecture. Supports both mock implementations for testing and real Kafka connectivity via `FFI` bindings.

## 🚀 Features

<img src="https://github.com/user-attachments/assets/37039b59-4c5c-42d7-bff6-28b021120b8c"
     alt="dart-kafka" align="right" width="250">

- **🔒 Type-safe**: Strong typing with value objects and domain entities  
- **🏗️ Clean Architecture**: Domain-Driven Design with layered architecture  
- **⚠️ Error Handling**: Comprehensive exception hierarchy with meaningful error messages  
- **🧪 Testable**: Clean separation of concerns enables easy unit testing with mocks  
- **⚡ High Performance**: Built on librdkafka FFI bindings for production use  
- **🎯 Simple API**: Easy-to-use factory methods and service classes  
- **🐳 Docker Ready**: Includes Docker Compose setup for local development  
- **📊 Full Coverage**: 98 % test coverage with comprehensive test suite


## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kafka_dart: ^1.0.0
```

Then run:

```bash
dart pub get
```

### Prerequisites

You need to install librdkafka on your system:

**Ubuntu/Debian:**
```bash
sudo apt-get install librdkafka-dev
```

**Fedora/RHEL:**
```bash
sudo dnf install librdkafka-devel
```

**macOS:**
```bash
brew install librdkafka
```

## 🚀 Quick Start

### Producer Example

```dart
import 'package:kafka_dart/kafka_dart.dart';

Future<void> main() async {
  // For real Kafka connectivity
  final producer = await KafkaFactory.createAndInitializeProducer(
    bootstrapServers: 'localhost:9092',
    useMock: false, // Use real librdkafka FFI bindings
  );

  try {
    await producer.sendMessage(
      topic: 'my-topic',
      payload: 'Hello, Kafka!',
      key: 'message-key',
    );
    await producer.flush();
    print('✅ Message sent to Kafka!');
  } finally {
    await producer.close();
  }
}
```

### Consumer Example

```dart
import 'package:kafka_dart/kafka_dart.dart';

Future<void> main() async {
  // For real Kafka connectivity  
  final consumer = await KafkaFactory.createAndInitializeConsumer(
    bootstrapServers: 'localhost:9092',
    groupId: 'my-consumer-group',
    useMock: false, // Use real librdkafka FFI bindings
  );

  try {
    await consumer.subscribe(['my-topic']);
    
    for (int i = 0; i < 10; i++) {
      final message = await consumer.pollMessage();
      if (message != null) {
        print('📨 Received: ${message.payload.value}');
        print('🔑 Key: ${message.key.hasValue ? message.key.value : 'null'}');
        await consumer.commitAsync();
      }
      await Future.delayed(Duration(seconds: 1));
    }
  } finally {
    await consumer.close();
  }
}
```

### Testing with Mocks

```dart
import 'package:kafka_dart/kafka_dart.dart';

Future<void> main() async {
  // For testing - uses mock implementation
  final producer = await KafkaFactory.createAndInitializeProducer(
    bootstrapServers: 'localhost:9092',
    useMock: true, // Safe for testing
  );

  try {
    await producer.sendMessage(
      topic: 'test-topic',
      payload: 'Test message',
      key: 'test-key',
    );
    print('✅ Mock message sent!');
  } finally {
    await producer.close();
  }
}
```

## 🏗️ Architecture

This library follows Domain-Driven Design principles with a clean, layered architecture:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│      (Public API & Factories)       │
├─────────────────────────────────────┤
│         Application Layer           │
│     (Services & Use Cases)          │
├─────────────────────────────────────┤
│           Domain Layer              │
│   (Entities, Value Objects, etc.)   │
├─────────────────────────────────────┤
│        Infrastructure Layer         │
│   (FFI Bindings & Repositories)     │
└─────────────────────────────────────┘
```

### Layers

- **🎨 Presentation Layer**: Public API and factory classes
- **⚙️ Application Layer**: Use cases and application services  
- **🧠 Domain Layer**: Core business logic with entities, value objects, and repository interfaces
- **🔧 Infrastructure Layer**: FFI bindings to librdkafka and repository implementations

## 🛠️ Development & Testing

This project includes a comprehensive Makefile for common development tasks:

### Testing Commands
```bash
make test              # Run all tests (uses mocks)
make test-coverage     # Run tests with coverage (excludes infrastructure)
make coverage-html     # Generate HTML coverage report and open in browser
make lint              # Run Dart analyzer
```

### Development Commands
```bash
make docs              # Generate API documentation
make generate          # Regenerate FFI bindings from librdkafka
make clean             # Clean coverage files
```

### Kafka Development Environment
```bash
make kafka-setup       # Start Kafka + create test topics + open UI
make kafka-up          # Start Kafka cluster only
make kafka-down        # Stop Kafka cluster
```

The Kafka setup includes:
- **Kafka broker** on `localhost:9092`
- **Kafka UI** on `http://localhost:8080` for monitoring
- **Pre-created topics** for testing

## 📊 Testing

### Automated Testing
```bash
# Run all unit tests (213 tests, 98% coverage)
make test

# Generate coverage report  
make test-coverage
make coverage-html
```

All tests use mock implementations for safety and speed. The test suite covers:
- Domain entities and value objects
- Application services
- Repository interfaces
- Integration scenarios

### Manual Testing with Real Kafka

**1. Start Kafka environment:**
```bash
make kafka-setup
```

**2. Test with real FFI bindings:**
```bash
dart run example/real_kafka_test.dart
```

**3. Monitor with Kafka UI:**
Visit http://localhost:8080

**4. Use Kafka CLI tools:**
```bash
# Send messages
docker exec -it kafka kafka-console-producer --topic test-topic --bootstrap-server localhost:9092

# Read messages  
docker exec -it kafka kafka-console-consumer --topic test-topic --from-beginning --bootstrap-server localhost:9092
```

## 📈 Coverage

Current test coverage: **98%**

Coverage excludes:
- **FFI bindings** (auto-generated from librdkafka)
- **Infrastructure adapters** (tested through integration)

Generate coverage reports:
```bash
make test-coverage    # Generate lcov.info
make coverage-html    # Generate HTML report and open
```

## 🔄 Implementation Modes

### Mock Mode (Default for Testing)
```dart
final producer = await KafkaFactory.createAndInitializeProducer(
  bootstrapServers: 'localhost:9092',
  useMock: true, // Safe, no external dependencies
);
```

### Real Kafka Mode (Production)
```dart  
final producer = await KafkaFactory.createAndInitializeProducer(
  bootstrapServers: 'localhost:9092',
  useMock: false, // Uses librdkafka FFI bindings
);
```

The factory automatically chooses the appropriate repository implementation based on the `useMock` parameter.

## 🛠️ Project Structure

```
lib/
├── src/
│   ├── application/         # Application services
│   │   └── services/        # Kafka producer/consumer services
│   ├── domain/             # Domain layer
│   │   ├── entities/       # Domain entities
│   │   ├── value_objects/  # Value objects
│   │   ├── repositories/   # Repository interfaces
│   │   └── exceptions/     # Domain exceptions
│   ├── infrastructure/     # Infrastructure layer
│   │   ├── bindings/       # FFI bindings to librdkafka
│   │   ├── repositories/   # Repository implementations
│   │   └── factories/      # Service factories
│   └── presentation/       # Public API (future)
└── kafka_dart.dart        # Main export file

example/
├── real_kafka_test.dart    # Real Kafka testing
├── manual_kafka_test.dart  # Manual testing with mocks
└── ...

test/                       # Comprehensive test suite
├── integration_test.dart   # Integration tests (mocks)
├── domain/                 # Domain layer tests
├── application/            # Application layer tests
└── ...

docker-compose.yml          # Kafka development environment
Makefile                   # Development commands
scripts/setup-kafka.sh     # Kafka setup automation
```

## 🔧 FFI Implementation

The library includes full FFI bindings to librdkafka:

**Producer Features:**
- ✅ Message sending with keys and headers
- ✅ Partition selection (specific or automatic)
- ✅ Synchronous flushing
- ✅ Proper resource cleanup

**Consumer Features:**
- ✅ Topic subscription
- ✅ Message polling with timeout
- ✅ Offset management (sync/async commits)
- ✅ Consumer group coordination

**Configuration:**
- Uses librdkafka-compatible properties
- Automatic platform detection (Linux/macOS/Windows)
- Error handling with meaningful exceptions

## 📚 Examples

See the [`/example`](./example) folder for complete working examples:

- [`real_kafka_test.dart`](./example/real_kafka_test.dart) - Real FFI implementation test
- [`manual_kafka_test.dart`](./example/manual_kafka_test.dart) - Mock implementation test
- [`producer_example.dart`](./example/producer_example.dart) - Producer patterns
- [`consumer_example.dart`](./example/consumer_example.dart) - Consumer patterns

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`make test`)
4. Run linting (`make lint`)
5. Test with real Kafka (`make kafka-setup && dart run example/real_kafka_test.dart`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Development Guidelines

- All new features must include tests
- Use mock implementations in unit tests
- Test real implementations manually with Docker Kafka
- Follow Domain-Driven Design principles
- Maintain 95%+ test coverage

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

Copyright 2025 © [Stefano Amorelli](https://amorelli.tech/)

## 🙏 Acknowledgments

- Built on top of [librdkafka](https://github.com/confluentinc/librdkafka) - the high-performance C/C++ Kafka client;
- Inspired by Domain-Driven Design principles;
- Thanks to the [Dart FFI](https://pub.dev/packages/ffi) contributors for excellent tooling;
- Thanks to the [Kafka community](https://forum.confluent.io/) for robust ecosystem.

## 🔗 Links

- **Package**: https://pub.dev/packages/kafka_dart  
- **Repository**: https://github.com/stefanoamorelli/kafka_dart
- **Issues**: https://github.com/stefanoamorelli/kafka_dart/issues
- **librdkafka**: https://github.com/confluentinc/librdkafka
- **Kafka Documentation**: https://kafka.apache.org/documentation/
