# 🚨 Logarte Smart Alert System

Monitor your app's health in real-time with intelligent alerts that detect patterns and notify you when things go wrong!

## 🎯 **Key Features**

✅ **API Failure Detection** - Same endpoint failing multiple times  
✅ **Configurable Thresholds** - 10 failures in 5 minutes (customizable)  
✅ **Smart Grouping** - Groups failures by endpoint  
✅ **Time Windows** - Configurable monitoring periods  
✅ **Severity Levels** - Low, Medium, High, Critical  
✅ **Cooldown Periods** - Prevent alert spam  
✅ **Real-time Streaming** - Live alert notifications  
✅ **Webhook Support** - Integrate with external systems  
✅ **Custom Rules** - Create your own alert conditions  

---

## 🚀 **Quick Setup**

### **1. Basic Alert Configuration**
```dart
final logarte = Logarte(
  alertConfig: AlertConfig(
    enableAlerts: true,
    rules: [
      // Alert when same endpoint fails 10 times in 5 minutes
      AlertRule(
        id: 'api_failures',
        type: AlertType.apiFailure,
        severity: AlertSeverity.high,
        name: 'API Endpoint Failures',
        description: 'Same endpoint failing repeatedly',
        failureThreshold: 10,
        timeWindow: Duration(minutes: 5),
      ),
    ],
    onAlert: (alert) {
      print('🚨 ALERT: ${alert.title} - ${alert.message}');
    },
  ),
);
```

### **2. Listen to Real-time Alerts**
```dart
// Stream of live alerts
logarte.alertStream.listen((alert) {
  // Handle alert notification
  showNotification(alert);
  
  // Send to monitoring dashboard
  sendToSlack(alert);
  
  // Trigger automated response
  if (alert.severity == AlertSeverity.critical) {
    escalateToTeam(alert);
  }
});
```

---

## 📋 **Alert Types**

### **1. API Failure Alerts**
```dart
AlertRule(
  id: 'api_failures',
  type: AlertType.apiFailure,
  severity: AlertSeverity.high,
  name: 'API Failures',
  description: 'Multiple failures on same endpoint',
  
  // Trigger when 10 failures occur within 5 minutes
  failureThreshold: 10,
  timeWindow: Duration(minutes: 5),
  
  // Monitor these status codes
  statusCodesToMonitor: [400, 401, 403, 404, 500, 502, 503, 504],
  
  // Optional: Monitor specific endpoints
  endpointPattern: r'.*\/api\/.*',  // Regex pattern
)
```

### **2. Server Error Alerts**
```dart
AlertRule(
  id: 'server_errors',
  type: AlertType.apiFailure,
  severity: AlertSeverity.critical,
  name: 'Server Errors',
  description: 'Critical server errors detected',
  
  // More aggressive monitoring for server errors
  failureThreshold: 5,
  timeWindow: Duration(minutes: 2),
  statusCodesToMonitor: [500, 502, 503, 504],
)
```

### **3. Slow Response Alerts**
```dart
AlertRule(
  id: 'slow_responses',
  type: AlertType.slowResponse,
  severity: AlertSeverity.medium,
  name: 'Slow API Responses',
  description: 'API taking too long to respond',
  slowResponseThreshold: 5000,  // 5 seconds
)
```

### **4. Crash Detection**
```dart
AlertRule(
  id: 'crashes',
  type: AlertType.crashDetected,
  severity: AlertSeverity.critical,
  name: 'Application Crashes',
  description: 'App crash or fatal error detected',
)
```

### **5. Custom Rules**
```dart
AlertRule(
  id: 'payment_errors',
  type: AlertType.customThreshold,
  severity: AlertSeverity.critical,
  name: 'Payment Processing Errors',
  description: 'Issues with payment processing',
  customCondition: (entry) {
    if (entry is NetworkLogarteEntry) {
      return entry.request.url.contains('/payment') && 
             entry.response.statusCode != null &&
             entry.response.statusCode! >= 400;
    }
    return false;
  },
)
```

---

## ⚙️ **Configuration Options**

