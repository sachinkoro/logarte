import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/logarte_entry.dart';
import '../models/logarte_user.dart';
import 'logarte_cloud_config.dart';

class FirebaseLogarteService {
  static const String _collectionLogs = 'logs';
  static const String _collectionUsers = 'users';
  static const String _collectionSessions = 'sessions';
  static const String _collectionApps = 'apps';
  static const String _collectionTeams = 'teams';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LogarteCloudConfig _config;
  final Connectivity _connectivity;
  final DeviceInfoPlugin _deviceInfo;
  final Uuid _uuid;

  // Local state
  String? _currentSessionId;
  String? _currentUserId;
  String? _currentAppId;
  final List<LogarteEntry> _pendingLogs = [];
  Timer? _batchTimer;
  bool _isOnline = true;

  // Device and app info cache
  Map<String, dynamic>? _deviceInfoCache;
  PackageInfo? _packageInfoCache;

  FirebaseLogarteService({
    required LogarteCloudConfig config,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Connectivity? connectivity,
    DeviceInfoPlugin? deviceInfo,
    Uuid? uuid,
  })  : _config = config,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _connectivity = connectivity ?? Connectivity(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _uuid = uuid ?? const Uuid() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize Firebase if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Monitor connectivity
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Cache device and package info
    await _cacheDeviceInfo();
    await _cachePackageInfo();

    // Start batch timer for efficient uploads
    _startBatchTimer();

    // Initialize user and session
    await _initializeUser();
    await _startSession();
  }

