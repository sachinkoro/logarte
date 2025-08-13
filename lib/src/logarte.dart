import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logarte/src/console/logarte_auth_screen.dart';
import 'package:logarte/src/console/logarte_overlay.dart';
import 'package:logarte/src/extensions/object_extensions.dart';
import 'package:logarte/src/extensions/route_extensions.dart';
import 'package:logarte/src/models/logarte_entry.dart';
import 'package:logarte/src/models/navigation_action.dart';
import 'package:logarte/src/services/firebase_logarte_service.dart';
import 'package:logarte/src/services/logarte_cloud_config.dart';
import 'package:logarte/src/services/logarte_secure_config.dart';
import 'package:logarte/src/services/logarte_secure_service.dart';
import 'package:logarte/src/services/logarte_alert_service.dart';

class Logarte {
  final String? password;
  final bool ignorePassword;
  final Function(String data)? onShare;
  final int logBufferLength;
  final Function(BuildContext context)? onRocketLongPressed;
  final Function(BuildContext context)? onRocketDoubleTapped;
  final bool disableDebugConsoleLogs;
  final Widget? customTab;

  // Cloud logging configuration
  final LogarteCloudConfig? cloudConfig;

  // Secure API configuration
  final LogarteSecureConfig? secureConfig;

  // Alert configuration
  final AlertConfig alertConfig;

  // Service instances
  FirebaseLogarteService? _firebaseService;
  LogarteSecureService? _secureService;
  LogarteAlertService? _alertService;

  Logarte({
    this.password,
    this.ignorePassword = !kReleaseMode,
    this.onShare,
    this.onRocketLongPressed,
    this.onRocketDoubleTapped,
    this.logBufferLength = 2500,
    this.disableDebugConsoleLogs = false,
    this.customTab,
    this.cloudConfig,
    this.secureConfig,
    this.alertConfig = const AlertConfig(),
  }) : assert(
          cloudConfig == null || secureConfig == null,
          'Cannot use both cloudConfig and secureConfig. Choose one approach.',
        ) {
    _initializeCloudLogging();
    _initializeSecureLogging();
    _initializeAlertSystem();
  }

  /// Create Logarte with direct Firebase configuration (less secure)
  Logarte.firebase({
    String? password,
    bool ignorePassword = !kReleaseMode,
    Function(String data)? onShare,
    Function(BuildContext context)? onRocketLongPressed,
    Function(BuildContext context)? onRocketDoubleTapped,
    int logBufferLength = 2500,
    bool disableDebugConsoleLogs = false,
    Widget? customTab,
    required LogarteCloudConfig cloudConfig,
    AlertConfig alertConfig = const AlertConfig(),
  }) : this(
          password: password,
          ignorePassword: ignorePassword,
          onShare: onShare,
          onRocketLongPressed: onRocketLongPressed,
          onRocketDoubleTapped: onRocketDoubleTapped,
          logBufferLength: logBufferLength,
          disableDebugConsoleLogs: disableDebugConsoleLogs,
          customTab: customTab,
          cloudConfig: cloudConfig,
          alertConfig: alertConfig,
        );

  /// Create Logarte with secure API configuration (recommended)
  Logarte.secure({
    String? password,
    bool ignorePassword = !kReleaseMode,
    Function(String data)? onShare,
    Function(BuildContext context)? onRocketLongPressed,
    Function(BuildContext context)? onRocketDoubleTapped,
    int logBufferLength = 2500,
    bool disableDebugConsoleLogs = false,
    Widget? customTab,
    required LogarteSecureConfig secureConfig,
    AlertConfig alertConfig = const AlertConfig(),
  }) : this(
          password: password,
          ignorePassword: ignorePassword,
          onShare: onShare,
          onRocketLongPressed: onRocketLongPressed,
          onRocketDoubleTapped: onRocketDoubleTapped,
          logBufferLength: logBufferLength,
          disableDebugConsoleLogs: disableDebugConsoleLogs,
          customTab: customTab,
          secureConfig: secureConfig,
          alertConfig: alertConfig,
        );

  final logs = ValueNotifier(<LogarteEntry>[]);

  void _initializeCloudLogging() {
    if (cloudConfig?.enableCloudLogging == true) {
      try {
        _firebaseService = FirebaseLogarteService(config: cloudConfig!);
      } catch (e) {
        debugPrint('Failed to initialize Firebase logging: $e');
      }
    }
  }

  void _initializeSecureLogging() {
    if (secureConfig?.enableCloudLogging == true) {
      final validation = secureConfig!.validate();
      if (validation != null) {
        debugPrint('Invalid secure config: $validation');
        return;
      }

      try {
        _secureService = LogarteSecureService(
          apiEndpoint: secureConfig!.apiEndpoint,
          apiKey: secureConfig!.apiKey,
          user: secureConfig!.user,
          timeout: secureConfig!.requestTimeout,
          enableBatching: secureConfig!.enableBatching,
          batchSize: secureConfig!.batchSize,
        );
      } catch (e) {
        debugPrint('Failed to initialize secure logging: $e');
      }
    }
  }

