import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/data/models/group.dart';

void main() {
  group('Group.fromJson Tests', () {
    test('should parse valid group JSON correctly', () {
      final json = {
        'id': '123',
        'name': 'Test Group',
        'description': 'A test group',
        'avatar_url': 'https://example.com/avatar.jpg',
        'creator_id': 'user123',
        'is_private': true,
        'member_count': 5,
        'max_member_count': 100,
        'created_at': '2023-01-01T00:00:00Z',
        'updated_at': '2023-01-02T00:00:00Z',
        'is_dissolved': false,
        'members': [
          {
            'user_id': 'user1',
            'group_id': '123',
            'role': 'owner',
            'joined_at': '2023-01-01T00:00:00Z'
          }
        ],
        'custom_data': {'key': 'value'}
      };

      final group = Group.fromJson(json);

      expect(group.id, '123');
      expect(group.name, 'Test Group');
      expect(group.memberCount, 5);
      expect(group.maxMemberCount, 100);
      expect(group.members?.length, 1);
    });

    test('should handle string member_count gracefully', () {
      final json = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'member_count': '5', // String instead of int
        'max_member_count': '100', // String instead of int
        'created_at': '2023-01-01T00:00:00Z',
      };

      expect(() => Group.fromJson(json), returnsNormally);
      final group = Group.fromJson(json);
      expect(group.memberCount, 5);
      expect(group.maxMemberCount, 100);
    });

    test('should handle invalid member_count string', () {
      final json = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'member_count': 'invalid_number',
        'created_at': '2023-01-01T00:00:00Z',
      };

      expect(() => Group.fromJson(json), returnsNormally);
      final group = Group.fromJson(json);
      expect(group.memberCount, 0); // Should default to 0
    });

    test('should handle members field as non-list', () {
      final json = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'member_count': 5,
        'created_at': '2023-01-01T00:00:00Z',
        'members': 'not_a_list', // String instead of List
      };

      expect(() => Group.fromJson(json), returnsNormally);
      final group = Group.fromJson(json);
      expect(group.members, isNull);
    });

    test('should handle members field as object with data key', () {
      final json = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'member_count': 5,
        'created_at': '2023-01-01T00:00:00Z',
        'members': {
          'data': [
            {
              'user_id': 'user1',
              'group_id': '123',
              'role': 'owner',
              'joined_at': '2023-01-01T00:00:00Z'
            }
          ]
        },
      };

      expect(() => Group.fromJson(json), returnsNormally);
      final group = Group.fromJson(json);
      expect(group.members, isNull); // Should be null since members is not a List
    });

    test('should handle null and missing fields', () {
      final json = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'created_at': '2023-01-01T00:00:00Z',
        // Missing optional fields
      };

      expect(() => Group.fromJson(json), returnsNormally);
      final group = Group.fromJson(json);
      expect(group.description, isNull);
      expect(group.avatarUrl, isNull);
      expect(group.memberCount, 0);
      expect(group.maxMemberCount, 200);
      expect(group.members, isNull);
    });

    test('should handle mixed data types in member_count extraction', () {
      final json = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'member_count': '10members', // String with numbers
        'created_at': '2023-01-01T00:00:00Z',
      };

      expect(() => Group.fromJson(json), returnsNormally);
      final group = Group.fromJson(json);
      expect(group.memberCount, 10); // Should extract the number
    });

    test('should handle custom_data as different types', () {
      final json1 = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'created_at': '2023-01-01T00:00:00Z',
        'custom_data': 'not_a_map', // String instead of Map
      };

      expect(() => Group.fromJson(json1), returnsNormally);
      final group1 = Group.fromJson(json1);
      expect(group1.customData, isNull);

      final json2 = {
        'id': '123',
        'name': 'Test Group',
        'creator_id': 'user123',
        'created_at': '2023-01-01T00:00:00Z',
        'custom_data': {'key': 'value'}, // Valid Map
      };

      expect(() => Group.fromJson(json2), returnsNormally);
      final group2 = Group.fromJson(json2);
      expect(group2.customData, isNotNull);
      expect(group2.customData!['key'], 'value');
    });
  });

  group('GroupMember.fromJson Tests', () {
    test('should parse valid group member JSON correctly', () {
      final json = {
        'user_id': 'user123',
        'group_id': 'group123',
        'role': 'member',
        'joined_at': '2023-01-01T00:00:00Z',
        'invited_by': 'user456',
        'nickname': 'TestUser',
        'user': {
          'id': 'user123',
          'username': 'testuser',
          'email': 'test@example.com',
          'created_at': '2023-01-01T00:00:00Z'
        }
      };

      expect(() => GroupMember.fromJson(json), returnsNormally);
      final member = GroupMember.fromJson(json);
      expect(member.userId, 'user123');
      expect(member.groupId, 'group123');
      expect(member.role, GroupMemberRole.member);
      expect(member.nickname, 'TestUser');
    });

    test('should handle missing user field', () {
      final json = {
        'user_id': 'user123',
        'group_id': 'group123',
        'role': 'member',
        'joined_at': '2023-01-01T00:00:00Z',
        // Missing user field
      };

      expect(() => GroupMember.fromJson(json), returnsNormally);
      final member = GroupMember.fromJson(json);
      expect(member.user, isNull);
    });

    test('should handle invalid role gracefully', () {
      final json = {
        'user_id': 'user123',
        'group_id': 'group123',
        'role': 'invalid_role',
        'joined_at': '2023-01-01T00:00:00Z',
      };

      expect(() => GroupMember.fromJson(json), returnsNormally);
      final member = GroupMember.fromJson(json);
      expect(member.role, GroupMemberRole.member); // Should default to member
    });
  });

  group('_parseInt helper function tests', () {
    test('should parse various integer formats', () {
      // Test through Group.fromJson since _parseInt is private
      final testCases = [
        {'member_count': 5, 'expected': 5},
        {'member_count': '10', 'expected': 10},
        {'member_count': '15members', 'expected': 15},
        {'member_count': 'count20', 'expected': 20},
        {'member_count': 'invalid', 'expected': 0},
        {'member_count': null, 'expected': 0},
      ];

      for (final testCase in testCases) {
        final json = {
          'id': '123',
          'name': 'Test Group',
          'creator_id': 'user123',
          'created_at': '2023-01-01T00:00:00Z',
          'member_count': testCase['member_count'],
        };

        final group = Group.fromJson(json);
        expect(group.memberCount, testCase['expected'],
            reason: 'Failed for input: ${testCase['member_count']}');
      }
    });
  });
}