  Future<void> _cacheDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceInfoCache = {
          'platform': 'android',
          'version': androidInfo.version.release,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceInfoCache = {
          'platform': 'ios',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
        };
      } else if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        _deviceInfoCache = {
          'platform': 'web',
          'browserName': webInfo.browserName?.name,
          'userAgent': webInfo.userAgent,
        };
      } else {
        _deviceInfoCache = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
      _deviceInfoCache = {'platform': 'unknown'};
    }
  }

  Future<void> _cachePackageInfo() async {
    try {
      _packageInfoCache = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('Failed to get package info: $e');
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (!wasOnline && _isOnline) {
      // Came back online, sync pending logs
      _syncPendingLogs();
    }
  }

  Future<void> _initializeUser() async {
    if (_config.userId != null) {
      _currentUserId = _config.userId;
    } else if (_config.phoneNumber != null) {
      _currentUserId = _config.phoneNumber;
    } else {
      // Generate anonymous user ID
      _currentUserId = _uuid.v4();
    }

    // Create or update user document
    await _createOrUpdateUser();
  }

  Future<void> _createOrUpdateUser() async {
    if (_currentUserId == null) return;

    try {
      final userRef =
          _firestore.collection(_collectionUsers).doc(_currentUserId);
      final userDoc = await userRef.get();

      final userData = LogarteUser(
        userId: _currentUserId!,
        phoneNumber: _config.phoneNumber,
        email: _config.email,
        displayName: _config.displayName,
        teamId: _config.teamId,
        role: _config.role ?? 'developer',
        isActive: true,
        lastSeen: DateTime.now(),
        createdAt: userDoc.exists ? null : DateTime.now(),
        updatedAt: DateTime.now(),
        settings: LogarteUserSettings(
          enableCloudLogging: _config.enableCloudLogging,
          logRetentionDays: _config.logRetentionDays,
          allowTeamAccess: _config.allowTeamAccess,
        ),
      ).toMap();

      if (userDoc.exists) {
        await userRef.update(userData..remove('createdAt'));
      } else {
        await userRef.set(userData);
      }
    } catch (e) {
      debugPrint('Failed to create/update user: $e');
    }
  }

  Future<void> _startSession() async {
    if (_currentUserId == null || !_config.enableCloudLogging) return;

    _currentSessionId =
        '${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    _currentAppId = _packageInfoCache?.packageName ?? 'unknown_app';

    try {
      await _firestore
          .collection(_collectionSessions)
          .doc(_currentSessionId)
          .set({
        'sessionId': _currentSessionId,
        'userId': _currentUserId,
        'appId': _currentAppId,
        'startTime': FieldValue.serverTimestamp(),
        'deviceInfo': _deviceInfoCache,
        'appVersion': _packageInfoCache?.version ?? 'unknown',
        'buildNumber': _packageInfoCache?.buildNumber ?? 'unknown',
        'environment':
            kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release'),
        'isActive': true,
        'logCount': 0,
        'crashCount': 0,
      });
    } catch (e) {
      debugPrint('Failed to start session: $e');
    }
  }

  Future<void> endSession() async {
    if (_currentSessionId == null) return;

    try {
      await _firestore
          .collection(_collectionSessions)
          .doc(_currentSessionId)
          .update({
        'endTime': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } catch (e) {
      debugPrint('Failed to end session: $e');
    }

    _currentSessionId = null;
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(
        Duration(seconds: _config.batchUploadIntervalSeconds), (_) {
      if (_pendingLogs.isNotEmpty) {
        _uploadBatch();
      }
    });
  }

  Future<void> logEntry(LogarteEntry entry) async {
    if (!_config.enableCloudLogging || _currentUserId == null) return;

    // Add to pending logs
    _pendingLogs.add(entry);

    // If we have enough logs or it's a critical log, upload immediately
    if (_pendingLogs.length >= _config.batchSize || _isCriticalLog(entry)) {
      await _uploadBatch();
    }
  }

  bool _isCriticalLog(LogarteEntry entry) {
    if (entry is NetworkLogarteEntry) {
      final statusCode = entry.response.statusCode;
      return statusCode != null && (statusCode >= 400 || statusCode == 0);
    }
    if (entry is PlainLogarteEntry) {
      return entry.message.toLowerCase().contains('error') ||
          entry.message.toLowerCase().contains('exception') ||
          entry.message.toLowerCase().contains('crash');
    }
    return false;
  }

  Future<void> _uploadBatch() async {
    if (_pendingLogs.isEmpty || !_isOnline || _currentUserId == null) return;

    final logsToUpload = List<LogarteEntry>.from(_pendingLogs);
    _pendingLogs.clear();

    try {
      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      for (final entry in logsToUpload) {
        final logId =
            '${_currentUserId}_${timestamp.millisecondsSinceEpoch}_${_uuid.v4()}';
        final logRef = _firestore.collection(_collectionLogs).doc(logId);

        final logData = {
          'logId': logId,
          'userId': _currentUserId,
          'teamId': _config.teamId,
          'appId': _currentAppId,
          'sessionId': _currentSessionId,
          'type': _getLogType(entry),
          'timestamp': FieldValue.serverTimestamp(),
          'deviceInfo': _deviceInfoCache,
          'metadata': {
            'appVersion': _packageInfoCache?.version ?? 'unknown',
            'environment':
                kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release'),
            'buildMode': kDebugMode ? 'debug' : 'release',
          },
          'data': _serializeLogData(entry),
        };

        batch.set(logRef, logData);
      }

      // Update session log count
      if (_currentSessionId != null) {
        final sessionRef =
            _firestore.collection(_collectionSessions).doc(_currentSessionId);
        batch.update(sessionRef, {
          'logCount': FieldValue.increment(logsToUpload.length),
        });
      }

      await batch.commit();
      debugPrint(
          'Successfully uploaded ${logsToUpload.length} logs to Firestore');
    } catch (e) {
      debugPrint('Failed to upload logs: $e');
      // Re-add logs to pending for retry
      _pendingLogs.insertAll(0, logsToUpload);
    }
  }

  String _getLogType(LogarteEntry entry) {
    if (entry is NetworkLogarteEntry) return 'network';
    if (entry is NavigatorLogarteEntry) return 'navigation';
    if (entry is DatabaseLogarteEntry) return 'database';
    if (entry is PlainLogarteEntry) return 'plain';
    return 'unknown';
  }

  Map<String, dynamic> _serializeLogData(LogarteEntry entry) {
    if (entry is NetworkLogarteEntry) {
      return {
        'request': {
          'method': entry.request.method,
          'url': entry.request.url,
          'headers': entry.request.headers,
          'body': _truncateIfNeeded(entry.request.body?.toString()),
          'sentAt': entry.request.sentAt?.millisecondsSinceEpoch,
        },
        'response': {
          'statusCode': entry.response.statusCode,
          'headers': entry.response.headers,
          'body': _truncateIfNeeded(entry.response.body?.toString()),
          'receivedAt': entry.response.receivedAt?.millisecondsSinceEpoch,
          'duration':
              entry.response.receivedAt != null && entry.request.sentAt != null
                  ? entry.response.receivedAt!
                      .difference(entry.request.sentAt!)
                      .inMilliseconds
                  : null,
        },
      };
    } else if (entry is NavigatorLogarteEntry) {
      return {
        'action': entry.action.name,
        'routeName': entry.route?.settings.name,
        'arguments': entry.route?.settings.arguments?.toString(),
        'previousRoute': entry.previousRoute?.settings.name,
        'previousArguments':
            entry.previousRoute?.settings.arguments?.toString(),
      };
    } else if (entry is DatabaseLogarteEntry) {
      return {
        'target': entry.target,
        'value': _truncateIfNeeded(entry.value?.toString()),
        'source': entry.source,
        'operation': 'write', // Default, could be extended
      };
    } else if (entry is PlainLogarteEntry) {
      return {
        'message': _truncateIfNeeded(entry.message),
        'level':
            entry.message.toLowerCase().contains('error') ? 'error' : 'info',
        'source': entry.source,
      };
    }
    return {};
  }

  String? _truncateIfNeeded(String? text) {
    if (text == null) return null;
    const maxLength = 10000; // 10KB limit per field
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...[TRUNCATED]'
        : text;
  }

  Future<void> _syncPendingLogs() async {
    if (_pendingLogs.isNotEmpty) {
      await _uploadBatch();
    }
  }

  /// Public method to force sync pending logs
  Future<void> forceSyncPendingLogs() async {
    await _syncPendingLogs();
  }

  // Remote log retrieval methods
  Future<List<Map<String, dynamic>>> getUserLogs({
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? logType,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionLogs)
          .where('userId', isEqualTo: userId ?? _currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startTime != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startTime);
      }
      if (endTime != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endTime);
      }
      if (logType != null) {
        query = query.where('type', isEqualTo: logType);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to retrieve user logs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTeamLogs({
    String? teamId,
    DateTime? startTime,
    DateTime? endTime,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionLogs)
          .where('teamId', isEqualTo: teamId ?? _config.teamId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startTime != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startTime);
      }
      if (endTime != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endTime);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to retrieve team logs: $e');
      return [];
    }
  }

  // Real-time log streaming
  Stream<List<Map<String, dynamic>>> streamUserLogs({
    String? userId,
    String? logType,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(_collectionLogs)
        .where('userId', isEqualTo: userId ?? _currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (logType != null) {
      query = query.where('type', isEqualTo: logType);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList());
  }

  void dispose() {
    _batchTimer?.cancel();
    endSession();
  }
}
