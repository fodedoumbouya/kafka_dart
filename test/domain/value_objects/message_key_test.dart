import 'package:test/test.dart';
import 'package:kafka_dart/src/domain/value_objects/message_key.dart';

void main() {
  group('MessageKey', () {
    group('Factory Constructors', () {
      group('create', () {
        test('should create message key with string value', () {
          final key = MessageKey.create('test-key');
          
          expect(key.value, equals('test-key'));
          expect(key.hasValue, isTrue);
        });

        test('should create message key with empty string', () {
          final key = MessageKey.create('');
          
          expect(key.value, equals(''));
          expect(key.hasValue, isTrue);
        });

        test('should create message key with special characters', () {
          final key = MessageKey.create('key-with_special.chars@123');
          
          expect(key.value, equals('key-with_special.chars@123'));
          expect(key.hasValue, isTrue);
        });

        test('should create message key with unicode characters', () {
          final key = MessageKey.create('ключ-測試-🔑');
          
          expect(key.value, equals('ключ-測試-🔑'));
          expect(key.hasValue, isTrue);
        });

        test('should create message key with very long string', () {
          final longKey = 'a' * 1000;
          final key = MessageKey.create(longKey);
          
          expect(key.value, equals(longKey));
          expect(key.hasValue, isTrue);
        });
      });

      group('none', () {
        test('should create message key with no value', () {
          final key = MessageKey.none();
          
          expect(key.value, isNull);
          expect(key.hasValue, isFalse);
        });

        test('should create multiple none keys with same behavior', () {
          final key1 = MessageKey.none();
          final key2 = MessageKey.none();
          
          expect(key1.hasValue, isFalse);
          expect(key2.hasValue, isFalse);
          expect(key1, equals(key2));
        });
      });
    });

    group('Properties', () {
      test('should return correct value for string key', () {
        final key = MessageKey.create('my-key');
        
        expect(key.value, equals('my-key'));
      });

      test('should return null for none key', () {
        final key = MessageKey.none();
        
        expect(key.value, isNull);
      });

      test('should correctly identify key with value', () {
        final key = MessageKey.create('test');
        
        expect(key.hasValue, isTrue);
      });

      test('should correctly identify key without value', () {
        final key = MessageKey.none();
        
        expect(key.hasValue, isFalse);
      });

      test('should identify empty string as having value', () {
        final key = MessageKey.create('');
        
        expect(key.hasValue, isTrue);
        expect(key.value, equals(''));
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when string values are the same', () {
        final key1 = MessageKey.create('same-key');
        final key2 = MessageKey.create('same-key');
        
        expect(key1, equals(key2));
        expect(key1.hashCode, equals(key2.hashCode));
      });

      test('should not be equal when string values differ', () {
        final key1 = MessageKey.create('key1');
        final key2 = MessageKey.create('key2');
        
        expect(key1, isNot(equals(key2)));
      });

      test('should be equal for none keys', () {
        final key1 = MessageKey.none();
        final key2 = MessageKey.none();
        
        expect(key1, equals(key2));
        expect(key1.hashCode, equals(key2.hashCode));
      });

      test('should not be equal between string and none key', () {
        final stringKey = MessageKey.create('test');
        final noneKey = MessageKey.none();
        
        expect(stringKey, isNot(equals(noneKey)));
      });

      test('should handle null value equality correctly', () {
        final key1 = MessageKey.none();
        final key2 = MessageKey.none();
        
        expect(key1.value, isNull);
        expect(key2.value, isNull);
        expect(key1, equals(key2));
      });

      test('should be equal to itself', () {
        final key = MessageKey.create('test-key');
        
        expect(key, equals(key));
      });

      test('should not be equal to null', () {
        final key = MessageKey.create('test-key');
        
        expect(key, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        final key = MessageKey.create('test-key');
        
        expect(key, isNot(equals('test-key')));
        expect(key, isNot(equals(123)));
      });

      test('should handle hash code for null values', () {
        final key1 = MessageKey.none();
        final key2 = MessageKey.none();
        
        // Both should have the same hash code (null.hashCode)
        expect(key1.hashCode, equals(key2.hashCode));
      });
    });

    group('String Representation', () {
      test('should show key value for string key', () {
        final key = MessageKey.create('my-test-key');
        
        expect(key.toString(), equals('MessageKey(my-test-key)'));
      });

      test('should show NONE for none key', () {
        final key = MessageKey.none();
        
        expect(key.toString(), equals('MessageKey(NONE)'));
      });

      test('should show empty string correctly', () {
        final key = MessageKey.create('');
        
        expect(key.toString(), equals('MessageKey()'));
      });

      test('should handle special characters in toString', () {
        final key = MessageKey.create('key@#\$%^&*()');
        
        expect(key.toString(), equals('MessageKey(key@#\$%^&*())'));
      });

      test('should handle unicode characters in toString', () {
        final key = MessageKey.create('测试🔑');
        
        expect(key.toString(), equals('MessageKey(测试🔑)'));
      });
    });

    group('Edge Cases', () {
      test('should handle very long key values', () {
        final longKey = 'x' * 10000;
        final key = MessageKey.create(longKey);
        
        expect(key.value, equals(longKey));
        expect(key.hasValue, isTrue);
        expect(key.toString(), contains('MessageKey($longKey)'));
      });

      test('should handle whitespace-only keys', () {
        final key = MessageKey.create('   \t\n  ');
        
        expect(key.value, equals('   \t\n  '));
        expect(key.hasValue, isTrue);
      });

      test('should maintain immutability', () {
        final key = MessageKey.create('immutable-key');
        final originalValue = key.value;
        
        // Accessing value multiple times should return same result
        expect(key.value, equals(originalValue));
        expect(key.value, equals('immutable-key'));
      });

      test('should handle numeric string keys', () {
        final key = MessageKey.create('123456');
        
        expect(key.value, equals('123456'));
        expect(key.hasValue, isTrue);
      });

      test('should handle boolean string keys', () {
        final trueKey = MessageKey.create('true');
        final falseKey = MessageKey.create('false');
        
        expect(trueKey.value, equals('true'));
        expect(falseKey.value, equals('false'));
        expect(trueKey.hasValue, isTrue);
        expect(falseKey.hasValue, isTrue);
      });
    });

    group('Type Safety', () {
      test('should maintain type identity', () {
        final key = MessageKey.create('test');
        
        expect(key, isA<MessageKey>());
        expect(key.runtimeType, equals(MessageKey));
      });

      test('should work with collections', () {
        final keys = [
          MessageKey.create('key1'),
          MessageKey.create('key2'),
          MessageKey.none(),
        ];
        
        expect(keys.length, equals(3));
        expect(keys[0].value, equals('key1'));
        expect(keys[1].value, equals('key2'));
        expect(keys[2].hasValue, isFalse);
      });

      test('should work as map keys', () {
        final keyMap = <MessageKey, String>{
          MessageKey.create('user1'): 'User One',
          MessageKey.create('user2'): 'User Two',
          MessageKey.none(): 'Anonymous',
        };
        
        expect(keyMap[MessageKey.create('user1')], equals('User One'));
        expect(keyMap[MessageKey.create('user2')], equals('User Two'));
        expect(keyMap[MessageKey.none()], equals('Anonymous'));
      });

      test('should work in sets', () {
        final keySet = {
          MessageKey.create('unique1'),
          MessageKey.create('unique2'),
          MessageKey.create('unique1'), // duplicate
          MessageKey.none(),
          MessageKey.none(), // duplicate
        };
        
        expect(keySet.length, equals(3)); // duplicates removed
      });
    });

    group('Null Safety', () {
      test('should handle null value correctly in none key', () {
        final key = MessageKey.none();
        
        expect(key.value, isNull);
        expect(key.value == null, isTrue);
        expect(key.hasValue, isFalse);
      });

      test('should differentiate between null and empty string', () {
        final noneKey = MessageKey.none();
        final emptyKey = MessageKey.create('');
        
        expect(noneKey.value, isNull);
        expect(emptyKey.value, equals(''));
        expect(noneKey.hasValue, isFalse);
        expect(emptyKey.hasValue, isTrue);
        expect(noneKey, isNot(equals(emptyKey)));
      });
    });
  });
}