# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-05-26

### 🎉 Initial Release

A high-performance Kafka client for Dart with Domain-Driven Design architecture and full librdkafka FFI bindings.

### ✨ Added

#### Core Features
- **Domain-Driven Design Architecture** with clean layered separation
- **Type-safe API** with strong typing using value objects and domain entities
- **Comprehensive error handling** with meaningful exception hierarchy
- **95% test coverage** with 213 automated tests

#### Kafka Connectivity
- **Real Kafka support** via librdkafka FFI bindings
- **Mock implementations** for safe testing without external dependencies
- **Dual-mode factory** supporting both real (`useMock: false`) and mock (`useMock: true`) implementations
- **Cross-platform support** for Linux, macOS, and Windows

#### Producer Features
- Message sending with configurable keys and payloads
- Partition selection (specific or automatic)
- Synchronous message flushing
- Proper resource cleanup and connection management

#### Consumer Features
- Topic subscription with consumer groups
- Message polling with configurable timeouts
- Offset management (synchronous and asynchronous commits)
- Consumer group coordination

#### Development Environment
- **Docker Compose setup** for local Kafka development
- **Kafka UI integration** for monitoring and debugging
- **Automated setup scripts** for one-command Kafka environment
- **Pre-configured test topics** for immediate development

#### Testing Infrastructure
- **Comprehensive test suite** covering all layers
- **Integration tests** with mock implementations
- **Manual testing examples** for real Kafka verification
- **Coverage reporting** with HTML output and exclusions for generated code

#### Build and Development Tools
- **Comprehensive Makefile** with all development commands
- **FFI binding generation** from librdkafka headers
- **Documentation generation** with dart doc
- **Linting and analysis** integration
- **Coverage reporting** with lcov and HTML output

### 🛠️ Infrastructure

#### Project Structure
- `lib/src/application/` - Application services and use cases
- `lib/src/domain/` - Domain entities, value objects, and repository interfaces
- `lib/src/infrastructure/` - FFI bindings and repository implementations
- `example/` - Working examples for both mock and real implementations
- `test/` - Comprehensive test suite with 95% coverage
- `scripts/` - Kafka setup and development automation
- `docker-compose.yml` - Local Kafka development environment

#### Configuration Management
- librdkafka-compatible configuration properties
- Automatic platform detection and library loading
- Consumer and producer specific configuration validation
- Support for additional custom properties

#### Error Handling
- `KafkaDomainException` base class with cause tracking
- Specific exceptions: `ProducerException`, `ConsumerException`, `InvalidTopicException`, etc.
- Meaningful error messages with context
- Proper exception propagation through all layers

### 📚 Documentation

- **Comprehensive README** with setup, usage, and development instructions
- **Architecture documentation** with layer explanations
- **API examples** for both producer and consumer patterns
- **Testing guidelines** with mock and real implementation strategies
- **Contributing guidelines** with development workflow
- **Makefile documentation** for all available commands

### 🔧 Development Experience

#### Available Make Commands
```bash
# Testing
make test              # Run all tests (213 tests, uses mocks)
make test-coverage     # Generate coverage report (95% coverage)
make coverage-html     # Generate and open HTML coverage report
make lint              # Run Dart analyzer

# Development
make docs              # Generate API documentation
make generate          # Regenerate FFI bindings
make clean             # Clean generated files

# Kafka Environment
make kafka-setup       # Start Kafka + UI + create topics
make kafka-up          # Start Kafka cluster
make kafka-down        # Stop Kafka cluster
```

#### Example Files
- `example/real_kafka_test.dart` - Real FFI implementation testing
- `example/manual_kafka_test.dart` - Mock implementation testing
- `example/producer_example.dart` - Producer usage patterns
- `example/consumer_example.dart` - Consumer usage patterns

### 🎯 Usage Examples

#### Producer (Real Kafka)
```dart
final producer = await KafkaFactory.createAndInitializeProducer(
  bootstrapServers: 'localhost:9092',
  useMock: false, // Use real librdkafka FFI bindings
);
await producer.sendMessage(topic: 'my-topic', payload: 'Hello!');
```

#### Consumer (Real Kafka)
```dart
final consumer = await KafkaFactory.createAndInitializeConsumer(
  bootstrapServers: 'localhost:9092',
  groupId: 'my-group',
  useMock: false, // Use real librdkafka FFI bindings
);
await consumer.subscribe(['my-topic']);
final message = await consumer.pollMessage();
```

#### Testing (Mock Implementation)
```dart
final producer = await KafkaFactory.createAndInitializeProducer(
  bootstrapServers: 'localhost:9092',
  useMock: true, // Safe for testing
);
```

### 🧪 Verified Compatibility

- **Dart SDK**: 3.8+
- **librdkafka**: Compatible with standard distributions
- **Platforms**: Linux (tested on Fedora 40), macOS, Windows
- **Kafka**: Compatible with Apache Kafka 2.8+ via librdkafka
- **Docker**: Tested with Confluent Platform 7.4.0

### 📊 Metrics

- **213 tests** with 95% code coverage
- **Zero compilation warnings** with strict analysis options
- **Zero runtime errors** in comprehensive test suite
- **Fast test execution** with mock implementations
- **Real Kafka integration** verified with Docker environment

### 🔗 Links

- **Package**: https://pub.dev/packages/kafka_dart  
- **Repository**: https://github.com/stefanoamorelli/kafka_dart
- **Issues**: https://github.com/stefanoamorelli/kafka_dart/issues
- **librdkafka**: https://github.com/confluentinc/librdkafka