  void _initializeAlertSystem() {
    if (alertConfig.enableAlerts) {
      try {
        _alertService = LogarteAlertService(alertConfig);
      } catch (e) {
        debugPrint('Failed to initialize alert system: $e');
      }
    }
  }

  void _add(LogarteEntry entry) {
    // Add to local buffer
    if (logs.value.length > logBufferLength) {
      logs.value.removeAt(0);
    }
    logs.value = [...logs.value, entry];

    // Upload to cloud if enabled (Firebase approach)
    _firebaseService?.logEntry(entry);

    // Upload to secure API if enabled (recommended approach)
    _secureService?.logEntry(entry);

    // Process for alerts if enabled
    _alertService?.processLogEntry(entry);
  }

  @Deprecated('Use logarte.log() instead')
  void info(
    Object? message, {
    bool write = true,
    String? source,
  }) {
    _log(
      message,
      write: write,
      source: source,
    );
  }

  void log(
    Object? message, {
    bool write = true,
    StackTrace? stackTrace,
    String? source,
  }) {
    _log(
      message,
      write: write,
      stackTrace: stackTrace,
      source: source,
    );
  }

  @Deprecated('Use logarte.log() instead')
  void error(
    Object? message, {
    StackTrace? stackTrace,
    bool write = true,
  }) {
    _log(
      'ERROR: $message\n\nTRACE: $stackTrace',
      write: write,
    );
  }

  void network({
    required NetworkRequestLogarteEntry request,
    required NetworkResponseLogarteEntry response,
    bool write = true,
  }) {
    try {
      _log(
        '[${request.method}] URL: ${request.url}',
        write: write,
      );
      _log(
        'HEADERS: ${request.headers.prettyJson}',
        write: write,
      );
      _log(
        'BODY: ${request.body.prettyJson}',
        write: write,
      );
      _log(
        'STATUS CODE: ${response.statusCode}',
        write: write,
      );
      _log(
        'RESPONSE HEADERS: ${response.headers.prettyJson}',
        write: write,
      );
      _log(
        'RESPONSE BODY: ${response.body.prettyJson}',
        write: write,
      );

      _add(
        NetworkLogarteEntry(
          request: request,
          response: response,
        ),
      );
    } catch (_) {}
  }

  void _log(
    Object? message, {
    bool write = true,
    String? source,
    StackTrace? stackTrace,
  }) {
    if (!disableDebugConsoleLogs) {
      developer.log(
        message.toString(),
        name: 'logarte',
        stackTrace: stackTrace,
      );
    }

    if (write) {
      _add(
        PlainLogarteEntry(
          '${message.toString()}${stackTrace != null ? '\n\n$stackTrace' : ''}',
          source: source,
        ),
      );
    }
  }

  void navigation({
    required Route<dynamic>? route,
    required Route<dynamic>? previousRoute,
    required NavigationAction action,
  }) {
    try {
      if ([route.routeName, previousRoute.routeName]
          .any((e) => e?.contains('/logarte') == true)) {
        return;
      }

      // TODO: make it common logic
      final message = previousRoute != null
          ? action == NavigationAction.pop
              ? '$action from "${route.routeName}" to "${previousRoute.routeName}"'
              : '$action to "${route.routeName}"'
          : '$action to "${route.routeName}"';

      _log(message, write: false);

      _add(
        NavigatorLogarteEntry(
          route: route,
          previousRoute: previousRoute,
          action: action,
        ),
      );
    } catch (_) {}
  }

  void database({
    required String target,
    required Object? value,
    required String source,
  }) {
    try {
      _log(
        '$source: $target → $value',
        write: false,
      );

      _add(
        DatabaseLogarteEntry(
          target: target,
          value: value,
          source: source,
        ),
      );
    } catch (_) {}
  }

  void attach({
    required BuildContext context,
    required bool visible,
  }) async {
    if (visible) {
      return LogarteOverlay.attach(
        context: context,
        instance: this,
      );
    }
  }

  /// Check if LogarteOverlay is currently attached
  bool get isOverlayAttached => LogarteOverlay.isAttached;

  /// Detach the LogarteOverlay if it's currently attached
  void detachOverlay() {
    LogarteOverlay.detach();
  }

