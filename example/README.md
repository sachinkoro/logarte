# Logarte Example App

This example demonstrates how to use the Logarte package for in-app debugging, cloud logging, and smart alerts.

## 🚀 Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the Example

```bash
flutter run
```

## 📋 What This Example Shows

### Local Debugging Features
- ✅ In-app debug console with floating button
- ✅ Network request logging with Dio interceptor
- ✅ Navigation tracking
- ✅ Custom logging and database operations
- ✅ Password-protected access
- ✅ Hidden gesture trigger (LogarteMagicalTap)

### Cloud Features (Optional)
- ☁️ Firebase cloud logging
- 👥 Team collaboration
- 📊 Real-time log streaming
- 🔄 Manual sync operations

### Alert System
- 🚨 API failure monitoring
- ⚡ Real-time alert notifications
- 📈 Endpoint failure tracking
- 🔧 Configurable thresholds

## 🎯 Key Components

### 1. Basic Setup (`main.dart`)
```dart
final Logarte logarte = Logarte(
  password: '1234',
  ignorePassword: kDebugMode,
  onShare: Share.share,
  customTab: const MyCustomTab(),
);
```

### 2. Network Logging
```dart
final dio = Dio()
  ..interceptors.add(LogarteDioInterceptor(logarte));
```

### 3. Navigation Tracking
```dart
MaterialApp(
  navigatorObservers: [LogarteNavigatorObserver(logarte)],
)
```

### 4. Console Attachment
```dart
@override
void initState() {
  super.initState();
  logarte.attach(
    context: context,
    visible: kDebugMode,
  );
}
```

## 🌟 Advanced Examples

Check out these additional example files:

### Cloud Features Example
See `../example_cloud_usage.dart` for:
- Firebase setup and configuration
- Cloud logging with team collaboration
- Real-time log streaming
- Manual sync operations
- User identification strategies

### Alert System Example  
See `../example_alerts_usage.dart` for:
- Smart alert configuration
- API failure monitoring
- Real-time alert handling
- Custom alert rules
- Webhook integrations

## 🔧 Testing Features

### Network Requests
Tap the network request buttons to generate HTTP traffic:
- **GET**: Successful requests
- **POST**: Request with body data
- **PUT**: Update operations
- **DELETE**: Deletion operations

### Database Operations
Tap "Write to database" to log storage operations:
- SharedPreferences writes
- SQLite operations
- Custom storage tracking

### Navigation
Open the test dialog to generate navigation events:
- Route pushes and pops
- Named route tracking
- Arguments logging

### Manual Logging
Use "Plain log" and "Exception" buttons to test:
- Custom message logging
- Error logging with stack traces
- Source attribution

## 📱 Console Access

### Debug Mode
- Floating button automatically appears
- Tap to open the console
- Password protection (use "1234")

### Production Mode
- Tap the "App Version 1.0" text 10 times
- This triggers the LogarteMagicalTap
- Enter password "1234" to access

### Direct Access
- Tap "Logarte console" button
- Opens console directly
- Useful for testing and demos

## 🎨 Custom Tab

The example includes a custom debug tab showing:
- Environment selection dropdown
- FCM token display with copy button
- Local cache size and clear button
- API URL configuration

This demonstrates how to add app-specific debugging features.

## 🔒 Security Notes

- Password is set to "1234" for demo purposes
- In production, use a secure password
- Consider disabling password in debug mode only
- LogarteMagicalTap provides hidden production access

## 🛠️ Customization

### Change Password
```dart
final logarte = Logarte(
  password: 'your-secure-password',
  ignorePassword: kDebugMode,
);
```

### Custom Share Function
```dart
final logarte = Logarte(
  onShare: (content) {
    // Custom sharing logic
    Share.share(content);
    // Or send to email, Slack, etc.
  },
);
```

### Custom Gestures
```dart
final logarte = Logarte(
  onRocketLongPressed: (context) {
    // Long press action
    showThemeDialog(context);
  },
  onRocketDoubleTapped: (context) {
    // Double tap action
    switchLanguage(context);
  },
);
```

## 📊 Performance

The example demonstrates efficient logging:
- Local buffer with 2500 entry limit
- Network interception with minimal overhead
- Memory-efficient log storage
- Automatic cleanup of old entries

## 🐛 Troubleshooting

### Console Not Appearing
- Check if `visible: true` in `attach()` method
- Verify context is valid when calling `attach()`
- Try manual console opening with `openConsole(context)`

### Network Logs Missing
- Ensure `LogarteDioInterceptor` is added to Dio
- Check if requests are actually being made
- Verify Dio instance is being used for requests

### Navigation Not Tracked
- Add `LogarteNavigatorObserver` to `navigatorObservers`
- Ensure named routes are being used
- Check if navigation is happening in the same navigator

For more help, check the main package documentation or open an issue on GitHub.

## 📚 Additional Resources

- [Main Documentation](../README.md)
- [Cloud Features Guide](../CLOUD_FEATURES.md)
- [Alert System Guide](../ALERT_SYSTEM.md)
- [Organization Setup](../ORGANIZATION_SETUP.md)