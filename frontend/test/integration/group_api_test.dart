import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/data/models/group.dart';

void main() {
  group('Group API Integration Tests', () {
    test('should handle various API response formats for getUserGroups', () {
      // Test case 1: Backend returns direct array
      final directArrayResponse = [
        {
          'id': '1',
          'name': 'Group 1',
          'creator_id': 'user1',
          'member_count': 5,
          'created_at': '2023-01-01T00:00:00Z',
        },
        {
          'id': '2',
          'name': 'Group 2',
          'creator_id': 'user2',
          'member_count': '10', // String number
          'created_at': '2023-01-01T00:00:00Z',
        }
      ];

      expect(() {
        for (final groupJson in directArrayResponse) {
          Group.fromJson(groupJson);
        }
      }, returnsNormally);

      // Test case 2: Backend returns wrapped in object with 'groups' key
      final wrappedGroupsResponse = {
        'groups': [
          {
            'id': '1',
            'name': 'Group 1',
            'creator_id': 'user1',
            'member_count': 5,
            'created_at': '2023-01-01T00:00:00Z',
          }
        ]
      };

      expect(() {
        final groupsData = wrappedGroupsResponse['groups'] as List<dynamic>;
        for (final groupJson in groupsData) {
          Group.fromJson(groupJson);
        }
      }, returnsNormally);

      // Test case 3: Backend returns wrapped in object with 'data' key
      final wrappedDataResponse = {
        'data': [
          {
            'id': '1',
            'name': 'Group 1',
            'creator_id': 'user1',
            'member_count': 5,
            'created_at': '2023-01-01T00:00:00Z',
          }
        ]
      };

      expect(() {
        final groupsData = wrappedDataResponse['data'] as List<dynamic>;
        for (final groupJson in groupsData) {
          Group.fromJson(groupJson);
        }
      }, returnsNormally);
    });

    test('should handle problematic API response that causes TypeError', () {
      // Simulate the actual problematic response that might be causing the error
      final problematicResponse1 = {
        'id': '1',
        'name': 'Group 1',
        'creator_id': 'user1',
        'member_count': 5,
        'created_at': '2023-01-01T00:00:00Z',
        'data': 'some_string_value', // This might be the problematic field
      };

      expect(() => Group.fromJson(problematicResponse1), returnsNormally);

      // Test with nested data structure that might cause issues
      final problematicResponse2 = {
        'id': '1',
        'name': 'Group 1',
        'creator_id': 'user1',
        'member_count': 5,
        'created_at': '2023-01-01T00:00:00Z',
        'members': {
          'data': 'string_instead_of_array' // This could cause the error
        }
      };

      expect(() => Group.fromJson(problematicResponse2), returnsNormally);

      // Test with completely malformed member_count
      final problematicResponse3 = {
        'id': '1',
        'name': 'Group 1',
        'creator_id': 'user1',
        'member_count': {
          'data': '5' // Object instead of int/string
        },
        'created_at': '2023-01-01T00:00:00Z',
      };

      expect(() => Group.fromJson(problematicResponse3), returnsNormally);
    });

    test('should handle edge cases in member parsing', () {
      // Test case where members field contains unexpected structure
      final edgeCaseResponse = {
        'id': '1',
        'name': 'Group 1',
        'creator_id': 'user1',
        'member_count': 5,
        'created_at': '2023-01-01T00:00:00Z',
        'members': [
          {
            'user_id': 'user1',
            'group_id': '1',
            'role': 'owner',
            'joined_at': '2023-01-01T00:00:00Z',
            'data': 'some_string' // Extra data field in member
          },
          {
            'user_id': 'user2',
            'group_id': '1',
            'role': 'member',
            'joined_at': '2023-01-01T00:00:00Z',
            'user': {
              'id': 'user2',
              'username': 'testuser',
              'email': 'test@example.com',
              'created_at': '2023-01-01T00:00:00Z',
              'data': 'user_data_string' // Extra data field in user
            }
          }
        ]
      };

      expect(() => Group.fromJson(edgeCaseResponse), returnsNormally);
      final group = Group.fromJson(edgeCaseResponse);
      expect(group.members?.length, 2);
    });

    test('should handle API response with mixed data types', () {
      // This test simulates a response where backend might return inconsistent types
      final mixedTypeResponse = {
        'id': 1, // int instead of string
        'name': 'Group 1',
        'creator_id': 123, // int instead of string
        'member_count': '5',
        'max_member_count': 100.0, // double instead of int
        'created_at': '2023-01-01T00:00:00Z',
        'is_private': 'true', // string instead of bool
        'is_dissolved': 0, // int instead of bool
      };

      expect(() => Group.fromJson(mixedTypeResponse), returnsNormally);
      final group = Group.fromJson(mixedTypeResponse);
      expect(group.id, '1');
      expect(group.creatorId, '123');
      expect(group.memberCount, 5);
    });

    test('should reproduce the exact TypeError scenario', () {
      // Try to reproduce the exact error: "data": type 'String' is not a subtype of type 'int'
      final errorProneResponse = {
        'id': '1',
        'name': 'Group 1',
        'creator_id': 'user1',
        'created_at': '2023-01-01T00:00:00Z',
        // Intentionally problematic fields that might cause the error
        'member_count': {
          'data': '5' // Nested object with data field
        },
        'max_member_count': {
          'data': '100'
        }
      };

      // This should not throw an error with our improved parsing
      expect(() => Group.fromJson(errorProneResponse), returnsNormally);
      final group = Group.fromJson(errorProneResponse);
      // Should handle the complex object gracefully
      expect(group.memberCount, 0); // Should default to 0 when parsing fails
    });
  });

  group('GroupMember edge cases', () {
    test('should handle GroupMember with problematic data field', () {
      final problematicMemberJson = {
        'user_id': 'user1',
        'group_id': 'group1',
        'role': 'member',
        'joined_at': '2023-01-01T00:00:00Z',
        'data': 'some_string_value', // This might be causing issues
        'user': {
          'id': 'user1',
          'username': 'testuser',
          'email': 'test@example.com',
          'created_at': '2023-01-01T00:00:00Z',
          'data': 'user_data_string' // Extra data in user object
        }
      };

      expect(() => GroupMember.fromJson(problematicMemberJson), returnsNormally);
      final member = GroupMember.fromJson(problematicMemberJson);
      expect(member.userId, 'user1');
      expect(member.user?.id, 'user1');
    });
  });
}