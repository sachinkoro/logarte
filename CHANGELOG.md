# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2024-12-01

### 🌟 Major Features Added

#### Cloud Logging Platform
- **Firebase Integration**: Store logs persistently in Firestore
- **Team Collaboration**: Secure log sharing between team members
- **User Identification**: Support for userId, phoneNumber, or anonymous logging
- **Real-time Streaming**: Live log monitoring and updates
- **Automatic Cleanup**: Scheduled log cleanup via Cloud Functions
- **Enterprise Security**: Granular access controls and data encryption

#### Smart Alert System
- **API Failure Detection**: Monitor when same endpoint fails repeatedly (configurable thresholds)
- **Real-time Alerts**: Stream of live alert notifications
- **Multiple Alert Types**: API failures, slow responses, crashes, custom conditions
- **Severity Levels**: Low, Medium, High, Critical with appropriate handling
- **Cooldown Periods**: Prevent alert spam with configurable intervals
- **Webhook Support**: Integration with external monitoring systems
- **Predefined Rules**: Ready-to-use alert rules for common scenarios

#### New Configuration Options
- **LogarteCloudConfig**: Comprehensive cloud logging configuration
- **AlertConfig**: Flexible alert system configuration
- **AlertRule**: Detailed alert rule definitions with custom conditions
- **Environment-specific**: Separate configs for development and production

### 🔧 API Additions

#### Core Logarte Class
- Added `cloudConfig` parameter for cloud logging setup
- Added `alertConfig` parameter for alert system setup
- Added `isCloudLoggingEnabled` getter
- Added `isAlertSystemEnabled` getter
- Added `currentUserId` getter
- Added `alertStream` for real-time alert notifications
- Added `recentAlerts` getter
- Added `getCloudLogs()` method for retrieving cloud logs
- Added `getTeamCloudLogs()` method for team log access
- Added `streamCloudLogs()` method for real-time log streaming
- Added `syncToCloud()` method for manual cloud sync
- Added `updateCloudConfig()` method for runtime configuration updates
- Added `updateAlertConfig()` method for runtime alert updates
- Added `getEndpointFailures()` method for monitoring API failures
- Added `clearEndpointFailures()` method for resetting failure counters
- Added `getEndpointFailureCount()` method for specific endpoint monitoring
- Added `getCloudStatus()` method for debugging cloud features
- Enhanced `dispose()` method to cleanup cloud and alert services

#### New Services
- **FirebaseLogarteService**: Complete Firebase integration service
- **LogarteAlertService**: Intelligent alert monitoring service
- **LogarteCloudConfig**: Cloud configuration management
- **AlertConfig**: Alert system configuration
- **AlertRule**: Individual alert rule configuration

#### New Models
- **LogarteUser**: User profile and settings model
- **LogarteTeam**: Team configuration model
- **AlertNotification**: Alert notification data model
- **AlertSeverity**: Alert severity enumeration
- **AlertType**: Alert type enumeration

#### New Exports
- Added `LogarteCloudConfig` export
- Added `FirebaseLogarteService` export
- Added `LogarteAlertService` export
- Added `LogarteUser` export
- Added `AlertConfig` export
- Added `AlertRule` export
- Added `AlertNotification` export
- Added `AlertSeverity` export
- Added `AlertType` export
- Added `PredefinedAlertRules` export

### 📦 Dependencies Added
- `firebase_core: ^3.6.0` - Firebase initialization
- `cloud_firestore: ^5.4.3` - Cloud logging storage
- `firebase_auth: ^5.3.1` - User authentication (optional)
- `device_info_plus: ^10.1.2` - Device information collection
- `package_info_plus: ^8.0.2` - App information collection
- `connectivity_plus: ^6.0.5` - Network connectivity monitoring
- `uuid: ^4.5.1` - Unique identifier generation

### 🛡️ Security Features
- **Firestore Security Rules**: Comprehensive security rules for data protection
- **User Isolation**: Users can only access their own logs
- **Team Access Control**: Optional secure sharing with team members
- **Role-based Permissions**: Admin, developer, viewer roles
- **Data Encryption**: Automatic encryption at rest and in transit
- **GDPR Compliance**: Right to delete and data minimization

### 🔥 Infrastructure
- **Cloud Functions**: Automated log cleanup every night at 12 AM UTC
- **Firestore Schema**: Optimized database schema with proper indexing
- **Batch Operations**: Efficient batch uploads for performance
- **Offline Support**: Local buffering with automatic sync when online
- **Real-time Updates**: Live streaming of logs and alerts

### 📊 Analytics & Monitoring
- **Endpoint Failure Tracking**: Monitor API endpoint health
- **Performance Metrics**: Response time and error rate monitoring
- **Usage Statistics**: Track logging patterns and system health
- **Alert Analytics**: Monitor alert frequency and effectiveness

