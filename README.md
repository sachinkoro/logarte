# 🚀 Logarte - Advanced Flutter Debug Console

**Powerful in-app debug console and cloud logging platform for Flutter apps with network inspector, storage monitor, team collaboration, smart alerts, and enterprise-grade security.**

[![pub package](https://img.shields.io/pub/v/logarte.svg)](https://pub.dartlang.org/packages/logarte)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)

---

## 📦 **What's New in v1.2.0**

🌟 **Cloud Logging** - Store logs in Firestore with team collaboration  
🚨 **Smart Alerts** - Monitor API failures and get real-time notifications  
👥 **Team Features** - Secure log sharing between team members  
🔒 **Enterprise Security** - Granular access controls and data encryption  
🤖 **Auto Cleanup** - Scheduled log cleanup with configurable retention  
📊 **Real-time Monitoring** - Live log streaming and analytics  

---

## 📦 **Features**

### **Local Debugging** (v1.0+)
- 🚀 **In-app console**: Monitor your app inside your app
- 🔒 **Access control**: Optional password protection
- 📡 **Network inspector**: Track API calls and responses
- 📁 **Storage monitor**: Track local storage operations
- 📤 **Copy & export**: Share debug logs with your team
- 📄 **Curl command**: Copy cURL command for API requests

### **Cloud & Team Features** (v1.2+)
- ☁️ **Cloud Storage**: Persistent logging in Firebase Firestore
- 👥 **Team Collaboration**: Secure log sharing between team members
- 🚨 **Smart Alerts**: Monitor API failures with configurable thresholds
- 📊 **Real-time Streaming**: Live log monitoring and updates
- 🤖 **Auto Cleanup**: Scheduled log cleanup every night
- 🔐 **Enterprise Security**: User isolation and team access controls

---

## 📱 **Screenshots**

| Local Console | Cloud Dashboard | Smart Alerts |
|---|---|---|
| <img width="200" src="https://github.com/kamranbekirovyz/logarte/blob/main/res/s1.png?raw=true"/> | <img width="200" src="https://github.com/kamranbekirovyz/logarte/blob/main/res/s2.png?raw=true"/> | <img width="200" src="https://github.com/kamranbekirovyz/logarte/blob/main/res/s3.png?raw=true"/> |

---

## 🚀 **Quick Start**

### 1. **Installation**

Add to your `pubspec.yaml`:

```yaml
dependencies:
  logarte: ^1.2.0
  
  # For cloud features (optional)
  firebase_core: ^3.6.0
  cloud_firestore: ^5.4.3
```

Then run:
```bash
flutter pub get
```

### 2. **Basic Setup (Local Only)**

```dart
import 'package:logarte/logarte.dart';

// Create global instance
final Logarte logarte = Logarte(
  password: '1234',                    // Optional password protection
  ignorePassword: kDebugMode,          // Skip password in debug mode
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [
        LogarteNavigatorObserver(logarte),  // Track navigation
      ],
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // Attach floating debug button
    logarte.attach(
      context: context,
      visible: kDebugMode,
    );
  }
}
```

### 3. **Network Logging**

```dart
// With Dio (recommended)
final dio = Dio()
  ..interceptors.add(LogarteDioInterceptor(logarte));

// Manual logging with other HTTP clients
logarte.network(
  request: NetworkRequestLogarteEntry(
    method: 'POST',
    url: 'https://api.example.com/login',
    headers: {'Content-Type': 'application/json'},
    body: {'username': 'user', 'password': 'pass'},
  ),
  response: NetworkResponseLogarteEntry(
    statusCode: 200,
    headers: {'Content-Type': 'application/json'},
    body: {'token': 'abc123', 'userId': '456'},
  ),
);
```

### 4. **Custom Logging**

```dart
// Simple logging
logarte.log('User clicked login button');

// Error logging with stack trace
try {
  await riskyOperation();
} catch (e, stackTrace) {
  logarte.log('Operation failed: $e', stackTrace: stackTrace);
}

// Database operations
logarte.database(
  target: 'user_preference',
  value: 'dark_theme',
  source: 'SharedPreferences',
);
```

---

## ☁️ **Cloud Features Setup**

### 1. **Firebase Setup**

Create a Firebase project and add your app:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init firestore
firebase init functions
```

### 2. **Deploy Infrastructure**

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy cleanup functions  
cd functions
npm install
firebase deploy --only functions
```

### 3. **Configure Cloud Logging**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:logarte/logarte.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(MyApp());
}

final Logarte logarte = Logarte(
  // Local features
  password: '1234',
  ignorePassword: kDebugMode,
  
  // Cloud configuration
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: true,
    userId: 'user_12345',              // Your app's user ID
    phoneNumber: '+1234567890',        // Alternative identifier
    email: 'user@example.com',
    displayName: 'John Doe',
    teamId: 'my_team',                 // Team collaboration
    role: 'developer',                 // 'admin', 'developer', 'viewer'
    logRetentionDays: 7,               // Auto-cleanup after 7 days
    allowTeamAccess: true,             // Let team see logs
  ),
  
  // Alert configuration
  alertConfig: AlertConfig(
    enableAlerts: true,
    rules: [
      // Alert when same endpoint fails 10+ times in 5 minutes
      AlertRule(
        id: 'api_failures',
        type: AlertType.apiFailure,
        severity: AlertSeverity.high,
        name: 'API Failures',
        description: 'Multiple failures on same endpoint',
        failureThreshold: 10,
        timeWindow: Duration(minutes: 5),
      ),
    ],
    onAlert: (alert) {
      print('🚨 ALERT: ${alert.title} - ${alert.message}');
      // Send to Slack, email, push notification, etc.
    },
  ),
);
```

---

## 🚨 **Smart Alerts**

Monitor your app's health with intelligent alerts:

### Basic Alert Setup

```dart
AlertConfig(
  enableAlerts: true,
  rules: [
    // Use predefined rules
    PredefinedAlertRules.apiFailures,    // 10 failures in 5 min
    PredefinedAlertRules.serverErrors,   // 5 server errors in 2 min
    PredefinedAlertRules.slowResponses,  // Responses > 5 seconds
    PredefinedAlertRules.crashes,        // App crashes
  ],
  onAlert: (alert) {
    // Handle alerts
    showNotification(alert.title, alert.message);
  },
)
```

### Custom Alert Rules

```dart
// Monitor payment failures aggressively
AlertRule(
  id: 'payment_failures',
  type: AlertType.apiFailure,
  severity: AlertSeverity.critical,
  name: 'Payment Failures',
  description: 'Payment processing issues',
  failureThreshold: 3,               // Very sensitive
  timeWindow: Duration(minutes: 1),
  endpointPattern: r'.*\/payment.*', // Only payment endpoints
),