### **Alert Severities**
```dart
enum AlertSeverity {
  low,      // 🔵 Info - Minor issues
  medium,   // 🟡 Warning - Attention needed  
  high,     // 🟠 Error - Significant problem
  critical  // 🔴 Critical - Immediate action required
}
```

### **Time Windows**
```dart
// Different monitoring periods
timeWindow: Duration(minutes: 1),   // Very sensitive
timeWindow: Duration(minutes: 5),   // Standard
timeWindow: Duration(minutes: 15),  // Less sensitive
timeWindow: Duration(hours: 1),     // Long-term trends
```

### **Failure Thresholds**
```dart
// Threshold examples for different scenarios
failureThreshold: 3,   // Sensitive - catch issues early
failureThreshold: 10,  // Standard - balanced approach
failureThreshold: 25,  // Conservative - only major issues
```

### **Cooldown Periods**
```dart
AlertConfig(
  cooldownPeriod: Duration(minutes: 5),  // Prevent spam alerts
)
```

---

## 🎛️ **Predefined Rules**

Use ready-made rules for common scenarios:

```dart
AlertConfig(
  enableAlerts: true,
  rules: PredefinedAlertRules.defaultRules,  // Includes all common rules
)

// Or pick specific ones
AlertConfig(
  enableAlerts: true,
  rules: [
    PredefinedAlertRules.apiFailures,    // 10 failures in 5 min
    PredefinedAlertRules.serverErrors,   // 5 server errors in 2 min
    PredefinedAlertRules.slowResponses,  // Responses > 5 seconds
    PredefinedAlertRules.crashes,        // App crashes
  ],
)
```

---

## 📡 **Notification Methods**

### **1. Callback Functions**
```dart
AlertConfig(
  onAlert: (alert) {
    // Custom handling
    print('Alert: ${alert.title}');
    
    // Send push notification
    LocalNotifications.show(alert.title, alert.message);
    
    // Post to Slack
    slackWebhook.send(alert.toSlackMessage());
    
    // Save to database
    database.saveAlert(alert);
  },
)
```

### **2. Webhook Integration**
```dart
AlertConfig(
  webhookUrl: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK',
  webhookHeaders: {
    'Content-Type': 'application/json',
  },
)
```

### **3. Real-time Streams**
```dart
// Listen to alert stream
logarte.alertStream.listen((alert) {
  // Handle each alert as it occurs
  handleAlert(alert);
});

// Get recent alerts
final recentAlerts = logarte.recentAlerts;
```

---

## 📊 **Monitoring & Management**

### **Check Alert System Status**
```dart
// Is alert system enabled and working?
final isEnabled = logarte.isAlertSystemEnabled;

// Get configuration
final config = logarte.alertConfig;
print('Active rules: ${config.rules.length}');
```

### **Track Endpoint Failures**
```dart
// Get all endpoint failure counts
final failures = logarte.getEndpointFailures();
// Returns: {'https://api.example.com/users': 5, ...}

// Get specific endpoint failure count
final count = logarte.getEndpointFailureCount('https://api.example.com/users');

// Clear failures for an endpoint (reset counter)
logarte.clearEndpointFailures('https://api.example.com/users');
```

### **Recent Alerts**
```dart
// Get recent alert notifications
final alerts = logarte.recentAlerts;

for (final alert in alerts) {
  print('${alert.timestamp}: ${alert.title}');
  print('Severity: ${alert.severity}');
  print('Metadata: ${alert.metadata}');
}
```

---

## 🎯 **Real-World Examples**

