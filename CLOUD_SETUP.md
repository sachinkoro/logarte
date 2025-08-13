# 🚀 Logarte Cloud Setup - Complete Guide

Store your Flutter app logs securely in the cloud with **zero Firebase credential exposure**.

## ⚡ Quick Start (5 Minutes)

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  logarte: ^1.2.0
  http: ^1.1.0
```

### 2. Deploy Secure Backend

```bash
# Clone and deploy the secure API
git clone <your-logarte-repo>
cd logarte/backend-api
firebase login
firebase deploy --only functions
```

### 3. Configure Your Flutter App

```dart
import 'package:logarte/logarte.dart';

void main() {
  // 🔐 SECURE: No Firebase credentials in your app!
  final logarte = Logarte(
    secureConfig: LogarteSecureConfig.production(
      apiEndpoint: 'https://your-functions-url.com',
      apiKey: 'your-secure-api-key',
      user: LogarteUser(
        userId: 'user123',
        email: 'user@company.com',
        displayName: 'John Doe',
        teamId: 'frontend-team',
        role: 'developer',
        isActive: true,
        lastSeen: DateTime.now(),
        updatedAt: DateTime.now(),
        settings: LogarteUserSettings(
          enableCloudLogging: true,
          logRetentionDays: 30,
          allowTeamAccess: true,
        ),
      ),
    ),
  );

  runApp(MyApp());
}
```

### 4. Start Logging

```dart
// Your logs are now stored securely in the cloud!
logarte.log('User completed checkout');
logarte.log('API Error: ${error.message}', stackTrace: stackTrace);
```

## 🏗️ Complete Setup

### Step 1: Deploy Backend Infrastructure

#### Option A: Firebase Cloud Functions (Recommended)
```bash
# 1. Create Firebase project
firebase projects:create your-app-logs

# 2. Deploy secure API
cd logarte/backend-api
npm install
firebase use your-app-logs
firebase deploy --only functions

# 3. Note the deployed URLs
firebase functions:list
```

#### Option B: Your Own Server
```bash
# Deploy to any cloud provider
cd logarte/backend-api/express
npm install
npm start # or deploy to Vercel/Heroku/AWS
```

### Step 2: Generate API Keys

```bash
# Generate secure API keys
node scripts/generate-api-keys.js --env production --org your-company

# Import to Firestore
node scripts/import-api-keys.js
```

**Generated Keys:**
- **Mobile App**: `lga_prod_xxx` (logs:write, alerts:create)
- **Dashboard**: `lga_prod_yyy` (logs:read, logs:write, alerts:*)
- **Admin**: `lga_prod_zzz` (admin:*, users:*, teams:*)

### Step 3: Configure Flutter App

#### Production Configuration
```dart
final config = LogarteSecureConfig.production(
  apiEndpoint: 'https://submitlogs-xxx-uc.a.run.app',
  apiKey: 'lga_prod_your_mobile_key_here',
  user: LogarteUser(
    userId: currentUser.id,
    email: currentUser.email,
    displayName: currentUser.name,
    teamId: currentUser.teamId, // Optional team grouping
    role: 'developer', // developer, admin, viewer
    isActive: true,
    lastSeen: DateTime.now(),
    updatedAt: DateTime.now(),
    settings: LogarteUserSettings(
      enableCloudLogging: true,
      logRetentionDays: 30,
      allowTeamAccess: true,
    ),
  ),
);
```

#### Development Configuration
```dart
final config = LogarteSecureConfig.development(
  apiEndpoint: 'https://dev-functions-url.com',
  apiKey: 'lga_dev_your_dev_key_here',
  user: LogarteUser(
    userId: 'dev-user',
    email: 'dev@company.com',
    // ... other fields
  ),
);
```

### Step 4: Add to Your App

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Add network logging
      navigatorObservers: [LogarteNavigatorObserver(logarte)],
      home: MyHomePage(),
    );
  }
}

class ApiService {
  final Dio dio = Dio();
  
  ApiService() {
    // Add automatic API logging
    dio.interceptors.add(LogarteDioInterceptor(logarte));
  }
}
```

## 📊 Usage Examples

