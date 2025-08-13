# 📦 Using Logarte as GitHub Package

## 🚀 Quick Setup

### 1. Push to GitHub
```bash
# From your logarte directory
git add .
git commit -m "Complete logarte cloud logging package"
git push origin main
```

### 2. Use in Your Project
```yaml
# pubspec.yaml in your Flutter project
dependencies:
  logarte:
    git:
      url: https://github.com/your-username/logarte.git
      ref: main  # or specific commit/tag
```

### 3. Import and Use
```dart
// In your Flutter project
import 'package:logarte/logarte.dart';

void main() {
  final logarte = Logarte.secure(
    secureConfig: LogarteSecureConfig.production(
      apiEndpoint: 'your-deployed-backend-url',
      apiKey: 'your-api-key',
      user: LogarteUser(
        userId: 'user123',
        // ... user details
      ),
    ),
  );
  
  runApp(MyApp());
}
```

## ✅ **Pros of GitHub Package**
- ✅ **Instant setup** - Just add git dependency
- ✅ **Private control** - Keep it in your organization
- ✅ **Version control** - Use specific commits/tags
- ✅ **Free hosting** - No package publishing costs
- ✅ **Team access** - Control who can use it

## ❌ **Cons of GitHub Package**
- ❌ **Manual updates** - Users must update git ref manually
- ❌ **No version discovery** - Can't see available versions easily
- ❌ **Build time** - Longer `flutter pub get` times
- ❌ **Limited visibility** - Not discoverable by other developers

## 🏗️ **Backend Deployment (Required)**

You still need to deploy the **backend API** separately:

### **Option A: Firebase Cloud Functions**
```bash
cd logarte/backend-api
firebase deploy --only functions
# Get URL: https://submitlogs-xxx-uc.a.run.app
```

### **Option B: Vercel (Free)**
```bash
cd logarte/backend-api
npm install -g vercel
vercel --prod
# Get URL: https://your-backend.vercel.app
```

### **Option C: Railway/Render (Free Tier)**
```bash
# Push backend-api to separate repo
# Connect to Railway/Render
# Auto-deploy on push
```

## 📝 **Complete Example**

### Your Project's `pubspec.yaml`
```yaml
name: my_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  logarte:
    git:
      url: https://github.com/your-username/logarte.git
      ref: v1.2.0  # Use specific version tag
  http: ^1.1.0
```

### Your Project's `main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:logarte/logarte.dart';
import 'package:dio/dio.dart';

late Logarte logarte;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Logarte with your deployed backend
  logarte = Logarte.secure(
    secureConfig: LogarteSecureConfig.production(
      apiEndpoint: 'https://your-backend.vercel.app',
      apiKey: 'lga_prod_your_key_here',
      user: LogarteUser(
        userId: 'current_user_id',
        email: 'user@yourcompany.com',
        displayName: 'John Doe',
        teamId: 'mobile-team',
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App with Logarte',
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
  
  Future<void> fetchData() async {
    try {
      final response = await dio.get('/api/data');
      logarte.log('Data fetched successfully');
    } catch (e) {
      logarte.log('API Error: $e', stackTrace: StackTrace.current);
    }
  }
}
```

## 🔄 **Version Management**

### Create Releases
```bash
# Tag versions for easy reference
git tag v1.2.0
git push origin v1.2.0

# Users can reference specific versions
dependencies:
  logarte:
    git:
      url: https://github.com/your-username/logarte.git
      ref: v1.2.0
```

### Update Usage
```bash
# In user's project
flutter pub upgrade
flutter pub get
```

## 🚀 **Production Checklist**

Before using in production:

### ✅ **Package Setup**
- [ ] Push to GitHub with proper README
- [ ] Create version tags (v1.0.0, v1.1.0, etc.)
- [ ] Test import in separate project
- [ ] Document configuration options

### ✅ **Backend Setup**  
- [ ] Deploy backend API (Firebase/Vercel/Railway)
- [ ] Generate production API keys
- [ ] Configure Firestore security rules
- [ ] Test API endpoints
- [ ] Set up monitoring

### ✅ **Security**
- [ ] Use production API keys
- [ ] Configure team access properly
- [ ] Set appropriate log retention
- [ ] Test permission boundaries

## 💡 **Pro Tips**

### **1. Environment Separation**
```dart
final config = kDebugMode 
  ? LogarteSecureConfig.development(
      apiEndpoint: 'https://dev-backend.vercel.app',
      apiKey: 'lga_dev_xxx',
      // ...
    )
  : LogarteSecureConfig.production(
      apiEndpoint: 'https://prod-backend.vercel.app', 
      apiKey: 'lga_prod_xxx',
      // ...
    );
```

### **2. Error Handling**
```dart
try {
  await logarte.syncToCloud();
} catch (e) {
  print('Logarte sync failed: $e');
  // App continues normally
}
```

### **3. Performance**
```dart
// Configure for your app's needs
LogarteSecureConfig(
  enableBatching: true,
  batchSize: 50,  // Larger batches for high-traffic apps
  requestTimeout: Duration(seconds: 10),
)
```

This approach gives you **full control** while being **production-ready**! 🎯