### **E-commerce App**
```dart
AlertConfig(
  enableAlerts: true,
  rules: [
    // Monitor payment failures aggressively
    AlertRule(
      id: 'payment_failures',
      type: AlertType.apiFailure,
      severity: AlertSeverity.critical,
      name: 'Payment Failures',
      description: 'Payment endpoint issues',
      failureThreshold: 3,              // Very sensitive
      timeWindow: Duration(minutes: 1),
      endpointPattern: r'.*\/payment.*',
    ),
    
    // Monitor login issues
    AlertRule(
      id: 'login_failures',
      type: AlertType.apiFailure,
      severity: AlertSeverity.high,
      name: 'Login Issues',
      description: 'Users cannot log in',
      failureThreshold: 5,
      timeWindow: Duration(minutes: 2),
      endpointPattern: r'.*\/(login|auth).*',
    ),
    
    // Monitor checkout process
    AlertRule(
      id: 'checkout_slow',
      type: AlertType.slowResponse,
      severity: AlertSeverity.medium,
      name: 'Slow Checkout',
      description: 'Checkout taking too long',
      slowResponseThreshold: 3000,      // 3 seconds
    ),
  ],
)
```

### **Social Media App**
```dart
AlertConfig(
  enableAlerts: true,
  rules: [
    // Monitor image upload failures
    AlertRule(
      id: 'upload_failures',
      type: AlertType.apiFailure,
      severity: AlertSeverity.high,
      name: 'Upload Failures',
      description: 'Users cannot upload content',
      failureThreshold: 8,
      timeWindow: Duration(minutes: 3),
      endpointPattern: r'.*\/upload.*',
    ),
    
    // Monitor feed loading issues
    AlertRule(
      id: 'feed_errors',
      type: AlertType.apiFailure,
      severity: AlertSeverity.medium,
      name: 'Feed Loading Issues',
      description: 'Feed not loading properly',
      failureThreshold: 15,
      timeWindow: Duration(minutes: 5),
      endpointPattern: r'.*\/feed.*',
    ),
  ],
)
```

### **Banking App**
```dart
AlertConfig(
  enableAlerts: true,
  cooldownPeriod: Duration(minutes: 1),  // Frequent updates for banking
  rules: [
    // Monitor transaction failures
    AlertRule(
      id: 'transaction_failures',
      type: AlertType.apiFailure,
      severity: AlertSeverity.critical,
      name: 'Transaction Failures',
      description: 'Transaction processing issues',
      failureThreshold: 2,              // Very sensitive
      timeWindow: Duration(minutes: 1),
      endpointPattern: r'.*\/(transfer|transaction).*',
    ),
    
    // Monitor authentication
    AlertRule(
      id: 'auth_failures',
      type: AlertType.apiFailure,
      severity: AlertSeverity.high,
      name: 'Authentication Issues',
      description: 'Users cannot authenticate',
      failureThreshold: 3,
      timeWindow: Duration(minutes: 1),
      statusCodesToMonitor: [401, 403],
    ),
  ],
)
```

---

## 🔧 **Integration Examples**

### **Slack Integration**
```dart
AlertConfig(
  onAlert: (alert) async {
    final slackMessage = {
      'text': '🚨 ${alert.title}',
      'attachments': [
        {
          'color': _getSlackColor(alert.severity),
          'fields': [
            {
              'title': 'Message',
              'value': alert.message,
              'short': false,
            },
            {
              'title': 'Severity',
              'value': alert.severity.name.toUpperCase(),
              'short': true,
            },
            {
              'title': 'Time',
              'value': alert.timestamp.toString(),
              'short': true,
            },
          ],
        },
      ],
    };
    
    await http.post(
      Uri.parse('YOUR_SLACK_WEBHOOK_URL'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(slackMessage),
    );
  },
)

String _getSlackColor(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.low: return 'good';
    case AlertSeverity.medium: return 'warning';
    case AlertSeverity.high: return 'danger';
    case AlertSeverity.critical: return 'danger';
  }
}
```

### **Push Notifications**
```dart
AlertConfig(
  onAlert: (alert) {
    // Send local notification
    FlutterLocalNotificationsPlugin().show(
      0,
      alert.title,
      alert.message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alerts',
          'Logarte Alerts',
          importance: _getImportance(alert.severity),
        ),
      ),
    );
  },
)
```

### **Email Alerts**
```dart
AlertConfig(
  onAlert: (alert) async {
    if (alert.severity == AlertSeverity.critical) {
      await emailService.send(
        to: 'team@company.com',
        subject: '🚨 CRITICAL ALERT: ${alert.title}',
        body: '''
        Critical alert triggered in production app:
        
        Title: ${alert.title}
        Message: ${alert.message}
        Time: ${alert.timestamp}
        
        Please investigate immediately.
        ''',
      );
    }
  },
)
```