  Future<void> openConsole(BuildContext context) async {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LogarteAuthScreen(this),
        settings: const RouteSettings(name: '/logarte_auth'),
      ),
    );
  }

  // ============ CLOUD LOGGING METHODS ============

  /// Check if cloud logging is enabled (either Firebase or secure API)
  bool get isCloudLoggingEnabled =>
      (cloudConfig?.enableCloudLogging == true && _firebaseService != null) ||
      (secureConfig?.enableCloudLogging == true && _secureService != null);

  /// Get user ID for cloud logging
  String? get currentUserId {
    if (_firebaseService != null) {
      return cloudConfig?.userId ?? cloudConfig?.phoneNumber;
    } else if (_secureService != null) {
      return secureConfig?.user.userId ?? secureConfig?.user.phoneNumber;
    }
    return null;
  }

  /// Retrieve logs from cloud storage
  Future<List<Map<String, dynamic>>> getCloudLogs({
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? logType,
    int limit = 100,
  }) async {
    if (_firebaseService == null) {
      debugPrint('Cloud logging not enabled');
      return [];
    }

    return await _firebaseService!.getUserLogs(
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      logType: logType,
      limit: limit,
    );
  }

  /// Retrieve team logs from cloud storage
  Future<List<Map<String, dynamic>>> getTeamCloudLogs({
    String? teamId,
    DateTime? startTime,
    DateTime? endTime,
    int limit = 100,
  }) async {
    if (_firebaseService == null) {
      debugPrint('Cloud logging not enabled');
      return [];
    }

    return await _firebaseService!.getTeamLogs(
      teamId: teamId,
      startTime: startTime,
      endTime: endTime,
      limit: limit,
    );
  }

  /// Stream real-time logs from cloud storage
  Stream<List<Map<String, dynamic>>> streamCloudLogs({
    String? userId,
    String? logType,
    int limit = 50,
  }) {
    if (_firebaseService == null) {
      debugPrint('Cloud logging not enabled');
      return Stream.empty();
    }

    return _firebaseService!.streamUserLogs(
      userId: userId,
      logType: logType,
      limit: limit,
    );
  }

  /// Force sync pending logs to cloud
  Future<void> syncToCloud() async {
    if (_firebaseService == null && _secureService == null) {
      debugPrint('Cloud logging not enabled');
      return;
    }

    // Force upload any pending logs
    try {
      if (_firebaseService != null) {
        await _firebaseService!.forceSyncPendingLogs();
      }
      if (_secureService != null) {
        await _secureService!.forceSyncPendingLogs();
      }
    } catch (e) {
      debugPrint('Failed to sync to cloud: $e');
    }
  }

  /// Update cloud logging configuration
  Future<void> updateCloudConfig(LogarteCloudConfig newConfig) async {
    // Dispose current service if enabled
    if (_firebaseService != null) {
      _firebaseService!.dispose();
      _firebaseService = null;
    }

    // Create new service with updated config
    if (newConfig.enableCloudLogging) {
      try {
        _firebaseService = FirebaseLogarteService(config: newConfig);
      } catch (e) {
        debugPrint('Failed to update cloud config: $e');
      }
    }
  }

  /// Get cloud logging status and statistics
  Map<String, dynamic> getCloudStatus() {
    return {
      'isEnabled': isCloudLoggingEnabled,
      'userId': currentUserId,
      'teamId': cloudConfig?.teamId,
      'pendingLogs': 0, // TODO: expose through public method
      'isOnline': true, // TODO: expose through public method
      'currentSession': 'session_id', // TODO: expose through public method
    };
  }

  // ============ ALERT SYSTEM METHODS ============

  /// Check if alert system is enabled
  bool get isAlertSystemEnabled =>
      alertConfig.enableAlerts && _alertService != null;

  /// Stream of alert notifications
  Stream<AlertNotification> get alertStream =>
      _alertService?.alertStream ?? Stream.empty();

  /// Get recent alerts
  List<AlertNotification> get recentAlerts => _alertService?.recentAlerts ?? [];

  /// Get endpoint failure counts
  Map<String, int> getEndpointFailures() {
    return _alertService?.getAllEndpointFailures() ?? {};
  }

  /// Clear failures for a specific endpoint
  void clearEndpointFailures(String endpoint) {
    _alertService?.clearEndpointFailures(endpoint);
  }

  /// Get failure count for specific endpoint
  int getEndpointFailureCount(String endpoint) {
    return _alertService?.getEndpointFailureCount(endpoint) ?? 0;
  }

  /// Update alert configuration
  void updateAlertConfig(AlertConfig newConfig) {
    _alertService?.dispose();

    if (newConfig.enableAlerts) {
      try {
        _alertService = LogarteAlertService(newConfig);
      } catch (e) {
        debugPrint('Failed to update alert config: $e');
      }
    } else {
      _alertService = null;
    }
  }

  /// Dispose cloud service and alert system when shutting down
  void dispose() {
    _firebaseService?.dispose();
    _secureService = null; // Secure service doesn't need explicit disposal
    _alertService?.dispose();
  }
}