// Custom condition alerts
AlertRule(
  id: 'custom_condition',
  type: AlertType.customThreshold,
  severity: AlertSeverity.high,
  name: 'Custom Alert',
  description: 'Custom business logic',
  customCondition: (entry) {
    // Your custom logic here
    return shouldTriggerAlert(entry);
  },
),
```

### Real-time Alert Monitoring

```dart
// Listen to alerts
logarte.alertStream.listen((alert) {
  print('Alert: ${alert.title}');
  
  // Send to external systems
  sendToSlack(alert);
  sendPushNotification(alert);
  
  // Trigger automated responses
  if (alert.severity == AlertSeverity.critical) {
    escalateToTeam(alert);
  }
});

// Check alert status
print('Alerts enabled: ${logarte.isAlertSystemEnabled}');
print('Recent alerts: ${logarte.recentAlerts.length}');
print('Endpoint failures: ${logarte.getEndpointFailures()}');
```

---

## 👥 **Team Collaboration**

### User Identification

```dart
// Option 1: User ID (recommended)
LogarteCloudConfig(
  userId: await getCurrentUserId(),
  enableCloudLogging: true,
)

// Option 2: Phone number
LogarteCloudConfig(
  phoneNumber: await getUserPhoneNumber(),
  enableCloudLogging: true,
)

// Option 3: Email
LogarteCloudConfig(
  userId: await getUserEmail(),
  enableCloudLogging: true,
)
```

### Team Configuration

```dart
LogarteCloudConfig(
  userId: employee.id,
  teamId: department.id,
  role: employee.role,              // 'admin', 'developer', 'viewer'
  allowTeamAccess: true,            // Share logs with team
  email: employee.email,
  displayName: employee.name,
)
```

### Cloud Operations

```dart
// Retrieve user logs
final logs = await logarte.getCloudLogs(
  limit: 100,
  logType: 'network',
  startTime: DateTime.now().subtract(Duration(days: 1)),
);

// Retrieve team logs
final teamLogs = await logarte.getTeamCloudLogs(
  teamId: 'my_team',
  limit: 200,
);

// Real-time streaming
logarte.streamCloudLogs().listen((logs) {
  print('New logs: ${logs.length}');
});