---

## 📈 **Best Practices**

### **1. Start Conservative**
```dart
// Begin with higher thresholds, then tune down
AlertRule(
  failureThreshold: 20,              // Start high
  timeWindow: Duration(minutes: 10), // Longer window
  severity: AlertSeverity.medium,    // Lower severity initially
)
```

### **2. Use Appropriate Severities**
- **Critical**: Payment failures, security breaches, crashes
- **High**: Core feature failures, auth issues
- **Medium**: Performance issues, non-critical features
- **Low**: Minor issues, informational

### **3. Set Reasonable Cooldowns**
```dart
// Prevent alert fatigue
cooldownPeriod: Duration(minutes: 5),  // For most alerts
cooldownPeriod: Duration(minutes: 1),  // For critical systems
cooldownPeriod: Duration(minutes: 15), // For low-priority alerts
```

### **4. Monitor Specific Endpoints**
```dart
// Focus on critical business endpoints
AlertRule(
  endpointPattern: r'.*\/(payment|checkout|login).*',
  failureThreshold: 3,  // More sensitive for critical endpoints
)

// Less sensitive for non-critical endpoints
AlertRule(
  endpointPattern: r'.*\/(analytics|tracking).*',
  failureThreshold: 50,  // Higher threshold
)
```

### **5. Environment-Specific Configuration**
```dart
// Production: Conservative, focused on business impact
final prodAlerts = AlertConfig(
  enableAlerts: true,
  rules: [
    PredefinedAlertRules.serverErrors,   // Only critical issues
    // Custom business-critical rules
  ],
);

// Staging: More aggressive, catch issues early
final stagingAlerts = AlertConfig(
  enableAlerts: true,
  rules: PredefinedAlertRules.defaultRules,  // All rules
);

// Use appropriate config
final logarte = Logarte(
  alertConfig: kReleaseMode ? prodAlerts : stagingAlerts,
);
```

---

## 🚨 **Alert Response Playbook**

### **When Alerts Fire**

**1. Critical Alerts** 🔴
- Immediate investigation required
- Page on-call engineer
- Check system status
- Escalate to team lead if needed

**2. High Alerts** 🟠  
- Investigate within 15 minutes
- Post in team channel
- Monitor for escalation

**3. Medium Alerts** 🟡
- Investigate within 1 hour
- Log for weekly review
- Consider threshold adjustment

**4. Low Alerts** 🔵
- Daily/weekly review
- Trend analysis
- Preventive measures

---

## 💡 **Troubleshooting**

### **Too Many Alerts**
```dart
// Increase thresholds
failureThreshold: 20,  // Was 10

// Longer time windows
timeWindow: Duration(minutes: 10),  // Was 5

// Longer cooldowns
cooldownPeriod: Duration(minutes: 10),  // Was 5
```

### **Missing Important Alerts**
```dart
// Decrease thresholds
failureThreshold: 5,   // Was 10

// Shorter time windows  
timeWindow: Duration(minutes: 2),  // Was 5

// Add more specific rules
endpointPattern: r'.*\/critical-endpoint.*',
```

### **Alert System Not Working**
```dart
// Check if enabled
print('Alerts enabled: ${logarte.isAlertSystemEnabled}');

// Check rules
print('Alert rules: ${logarte.alertConfig.rules.length}');

// Test with simple rule
logarte.updateAlertConfig(AlertConfig(
  enableAlerts: true,
  rules: [
    AlertRule(
      id: 'test',
      type: AlertType.apiFailure,
      severity: AlertSeverity.low,
      name: 'Test Alert',
      description: 'Testing alerts',
      failureThreshold: 1,  // Very sensitive for testing
      timeWindow: Duration(minutes: 1),
    ),
  ],
));
```

---

**🎯 Your app is now equipped with intelligent monitoring that will catch issues before they impact users!**
