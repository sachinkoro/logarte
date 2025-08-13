import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/logarte_entry.dart';
import '../models/logarte_user.dart';
import '../models/navigation_action.dart';

/// Secure service that sends logs to a backend API instead of directly to Firestore
/// This approach keeps Firebase credentials secure on the server side
class LogarteSecureService {
  final String _apiEndpoint;
  final String _apiKey;
  final LogarteUser _user;
  final Duration _timeout;
  final bool _enableBatching;
  final int _batchSize;

  // Local buffer for offline support
  final List<Map<String, dynamic>> _pendingLogs = [];
  bool _isOnline = true;

  LogarteSecureService({
    required String apiEndpoint,
    required String apiKey,
    required LogarteUser user,
    Duration timeout = const Duration(seconds: 30),
    bool enableBatching = true,
    int batchSize = 10,
  })  : _apiEndpoint = apiEndpoint.endsWith('/')
            ? apiEndpoint.substring(0, apiEndpoint.length - 1)
            : apiEndpoint,
        _apiKey = apiKey,
        _user = user,
        _timeout = timeout,
        _enableBatching = enableBatching,
        _batchSize = batchSize;

  /// Send a single log entry to the secure API
  Future<bool> logEntry(LogarteEntry entry) async {
    final logData = _entryToJson(entry);

    if (_enableBatching) {
      _pendingLogs.add(logData);
      if (_pendingLogs.length >= _batchSize) {
        return await _flushBatch();
      }
      return true;
    } else {
      return await _sendSingleLog(logData);
    }
  }

  /// Send multiple log entries as a batch
  Future<bool> logBatch(List<LogarteEntry> entries) async {
    final logDataList = entries.map(_entryToJson).toList();
    return await _sendBatch(logDataList);
  }

  /// Force send all pending logs
  Future<bool> forceSyncPendingLogs() async {
    if (_pendingLogs.isEmpty) return true;
    return await _flushBatch();
  }

  /// Get logs for current user (if API supports it)
  Future<List<LogarteEntry>> getUserLogs({
    int limit = 100,
    DateTime? before,
    String? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (before != null) 'before': before.toIso8601String(),
        if (type != null) 'type': type,
      };

      final uri =
          Uri.parse('$_apiEndpoint/logs').replace(queryParameters: queryParams);
      final response = await http
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['logs'] as List).map((log) => _jsonToEntry(log)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching logs: $e');
      return [];
    }
  }

  /// Convert LogarteEntry to JSON for API
  Map<String, dynamic> _entryToJson(LogarteEntry entry) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': entry.type.toString().split('.').last,
      'timestamp': entry.date.toIso8601String(),
      'level': 'info', // Default level since LogarteEntry doesn't have level
      'message': entry.contents.join(' '),
      'data': _getEntryData(entry),
      'user': {
        'userId': _user.userId,
        'email': _user.email,
        'displayName': _user.displayName,
        'teamId': _user.teamId,
        'phoneNumber': _user.phoneNumber,
        'role': _user.role,
      },
      'appInfo': {
        'platform': Platform.operatingSystem,
      },
    };
  }

  /// Extract data from different entry types
  Map<String, dynamic> _getEntryData(LogarteEntry entry) {
    if (entry is NetworkLogarteEntry) {
      return {
        'request': {
          'url': entry.request.url,
          'method': entry.request.method,
          'headers': entry.request.headers,
          'body': entry.request.body,
        },
        'response': {
          'statusCode': entry.response.statusCode,
          'headers': entry.response.headers,
          'body': entry.response.body,
        },
      };
    } else if (entry is DatabaseLogarteEntry) {
      return {
        'target': entry.target,
        'value': entry.value,
        'source': entry.source,
      };
    } else if (entry is PlainLogarteEntry) {
      return {
        'source': entry.source,
      };
    }
    return {};
  }

  /// Convert JSON back to LogarteEntry (for getUserLogs)
  LogarteEntry _jsonToEntry(Map<String, dynamic> json) {
    final typeString = json['type'] as String? ?? 'plain';
    final message = json['message'] as String? ?? '';

    // Create appropriate LogarteEntry subclass based on type
    switch (typeString) {
      case 'network':
        // For network entries, create a simplified NetworkLogarteEntry
        return NetworkLogarteEntry(
          request: NetworkRequestLogarteEntry(
            url: json['data']?['request']?['url'] ?? '',
            method: json['data']?['request']?['method'] ?? 'GET',
            headers: Map<String, String>.from(
                json['data']?['request']?['headers'] ?? {}),
            body: json['data']?['request']?['body'],
          ),
          response: NetworkResponseLogarteEntry(
            statusCode: json['data']?['response']?['statusCode'] ?? 200,
            headers: Map<String, String>.from(
                json['data']?['response']?['headers'] ?? {}),
            body: json['data']?['response']?['body'],
          ),
        );
      case 'database':
        return DatabaseLogarteEntry(
          target: json['data']?['target'] ?? '',
          value: json['data']?['value'],
          source: json['data']?['source'] ?? '',
        );
      case 'navigation':
        return NavigatorLogarteEntry(
          route: null, // We can't reconstruct route objects from JSON
          previousRoute: null,
          action: NavigationAction.push, // Default action
        );
      default:
        return PlainLogarteEntry(
          message,
          source: json['data']?['source'],
        );
    }
  }

  /// Send a single log to the API
  Future<bool> _sendSingleLog(Map<String, dynamic> logData) async {
    return await _sendBatch([logData]);
  }

  /// Send batch of logs to the API
  Future<bool> _sendBatch(List<Map<String, dynamic>> logs) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiEndpoint/logs/batch'),
            headers: _getHeaders(),
            body: json.encode({
              'logs': logs,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      _isOnline = true;
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _isOnline = false;
      print('Error sending logs: $e');
      return false;
    }
  }

  /// Flush pending batch
  Future<bool> _flushBatch() async {
    if (_pendingLogs.isEmpty) return true;

    final logsToSend = List<Map<String, dynamic>>.from(_pendingLogs);
    _pendingLogs.clear();

    final success = await _sendBatch(logsToSend);

    if (!success) {
      // Re-add failed logs to pending (with limit to prevent infinite growth)
      if (_pendingLogs.length < 1000) {
        _pendingLogs.insertAll(0, logsToSend);
      }
    }

    return success;
  }

  /// Get HTTP headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'X-User-ID': _user.userId,
      'X-User-Email': _user.email ?? '',
      'X-Team-ID': _user.teamId ?? '',
    };
  }

  /// Check if service is online
  bool get isOnline => _isOnline;

  /// Get pending logs count
  int get pendingLogsCount => _pendingLogs.length;

  /// Create alert
  Future<bool> createAlert({
    required String type,
    required String message,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiEndpoint/alerts'),
            headers: _getHeaders(),
            body: json.encode({
              'type': type,
              'message': message,
              'metadata': metadata,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error creating alert: $e');
      return false;
    }
  }
}
