import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/message_model.dart';
import 'api_exception.dart';
import 'message_remote_datasource.dart';

/// 消息远程数据源实现
/// 
/// 使用HTTP请求与服务器交互，实现消息的获取和发送
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;
  final Map<String, String> _headers;
  
  MessageRemoteDataSourceImpl({
    required http.Client client,
    required String baseUrl,
    required String authToken,
  }) : _client = client,
       _baseUrl = baseUrl,
       _headers = {
         'Content-Type': 'application/json',
         'Authorization': 'Bearer $authToken',
       };
  
  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/messages?conversationId=$conversationId&limit=$limit&offset=$offset');
      final response = await _client.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: json.decode(response.body)['message'] ?? 'Failed to get messages',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
  
  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      final url = Uri.parse('$_baseUrl/messages');
      final response = await _client.post(
        url,
        headers: _headers,
        body: json.encode(message.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        return MessageModel.fromJson(data);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: json.decode(response.body)['message'] ?? 'Failed to send message',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
  
  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final url = Uri.parse('$_baseUrl/messages/$messageId');
      final response = await _client.delete(url, headers: _headers);
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          statusCode: response.statusCode,
          message: json.decode(response.body)['message'] ?? 'Failed to delete message',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
  
  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final url = Uri.parse('$_baseUrl/messages/$messageId/read');
      final response = await _client.put(url, headers: _headers);
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          statusCode: response.statusCode,
          message: json.decode(response.body)['message'] ?? 'Failed to mark message as read',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
  
  @override
  Future<void> markAllMessagesAsRead(String conversationId) async {
    try {
      final url = Uri.parse('$_baseUrl/conversations/$conversationId/read');
      final response = await _client.put(url, headers: _headers);
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          statusCode: response.statusCode,
          message: json.decode(response.body)['message'] ?? 'Failed to mark all messages as read',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
  
  @override
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/messages/unread/count?userId=$userId');
      final response = await _client.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return data['count'] as int;
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: json.decode(response.body)['message'] ?? 'Failed to get unread message count',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
  
  @override
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? conversationId,
  }) async {
    try {
      String url = '$_baseUrl/messages/search?query=$query';
      if (conversationId != null) {
        url += '&conversationId=$conversationId';
      }
      
      final response = await _client.get(Uri.parse(url), headers: _headers);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: json.decode(response.body)['message'] ?? 'Failed to search messages',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
}