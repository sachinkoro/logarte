/// User model for Firestore storage
class LogarteUser {
  final String userId;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
  final String? teamId;
  final String role; // 'developer', 'admin', 'viewer'
  final bool isActive;
  final DateTime lastSeen;
  final DateTime? createdAt;
  final DateTime updatedAt;
  final LogarteUserSettings settings;

  const LogarteUser({
    required this.userId,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.teamId,
    required this.role,
    required this.isActive,
    required this.lastSeen,
    this.createdAt,
    required this.updatedAt,
    required this.settings,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'email': email,
      'displayName': displayName,
      'teamId': teamId,
      'role': role,
      'isActive': isActive,
      'lastSeen': lastSeen,
      if (createdAt != null) 'createdAt': createdAt,
      'updatedAt': updatedAt,
      'settings': settings.toMap(),
    };
  }

  factory LogarteUser.fromMap(Map<String, dynamic> map) {
    return LogarteUser(
      userId: map['userId'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      teamId: map['teamId'] as String?,
      role: map['role'] as String,
      isActive: map['isActive'] as bool,
      lastSeen: (map['lastSeen'] as DateTime),
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: (map['updatedAt'] as DateTime),
      settings:
          LogarteUserSettings.fromMap(map['settings'] as Map<String, dynamic>),
    );
  }

  LogarteUser copyWith({
    String? userId,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? teamId,
    String? role,
    bool? isActive,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    LogarteUserSettings? settings,
  }) {
    return LogarteUser(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
    );
  }
}

/// User settings model
class LogarteUserSettings {
  final bool enableCloudLogging;
  final int logRetentionDays;
  final bool allowTeamAccess;

  const LogarteUserSettings({
    required this.enableCloudLogging,
    required this.logRetentionDays,
    required this.allowTeamAccess,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableCloudLogging': enableCloudLogging,
      'logRetentionDays': logRetentionDays,
      'allowTeamAccess': allowTeamAccess,
    };
  }

  factory LogarteUserSettings.fromMap(Map<String, dynamic> map) {
    return LogarteUserSettings(
      enableCloudLogging: map['enableCloudLogging'] as bool,
      logRetentionDays: map['logRetentionDays'] as int,
      allowTeamAccess: map['allowTeamAccess'] as bool,
    );
  }

  LogarteUserSettings copyWith({
    bool? enableCloudLogging,
    int? logRetentionDays,
    bool? allowTeamAccess,
  }) {
    return LogarteUserSettings(
      enableCloudLogging: enableCloudLogging ?? this.enableCloudLogging,
      logRetentionDays: logRetentionDays ?? this.logRetentionDays,
      allowTeamAccess: allowTeamAccess ?? this.allowTeamAccess,
    );
  }
}

/// Team model for Firestore storage
class LogarteTeam {
  final String teamId;
  final String name;
  final String? description;
  final String ownerId;
  final List<String> members;
  final LogarteTeamSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LogarteTeam({
    required this.teamId,
    required this.name,
    this.description,
    required this.ownerId,
    required this.members,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'members': members,
      'settings': settings.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory LogarteTeam.fromMap(Map<String, dynamic> map) {
    return LogarteTeam(
      teamId: map['teamId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      ownerId: map['ownerId'] as String,
      members: List<String>.from(map['members'] as List),
      settings:
          LogarteTeamSettings.fromMap(map['settings'] as Map<String, dynamic>),
      createdAt: (map['createdAt'] as DateTime),
      updatedAt: (map['updatedAt'] as DateTime),
    );
  }
}

/// Team settings model
class LogarteTeamSettings {
  final int logRetentionDays;
  final int maxLogsPerUser;
  final bool allowCrossUserAccess;

  const LogarteTeamSettings({
    required this.logRetentionDays,
    required this.maxLogsPerUser,
    required this.allowCrossUserAccess,
  });

  Map<String, dynamic> toMap() {
    return {
      'logRetentionDays': logRetentionDays,
      'maxLogsPerUser': maxLogsPerUser,
      'allowCrossUserAccess': allowCrossUserAccess,
    };
  }

  factory LogarteTeamSettings.fromMap(Map<String, dynamic> map) {
    return LogarteTeamSettings(
      logRetentionDays: map['logRetentionDays'] as int,
      maxLogsPerUser: map['maxLogsPerUser'] as int,
      allowCrossUserAccess: map['allowCrossUserAccess'] as bool,
    );
  }
}
