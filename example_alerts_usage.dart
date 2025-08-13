import 'package:flutter/material.dart';
import 'package:logarte/logarte.dart';
import 'package:dio/dio.dart';

// Example: Using Logarte with Smart Alert System
void main() {
  runApp(const AlertExampleApp());
}

class AlertExampleApp extends StatelessWidget {
  const AlertExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logarte Alerts Example',
      home: const AlertExampleHomePage(),
      navigatorObservers: [
        LogarteNavigatorObserver(alertLogarte),
      ],
    );
  }
}

// Configure Logarte with Alert System
final Logarte alertLogarte = Logarte(
  password: '1234',
  ignorePassword: true,

  // Cloud logging configuration
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: true,
    userId: 'alert_demo_user',
    teamId: 'demo_team',
    allowTeamAccess: true,
  ),

  // Alert system configuration
  alertConfig: AlertConfig(
    enableAlerts: true,
    cooldownPeriod: Duration(minutes: 2), // Prevent spam

    // Alert rules
    rules: [
      // Monitor API failures
      AlertRule(
        id: 'api_failures',
        type: AlertType.apiFailure,
        severity: AlertSeverity.high,
        name: 'API Endpoint Failures',
        description: 'Same endpoint failing repeatedly',
        failureThreshold: 10, // 10 failures
        timeWindow: Duration(minutes: 5), // within 5 minutes
        statusCodesToMonitor: [400, 401, 403, 404, 500, 502, 503, 504],
      ),

      // Monitor server errors more aggressively
      AlertRule(
        id: 'server_errors',
        type: AlertType.apiFailure,
        severity: AlertSeverity.critical,
        name: 'Server Errors',
        description: 'Critical server errors detected',
        failureThreshold: 5, // 5 failures
        timeWindow: Duration(minutes: 2), // within 2 minutes
        statusCodesToMonitor: [500, 502, 503, 504],
      ),

      // Monitor slow responses
      AlertRule(
        id: 'slow_responses',
        type: AlertType.slowResponse,
        severity: AlertSeverity.medium,
        name: 'Slow API Responses',
        description: 'API taking too long to respond',
        slowResponseThreshold: 5000, // 5 seconds
      ),

      // Monitor login endpoint specifically
      AlertRule(
        id: 'login_failures',
        type: AlertType.apiFailure,
        severity: AlertSeverity.high,
        name: 'Login Endpoint Issues',
        description: 'Login endpoint experiencing issues',
        failureThreshold: 3, // 3 failures
        timeWindow: Duration(minutes: 1), // within 1 minute
        endpointPattern: r'.*\/login.*', // Regex for login endpoints
        statusCodesToMonitor: [401, 403, 500],
      ),

      // Custom rule for crashes
      AlertRule(
        id: 'crashes',
        type: AlertType.crashDetected,
        severity: AlertSeverity.critical,
        name: 'Application Crashes',
        description: 'App crash or fatal error detected',
      ),

      // Custom rule example
      AlertRule(
        id: 'custom_payment_errors',
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
      ),
    ],

    // Callback for handling alerts
    onAlert: (alert) {
      print('🚨 ALERT TRIGGERED: ${alert.title}');
      print('   Message: ${alert.message}');
      print('   Severity: ${alert.severity}');
      print('   Time: ${alert.timestamp}');

      // Here you could:
      // - Send push notifications
      // - Send emails/SMS
      // - Post to Slack/Discord
      // - Update monitoring dashboards
      // - Trigger automated responses
    },

    // Optional webhook for external systems
    webhookUrl: 'https://your-monitoring-system.com/webhook',
    webhookHeaders: {
      'Authorization': 'Bearer your-token',
      'Content-Type': 'application/json',
    },
  ),
);

class AlertExampleHomePage extends StatefulWidget {
  const AlertExampleHomePage({super.key});

  @override
  State<AlertExampleHomePage> createState() => _AlertExampleHomePageState();
}

class _AlertExampleHomePageState extends State<AlertExampleHomePage> {
  late final Dio _dio;
  final List<AlertNotification> _alerts = [];
  Map<String, int> _endpointFailures = {};

  @override
  void initState() {
    super.initState();

    // Setup Dio with Logarte interceptor
    _dio = Dio()..interceptors.add(LogarteDioInterceptor(alertLogarte));

    // Attach the console
    alertLogarte.attach(context: context, visible: true);

    // Listen to alerts
    _listenToAlerts();

    // Update failure counts periodically
    _updateFailureCounts();
  }

