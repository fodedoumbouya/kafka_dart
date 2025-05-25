import 'package:test/test.dart';
import 'package:kafka_dart/src/domain/entities/kafka_configuration.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

void main() {
  group('KafkaConfiguration', () {
    group('Factory Constructors', () {
      group('create', () {
        test('should create empty configuration when no properties provided', () {
          final config = KafkaConfiguration.create();
          
          expect(config.allProperties, isEmpty);
          expect(config.isProducerConfig, isTrue);
          expect(config.isConsumerConfig, isFalse);
        });

        test('should create configuration with provided properties', () {
          final properties = {'key1': 'value1', 'key2': 'value2'};
          final config = KafkaConfiguration.create(properties);
          
          expect(config.getProperty('key1'), equals('value1'));
          expect(config.getProperty('key2'), equals('value2'));
          expect(config.allProperties.length, equals(2));
        });

        test('should create independent copy of properties map', () {
          final properties = {'key': 'value'};
          final config = KafkaConfiguration.create(properties);
          
          properties['key'] = 'modified';
          expect(config.getProperty('key'), equals('value'));
        });
      });

      group('producer', () {
        test('should create valid producer configuration', () {
          final config = KafkaConfiguration.producer(
            bootstrapServers: 'localhost:9092',
          );
          
          expect(config.getProperty('bootstrap.servers'), equals('localhost:9092'));
          expect(config.getProperty('client.id'), equals('kafka_dart_producer'));
          expect(config.getProperty('acks'), equals('all'));
          expect(config.getProperty('retries'), equals('3'));
          expect(config.getProperty('enable.idempotence'), equals('true'));
          expect(config.isProducerConfig, isTrue);
          expect(config.isConsumerConfig, isFalse);
        });

        test('should merge additional properties', () {
          final config = KafkaConfiguration.producer(
            bootstrapServers: 'localhost:9092',
            additionalProperties: {'custom.property': 'custom.value'},
          );
          
          expect(config.getProperty('bootstrap.servers'), equals('localhost:9092'));
          expect(config.getProperty('custom.property'), equals('custom.value'));
        });

        test('should allow overriding default properties', () {
          final config = KafkaConfiguration.producer(
            bootstrapServers: 'localhost:9092',
            additionalProperties: {'acks': '1', 'retries': '0'},
          );
          
          expect(config.getProperty('acks'), equals('1'));
          expect(config.getProperty('retries'), equals('0'));
        });

        test('should throw exception with empty bootstrap servers', () {
          expect(
            () => KafkaConfiguration.producer(bootstrapServers: ''),
            throwsA(isA<InvalidConfigurationException>()
                .having((e) => e.message, 'message', contains('cannot be empty'))),
          );
        });
      });

      group('consumer', () {
        test('should create valid consumer configuration', () {
          final config = KafkaConfiguration.consumer(
            bootstrapServers: 'localhost:9092',
            groupId: 'test-group',
          );
          
          expect(config.getProperty('bootstrap.servers'), equals('localhost:9092'));
          expect(config.getProperty('group.id'), equals('test-group'));
          expect(config.getProperty('client.id'), equals('kafka_dart_consumer'));
          expect(config.getProperty('auto.offset.reset'), equals('earliest'));
          expect(config.getProperty('enable.auto.commit'), equals('false'));
          expect(config.isConsumerConfig, isTrue);
          expect(config.isProducerConfig, isFalse);
        });

        test('should merge additional properties', () {
          final config = KafkaConfiguration.consumer(
            bootstrapServers: 'localhost:9092',
            groupId: 'test-group',
            additionalProperties: {'max.poll.records': '100'},
          );
          
          expect(config.getProperty('max.poll.records'), equals('100'));
        });

        test('should throw exception with empty bootstrap servers', () {
          expect(
            () => KafkaConfiguration.consumer(
              bootstrapServers: '',
              groupId: 'test-group',
            ),
            throwsA(isA<InvalidConfigurationException>()
                .having((e) => e.message, 'message', contains('cannot be empty'))),
          );
        });

        test('should throw exception with empty group id', () {
          expect(
            () => KafkaConfiguration.consumer(
              bootstrapServers: 'localhost:9092',
              groupId: '',
            ),
            throwsA(isA<InvalidConfigurationException>()
                .having((e) => e.message, 'message', contains('group.id cannot be empty'))),
          );
        });
      });
    });

    group('Validation', () {
      test('should validate bootstrap.servers is required', () {
        final config = KafkaConfiguration.create();
        
        expect(
          () => config.setProperty('group.id', 'test'),
          returnsNormally,
        );
      });

      test('should validate empty configuration key', () {
        final config = KafkaConfiguration.create();
        
        expect(
          () => config.setProperty('', 'value'),
          throwsA(isA<InvalidConfigurationException>()
              .having((e) => e.message, 'message', contains('key cannot be empty'))),
        );
      });

      test('should allow setting valid properties', () {
        final config = KafkaConfiguration.create();
        
        config.setProperty('bootstrap.servers', 'localhost:9092');
        config.setProperty('group.id', 'test-group');
        
        expect(config.getProperty('bootstrap.servers'), equals('localhost:9092'));
        expect(config.getProperty('group.id'), equals('test-group'));
      });
    });

    group('Property Management', () {
      test('should return null for non-existent property', () {
        final config = KafkaConfiguration.create();
        
        expect(config.getProperty('non.existent'), isNull);
      });

      test('should update existing property', () {
        final config = KafkaConfiguration.create({'key': 'old_value'});
        
        config.setProperty('key', 'new_value');
        
        expect(config.getProperty('key'), equals('new_value'));
      });

      test('should return unmodifiable properties map', () {
        final config = KafkaConfiguration.create({'key': 'value'});
        final properties = config.allProperties;
        
        expect(() => properties['new_key'] = 'new_value', throwsUnsupportedError);
      });

      test('should return correct properties count', () {
        final config = KafkaConfiguration.create();
        
        expect(config.allProperties.length, equals(0));
        
        config.setProperty('key1', 'value1');
        config.setProperty('key2', 'value2');
        
        expect(config.allProperties.length, equals(2));
      });
    });

    group('Configuration Type Detection', () {
      test('should detect producer configuration correctly', () {
        final config = KafkaConfiguration.create({'bootstrap.servers': 'localhost:9092'});
        
        expect(config.isProducerConfig, isTrue);
        expect(config.isConsumerConfig, isFalse);
      });

      test('should detect consumer configuration correctly', () {
        final config = KafkaConfiguration.create({
          'bootstrap.servers': 'localhost:9092',
          'group.id': 'test-group',
        });
        
        expect(config.isConsumerConfig, isTrue);
        expect(config.isProducerConfig, isFalse);
      });

      test('should update configuration type when group.id is added', () {
        final config = KafkaConfiguration.create({'bootstrap.servers': 'localhost:9092'});
        
        expect(config.isProducerConfig, isTrue);
        
        config.setProperty('group.id', 'test-group');
        
        expect(config.isConsumerConfig, isTrue);
        expect(config.isProducerConfig, isFalse);
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when properties are the same', () {
        final config1 = KafkaConfiguration.create({'key1': 'value1', 'key2': 'value2'});
        final config2 = KafkaConfiguration.create({'key1': 'value1', 'key2': 'value2'});
        
        expect(config1, equals(config2));
        // Equal objects must have equal hash codes
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final config1 = KafkaConfiguration.create({'key': 'value1'});
        final config2 = KafkaConfiguration.create({'key': 'value2'});
        
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when property count differs', () {
        final config1 = KafkaConfiguration.create({'key1': 'value1'});
        final config2 = KafkaConfiguration.create({'key1': 'value1', 'key2': 'value2'});
        
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when keys differ', () {
        final config1 = KafkaConfiguration.create({'key1': 'value'});
        final config2 = KafkaConfiguration.create({'key2': 'value'});
        
        expect(config1, isNot(equals(config2)));
      });

      test('should be equal to itself', () {
        final config = KafkaConfiguration.create({'key': 'value'});
        
        expect(config, equals(config));
      });

      test('should not be equal to null', () {
        final config = KafkaConfiguration.create({'key': 'value'});
        
        expect(config, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        final config = KafkaConfiguration.create({'key': 'value'});
        
        expect(config, isNot(equals('not a configuration')));
      });
    });

    group('String Representation', () {
      test('should include properties in toString', () {
        final config = KafkaConfiguration.create({'key1': 'value1', 'key2': 'value2'});
        final stringRepresentation = config.toString();
        
        expect(stringRepresentation, contains('KafkaConfiguration'));
        expect(stringRepresentation, contains('key1'));
        expect(stringRepresentation, contains('value1'));
        expect(stringRepresentation, contains('key2'));
        expect(stringRepresentation, contains('value2'));
      });

      test('should show empty map for empty configuration', () {
        final config = KafkaConfiguration.create();
        final stringRepresentation = config.toString();
        
        expect(stringRepresentation, equals('KafkaConfiguration({})'));
      });
    });

    group('Edge Cases', () {
      test('should handle properties with special characters', () {
        final config = KafkaConfiguration.create();
        
        config.setProperty('key.with.dots', 'value-with-dashes');
        config.setProperty('key_with_underscores', 'value with spaces');
        
        expect(config.getProperty('key.with.dots'), equals('value-with-dashes'));
        expect(config.getProperty('key_with_underscores'), equals('value with spaces'));
      });

      test('should handle empty property values', () {
        final config = KafkaConfiguration.create();
        
        config.setProperty('empty.key', '');
        
        expect(config.getProperty('empty.key'), equals(''));
      });

      test('should handle property overwriting', () {
        final config = KafkaConfiguration.create({'key': 'original'});
        
        config.setProperty('key', 'updated');
        config.setProperty('key', 'final');
        
        expect(config.getProperty('key'), equals('final'));
      });

      test('should maintain property order independence in equality', () {
        final config1 = KafkaConfiguration.create();
        config1.setProperty('a', '1');
        config1.setProperty('b', '2');
        
        final config2 = KafkaConfiguration.create();
        config2.setProperty('b', '2');
        config2.setProperty('a', '1');
        
        expect(config1, equals(config2));
      });
    });
  });
}