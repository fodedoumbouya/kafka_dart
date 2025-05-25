import 'package:test/test.dart';
import 'package:kafka_dart/src/domain/value_objects/partition.dart';
import 'package:kafka_dart/src/domain/exceptions/domain_exceptions.dart';

void main() {
  group('Partition', () {
    group('Factory Constructors', () {
      group('create', () {
        test('should create partition with valid positive number', () {
          final partition = Partition.create(5);
          
          expect(partition.value, equals(5));
          expect(partition.isAnyPartition, isFalse);
        });

        test('should create partition with zero', () {
          final partition = Partition.create(0);
          
          expect(partition.value, equals(0));
          expect(partition.isAnyPartition, isFalse);
        });

        test('should throw exception with negative partition number', () {
          expect(
            () => Partition.create(-1),
            throwsA(isA<InvalidPartitionException>()
                .having((e) => e.message, 'message', contains('cannot be negative'))),
          );
        });

        test('should throw exception with large negative number', () {
          expect(
            () => Partition.create(-100),
            throwsA(isA<InvalidPartitionException>()
                .having((e) => e.message, 'message', contains('cannot be negative'))),
          );
        });

        test('should handle large positive partition numbers', () {
          final partition = Partition.create(999999);
          
          expect(partition.value, equals(999999));
          expect(partition.isAnyPartition, isFalse);
        });
      });

      group('any', () {
        test('should create any partition with special value', () {
          final partition = Partition.any();
          
          expect(partition.value, equals(-1));
          expect(partition.isAnyPartition, isTrue);
        });

        test('should create multiple any partitions with same behavior', () {
          final partition1 = Partition.any();
          final partition2 = Partition.any();
          
          expect(partition1.isAnyPartition, isTrue);
          expect(partition2.isAnyPartition, isTrue);
          expect(partition1, equals(partition2));
        });
      });
    });

    group('Properties', () {
      test('should return correct value for regular partition', () {
        final partition = Partition.create(42);
        
        expect(partition.value, equals(42));
      });

      test('should return -1 for any partition', () {
        final partition = Partition.any();
        
        expect(partition.value, equals(-1));
      });

      test('should correctly identify regular partition', () {
        final partition = Partition.create(10);
        
        expect(partition.isAnyPartition, isFalse);
      });

      test('should correctly identify any partition', () {
        final partition = Partition.any();
        
        expect(partition.isAnyPartition, isTrue);
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when partition numbers are the same', () {
        final partition1 = Partition.create(5);
        final partition2 = Partition.create(5);
        
        expect(partition1, equals(partition2));
        expect(partition1.hashCode, equals(partition2.hashCode));
      });

      test('should not be equal when partition numbers differ', () {
        final partition1 = Partition.create(5);
        final partition2 = Partition.create(10);
        
        expect(partition1, isNot(equals(partition2)));
      });

      test('should be equal for any partitions', () {
        final partition1 = Partition.any();
        final partition2 = Partition.any();
        
        expect(partition1, equals(partition2));
        expect(partition1.hashCode, equals(partition2.hashCode));
      });

      test('should not be equal between regular and any partition', () {
        final regularPartition = Partition.create(0);
        final anyPartition = Partition.any();
        
        expect(regularPartition, isNot(equals(anyPartition)));
      });

      test('should be equal to itself', () {
        final partition = Partition.create(7);
        
        expect(partition, equals(partition));
      });

      test('should not be equal to null', () {
        final partition = Partition.create(7);
        
        expect(partition, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        final partition = Partition.create(7);
        
        expect(partition, isNot(equals(7)));
        expect(partition, isNot(equals('Partition(7)')));
      });
    });

    group('String Representation', () {
      test('should show partition number for regular partition', () {
        final partition = Partition.create(42);
        
        expect(partition.toString(), equals('Partition(42)'));
      });

      test('should show ANY for any partition', () {
        final partition = Partition.any();
        
        expect(partition.toString(), equals('Partition(ANY)'));
      });

      test('should show zero correctly', () {
        final partition = Partition.create(0);
        
        expect(partition.toString(), equals('Partition(0)'));
      });

      test('should show large numbers correctly', () {
        final partition = Partition.create(123456);
        
        expect(partition.toString(), equals('Partition(123456)'));
      });
    });

    group('Edge Cases', () {
      test('should handle maximum integer value', () {
        const maxInt = 9223372036854775807; // dart's max int
        final partition = Partition.create(maxInt);
        
        expect(partition.value, equals(maxInt));
        expect(partition.isAnyPartition, isFalse);
        expect(partition.toString(), equals('Partition($maxInt)'));
      });

      test('should maintain immutability', () {
        final partition = Partition.create(5);
        final originalValue = partition.value;
        
        // Attempting to access value multiple times should return same result
        expect(partition.value, equals(originalValue));
        expect(partition.value, equals(5));
      });

      test('should distinguish between -1 created illegally vs any partition', () {
        final anyPartition = Partition.any();
        
        expect(anyPartition.value, equals(-1));
        expect(anyPartition.isAnyPartition, isTrue);
        
        // Verify we can't create -1 through normal constructor
        expect(() => Partition.create(-1), throwsA(isA<InvalidPartitionException>()));
      });

      test('should handle boundary values correctly', () {
        // Test boundary between valid (0) and invalid (-1)
        final validPartition = Partition.create(0);
        expect(validPartition.value, equals(0));
        expect(validPartition.isAnyPartition, isFalse);
        
        expect(() => Partition.create(-1), throwsA(isA<InvalidPartitionException>()));
      });
    });

    group('Type Safety', () {
      test('should maintain type identity', () {
        final partition = Partition.create(1);
        
        expect(partition, isA<Partition>());
        expect(partition.runtimeType, equals(Partition));
      });

      test('should work with collections', () {
        final partitions = [
          Partition.create(0),
          Partition.create(1),
          Partition.any(),
        ];
        
        expect(partitions.length, equals(3));
        expect(partitions[0].value, equals(0));
        expect(partitions[1].value, equals(1));
        expect(partitions[2].isAnyPartition, isTrue);
      });

      test('should work as map keys', () {
        final partitionMap = <Partition, String>{
          Partition.create(0): 'partition-0',
          Partition.create(1): 'partition-1',
          Partition.any(): 'any-partition',
        };
        
        expect(partitionMap[Partition.create(0)], equals('partition-0'));
        expect(partitionMap[Partition.create(1)], equals('partition-1'));
        expect(partitionMap[Partition.any()], equals('any-partition'));
      });
    });
  });
}