  void _listenToAlerts() {
    alertLogarte.alertStream.listen((alert) {
      setState(() {
        _alerts.insert(0, alert);
        if (_alerts.length > 20) {
          _alerts.removeAt(20);
        }
      });

      // Show snackbar for critical alerts
      if (alert.severity == AlertSeverity.critical) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 CRITICAL: ${alert.title}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  void _updateFailureCounts() {
    setState(() {
      _endpointFailures = alertLogarte.getEndpointFailures();
    });

    // Update every 10 seconds
    Future.delayed(Duration(seconds: 10), _updateFailureCounts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logarte Alerts Demo'),
        actions: [
          IconButton(
            icon: Badge(
              //count: _alerts.length,
              child: Icon(Icons.notifications),
            ),
            onPressed: _showAlertsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertSystemStatus(),
            const SizedBox(height: 20),
            _buildTestActions(),
            const SizedBox(height: 20),
            _buildEndpointFailures(),
            const SizedBox(height: 20),
            _buildRecentAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSystemStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert System Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  alertLogarte.isAlertSystemEnabled
                      ? Icons.check_circle
                      : Icons.error,
                  color: alertLogarte.isAlertSystemEnabled
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  alertLogarte.isAlertSystemEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: alertLogarte.isAlertSystemEnabled
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Active Rules: ${alertLogarte.alertConfig.rules.length}'),
            Text('Recent Alerts: ${_alerts.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Alert Triggers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _triggerApiFailures,
                  child: const Text('Trigger API Failures'),
                ),
                ElevatedButton(
                  onPressed: _triggerServerErrors,
                  child: const Text('Trigger Server Errors'),
                ),
                ElevatedButton(
                  onPressed: _triggerSlowResponse,
                  child: const Text('Trigger Slow Response'),
                ),
                ElevatedButton(
                  onPressed: _triggerLoginFailures,
                  child: const Text('Trigger Login Failures'),
                ),
                ElevatedButton(
                  onPressed: _triggerCrash,
                  child: const Text('Trigger Crash Alert'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointFailures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endpoint Failure Tracking',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_endpointFailures.isEmpty)
              const Text('No endpoint failures tracked')
            else
              ..._endpointFailures.entries.map(
                (entry) => ListTile(
                  dense: true,
                  title: Text(entry.key),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text('${entry.value} failures'),
                        backgroundColor: entry.value >= 5
                            ? Colors.red[100]
                            : Colors.orange[100],
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _clearEndpointFailures(entry.key),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Alerts (${_alerts.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_alerts.isEmpty)
              const Text('No alerts triggered yet')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return ListTile(
                    dense: true,
                    leading: _getAlertIcon(alert.severity),
                    title: Text(alert.title),
                    subtitle: Text(
                      '${alert.message}\n${alert.timestamp.toString()}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showAlertDetails(alert),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return const Icon(Icons.info, color: Colors.blue);
      case AlertSeverity.medium:
        return const Icon(Icons.warning, color: Colors.orange);
      case AlertSeverity.high:
        return const Icon(Icons.error, color: Colors.red);
      case AlertSeverity.critical:
        return const Icon(Icons.dangerous, color: Colors.red);
    }
  }

  // Test methods to trigger alerts
  Future<void> _triggerApiFailures() async {
    // Make multiple requests to a failing endpoint
    for (int i = 0; i < 12; i++) {
      try {
        await _dio.get('https://httpstat.us/404');
      } catch (e) {
        // Expected to fail
      }
      await Future.delayed(Duration(milliseconds: 200));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Triggered 12 API failures - alert should fire')),
    );
  }

  Future<void> _triggerServerErrors() async {
    // Make multiple requests that return server errors
    for (int i = 0; i < 6; i++) {
      try {
        await _dio.get('https://httpstat.us/500');
      } catch (e) {
        // Expected to fail
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Triggered 6 server errors - alert should fire')),
    );
  }

  Future<void> _triggerSlowResponse() async {
    try {
      // This endpoint simulates a slow response
      await _dio.get('https://httpstat.us/200?sleep=6000');
    } catch (e) {
      // May timeout
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Triggered slow response - alert should fire')),
    );
  }

  Future<void> _triggerLoginFailures() async {
    // Trigger multiple login failures
    for (int i = 0; i < 4; i++) {
      try {
        await _dio.post('https://httpstat.us/401', data: {'username': 'test'});
      } catch (e) {
        // Expected to fail
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Triggered 4 login failures - alert should fire')),
    );
  }

  void _triggerCrash() {
    // Log a crash message
    alertLogarte.log('CRASH: Simulated application crash for testing');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Triggered crash alert')),
    );
  }

  void _clearEndpointFailures(String endpoint) {
    alertLogarte.clearEndpointFailures(endpoint);
    _updateFailureCounts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared failures for $endpoint')),
    );
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recent Alerts (${_alerts.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _alerts.isEmpty
              ? const Center(child: Text('No alerts'))
              : ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return ListTile(
                      leading: _getAlertIcon(alert.severity),
                      title: Text(alert.title),
                      subtitle: Text(alert.message),
                      onTap: () => _showAlertDetails(alert),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(AlertNotification alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Severity: ${alert.severity.name.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Message: ${alert.message}'),
              const SizedBox(height: 8),
              Text('Time: ${alert.timestamp}'),
              const SizedBox(height: 8),
              Text('Rule: ${alert.rule.name}'),
              if (alert.metadata.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Metadata:'),
                Text(alert.metadata.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dio.close();
    alertLogarte.dispose();
    super.dispose();
  }
}
