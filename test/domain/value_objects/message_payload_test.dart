import 'package:test/test.dart';
import 'package:kafka_dart/src/domain/value_objects/message_payload.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

void main() {
  group('MessagePayload', () {
    group('Factory Constructor', () {
      test('should create payload with valid string', () {
        final payload = MessagePayload.create('test message');
        
        expect(payload.value, equals('test message'));
        expect(payload.sizeInBytes, equals(12));
      });

      test('should create payload with single character', () {
        final payload = MessagePayload.create('a');
        
        expect(payload.value, equals('a'));
        expect(payload.sizeInBytes, equals(1));
      });

      test('should throw exception with empty string', () {
        expect(
          () => MessagePayload.create(''),
          throwsA(isA<InvalidMessagePayloadException>()
              .having((e) => e.message, 'message', contains('cannot be empty'))),
        );
      });

      test('should create payload with whitespace-only content', () {
        final payload = MessagePayload.create('   ');
        
        expect(payload.value, equals('   '));
        expect(payload.sizeInBytes, equals(3));
      });

      test('should create payload with special characters', () {
        final payload = MessagePayload.create('Hello @#\\\$%^&*()');
        
        expect(payload.value, equals('Hello @#\\\$%^&*()'));
        expect(payload.sizeInBytes, equals(16));
      });

      test('should create payload with unicode characters', () {
        final payload = MessagePayload.create('测试消息 🚀');
        
        expect(payload.value, equals('测试消息 🚀'));
        // Note: Unicode characters may have different byte lengths
        expect(payload.sizeInBytes, greaterThan(0));
      });

      test('should create payload with newlines and tabs', () {
        final payload = MessagePayload.create('line1\nline2\tcolumn');
        
        expect(payload.value, equals('line1\nline2\tcolumn'));
        expect(payload.sizeInBytes, equals(18));
      });

      test('should create payload with very long string', () {
        final longMessage = 'x' * 10000;
        final payload = MessagePayload.create(longMessage);
        
        expect(payload.value, equals(longMessage));
        expect(payload.sizeInBytes, equals(10000));
      });
    });

    group('Properties', () {
      test('should return correct value', () {
        final payload = MessagePayload.create('my message');
        
        expect(payload.value, equals('my message'));
      });

      test('should calculate size correctly for ASCII characters', () {
        final payload = MessagePayload.create('Hello World');
        
        expect(payload.sizeInBytes, equals(11));
      });

      test('should calculate size for single character', () {
        final payload = MessagePayload.create('A');
        
        expect(payload.sizeInBytes, equals(1));
      });

      test('should calculate size for numeric strings', () {
        final payload = MessagePayload.create('123456789');
        
        expect(payload.sizeInBytes, equals(9));
      });

      test('should calculate size for mixed content', () {
        final payload = MessagePayload.create('Text123!@#');
        
        expect(payload.sizeInBytes, equals(10));
      });
    });

    group('Validation', () {
      test('should reject empty string consistently', () {
        expect(() => MessagePayload.create(''), throwsA(isA<InvalidMessagePayloadException>()));
      });

      test('should accept minimal valid content', () {
        final payload = MessagePayload.create(' '); // single space
        
        expect(payload.value, equals(' '));
        expect(payload.sizeInBytes, equals(1));
      });

      test('should maintain validation across multiple calls', () {
        expect(() => MessagePayload.create(''), throwsA(isA<InvalidMessagePayloadException>()));
        expect(() => MessagePayload.create(''), throwsA(isA<InvalidMessagePayloadException>()));
        
        final validPayload = MessagePayload.create('valid');
        expect(validPayload.value, equals('valid'));
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when values are the same', () {
        final payload1 = MessagePayload.create('same message');
        final payload2 = MessagePayload.create('same message');
        
        expect(payload1, equals(payload2));
        expect(payload1.hashCode, equals(payload2.hashCode));
      });

      test('should not be equal when values differ', () {
        final payload1 = MessagePayload.create('message one');
        final payload2 = MessagePayload.create('message two');
        
        expect(payload1, isNot(equals(payload2)));
      });

      test('should be equal to itself', () {
        final payload = MessagePayload.create('test message');
        
        expect(payload, equals(payload));
      });

      test('should not be equal to null', () {
        final payload = MessagePayload.create('test message');
        
        expect(payload, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        final payload = MessagePayload.create('test message');
        
        expect(payload, isNot(equals('test message')));
        expect(payload, isNot(equals(123)));
      });

      test('should have consistent hash codes for same content', () {
        final payload1 = MessagePayload.create('consistent');
        final payload2 = MessagePayload.create('consistent');
        
        expect(payload1.hashCode, equals(payload2.hashCode));
        expect(payload1.hashCode, equals(payload1.hashCode)); // consistent with itself
      });
    });

    group('String Representation', () {
      test('should show size in bytes for small payload', () {
        final payload = MessagePayload.create('hello');
        
        expect(payload.toString(), equals('MessagePayload(5 bytes)'));
      });

      test('should show size in bytes for large payload', () {
        final longMessage = 'a' * 1000;
        final payload = MessagePayload.create(longMessage);
        
        expect(payload.toString(), equals('MessagePayload(1000 bytes)'));
      });

      test('should show size for single character', () {
        final payload = MessagePayload.create('x');
        
        expect(payload.toString(), equals('MessagePayload(1 bytes)'));
      });

      test('should show size for unicode content', () {
        final payload = MessagePayload.create('🚀');
        final size = payload.sizeInBytes;
        
        expect(payload.toString(), equals('MessagePayload($size bytes)'));
      });

      test('should not expose actual content in toString', () {
        final payload = MessagePayload.create('secret content');
        final stringRep = payload.toString();
        
        expect(stringRep, isNot(contains('secret content')));
        expect(stringRep, contains('bytes'));
      });
    });

    group('Edge Cases', () {
      test('should handle maximum length strings', () {
        final maxMessage = 'x' * 100000; // Very long string
        final payload = MessagePayload.create(maxMessage);
        
        expect(payload.value, equals(maxMessage));
        expect(payload.sizeInBytes, equals(100000));
      });

      test('should maintain immutability', () {
        final payload = MessagePayload.create('immutable');
        final originalValue = payload.value;
        final originalSize = payload.sizeInBytes;
        
        // Accessing properties multiple times should return same results
        expect(payload.value, equals(originalValue));
        expect(payload.sizeInBytes, equals(originalSize));
        expect(payload.value, equals('immutable'));
        expect(payload.sizeInBytes, equals(9));
      });

      test('should handle JSON-like content', () {
        final jsonContent = '{"key": "value", "number": 123}';
        final payload = MessagePayload.create(jsonContent);
        
        expect(payload.value, equals(jsonContent));
        expect(payload.sizeInBytes, equals(jsonContent.length));
      });

      test('should handle XML-like content', () {
        final xmlContent = '<root><item>value</item></root>';
        final payload = MessagePayload.create(xmlContent);
        
        expect(payload.value, equals(xmlContent));
        expect(payload.sizeInBytes, equals(xmlContent.length));
      });

      test('should handle escaped characters', () {
        final escapedContent = 'line1\\nline2\\ttab';
        final payload = MessagePayload.create(escapedContent);
        
        expect(payload.value, equals(escapedContent));
        expect(payload.sizeInBytes, equals(escapedContent.length));
      });
    });

    group('Type Safety', () {
      test('should maintain type identity', () {
        final payload = MessagePayload.create('test');
        
        expect(payload, isA<MessagePayload>());
        expect(payload.runtimeType, equals(MessagePayload));
      });

      test('should work with collections', () {
        final payloads = [
          MessagePayload.create('message1'),
          MessagePayload.create('message2'),
          MessagePayload.create('message3'),
        ];
        
        expect(payloads.length, equals(3));
        expect(payloads[0].value, equals('message1'));
        expect(payloads[1].value, equals('message2'));
        expect(payloads[2].value, equals('message3'));
      });

      test('should work as map keys', () {
        final payloadMap = <MessagePayload, String>{
          MessagePayload.create('key1'): 'value1',
          MessagePayload.create('key2'): 'value2',
        };
        
        expect(payloadMap[MessagePayload.create('key1')], equals('value1'));
        expect(payloadMap[MessagePayload.create('key2')], equals('value2'));
      });

      test('should work in sets', () {
        final payloadSet = {
          MessagePayload.create('unique1'),
          MessagePayload.create('unique2'),
          MessagePayload.create('unique1'), // duplicate
        };
        
        expect(payloadSet.length, equals(2)); // duplicate removed
      });
    });

    group('Size Calculations', () {
      test('should accurately measure ASCII content', () {
        final testCases = [
          ('a', 1),
          ('ab', 2),
          ('hello', 5),
          ('Hello World!', 12),
          ('1234567890', 10),
        ];
        
        for (final (content, expectedSize) in testCases) {
          final payload = MessagePayload.create(content);
          expect(payload.sizeInBytes, equals(expectedSize), 
                 reason: 'Size mismatch for content: "$content"');
        }
      });

      test('should handle special whitespace characters', () {
        final payload = MessagePayload.create(' \t\n\r');
        
        expect(payload.sizeInBytes, equals(4));
      });

      test('should measure size independently of content type', () {
        final binaryLikeContent = '\x00\x01\x02\x03';
        final payload = MessagePayload.create(binaryLikeContent);
        
        expect(payload.sizeInBytes, equals(4));
        expect(payload.value, equals(binaryLikeContent));
      });
    });
  });
}