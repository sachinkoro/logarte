/// Configuration class for Logarte cloud features
class LogarteCloudConfig {
  /// User identification - either userId OR phoneNumber must be provided
  final String? userId;
  final String? phoneNumber;

  /// Optional user details
  final String? email;
  final String? displayName;

  /// Team configuration
  final String? teamId;
  final String? role; // 'developer', 'admin', 'viewer'

  /// Cloud logging settings
  final bool enableCloudLogging;
  final int logRetentionDays;
  final bool allowTeamAccess;

  /// Performance settings
  final int batchSize;
  final int batchUploadIntervalSeconds;
  final int maxLogSizeBytes;

  /// Firebase configuration
  final String? firebaseProjectId;
  final Map<String, dynamic>? firebaseOptions;

  const LogarteCloudConfig({
    this.userId,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.teamId,
    this.role,
    this.enableCloudLogging = false,
    this.logRetentionDays = 7,
    this.allowTeamAccess = false,
    this.batchSize = 10,
    this.batchUploadIntervalSeconds = 30,
    this.maxLogSizeBytes = 10000,
    this.firebaseProjectId,
    this.firebaseOptions,
  }) : assert(
          enableCloudLogging == false || userId != null || phoneNumber != null,
          'Either userId or phoneNumber must be provided when cloud logging is enabled',
        );

  /// Creates a copy with modified values
  LogarteCloudConfig copyWith({
    String? userId,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? teamId,
    String? role,
    bool? enableCloudLogging,
    int? logRetentionDays,
    bool? allowTeamAccess,
    int? batchSize,
    int? batchUploadIntervalSeconds,
    int? maxLogSizeBytes,
    String? firebaseProjectId,
    Map<String, dynamic>? firebaseOptions,
  }) {
    return LogarteCloudConfig(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      enableCloudLogging: enableCloudLogging ?? this.enableCloudLogging,
      logRetentionDays: logRetentionDays ?? this.logRetentionDays,
      allowTeamAccess: allowTeamAccess ?? this.allowTeamAccess,
      batchSize: batchSize ?? this.batchSize,
      batchUploadIntervalSeconds:
          batchUploadIntervalSeconds ?? this.batchUploadIntervalSeconds,
      maxLogSizeBytes: maxLogSizeBytes ?? this.maxLogSizeBytes,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      firebaseOptions: firebaseOptions ?? this.firebaseOptions,
    );
  }

  /// Default configuration for development
  static const LogarteCloudConfig development = LogarteCloudConfig(
    enableCloudLogging: false,
    logRetentionDays: 3,
    allowTeamAccess: true,
    batchSize: 5,
    batchUploadIntervalSeconds: 10,
  );

  /// Default configuration for production
  static const LogarteCloudConfig production = LogarteCloudConfig(
    enableCloudLogging:
        false, // Set to false for const, enable when configuring with user ID
    logRetentionDays: 7,
    allowTeamAccess: false,
    batchSize: 20,
    batchUploadIntervalSeconds: 60,
  );

  @override
  String toString() {
    return 'LogarteCloudConfig('
        'userId: $userId, '
        'phoneNumber: $phoneNumber, '
        'enableCloudLogging: $enableCloudLogging, '
        'teamId: $teamId, '
        'role: $role'
        ')';
  }
}