### Basic Logging
```dart
// Plain logs
logarte.log('User opened settings page');
logarte.log('Error processing payment: ${error}', stackTrace: stackTrace);

// Database operations
logarte.database(
  target: 'users',
  value: {'name': 'John', 'email': 'john@example.com'},
  source: 'CREATE',
);
```

### Automatic Logging
```dart
// Network requests (automatic with Dio interceptor)
final response = await dio.get('/api/users');

// Navigation (automatic with navigator observer)
Navigator.pushNamed(context, '/profile');
```

### Force Sync
```dart
// Upload pending logs immediately
await logarte.syncToCloud();

// Check status
final status = logarte.getCloudStatus();
print('Logs enabled: ${status['isEnabled']}');
print('User: ${status['userId']}');
```

## 🔐 Security Features

### ✅ What's Secure
- **No Firebase credentials** in mobile apps
- **API keys are revokable** without app updates
- **Rate limiting** (50,000 requests/hour)
- **Team-based access control**
- **Server-side validation**
- **Complete audit trail**

### 🔑 API Key Permissions
```dart
// Mobile App Key (recommended for apps)
permissions: ['logs:write', 'alerts:create']

// Dashboard Key (for web dashboards)  
permissions: ['logs:read', 'logs:write', 'alerts:*']

// Admin Key (for management)
permissions: ['admin:*', 'users:*', 'teams:*']
```

## 🌐 Web Dashboard Access

Your organization gets a web dashboard at:
```
https://your-dashboard-url.com
```

**Features:**
- 📊 Real-time log viewing
- 👥 User and team management
- 🚨 Alert configuration
- 📈 Analytics and charts
- ⚙️ Organization settings

**Login:** Google Firebase Authentication

## 🔧 Configuration Options

### Batching & Performance
```dart
LogarteSecureConfig(
  enableBatching: true,        // Batch logs for efficiency
  batchSize: 20,              // Logs per batch
  requestTimeout: Duration(seconds: 30),
  enableOfflineSupport: true, // Cache when offline
)
```

### User Settings
```dart
LogarteUserSettings(
  enableCloudLogging: true,    // Enable cloud storage
  logRetentionDays: 30,       // Auto-delete after 30 days
  allowTeamAccess: true,      // Team can view logs
)
```

### Environment Separation
```dart
// Use different keys for different environments
final config = kDebugMode 
    ? LogarteSecureConfig.development(...)
    : LogarteSecureConfig.production(...);
```

## 🚨 Alert System

```dart
// Alerts are automatically generated for:
// - API failures (>10 failures in 5 minutes)
// - High error rates (>10% error rate)
// - Slow responses (>2 second response time)

// View recent alerts
final alerts = logarte.recentAlerts;

// Check endpoint failures
final failures = logarte.getEndpointFailures();
print('API failures: ${failures['/api/users']}');
```

## 💰 Pricing

### Firebase Cloud Functions
- **Free Tier**: 2M requests/month
- **Paid**: $0.40 per million requests
- **Firestore**: $0.06 per 100K reads

### Typical Costs
- **Small app**: $1-5/month
- **Medium app**: $10-25/month
- **Large app**: $50-100/month

## 🆘 Troubleshooting

### Common Issues

**1. API Key Invalid**
```dart
// Check your API key is correct and active
// Regenerate if needed: node scripts/generate-api-keys.js
```

**2. Network Errors**
```dart
// Check endpoint URL and network connectivity
final status = logarte.getCloudStatus();
print('Online: ${status['isOnline']}');
```

**3. Logs Not Appearing**
```dart
// Force sync pending logs
await logarte.syncToCloud();

// Check if cloud logging is enabled
print('Cloud enabled: ${logarte.isCloudLoggingEnabled}');
```

### Debug Mode
```dart
// Enable debug logs to see what's happening
LogarteSecureConfig.development(
  // ... config
);
```

## 📞 Support

- **📖 Documentation**: [Full API Reference](./docs/)
- **🐛 Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **💬 Community**: [Discord Server](https://discord.gg/logarte)

---

## 🎉 You're Ready!

Your Flutter app now has **enterprise-grade cloud logging** with:
- ✅ **100% secure** Firebase credential protection
- ✅ **Real-time** log storage and monitoring
- ✅ **Team collaboration** and access control
- ✅ **Professional dashboard** for log management
- ✅ **Smart alerts** for proactive monitoring

**Start logging securely! 🚀**
