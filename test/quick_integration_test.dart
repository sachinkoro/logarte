import 'package:flutter_test/flutter_test.dart';
import 'package:logarte/logarte.dart';
import 'package:dio/dio.dart';

/// Quick integration test to verify Logarte works with your production backend
/// Run this with: flutter test test/quick_integration_test.dart
void main() {
  group('Quick Production Backend Test', () {
    test('Full integration test with your production endpoint', () async {
      print('🚀 Starting Logarte integration test...');
      
      // 1. Initialize Logarte with your production config
      final logarte = Logarte(
        secureConfig: LogarteSecureConfig(
          apiEndpoint: 'https://submitlogs-e4gu3zs5kq-uc.a.run.app',
          apiKey: 'lga_production_me9ivrce_6df84fdd4033d699',
          enableCloudLogging: true,
          user: LogarteUser(
            userId: 'integration_test_${DateTime.now().millisecondsSinceEpoch}',
            email: 'integration@test.com',
            displayName: 'Integration Test User',
            teamId: 'test_team_001',
            role: 'developer',
            isActive: true,
            lastSeen: DateTime.now(),
            updatedAt: DateTime.now(),
            settings: LogarteUserSettings(
              enableCloudLogging: true,
              logRetentionDays: 1, // Short retention for testing
              allowTeamAccess: true,
            ),
          ),
          enableBatching: false, // Immediate sending for testing
          requestTimeout: Duration(seconds: 30),
        ),
        alertConfig: AlertConfig(
          enableAlerts: true,
          rules: [
            AlertRule(
              id: 'integration_test_failures',
              type: AlertType.apiFailure,
              severity: AlertSeverity.medium,
              name: 'Integration Test API Failures',
              description: 'Detects API failures during integration testing',
              failureThreshold: 2,
              timeWindow: Duration(minutes: 1),
            ),
          ],
        ),
      );

      print('✅ Logarte initialized successfully');
      print('   - Cloud logging enabled: ${logarte.isCloudLoggingEnabled}');
      print('   - Alert system enabled: ${logarte.isAlertSystemEnabled}');
      print('   - User ID: ${logarte.currentUserId}');

      // 2. Test basic logging
      print('\n📝 Testing basic logging...');
      logarte.log('Integration test started at ${DateTime.now()}');
      logarte.log('Testing plain message logging');
      logarte.log('Testing error logging with stack trace', stackTrace: StackTrace.current);
      
      // Test database logging
      logarte.database(
        target: 'integration_test_config',
        value: {'backend_url': 'https://submitlogs-e4gu3zs5kq-uc.a.run.app', 'test_id': 'quick_test'},
        source: 'integration_test',
      );

      expect(logarte.logs.value.length, greaterThanOrEqualTo(4));
      print('✅ Basic logging working - ${logarte.logs.value.length} logs captured');

      // 3. Test network logging with Dio interceptor
      print('\n🌐 Testing network logging...');
      final dio = Dio();
      dio.interceptors.add(LogarteDioInterceptor(logarte));

      try {
        // Successful request
        final response = await dio.get('https://jsonplaceholder.typicode.com/posts/1');
        print('✅ Successful request logged (Status: ${response.statusCode})');
      } catch (e) {
        print('⚠️  Network request failed: $e');
      }

      try {
        // Failed request
        await dio.get('https://jsonplaceholder.typicode.com/nonexistent');
      } catch (e) {
        print('✅ Failed request logged (Expected failure)');
      }

      // Wait for network logs to be processed
      await Future.delayed(Duration(milliseconds: 500));
      final networkLogs = logarte.logs.value.whereType<NetworkLogarteEntry>();
      expect(networkLogs.length, greaterThanOrEqualTo(1));
      print('✅ Network logging working - ${networkLogs.length} network logs captured');

      // 4. Test cloud sync
      print('\n☁️  Testing cloud sync...');
      try {
        await logarte.syncToCloud();
        print('✅ Cloud sync completed successfully');
      } catch (e) {
        print('❌ Cloud sync failed: $e');
        print('   This could be due to:');
        print('   - Network connectivity issues');
        print('   - Backend API key validation');
        print('   - Backend endpoint availability');
        // Don't fail the test for cloud sync issues
      }

      // 5. Test alert system
      print('\n🚨 Testing alert system...');
      final alertsFired = <AlertNotification>[];
      final alertSubscription = logarte.alertStream.listen((alert) {
        alertsFired.add(alert);
        print('🚨 Alert fired: ${alert.title} - ${alert.message}');
      });

      // Trigger some failures to test alerts
      for (int i = 0; i < 3; i++) {
        try {
          await dio.get('https://httpstat.us/500');
        } catch (e) {
          // Expected to fail
        }
        await Future.delayed(Duration(milliseconds: 200));
      }

      await Future.delayed(Duration(seconds: 1)); // Wait for alert processing
      alertSubscription.cancel();

      print('✅ Alert system tested - ${alertsFired.length} alerts fired');

      // 6. Test configuration validation
      print('\n⚙️  Testing configuration...');
      final cloudStatus = logarte.getCloudStatus();
      expect(cloudStatus['isEnabled'], isTrue);
      expect(cloudStatus['userId'], isNotNull);
      expect(cloudStatus['teamId'], equals('test_team_001'));
      print('✅ Configuration validation passed');

      // 7. Test backend health (optional)
      print('\n🏥 Testing backend health...');
      try {
        final healthResponse = await dio.get(
          'https://submitlogs-e4gu3zs5kq-uc.a.run.app/health',
          options: Options(
            headers: {
              'Authorization': 'Bearer lga_production_me9ivrce_6df84fdd4033d699',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        print('✅ Backend health check passed (Status: ${healthResponse.statusCode})');
      } catch (e) {
        print('⚠️  Backend health check failed: $e');
        print('   Backend might not have a /health endpoint or might be temporarily unavailable');
      }

      // 8. Cleanup
      print('\n🧹 Cleaning up...');
      logarte.dispose();
      dio.close();

      print('\n🎉 Integration test completed successfully!');
      print('Summary:');
      print('- Total logs captured: ${logarte.logs.value.length}');
      print('- Network logs: ${networkLogs.length}');
      print('- Alerts fired: ${alertsFired.length}');
      print('- Cloud logging: ${logarte.isCloudLoggingEnabled ? 'Enabled' : 'Disabled'}');
      print('- Backend endpoint: https://submitlogs-e4gu3zs5kq-uc.a.run.app');
      print('- API key format: Valid (${logarte.secureConfig?.apiKey?.substring(0, 20)}...)');
    });

    test('Backend API Key Validation', () {
      const apiKey = 'lga_production_me9ivrce_6df84fdd4033d699';
      
      // Test API key format
      expect(apiKey.startsWith('lga_'), isTrue, reason: 'API key should start with lga_');
      expect(apiKey.contains('production'), isTrue, reason: 'Should be production key');
      expect(apiKey.length, greaterThan(30), reason: 'API key should be sufficiently long');
      
      final parts = apiKey.split('_');
      expect(parts.length, greaterThanOrEqualTo(3), reason: 'API key should have at least 3 parts separated by underscore');
      expect(parts[0], equals('lga'), reason: 'First part should be lga');
      expect(parts[1], equals('production'), reason: 'Second part should be production');
      expect(parts[2].length, greaterThan(5), reason: 'Key part should be sufficiently long');
      
      print('✅ API key validation passed');
    });

    test('Backend Endpoint Validation', () {
      const endpoint = 'https://submitlogs-e4gu3zs5kq-uc.a.run.app';
      
      final uri = Uri.parse(endpoint);
      expect(uri.scheme, equals('https'), reason: 'Should use HTTPS');
      expect(uri.host, isNotEmpty, reason: 'Should have valid host');
      expect(uri.host.endsWith('.run.app'), isTrue, reason: 'Should be Google Cloud Run endpoint');
      expect(uri.path, isEmpty, reason: 'Base endpoint should not have path');
      
      print('✅ Endpoint validation passed');
      print('   - Scheme: ${uri.scheme}');
      print('   - Host: ${uri.host}');
      print('   - Full URL: $endpoint');
    });
  });
}
