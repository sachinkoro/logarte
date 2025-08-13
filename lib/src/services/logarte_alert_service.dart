import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logarte/src/models/logarte_entry.dart';

/// Alert severity levels
enum AlertSeverity { low, medium, high, critical }

/// Alert types for different monitoring scenarios
enum AlertType {
  apiFailure,
  highErrorRate,
  slowResponse,
  crashDetected,
  customThreshold
}

/// Alert configuration for API failure monitoring
class AlertRule {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String name;
  final String description;
  final bool enabled;

  // API Failure specific settings
  final int failureThreshold;
  final Duration timeWindow;
  final List<int> statusCodesToMonitor;
  final String? endpointPattern; // Regex pattern to match endpoints

  // Response time settings
  final int? slowResponseThreshold; // milliseconds

  // Custom conditions
  final bool Function(LogarteEntry)? customCondition;

  const AlertRule({
    required this.id,
    required this.type,
    required this.severity,
    required this.name,
    required this.description,
    this.enabled = true,
    this.failureThreshold = 10,
    this.timeWindow = const Duration(minutes: 10),
    this.statusCodesToMonitor = const [400, 401, 403, 404, 500, 502, 503, 504],
    this.endpointPattern,
    this.slowResponseThreshold,
    this.customCondition,
  });

  AlertRule copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? name,
    String? description,
    bool? enabled,
    int? failureThreshold,
    Duration? timeWindow,
    List<int>? statusCodesToMonitor,
    String? endpointPattern,
    int? slowResponseThreshold,
    bool Function(LogarteEntry)? customCondition,
  }) {
    return AlertRule(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      failureThreshold: failureThreshold ?? this.failureThreshold,
      timeWindow: timeWindow ?? this.timeWindow,
      statusCodesToMonitor: statusCodesToMonitor ?? this.statusCodesToMonitor,
      endpointPattern: endpointPattern ?? this.endpointPattern,
      slowResponseThreshold:
          slowResponseThreshold ?? this.slowResponseThreshold,
      customCondition: customCondition ?? this.customCondition,
    );
  }
}

/// Alert notification data
class AlertNotification {
  final String id;
  final AlertRule rule;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final List<LogarteEntry> triggeringLogs;

  AlertNotification({
    required this.id,
    required this.rule,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
    this.triggeringLogs = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ruleId': rule.id,
      'severity': severity.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'triggeringLogsCount': triggeringLogs.length,
    };
  }
}

/// Configuration for alert notifications
class AlertConfig {
  final bool enableAlerts;
  final List<AlertRule> rules;
  final Duration cooldownPeriod; // Prevent spam alerts
  final Function(AlertNotification)? onAlert;
  final String? webhookUrl;
  final Map<String, String>? webhookHeaders;

  const AlertConfig({
    this.enableAlerts = false,
    this.rules = const [],
    this.cooldownPeriod = const Duration(minutes: 5),
    this.onAlert,
    this.webhookUrl,
    this.webhookHeaders,
  });

  AlertConfig copyWith({
    bool? enableAlerts,
    List<AlertRule>? rules,
    Duration? cooldownPeriod,
    Function(AlertNotification)? onAlert,
    String? webhookUrl,
    Map<String, String>? webhookHeaders,
  }) {
    return AlertConfig(
      enableAlerts: enableAlerts ?? this.enableAlerts,
      rules: rules ?? this.rules,
      cooldownPeriod: cooldownPeriod ?? this.cooldownPeriod,
      onAlert: onAlert ?? this.onAlert,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      webhookHeaders: webhookHeaders ?? this.webhookHeaders,
    );
  }
}

/// Service for monitoring logs and triggering alerts
class LogarteAlertService {
  final AlertConfig _config;

  // Tracking data structures
  final Map<String, Queue<DateTime>> _endpointFailures = {};
  final Map<String, DateTime> _lastAlertTime = {};
  final List<AlertNotification> _recentAlerts = [];

  // Stream controller for real-time alerts
  final StreamController<AlertNotification> _alertController =
      StreamController.broadcast();

  LogarteAlertService(this._config);

  /// Stream of alert notifications
  Stream<AlertNotification> get alertStream => _alertController.stream;

  /// Get recent alerts
  List<AlertNotification> get recentAlerts => List.unmodifiable(_recentAlerts);

  /// Process a log entry for potential alerts
  void processLogEntry(LogarteEntry entry) {
    if (!_config.enableAlerts) return;

    for (final rule in _config.rules) {
      if (!rule.enabled) continue;

      try {
        _checkRule(rule, entry);
      } catch (e) {
        debugPrint('Error processing alert rule ${rule.id}: $e');
      }
    }
  }