// Force sync to cloud
await logarte.syncToCloud();
```

---

## 🎯 **Advanced Usage**

### Production Configuration

```dart
final logarte = Logarte(
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: kReleaseMode,  // Only in production
    userId: await getCurrentUserId(),
    logRetentionDays: 3,               // Short retention
    allowTeamAccess: false,            // Privacy first
    batchSize: 25,                     // Efficient batching
    batchUploadIntervalSeconds: 60,    // Less frequent uploads
  ),
  alertConfig: AlertConfig(
    enableAlerts: kReleaseMode,
    rules: [
      // Only critical alerts in production
      PredefinedAlertRules.serverErrors,
      PredefinedAlertRules.crashes,
    ],
  ),
);
```

### Development Configuration

```dart
final logarte = Logarte(
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: kDebugMode,    // Only in debug
    userId: 'dev_${developer.name}',
    teamId: 'dev_team',
    allowTeamAccess: true,             // Team collaboration
    logRetentionDays: 1,               // Quick cleanup
    batchUploadIntervalSeconds: 10,    // Fast feedback
  ),
  alertConfig: AlertConfig(
    enableAlerts: true,
    rules: PredefinedAlertRules.defaultRules,  // All rules for testing
  ),
);
```

### Hidden Access (Production)

```dart
// Hidden gesture trigger (tap 10 times)
LogarteMagicalTap(
  logarte: logarte,
  child: Text('App Version 1.0'),
)

// Or trigger manually
void onSecretGesture() {
  logarte.openConsole(context);
}
```

### Custom Tab Integration

```dart
final logarte = Logarte(
  customTab: MyCustomDebugTab(),
);

class MyCustomDebugTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Environment'),
          trailing: DropdownButton(
            value: currentEnvironment,
            onChanged: switchEnvironment,
            items: environments.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.name),
            )).toList(),
          ),
        ),
        ListTile(
          title: Text('Clear Cache'),
          trailing: ElevatedButton(
            onPressed: clearAppCache,
            child: Text('Clear'),
          ),
        ),
      ],
    );
  }
}
```

---

## 🔧 **Configuration Reference**

### LogarteCloudConfig

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enableCloudLogging` | `bool` | `false` | Enable cloud storage |
| `userId` | `String?` | `null` | Primary user identifier |
| `phoneNumber` | `String?` | `null` | Alternative identifier |
| `email` | `String?` | `null` | User email |
| `displayName` | `String?` | `null` | User display name |
| `teamId` | `String?` | `null` | Team identifier |
| `role` | `String?` | `'developer'` | User role |
| `logRetentionDays` | `int` | `7` | Days to keep logs |
| `allowTeamAccess` | `bool` | `false` | Allow team to see logs |
| `batchSize` | `int` | `10` | Logs per batch upload |
| `batchUploadIntervalSeconds` | `int` | `30` | Upload interval |
| `maxLogSizeBytes` | `int` | `10000` | Max log size per entry |

