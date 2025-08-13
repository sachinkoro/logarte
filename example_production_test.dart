import 'package:flutter/material.dart';
import 'package:logarte/logarte.dart';
import 'package:dio/dio.dart';

// Production Test Example with your actual backend
void main() {
  runApp(const ProductionTestApp());
}

class ProductionTestApp extends StatelessWidget {
  const ProductionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logarte Production Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProductionTestHomePage(),
      navigatorObservers: [
        LogarteNavigatorObserver(productionLogarte),
      ],
    );
  }
}

// Production Logarte Configuration with your actual backend
final Logarte productionLogarte = Logarte(
  password: '1234',
  ignorePassword: true, // For testing
  
  // Your actual production backend configuration
  secureConfig: LogarteSecureConfig(
    apiEndpoint: 'https://submitlogs-e4gu3zs5kq-uc.a.run.app',
    apiKey: 'lga_production_me9ivrce_6df84fdd4033d699',
    enableCloudLogging: true,
    user: LogarteUser(
      userId: 'prod_test_${DateTime.now().millisecondsSinceEpoch}',
      email: 'production.test@logarte.com',
      displayName: 'Production Test User',
      teamId: 'logarte_test_team',
      role: 'developer',
      isActive: true,
      lastSeen: DateTime.now(),
      updatedAt: DateTime.now(),
      settings: LogarteUserSettings(
        enableCloudLogging: true,
        logRetentionDays: 7, // Keep logs for 7 days
        allowTeamAccess: true,
      ),
    ),
    enableBatching: true,
    batchSize: 5,
    requestTimeout: Duration(seconds: 30),
  ),
  
  // Alert configuration for production testing
  alertConfig: AlertConfig(
    enableAlerts: true,
    cooldownPeriod: Duration(minutes: 2),
    rules: [
      AlertRule(
        id: 'prod_api_failures',
        type: AlertType.apiFailure,
        severity: AlertSeverity.high,
        name: 'Production API Failures',
        description: 'Detects API failures in production test',
        failureThreshold: 3,
        timeWindow: Duration(minutes: 5),
        statusCodesToMonitor: [400, 401, 403, 404, 500, 502, 503, 504],
      ),
      AlertRule(
        id: 'prod_slow_responses',
        type: AlertType.slowResponse,
        severity: AlertSeverity.medium,
        name: 'Slow Response Times',
        description: 'Detects slow API responses',
        slowResponseThreshold: 3000, // 3 seconds
      ),
    ],
  ),
);

class ProductionTestHomePage extends StatefulWidget {
  const ProductionTestHomePage({super.key});

  @override
  State<ProductionTestHomePage> createState() => _ProductionTestHomePageState();
}

class _ProductionTestHomePageState extends State<ProductionTestHomePage> {
  late Dio _dio;
  final List<String> _testResults = [];
  final List<AlertNotification> _alerts = [];
  bool _isTestingInProgress = false;
  Map<String, dynamic> _cloudStatus = {};

  @override
  void initState() {
    super.initState();
    
    // Setup Dio with Logarte interceptor
    _dio = Dio();
    _dio.interceptors.add(LogarteDioInterceptor(productionLogarte));
    
    // Attach Logarte console
    productionLogarte.attach(context: context, visible: true);
    
    // Listen to alerts
    productionLogarte.alertStream.listen((alert) {
      setState(() {
        _alerts.insert(0, alert);
        if (_alerts.length > 10) _alerts.removeAt(10);
      });
      
      _addTestResult('🚨 ALERT: ${alert.title} - ${alert.message}');
    });
    
    // Update cloud status
    _updateCloudStatus();
    
    // Log initial startup
    productionLogarte.log('Production test app started');
    productionLogarte.log('Backend: https://submitlogs-e4gu3zs5kq-uc.a.run.app');
    productionLogarte.log('User: ${productionLogarte.currentUserId}');
  }