  void _checkRule(AlertRule rule, LogarteEntry entry) {
    switch (rule.type) {
      case AlertType.apiFailure:
        _checkApiFailure(rule, entry);
        break;
      case AlertType.slowResponse:
        _checkSlowResponse(rule, entry);
        break;
      case AlertType.crashDetected:
        _checkCrash(rule, entry);
        break;
      case AlertType.customThreshold:
        _checkCustomCondition(rule, entry);
        break;
      case AlertType.highErrorRate:
        // TODO: Implement error rate monitoring
        break;
    }
  }

  void _checkApiFailure(AlertRule rule, LogarteEntry entry) {
    if (entry is! NetworkLogarteEntry) return;

    final statusCode = entry.response.statusCode;
    if (statusCode == null) return;

    // Check if this status code should be monitored
    if (!rule.statusCodesToMonitor.contains(statusCode)) return;

    // Check endpoint pattern if specified
    if (rule.endpointPattern != null) {
      final regex = RegExp(rule.endpointPattern!);
      if (!regex.hasMatch(entry.request.url)) return;
    }

    // Extract endpoint identifier (URL without query params)
    final endpoint = _normalizeEndpoint(entry.request.url);

    // Track this failure
    _trackFailure(endpoint, rule);

    // Check if threshold is exceeded
    final failures = _endpointFailures[endpoint];
    if (failures != null && failures.length >= rule.failureThreshold) {
      _triggerAlert(rule, endpoint, entry, failures.toList());
    }
  }

  void _checkSlowResponse(AlertRule rule, LogarteEntry entry) {
    if (entry is! NetworkLogarteEntry) return;
    if (rule.slowResponseThreshold == null) return;

    final duration =
        entry.response.receivedAt != null && entry.request.sentAt != null
            ? entry.response.receivedAt!
                .difference(entry.request.sentAt!)
                .inMilliseconds
            : null;

    if (duration != null && duration > rule.slowResponseThreshold!) {
      final endpoint = _normalizeEndpoint(entry.request.url);
      _triggerSlowResponseAlert(rule, endpoint, entry, duration);
    }
  }

  void _checkCrash(AlertRule rule, LogarteEntry entry) {
    if (entry is! PlainLogarteEntry) return;

    final message = entry.message.toLowerCase();
    if (message.contains('crash') ||
        message.contains('fatal') ||
        message.contains('segfault') ||
        message.contains('exception')) {
      _triggerCrashAlert(rule, entry);
    }
  }

  void _checkCustomCondition(AlertRule rule, LogarteEntry entry) {
    if (rule.customCondition == null) return;

    if (rule.customCondition!(entry)) {
      _triggerCustomAlert(rule, entry);
    }
  }

  void _trackFailure(String endpoint, AlertRule rule) {
    final now = DateTime.now();
    final cutoff = now.subtract(rule.timeWindow);

    // Initialize or get existing failure queue
    _endpointFailures[endpoint] ??= Queue<DateTime>();
    final failures = _endpointFailures[endpoint]!;

    // Remove old failures outside time window
    while (failures.isNotEmpty && failures.first.isBefore(cutoff)) {
      failures.removeFirst();
    }

    // Add current failure
    failures.add(now);
  }

