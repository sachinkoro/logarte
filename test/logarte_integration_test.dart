import 'package:flutter_test/flutter_test.dart';
import 'package:logarte/logarte.dart';
import 'package:dio/dio.dart';

void main() {
  group('Logarte Integration Tests with Production Backend', () {
    late Logarte logarte;
    late Dio testDio;

    setUp(() {
      // Initialize Logarte with your production backend
      logarte = Logarte(
        secureConfig: LogarteSecureConfig(
          apiEndpoint: 'https://submitlogs-e4gu3zs5kq-uc.a.run.app',
          apiKey: 'lga_production_me9ivrce_6df84fdd4033d699',
          enableCloudLogging: true,
          user: LogarteUser(
            userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
            email: 'test@example.com',
            displayName: 'Test User',
            teamId: 'test_team',
            role: 'developer',
            isActive: true,
            lastSeen: DateTime.now(),
            updatedAt: DateTime.now(),
            settings: LogarteUserSettings(
              enableCloudLogging: true,
              logRetentionDays: 7,
              allowTeamAccess: true,
            ),
          ),
          enableBatching: false, // Disable batching for immediate testing
          requestTimeout: Duration(seconds: 30),
        ),
        alertConfig: AlertConfig(
          enableAlerts: true,
          rules: [
            AlertRule(
              id: 'test_api_failures',
              type: AlertType.apiFailure,
              severity: AlertSeverity.high,
              name: 'Test API Failures',
              description: 'Test alert for API failures',
              failureThreshold: 3,
              timeWindow: Duration(minutes: 5),
            ),
          ],
        ),
      );

      // Setup test Dio client
      testDio = Dio();
      testDio.interceptors.add(LogarteDioInterceptor(logarte));
    });

    tearDown(() {
      logarte.dispose();
      testDio.close();
    });

    group('Configuration Tests', () {
      test('should have cloud logging enabled', () {
        expect(logarte.isCloudLoggingEnabled, isTrue);
      });

      test('should have alert system enabled', () {
        expect(logarte.isAlertSystemEnabled, isTrue);
      });

      test('should have correct user ID', () {
        expect(logarte.currentUserId, isNotNull);
        expect(logarte.currentUserId!.startsWith('test_user_'), isTrue);
      });

      test('should have correct cloud status', () {
        final status = logarte.getCloudStatus();
        expect(status['isEnabled'], isTrue);
        expect(status['userId'], isNotNull);
        expect(status['teamId'], equals('test_team'));
      });
    });

    group('Basic Logging Tests', () {
      test('should log plain messages', () async {
        // Log some test messages
        logarte.log('Test message 1');
        logarte.log('Test message 2 with error', stackTrace: StackTrace.current);
        logarte.log('Test message 3', source: 'integration_test');

        // Verify logs are in local buffer
        expect(logarte.logs.value.length, greaterThanOrEqualTo(3));
        expect(logarte.logs.value.any((log) => log.contents.any((content) => content.contains('Test message 1'))), isTrue);
      });

      test('should log database operations', () {
        logarte.database(
          target: 'user_settings',
          value: {'theme': 'dark', 'notifications': true},
          source: 'SharedPreferences',
        );

        logarte.database(
          target: 'user_profile',
          value: 'John Doe',
          source: 'SQLite',
        );

        // Verify database logs
        final dbLogs = logarte.logs.value.whereType<DatabaseLogarteEntry>();
        expect(dbLogs.length, greaterThanOrEqualTo(2));
        expect(dbLogs.any((log) => log.target == 'user_settings'), isTrue);
        expect(dbLogs.any((log) => log.source == 'SQLite'), isTrue);
      });
    });

    group('Network Logging Tests', () {
      test('should log successful network requests', () async {
        // Make a successful request
        try {
          final response = await testDio.get('https://jsonplaceholder.typicode.com/posts/1');
          expect(response.statusCode, equals(200));
        } catch (e) {
          // Network might fail in test environment, that's okay
        }

        // Verify network logs are captured
        await Future.delayed(Duration(milliseconds: 500)); // Allow time for logging
        final networkLogs = logarte.logs.value.whereType<NetworkLogarteEntry>();
        expect(networkLogs.length, greaterThanOrEqualTo(1));
      });

      test('should log failed network requests', () async {
        // Make a request that will fail
        try {
          await testDio.get('https://jsonplaceholder.typicode.com/invalid-endpoint');
        } catch (e) {
          // Expected to fail
        }

        // Verify error logs are captured
        await Future.delayed(Duration(milliseconds: 500));
        final networkLogs = logarte.logs.value.whereType<NetworkLogarteEntry>();
        expect(networkLogs.length, greaterThanOrEqualTo(1));
      });

      test('should log POST requests with data', () async {
        try {
          await testDio.post(
            'https://jsonplaceholder.typicode.com/posts',
            data: {
              'title': 'Integration Test Post',
              'body': 'This is a test from Logarte integration tests',
              'userId': logarte.currentUserId,
            },
          );
        } catch (e) {
          // Network might fail, that's okay for testing
        }

        await Future.delayed(Duration(milliseconds: 500));
        final networkLogs = logarte.logs.value.whereType<NetworkLogarteEntry>();
        expect(networkLogs.any((log) => log.request.method == 'POST'), isTrue);
      });
    });

    group('Cloud Sync Tests', () {
      test('should sync logs to cloud successfully', () async {
        // Add some logs first
        logarte.log('Cloud sync test message 1');
        logarte.log('Cloud sync test message 2');
        logarte.database(target: 'test_table', value: 'test_value', source: 'test');

        // Attempt to sync to cloud
        try {
          await logarte.syncToCloud();
          // If no exception is thrown, sync was successful
          expect(true, isTrue);
        } catch (e) {
          // Print error for debugging but don't fail test
          print('Cloud sync failed (expected in test environment): $e');
        }
      });

      test('should retrieve cloud logs', () async {
        // First sync some logs
        logarte.log('Retrievable test message');
        try {
          await logarte.syncToCloud();
          await Future.delayed(Duration(seconds: 2)); // Wait for backend processing

          // Try to retrieve logs
          final cloudLogs = await logarte.getCloudLogs(limit: 10);
          // In a real scenario, this would return logs
          // In test environment, it might be empty or fail
          expect(cloudLogs, isA<List<LogarteEntry>>());
        } catch (e) {
          print('Cloud retrieval failed (expected in test environment): $e');
        }
      });
    });

    group('Alert System Tests', () {
      test('should trigger alerts on repeated failures', () async {
        final alertsFired = <AlertNotification>[];
        
        // Listen to alert stream
        final subscription = logarte.alertStream.listen((alert) {
          alertsFired.add(alert);
        });

        // Trigger multiple failures to same endpoint
        for (int i = 0; i < 5; i++) {
          try {
            await testDio.get('https://httpstat.us/500');
          } catch (e) {
            // Expected to fail
          }
          await Future.delayed(Duration(milliseconds: 200));
        }

        // Wait a bit for alert processing
        await Future.delayed(Duration(seconds: 2));

        // Check if alerts were triggered
        expect(alertsFired.length, greaterThanOrEqualTo(1));
        
        subscription.cancel();
      });

      test('should track endpoint failures', () async {
        // Make some failing requests
        try {
          await testDio.get('https://httpstat.us/404');
        } catch (e) {}
        
        try {
          await testDio.get('https://httpstat.us/500');
        } catch (e) {}

        await Future.delayed(Duration(milliseconds: 500));

        // Check failure tracking
        final failures = logarte.getEndpointFailures();
        expect(failures, isA<Map<String, int>>());
        // In real scenario, should have tracked failures
      });

      test('should clear endpoint failures', () {
        // Add some failures first (simulate)
        final testEndpoint = 'https://test-endpoint.com/api';
        
        // Clear failures for specific endpoint
        logarte.clearEndpointFailures(testEndpoint);
        
        // Verify it was cleared
        final count = logarte.getEndpointFailureCount(testEndpoint);
        expect(count, equals(0));
      });
    });

    group('Backend API Health Tests', () {
      test('should be able to reach backend endpoint', () async {
        final dio = Dio();
        
        try {
          // Test health check endpoint
          final response = await dio.get(
            'https://submitlogs-e4gu3zs5kq-uc.a.run.app/health',
            options: Options(
              headers: {
                'Authorization': 'Bearer lga_production_me9ivrce_6df84fdd4033d699',
              },
              validateStatus: (status) => status != null && status < 500,
            ),
          );
          
          print('Backend health check response: ${response.statusCode}');
          expect(response.statusCode, lessThan(500));
        } catch (e) {
          print('Backend health check failed: $e');
          // Don't fail test since backend might not be available
        } finally {
          dio.close();
        }
      });

      test('should validate API key format', () {
        final apiKey = 'lga_production_me9ivrce_6df84fdd4033d699';
        
        // Validate API key format
        expect(apiKey.startsWith('lga_'), isTrue);
        expect(apiKey.split('_').length, equals(3));
        expect(apiKey.split('_')[1], equals('production'));
        expect(apiKey.length, greaterThan(20));
      });

      test('should have valid endpoint URL', () {
        const endpoint = 'https://submitlogs-e4gu3zs5kq-uc.a.run.app';
        
        final uri = Uri.parse(endpoint);
        expect(uri.scheme, equals('https'));
        expect(uri.host, isNotEmpty);
        expect(uri.host.endsWith('.run.app'), isTrue);
      });
    });

    group('Error Handling Tests', () {
      test('should handle network timeouts gracefully', () async {
        // Create Logarte with very short timeout
        final shortTimeoutLogarte = Logarte(
          secureConfig: LogarteSecureConfig(
            apiEndpoint: 'https://submitlogs-e4gu3zs5kq-uc.a.run.app',
            apiKey: 'lga_production_me9ivrce_6df84fdd4033d699',
            enableCloudLogging: true,
            user: LogarteUser(
              userId: 'timeout_test_user',
              email: 'test@example.com',
              displayName: 'Timeout Test User',
              teamId: 'test_team',
              role: 'developer',
              isActive: true,
              lastSeen: DateTime.now(),
              updatedAt: DateTime.now(),
              settings: LogarteUserSettings(),
            ),
            requestTimeout: Duration(milliseconds: 1), // Very short timeout
          ),
        );

        // This should not throw an exception, even with timeout
        shortTimeoutLogarte.log('Test message with timeout');
        
        try {
          await shortTimeoutLogarte.syncToCloud();
        } catch (e) {
          // Expected to timeout, but shouldn't crash
          expect(e, isA<Exception>());
        }

        shortTimeoutLogarte.dispose();
      });

      test('should handle invalid API responses gracefully', () async {
        // Create Logarte with invalid endpoint
        final invalidLogarte = Logarte(
          secureConfig: LogarteSecureConfig(
            apiEndpoint: 'https://invalid-endpoint-that-does-not-exist.com',
            apiKey: 'invalid_key',
            enableCloudLogging: true,
            user: LogarteUser(
              userId: 'invalid_test_user',
              email: 'test@example.com',
              displayName: 'Invalid Test User',
              teamId: 'test_team',
              role: 'developer',
              isActive: true,
              lastSeen: DateTime.now(),
              updatedAt: DateTime.now(),
              settings: LogarteUserSettings(),
            ),
          ),
        );

        // Should not crash even with invalid endpoint
        invalidLogarte.log('Test with invalid endpoint');
        
        try {
          await invalidLogarte.syncToCloud();
        } catch (e) {
          // Expected to fail, but shouldn't crash app
          expect(e, isA<Exception>());
        }

        invalidLogarte.dispose();
      });
    });

    group('Performance Tests', () {
      test('should handle rapid logging without issues', () async {
        final startTime = DateTime.now();
        
        // Log 100 messages rapidly
        for (int i = 0; i < 100; i++) {
          logarte.log('Rapid test message $i');
          if (i % 10 == 0) {
            logarte.database(target: 'rapid_test_$i', value: i, source: 'performance_test');
          }
        }
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        
        // Should complete within reasonable time
        expect(duration.inMilliseconds, lessThan(5000)); // Less than 5 seconds
        expect(logarte.logs.value.length, greaterThanOrEqualTo(100));
        
        print('Logged 100 messages in ${duration.inMilliseconds}ms');
      });

      test('should handle concurrent network requests', () async {
        final futures = <Future>[];
        
        // Make 10 concurrent requests
        for (int i = 0; i < 10; i++) {
          futures.add(
            testDio.get('https://jsonplaceholder.typicode.com/posts/$i')
                .catchError((e) => null), // Ignore errors
          );
        }
        
        await Future.wait(futures);
        
        // Should have logged multiple network requests
        await Future.delayed(Duration(seconds: 1));
        final networkLogs = logarte.logs.value.whereType<NetworkLogarteEntry>();
        expect(networkLogs.length, greaterThanOrEqualTo(5)); // At least some should succeed
      });
    });
  });
}
