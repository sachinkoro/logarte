import '../models/logarte_user.dart';

/// Secure configuration for Logarte that uses API endpoints instead of direct Firebase access
/// This approach keeps Firebase credentials safe on the server side
class LogarteSecureConfig {
  /// Your secure API endpoint (hosted backend service)
  final String apiEndpoint;

  /// API key for authentication with your backend
  /// This is safer than Firebase credentials as it can be scoped and revoked
  final String apiKey;

  /// User information for log attribution
  final LogarteUser user;

  /// Enable cloud logging
  final bool enableCloudLogging;

  /// Batch logs for better performance
  final bool enableBatching;

  /// Number of logs to batch before sending
  final int batchSize;

  /// Timeout for API requests
  final Duration requestTimeout;

  /// Enable offline support (logs stored locally when offline)
  final bool enableOfflineSupport;

  /// Environment (development, staging, production)
  final String environment;

  const LogarteSecureConfig({
    required this.apiEndpoint,
    required this.apiKey,
    required this.user,
    this.enableCloudLogging = true,
    this.enableBatching = true,
    this.batchSize = 10,
    this.requestTimeout = const Duration(seconds: 30),
    this.enableOfflineSupport = true,
    this.environment = 'production',
  });

  /// Copy configuration with changes
  LogarteSecureConfig copyWith({
    String? apiEndpoint,
    String? apiKey,
    LogarteUser? user,
    bool? enableCloudLogging,
    bool? enableBatching,
    int? batchSize,
    Duration? requestTimeout,
    bool? enableOfflineSupport,
    String? environment,
  }) {
    return LogarteSecureConfig(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      user: user ?? this.user,
      enableCloudLogging: enableCloudLogging ?? this.enableCloudLogging,
      enableBatching: enableBatching ?? this.enableBatching,
      batchSize: batchSize ?? this.batchSize,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      enableOfflineSupport: enableOfflineSupport ?? this.enableOfflineSupport,
      environment: environment ?? this.environment,
    );
  }

  /// Validate the configuration
  String? validate() {
    if (apiEndpoint.isEmpty) {
      return 'API endpoint is required';
    }

    if (!apiEndpoint.startsWith('http')) {
      return 'API endpoint must be a valid URL';
    }

    if (apiKey.isEmpty) {
      return 'API key is required';
    }

    if (user.userId == null && user.email == null && user.phoneNumber == null) {
      return 'User must have at least userId, email, or phoneNumber';
    }

    if (batchSize <= 0) {
      return 'Batch size must be greater than 0';
    }

    return null; // Valid
  }

  /// Development configuration template
  static LogarteSecureConfig development({
    required String apiEndpoint,
    required String apiKey,
    required LogarteUser user,
  }) {
    return LogarteSecureConfig(
      apiEndpoint: apiEndpoint,
      apiKey: apiKey,
      user: user,
      enableCloudLogging: true,
      enableBatching: false, // Immediate logging for debugging
      batchSize: 1,
      requestTimeout: const Duration(seconds: 10),
      enableOfflineSupport: true,
      environment: 'development',
    );
  }

  /// Production configuration template
  static LogarteSecureConfig production({
    required String apiEndpoint,
    required String apiKey,
    required LogarteUser user,
  }) {
    return LogarteSecureConfig(
      apiEndpoint: apiEndpoint,
      apiKey: apiKey,
      user: user,
      enableCloudLogging: true,
      enableBatching: true,
      batchSize: 20,
      requestTimeout: const Duration(seconds: 30),
      enableOfflineSupport: true,
      environment: 'production',
    );
  }

  @override
  String toString() {
    return 'LogarteSecureConfig(endpoint: $apiEndpoint, environment: $environment, batching: $enableBatching)';
  }
}