### AlertConfig

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enableAlerts` | `bool` | `false` | Enable alert system |
| `rules` | `List<AlertRule>` | `[]` | Alert rules |
| `cooldownPeriod` | `Duration` | `5 minutes` | Prevent alert spam |
| `onAlert` | `Function(AlertNotification)?` | `null` | Alert callback |
| `webhookUrl` | `String?` | `null` | Webhook URL |
| `webhookHeaders` | `Map<String, String>?` | `null` | Webhook headers |

### AlertRule

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | `String` | Unique rule identifier |
| `type` | `AlertType` | Type of alert |
| `severity` | `AlertSeverity` | Alert severity level |
| `name` | `String` | Human-readable name |
| `description` | `String` | Rule description |
| `failureThreshold` | `int` | Number of failures to trigger |
| `timeWindow` | `Duration` | Time window for counting |
| `statusCodesToMonitor` | `List<int>` | HTTP status codes to monitor |
| `endpointPattern` | `String?` | Regex pattern for endpoints |
| `slowResponseThreshold` | `int?` | Milliseconds for slow response |
| `customCondition` | `Function?` | Custom alert condition |

---

## 🛡️ **Security & Privacy**

### Data Protection
- 🔐 **End-to-end encryption** with Firestore
- 🚫 **No sensitive data logging** (passwords, tokens masked)
- 👥 **User isolation** - users only see their own logs
- 🏢 **Team controls** - optional sharing with proper permissions
- 🗑️ **Automatic cleanup** - configurable retention periods

### Access Control
- ✅ **User-based isolation** - Firebase security rules
- ✅ **Team-based sharing** - opt-in log access
- ✅ **Role-based permissions** - admin, developer, viewer
- ✅ **Audit trails** - track access and changes

### Compliance
- 📋 **GDPR compliant** - right to delete, data minimization
- 🔒 **Enterprise security** - encryption at rest and in transit
- 📊 **Audit logging** - track all access and operations
- 🛡️ **SOC 2 ready** - comprehensive security controls

---

## 📊 **Performance & Scaling**

### Optimization
- ⚡ **Batch operations** - efficient Firestore writes
- 💾 **Local buffering** - seamless offline operation
- 🎯 **Smart indexing** - optimized queries
- 📦 **Data compression** - minimal bandwidth usage

### Limits
- 📏 **Log size limit**: 10KB per entry (configurable)
- 🔢 **Batch size**: 10-50 logs per batch (configurable)
- ⏱️ **Upload interval**: 30-120 seconds (configurable)
- 📅 **Retention period**: 1-30 days (configurable)

---

## 🔗 **Integration Examples**

### Slack Integration

```dart
AlertConfig(
  onAlert: (alert) async {
    final webhook = 'YOUR_SLACK_WEBHOOK_URL';
    final message = {
      'text': '🚨 ${alert.title}',
      'attachments': [{
        'color': alert.severity == AlertSeverity.critical ? 'danger' : 'warning',
        'fields': [
          {'title': 'Message', 'value': alert.message, 'short': false},
          {'title': 'Severity', 'value': alert.severity.name, 'short': true},
          {'title': 'Time', 'value': alert.timestamp.toString(), 'short': true},
        ],
      }],
    };
    
    await http.post(
      Uri.parse(webhook),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(message),
    );
  },
)
```

### Push Notifications

```dart
AlertConfig(
  onAlert: (alert) {
    FlutterLocalNotificationsPlugin().show(
      0,
      alert.title,
      alert.message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'logarte_alerts',
          'Logarte Alerts',
          importance: Importance.high,
        ),
      ),
    );
  },
)
```

---

## 🚀 **Migration Guide**

### From v1.0 to v1.2

```dart
// Before (v1.0)
final logarte = Logarte(
  password: '1234',
);

// After (v1.2) - Backward compatible
final logarte = Logarte(
  password: '1234',
  
  // New optional features
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: true,
    userId: 'user_123',
  ),
  alertConfig: AlertConfig(
    enableAlerts: true,
    rules: PredefinedAlertRules.defaultRules,
  ),
);
```

**✅ All existing code continues to work unchanged!**

---

## 📋 **Troubleshooting**

### Common Issues

**Cloud logging not working**
```dart
// Check Firebase initialization
await Firebase.initializeApp();

// Verify configuration
final status = logarte.getCloudStatus();
print('Cloud enabled: ${status['isEnabled']}');
print('User ID: ${status['userId']}');
```

**Alerts not triggering**
```dart
// Check alert system
print('Alerts enabled: ${logarte.isAlertSystemEnabled}');
print('Rules count: ${logarte.alertConfig.rules.length}');

// Test with simple rule
logarte.updateAlertConfig(AlertConfig(
  enableAlerts: true,
  rules: [
    AlertRule(
      id: 'test',
      type: AlertType.apiFailure,
      failureThreshold: 1,  // Very sensitive
      timeWindow: Duration(minutes: 1),
    ),
  ],
));
```

**Permission denied errors**
- ✅ Check Firestore security rules
- ✅ Verify user authentication
- ✅ Ensure userId matches auth user

**Logs not syncing**
```dart
// Force sync
await logarte.syncToCloud();

// Check connectivity
final status = logarte.getCloudStatus();
print('Online: ${status['isOnline']}');
```

---

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
```bash
git clone https://github.com/kamranbekirovyz/logarte.git
cd logarte
flutter pub get
cd example
flutter run
```

---

## 📄 **License**

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🆘 **Support**

- 📖 **Documentation**: [GitHub Wiki](https://github.com/kamranbekirovyz/logarte/wiki)
- 🐛 **Issues**: [GitHub Issues](https://github.com/kamranbekirovyz/logarte/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/kamranbekirovyz/logarte/discussions)
- 📧 **Email**: support@logarte.dev

---

## 🙏 **Sponsors**

Want to say "thanks"? Check out our sponsors:

<a href="https://userorient.com" target="_blank">
  <img src="https://www.userorient.com/assets/extras/sponsor.png">
</a>

---

**Made with ❤️ for the Flutter community**

**Transform your debugging experience with Logarte! 🚀**