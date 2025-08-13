import 'package:flutter/material.dart';
import 'package:logarte/logarte.dart';
import 'package:dio/dio.dart';

// Example: Using Logarte with Secure Cloud Logging
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CloudLogarteExampleApp());
}

class CloudLogarteExampleApp extends StatelessWidget {
  const CloudLogarteExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logarte Secure Cloud Example',
      home: const CloudExampleHomePage(),
      navigatorObservers: [
        LogarteNavigatorObserver(secureLogarte),
      ],
    );
  }
}

// Secure Cloud Configuration (Recommended Approach)
final Logarte secureLogarte = Logarte(
  password: '1234',
  ignorePassword: true, // For development
  secureConfig: LogarteSecureConfig.production(
    apiEndpoint: 'https://your-backend-api.com',
    apiKey: 'your-secure-api-key',
    user: LogarteUser(
      userId: 'user_12345',
      email: 'user@example.com',
      displayName: 'John Doe',
      teamId: 'team_awesome',
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
  alertConfig: AlertConfig(
    enableAlerts: true,
    rules: [
      AlertRule(
        id: 'api_failures',
        type: AlertType.apiFailure,
        severity: AlertSeverity.high,
        name: 'API Failures',
        description: 'Detects repeated API failures',
        failureThreshold: 5,
        timeWindow: Duration(minutes: 10),
      ),
    ],
  ),
);

class CloudExampleHomePage extends StatefulWidget {
  const CloudExampleHomePage({super.key});

  @override
  State<CloudExampleHomePage> createState() => _CloudExampleHomePageState();
}

class _CloudExampleHomePageState extends State<CloudExampleHomePage> {
  late Dio _dio;
  Map<String, dynamic> _cloudStatus = {};
  List<LogarteEntry> _cloudLogs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Setup Dio with Logarte interceptor
    _dio = Dio()..interceptors.add(LogarteDioInterceptor(secureLogarte));
    
    // Attach the console
    secureLogarte.attach(context: context, visible: true);
    
    // Get cloud status
    _updateCloudStatus();
  }

  void _updateCloudStatus() {
    setState(() {
      _cloudStatus = secureLogarte.getCloudStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logarte Secure Cloud Demo'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cloud Status Card
            _buildCloudStatusCard(),
            const SizedBox(height: 16),
            
            // Basic Logging Section
            _buildBasicLoggingSection(),
            const SizedBox(height: 16),
            
            // Network Requests Section
            _buildNetworkSection(),
            const SizedBox(height: 16),
            
            // Cloud Operations Section
            _buildCloudOperationsSection(),
            const SizedBox(height: 16),
            
            // Alert System Section
            _buildAlertSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '☁️ Cloud Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Enabled: ${_cloudStatus['isEnabled'] ?? false}'),
            Text('User ID: ${_cloudStatus['userId'] ?? 'N/A'}'),
            Text('Team ID: ${_cloudStatus['teamId'] ?? 'N/A'}'),
            Text('Pending Logs: ${_cloudStatus['pendingLogs'] ?? 0}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _updateCloudStatus,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicLoggingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Basic Logging',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => secureLogarte.log('User clicked button'),
                  child: const Text('Log Message'),
                ),
                ElevatedButton(
                  onPressed: () => secureLogarte.log('Error occurred',
                      stackTrace: StackTrace.current),
                  child: const Text('Log Error'),
                ),
                ElevatedButton(
                  onPressed: () => secureLogarte.database(
                    target: 'user_preference',
                    value: 'dark_theme',
                    source: 'SharedPreferences',
                  ),
                  child: const Text('Log Database Op'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌐 Network Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _makeSuccessRequest,
                  child: const Text('Success Request'),
                ),
                ElevatedButton(
                  onPressed: _makeErrorRequest,
                  child: const Text('Error Request'),
                ),
                ElevatedButton(
                  onPressed: _makePostRequest,
                  child: const Text('POST Request'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudOperationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '☁️ Cloud Operations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _syncToCloud,
                  child: _isLoading 
                    ? const Text('Syncing...')
                    : const Text('Sync to Cloud'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadCloudLogs,
                  child: const Text('Load Cloud Logs'),
                ),
              ],
            ),
            if (_cloudLogs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Recent Cloud Logs:'),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _cloudLogs.length,
                  itemBuilder: (context, index) {
                    final log = _cloudLogs[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        log.contents.join(' '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        '${log.type.toString().split('.').last} - ${log.date}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚨 Alert System',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Enabled: ${secureLogarte.isAlertSystemEnabled}'),
            Text('Recent Alerts: ${secureLogarte.recentAlerts.length}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _triggerMultipleErrors,
              child: const Text('Trigger Alert (5 errors)'),
            ),
          ],
        ),
      ),
    );
  }

  // Network request methods
  Future<void> _makeSuccessRequest() async {
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      secureLogarte.log('Success request completed');
    } catch (e) {
      secureLogarte.log('Request failed: $e');
    }
  }

  Future<void> _makeErrorRequest() async {
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/invalid-endpoint');
    } catch (e) {
      secureLogarte.log('Expected error request: $e');
    }
  }

  Future<void> _makePostRequest() async {
    try {
      await _dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: {
          'title': 'Secure Logarte Test',
          'body': 'Testing secure cloud logging functionality',
          'userId': secureLogarte.currentUserId,
        },
      );
      secureLogarte.log('POST request completed');
    } catch (e) {
      secureLogarte.log('POST request failed: $e');
    }
  }

  // Cloud operations
  Future<void> _syncToCloud() async {
    setState(() => _isLoading = true);
    try {
      await secureLogarte.syncToCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synced to cloud successfully')),
        );
        _updateCloudStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCloudLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await secureLogarte.getCloudLogs(
        limit: 10,
        before: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _cloudLogs = logs;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${logs.length} cloud logs')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load logs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerMultipleErrors() async {
    // Trigger multiple errors to test alert system
    for (int i = 0; i < 6; i++) {
      try {
        await _dio.get('https://jsonplaceholder.typicode.com/error-$i');
      } catch (e) {
        secureLogarte.log('Triggered error $i: $e');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _dio.close();
    secureLogarte.dispose();
    super.dispose();
  }
}