### 🎯 Developer Experience
- **Backward Compatibility**: All existing v1.0 code continues to work
- **Easy Migration**: Simple configuration additions for new features
- **Comprehensive Documentation**: Detailed guides and examples
- **TypeScript-style Documentation**: Complete API documentation
- **Examples**: Ready-to-use code examples for all features

### 📖 Documentation
- **CLOUD_FEATURES.md**: Comprehensive cloud features guide
- **ALERT_SYSTEM.md**: Complete alert system documentation
- **ORGANIZATION_SETUP.md**: Setup guide for organizations
- **IMPLEMENTATION_SUMMARY.md**: Technical implementation overview
- **firestore_schema.md**: Database schema documentation
- **example_cloud_usage.dart**: Cloud features example
- **example_alerts_usage.dart**: Alert system example

### 🐛 Bug Fixes
- Fixed memory leaks in log buffer management
- Improved error handling in network interceptors
- Enhanced offline/online state management
- Fixed timestamp formatting across time zones
- Improved Unicode support in log messages

### ⚡ Performance Improvements
- Optimized log buffer operations
- Reduced memory footprint for large log volumes
- Improved network request interception performance
- Enhanced UI rendering for large datasets
- Optimized Firestore query performance

### 🔄 Breaking Changes
None. This release is fully backward compatible with v1.0.

### 📈 Migration Notes
- Existing v1.0 code works unchanged
- New features are opt-in via configuration
- Cloud features require Firebase setup
- Alert system is disabled by default

---

## [1.1.0] - 2023-XX-XX

### Added
- Added back button to console when launched without floating button
- Update dio dependency version range to ensure compatibility

### Fixed
- Improved navigation handling in console screens

---

## [1.0.0] - 2023-XX-XX

### 🎉 First Stable Release
- Hitting first stable release! Logarte is now "readier" for production use
- Fixed a bug where clicking floating button in network details page would stuck the console

### Features
- In-app debug console with tabbed interface
- Network request/response logging with Dio interceptor
- Navigation tracking with LogarteNavigatorObserver
- Database operation logging
- Plain text logging with stack traces
- Password protection with optional bypass
- Search functionality across all log types
- Copy and share functionality
- cURL command generation for network requests
- Floating action button with drag and edge-snapping
- LogarteMagicalTap for hidden access in production
- Custom tabs support for app-specific debugging features

---

## [0.3.1] - 2023-XX-XX

### Added
- Added `disableDebugConsoleLogs` parameter to disable logs in IDE's debug console (default is false)

---

## [0.3.0] - 2023-XX-XX

### Added
- Custom tab support: You can now pass a custom tab to the console

---

## [0.2.4] - 2023-XX-XX

### Improved
- Improve database log's format and fix overflow issue on console

---

## [0.2.3] - 2023-XX-XX

### Fixed
- Fix stack trace not being shown on logs

---

## [0.2.2] - 2023-XX-XX

### Added
- Draggable entry button with edge snapping behavior

---

## [0.2.1] - 2023-XX-XX

### Improved
- Simplified documentation

---

## [0.2.0] - 2023-XX-XX

### Changed
- Simplified logging methods
- Deprecated `logarte.info()` and `logarte.error()` methods. Use `logarte.log()` instead
- Updated dependencies
- Updated example project

---

## [0.1.6] - 2023-XX-XX

### Fixed
- Fix images not being displayed in the documentation

---

## [0.1.5] - 2023-XX-XX

### Improved
- Documentation improvements

---

## [0.1.4] - 2023-XX-XX

### Fixed
- Fix links in the documentation

---

## [0.1.3] - 2023-XX-XX

### Added
- Package documentation for pub.dev release
- Upgrade dependencies to latest versions

---

## [0.1.2] - 2023-XX-XX

### Added
- `LogarteMagicalTap` widget for hidden console access
- Search functionality in console interface
- Improved overall console interface

---

## [0.1.1] - 2023-XX-XX

### Added
- `Logarte#onRocketLongPressed` and `Logarte#onRocketDoubleTapped` parameters
- Initial version of console logger

---

## [0.1.0] - 2023-XX-XX

### 🎉 Initial Release
- `LogarteNavigatorObserver` for navigation tracking
- `LogarteDioInterceptor` for network request logging
- Console graphical user interface
- Basic logging functionality

---

## Legend
- 🌟 Major features
- ✨ Minor features  
- 🔧 API changes
- 🐛 Bug fixes
- ⚡ Performance improvements
- 🔄 Breaking changes
- 📖 Documentation
- 🛡️ Security
- 📦 Dependencies