import 'package:flutter/material.dart';
import 'package:logarte/logarte.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';

// Example: Using Logarte with Cloud Logging
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const CloudLogarteExampleApp());
}

class CloudLogarteExampleApp extends StatelessWidget {
  const CloudLogarteExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logarte Cloud Example',
      home: const CloudExampleHomePage(),
      navigatorObservers: [
        LogarteNavigatorObserver(cloudLogarte),
      ],
    );
  }
}

// Example 1: Basic Cloud Configuration with User ID
final Logarte cloudLogarte = Logarte(
  password: '1234',
  ignorePassword: true, // For development
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: true,
    userId: 'user_12345', // Your app's user ID
    email: 'user@example.com',
    displayName: 'John Doe',
    teamId: 'team_awesome',
    role: 'developer',
    logRetentionDays: 7,
    allowTeamAccess: true,
    batchSize: 10,
    batchUploadIntervalSeconds: 30,
  ),
  onShare: (content) {
    // Handle sharing logs
    print('Sharing log: $content');
  },
);

// Example 2: Phone Number Based Configuration
final Logarte phoneLogarte = Logarte(
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: true,
    phoneNumber: '+1234567890', // Using phone number as identifier
    displayName: 'Jane Smith',
    logRetentionDays: 3, // Shorter retention for privacy
    allowTeamAccess: false, // Private logs
  ),
);

// Example 3: Team-based Configuration
final Logarte teamLogarte = Logarte(
  cloudConfig: LogarteCloudConfig(
    enableCloudLogging: true,
    userId: 'team_member_456',
    teamId: 'development_team',
    role: 'admin',
    email: 'admin@company.com',
    allowTeamAccess: true,
    logRetentionDays: 14, // Longer retention for admin
  ),
);

class CloudExampleHomePage extends StatefulWidget {
  const CloudExampleHomePage({super.key});

  @override
  State<CloudExampleHomePage> createState() => _CloudExampleHomePageState();
}

class _CloudExampleHomePageState extends State<CloudExampleHomePage> {
  late final Dio _dio;
  List<Map<String, dynamic>> _cloudLogs = [];
  Map<String, dynamic> _cloudStatus = {};

  @override
  void initState() {
    super.initState();

    // Setup Dio with Logarte interceptor
    _dio = Dio()..interceptors.add(LogarteDioInterceptor(cloudLogarte));

    // Attach the console
    cloudLogarte.attach(context: context, visible: true);

    // Get cloud status
    _updateCloudStatus();
  }

  void _updateCloudStatus() {
    setState(() {
      _cloudStatus = cloudLogarte.getCloudStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logarte Cloud Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: _syncToCloud,
            tooltip: 'Sync to Cloud',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: _loadCloudLogs,
            tooltip: 'Load Cloud Logs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cloud Status Section
            _buildCloudStatusCard(),

            const SizedBox(height: 20),

            // Local Logging Examples
            _buildLocalLoggingSection(),

            const SizedBox(height: 20),

            // Network Requests Section
            _buildNetworkSection(),

            const SizedBox(height: 20),

            // Cloud Operations Section
            _buildCloudOperationsSection(),

            const SizedBox(height: 20),

            // Cloud Logs Display
            _buildCloudLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloud Logging Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
                'Enabled', _cloudStatus['isEnabled']?.toString() ?? 'false'),
            _buildStatusRow(
                'User ID', _cloudStatus['userId']?.toString() ?? 'N/A'),
            _buildStatusRow(
                'Team ID', _cloudStatus['teamId']?.toString() ?? 'N/A'),
            _buildStatusRow(
                'Pending Logs', _cloudStatus['pendingLogs']?.toString() ?? '0'),
            _buildStatusRow(
                'Online', _cloudStatus['isOnline']?.toString() ?? 'false'),
            _buildStatusRow(
                'Session', _cloudStatus['currentSession']?.toString() ?? 'N/A'),
            const SizedBox(height: 12),
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
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'true'
                    ? Colors.green
                    : value == 'false'
                        ? Colors.red
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalLoggingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local Logging Examples',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => cloudLogarte.log('User clicked button'),
                  child: const Text('Log Message'),
                ),
                ElevatedButton(
                  onPressed: () => cloudLogarte.log('Error occurred',
                      stackTrace: StackTrace.current),
                  child: const Text('Log Error'),
                ),
                ElevatedButton(
                  onPressed: () => cloudLogarte.database(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloud Operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _syncToCloud,
                  child: const Text('Sync to Cloud'),
                ),
                ElevatedButton(
                  onPressed: _loadCloudLogs,
                  child: const Text('Load Cloud Logs'),
                ),
                ElevatedButton(
                  onPressed: _loadTeamLogs,
                  child: const Text('Load Team Logs'),
                ),
                ElevatedButton(
                  onPressed: _startRealTimeLogging,
                  child: const Text('Real-time Stream'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudLogsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloud Logs (${_cloudLogs.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_cloudLogs.isEmpty)
              const Text(
                  'No cloud logs loaded. Tap "Load Cloud Logs" to fetch.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cloudLogs.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final log = _cloudLogs[index];
                  return ListTile(
                    dense: true,
                    title: Text(log['type'] ?? 'unknown'),
                    subtitle: Text(
                      'User: ${log['userId'] ?? 'unknown'}\n'
                      'Time: ${log['timestamp']?.toString() ?? 'unknown'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showLogDetails(log),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Network request examples
  Future<void> _makeSuccessRequest() async {
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      cloudLogarte.log('Success request completed');
    } catch (e) {
      cloudLogarte.log('Request failed: $e');
    }
  }

  Future<void> _makeErrorRequest() async {
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/invalid-endpoint');
    } catch (e) {
      cloudLogarte.log('Expected error request: $e');
    }
  }

  Future<void> _makePostRequest() async {
    try {
      await _dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: {
          'title': 'Cloud Logarte Test',
          'body': 'Testing cloud logging functionality',
          'userId': cloudLogarte.currentUserId,
        },
      );
      cloudLogarte.log('POST request completed');
    } catch (e) {
      cloudLogarte.log('POST request failed: $e');
    }
  }

  // Cloud operations
  Future<void> _syncToCloud() async {
    try {
      await cloudLogarte.syncToCloud();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synced to cloud successfully')),
      );
      _updateCloudStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  Future<void> _loadCloudLogs() async {
    try {
      final logs = await cloudLogarte.getCloudLogs(
        limit: 20,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      );

      setState(() {
        _cloudLogs = logs;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${logs.length} cloud logs')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load logs: $e')),
      );
    }
  }

  Future<void> _loadTeamLogs() async {
    try {
      final logs = await cloudLogarte.getTeamCloudLogs(
        limit: 20,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      );

      setState(() {
        _cloudLogs = logs;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${logs.length} team logs')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load team logs: $e')),
      );
    }
  }

  void _startRealTimeLogging() {
    // Example of real-time log streaming
    cloudLogarte.streamCloudLogs(limit: 10).listen(
      (logs) {
        if (mounted) {
          setState(() {
            _cloudLogs = logs;
          });
        }
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stream error: $error')),
        );
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Real-time logging started')),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Details - ${log['type']}'),
        content: SingleChildScrollView(
          child: Text(
            log.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
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
    cloudLogarte.dispose();
    super.dispose();
  }
}