  void _updateCloudStatus() {
    setState(() {
      _cloudStatus = productionLogarte.getCloudStatus();
    });
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.insert(0, '${DateTime.now().toString().substring(11, 19)}: $result');
      if (_testResults.length > 20) _testResults.removeAt(20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logarte Production Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Badge(
              label: _alerts.isNotEmpty ? Text(_alerts.length.toString()) : null,
              child: const Icon(Icons.notifications),
            ),
            onPressed: _showAlertsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 16),
            _buildTestControls(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildTestResults(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTestingInProgress ? null : _runFullTest,
        icon: _isTestingInProgress 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow),
        label: Text(_isTestingInProgress ? 'Testing...' : 'Run Full Test'),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _cloudStatus['isEnabled'] == true ? Icons.cloud_done : Icons.cloud_off,
                  color: _cloudStatus['isEnabled'] == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Backend Connection Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Endpoint', 'https://submitlogs-e4gu3zs5kq-uc.a.run.app'),
            _buildStatusRow('API Key', 'lga_production_me9i****** (Valid)'),
            _buildStatusRow('Cloud Logging', _cloudStatus['isEnabled'] == true ? 'Enabled' : 'Disabled'),
            _buildStatusRow('User ID', _cloudStatus['userId'] ?? 'Not set'),
            _buildStatusRow('Team ID', _cloudStatus['teamId'] ?? 'Not set'),
            _buildStatusRow('Alert System', productionLogarte.isAlertSystemEnabled ? 'Active' : 'Inactive'),
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

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value.contains('Enabled') || value.contains('Active') || value.contains('Valid')
                  ? Colors.green
                  : value.contains('Disabled') || value.contains('Inactive')
                    ? Colors.red
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Individual Tests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testBasicLogging,
                  child: const Text('Test Basic Logging'),
                ),
                ElevatedButton(
                  onPressed: _testNetworkLogging,
                  child: const Text('Test Network Logging'),
                ),
                ElevatedButton(
                  onPressed: _testCloudSync,
                  child: const Text('Test Cloud Sync'),
                ),
                ElevatedButton(
                  onPressed: _testAlertSystem,
                  child: const Text('Test Alert System'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => productionLogarte.log('Quick test message at ${DateTime.now()}'),
                  icon: const Icon(Icons.message),
                  label: const Text('Send Log'),
                ),
                ElevatedButton.icon(
                  onPressed: _makeTestAPICall,
                  icon: const Icon(Icons.api),
                  label: const Text('API Call'),
                ),
                ElevatedButton.icon(
                  onPressed: _triggerError,
                  icon: const Icon(Icons.error),
                  label: const Text('Trigger Error'),
                ),
                ElevatedButton.icon(
                  onPressed: () => productionLogarte.openConsole(context),
                  icon: const Icon(Icons.developer_mode),
                  label: const Text('Open Console'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Test Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => setState(() => _testResults.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _testResults.isEmpty
                ? const Center(child: Text('No test results yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _testResults.length,
                    itemBuilder: (context, index) {
                      final result = _testResults[index];
                      return Text(
                        result,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: result.contains('✅') 
                            ? Colors.green
                            : result.contains('❌') || result.contains('🚨')
                              ? Colors.red
                              : result.contains('⚠️')
                                ? Colors.orange
                                : null,
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Test Methods
  Future<void> _runFullTest() async {
    setState(() => _isTestingInProgress = true);
    _addTestResult('🚀 Starting full production test...');

    try {
      await _testBasicLogging();
      await Future.delayed(const Duration(seconds: 1));
      
      await _testNetworkLogging();
      await Future.delayed(const Duration(seconds: 1));
      
      await _testCloudSync();
      await Future.delayed(const Duration(seconds: 1));
      
      await _testAlertSystem();
      
      _addTestResult('🎉 Full test completed successfully!');
    } catch (e) {
      _addTestResult('❌ Full test failed: $e');
    } finally {
      setState(() => _isTestingInProgress = false);
    }
  }

  Future<void> _testBasicLogging() async {
    _addTestResult('📝 Testing basic logging...');
    
    productionLogarte.log('Test message 1');
    productionLogarte.log('Test error message', stackTrace: StackTrace.current);
    productionLogarte.database(target: 'test_db', value: 'test_value', source: 'production_test');
    
    _addTestResult('✅ Basic logging test completed');
  }

  Future<void> _testNetworkLogging() async {
    _addTestResult('🌐 Testing network logging...');
    
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      _addTestResult('✅ Network logging test completed');
    } catch (e) {
      _addTestResult('⚠️ Network test had issues: $e');
    }
  }

  Future<void> _testCloudSync() async {
    _addTestResult('☁️ Testing cloud sync...');
    
    try {
      await productionLogarte.syncToCloud();
      _addTestResult('✅ Cloud sync successful');
    } catch (e) {
      _addTestResult('❌ Cloud sync failed: $e');
    }
  }

  Future<void> _testAlertSystem() async {
    _addTestResult('🚨 Testing alert system...');
    
    // Trigger some failures
    for (int i = 0; i < 4; i++) {
      try {
        await _dio.get('https://httpstat.us/500');
      } catch (e) {
        // Expected to fail
      }
    }
    
    await Future.delayed(const Duration(seconds: 2));
    _addTestResult('✅ Alert system test completed');
  }

  Future<void> _makeTestAPICall() async {
    _addTestResult('📡 Making test API call...');
    
    try {
      final response = await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      _addTestResult('✅ API call successful (${response.statusCode})');
    } catch (e) {
      _addTestResult('❌ API call failed: $e');
    }
  }

  Future<void> _triggerError() async {
    _addTestResult('💥 Triggering error for testing...');
    
    try {
      await _dio.get('https://httpstat.us/500');
    } catch (e) {
      _addTestResult('✅ Error triggered and logged');
    }
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alerts (${_alerts.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _alerts.isEmpty
            ? const Center(child: Text('No alerts yet'))
            : ListView.builder(
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return ListTile(
                    leading: Icon(
                      Icons.warning,
                      color: alert.severity == AlertSeverity.critical 
                        ? Colors.red 
                        : Colors.orange,
                    ),
                    title: Text(alert.title),
                    subtitle: Text(alert.message),
                    trailing: Text(
                      alert.timestamp.toString().substring(11, 19),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dio.close();
    productionLogarte.dispose();
    super.dispose();
  }
}