  String _normalizeEndpoint(String url) {
    try {
      final uri = Uri.parse(url);
      // Remove query parameters and fragments for grouping
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (e) {
      return url;
    }
  }

  void _triggerAlert(AlertRule rule, String endpoint,
      LogarteEntry triggeringEntry, List<DateTime> failures) {
    final alertId =
        '${rule.id}_${endpoint}_${DateTime.now().millisecondsSinceEpoch}';

    // Check cooldown period
    if (_isInCooldown(alertId, rule)) return;

    final alert = AlertNotification(
      id: alertId,
      rule: rule,
      severity: rule.severity,
      title: 'API Endpoint Failure Alert',
      message:
          'Endpoint "$endpoint" failed ${failures.length} times in ${rule.timeWindow.inMinutes} minutes',
      timestamp: DateTime.now(),
      metadata: {
        'endpoint': endpoint,
        'failureCount': failures.length,
        'timeWindow': rule.timeWindow.inMinutes,
        'statusCode':
            (triggeringEntry as NetworkLogarteEntry).response.statusCode,
      },
      triggeringLogs: [triggeringEntry],
    );

    _sendAlert(alert);
  }

  void _triggerSlowResponseAlert(AlertRule rule, String endpoint,
      NetworkLogarteEntry entry, int duration) {
    final alertId =
        '${rule.id}_slow_${endpoint}_${DateTime.now().millisecondsSinceEpoch}';

    if (_isInCooldown(alertId, rule)) return;

    final alert = AlertNotification(
      id: alertId,
      rule: rule,
      severity: rule.severity,
      title: 'Slow API Response Alert',
      message:
          'Endpoint "$endpoint" responded in ${duration}ms (threshold: ${rule.slowResponseThreshold}ms)',
      timestamp: DateTime.now(),
      metadata: {
        'endpoint': endpoint,
        'responseTime': duration,
        'threshold': rule.slowResponseThreshold,
      },
      triggeringLogs: [entry],
    );

    _sendAlert(alert);
  }

  void _triggerCrashAlert(AlertRule rule, PlainLogarteEntry entry) {
    final alertId = '${rule.id}_crash_${DateTime.now().millisecondsSinceEpoch}';

    if (_isInCooldown(alertId, rule)) return;

    final alert = AlertNotification(
      id: alertId,
      rule: rule,
      severity: AlertSeverity.critical,
      title: 'Application Crash Detected',
      message: 'Crash detected: ${entry.message}',
      timestamp: DateTime.now(),
      metadata: {
        'crashMessage': entry.message,
        'source': entry.source,
      },
      triggeringLogs: [entry],
    );

    _sendAlert(alert);
  }

  void _triggerCustomAlert(AlertRule rule, LogarteEntry entry) {
    final alertId =
        '${rule.id}_custom_${DateTime.now().millisecondsSinceEpoch}';

    if (_isInCooldown(alertId, rule)) return;

    final alert = AlertNotification(
      id: alertId,
      rule: rule,
      severity: rule.severity,
      title: rule.name,
      message: rule.description,
      timestamp: DateTime.now(),
      metadata: {
        'ruleType': 'custom',
      },
      triggeringLogs: [entry],
    );

    _sendAlert(alert);
  }

  bool _isInCooldown(String alertId, AlertRule rule) {
    final ruleKey = '${rule.id}_cooldown';
    final lastAlert = _lastAlertTime[ruleKey];

    if (lastAlert == null) return false;

    return DateTime.now().difference(lastAlert) < _config.cooldownPeriod;
  }

  void _sendAlert(AlertNotification alert) {
    // Update cooldown tracking
    _lastAlertTime['${alert.rule.id}_cooldown'] = alert.timestamp;

    // Store recent alert
    _recentAlerts.add(alert);
    if (_recentAlerts.length > 100) {
      _recentAlerts.removeAt(0);
    }

    // Send to stream
    _alertController.add(alert);

    // Call configured callback
    _config.onAlert?.call(alert);

    // Send webhook if configured
    _sendWebhook(alert);

    debugPrint('🚨 ALERT: ${alert.title} - ${alert.message}');
  }

  void _sendWebhook(AlertNotification alert) {
    if (_config.webhookUrl == null) return;

    // TODO: Implement HTTP webhook call
    // This would typically use http package to send POST request
    debugPrint('📡 Webhook: ${_config.webhookUrl} - ${alert.toMap()}');
  }

  /// Clear failure tracking for an endpoint
  void clearEndpointFailures(String endpoint) {
    final normalized = _normalizeEndpoint(endpoint);
    _endpointFailures.remove(normalized);
  }

  /// Get current failure count for an endpoint
  int getEndpointFailureCount(String endpoint) {
    final normalized = _normalizeEndpoint(endpoint);
    return _endpointFailures[normalized]?.length ?? 0;
  }

  /// Get all monitored endpoints with their failure counts
  Map<String, int> getAllEndpointFailures() {
    return Map.fromEntries(
      _endpointFailures.entries.map(
        (e) => MapEntry(e.key, e.value.length),
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _alertController.close();
  }
}

/// Predefined alert rules for common scenarios
class PredefinedAlertRules {
  static const AlertRule apiFailures = AlertRule(
    id: 'api_failures_10_in_5min',
    type: AlertType.apiFailure,
    severity: AlertSeverity.high,
    name: 'API Failures',
    description: 'Alert when same endpoint fails 10+ times in 5 minutes',
    failureThreshold: 10,
    timeWindow: Duration(minutes: 5),
    statusCodesToMonitor: [400, 401, 403, 404, 500, 502, 503, 504],
  );

  static const AlertRule serverErrors = AlertRule(
    id: 'server_errors_5_in_2min',
    type: AlertType.apiFailure,
    severity: AlertSeverity.critical,
    name: 'Server Errors',
    description: 'Alert on 5+ server errors in 2 minutes',
    failureThreshold: 5,
    timeWindow: Duration(minutes: 2),
    statusCodesToMonitor: [500, 502, 503, 504],
  );

  static const AlertRule slowResponses = AlertRule(
    id: 'slow_responses_5sec',
    type: AlertType.slowResponse,
    severity: AlertSeverity.medium,
    name: 'Slow API Responses',
    description: 'Alert on API responses taking longer than 5 seconds',
    slowResponseThreshold: 5000,
  );

  static const AlertRule crashes = AlertRule(
    id: 'app_crashes',
    type: AlertType.crashDetected,
    severity: AlertSeverity.critical,
    name: 'Application Crashes',
    description: 'Alert on application crashes and fatal errors',
  );

  static List<AlertRule> get defaultRules => [
        apiFailures,
        serverErrors,
        slowResponses,
        crashes,
      ];
}
