# Logarte Cloud - Firestore Database Schema

## 📊 Collection Structure

### 1. **users** Collection
```
users/{userId}
├── userId: string
├── phoneNumber?: string  
├── email?: string
├── displayName?: string
├── teamId?: string
├── role: 'developer' | 'admin' | 'viewer'
├── isActive: boolean
├── lastSeen: timestamp
├── createdAt: timestamp
├── updatedAt: timestamp
└── settings: {
    enableCloudLogging: boolean,
    logRetentionDays: number,
    allowTeamAccess: boolean
  }
```

### 2. **teams** Collection
```
teams/{teamId}
├── teamId: string
├── name: string
├── description?: string
├── ownerId: string
├── members: string[] (array of userIds)
├── settings: {
    logRetentionDays: number,
    maxLogsPerUser: number,
    allowCrossUserAccess: boolean
  }
├── createdAt: timestamp
└── updatedAt: timestamp
```

### 3. **logs** Collection (Main Log Storage)
```
logs/{logId}
├── logId: string (auto-generated)
├── userId: string (indexed)
├── teamId?: string (indexed)
├── appId: string (indexed) 
├── sessionId: string (indexed)
├── type: 'network' | 'navigation' | 'database' | 'plain'
├── timestamp: timestamp (indexed)
├── deviceInfo: {
    platform: 'ios' | 'android' | 'web' | 'macos' | 'windows' | 'linux',
    version: string,
    model?: string,
    buildNumber?: string
  }
├── metadata: {
    appVersion: string,
    environment: 'debug' | 'release' | 'profile',
    buildMode: string
  }
└── data: object (log-specific data structure)
```

### 4. **sessions** Collection
```
sessions/{sessionId}
├── sessionId: string
├── userId: string (indexed)
├── appId: string
├── startTime: timestamp
├── endTime?: timestamp
├── duration?: number (seconds)
├── logCount: number
├── crashCount: number
├── deviceInfo: object
├── appVersion: string
└── isActive: boolean
```

### 5. **apps** Collection
```
apps/{appId}
├── appId: string
├── name: string
├── packageName: string
├── teamId: string
├── ownerId: string
├── collaborators: string[]
├── settings: {
    enableRealTimeMonitoring: boolean,
    alertOnErrors: boolean,
    logRetentionDays: number
  }
├── createdAt: timestamp
└── updatedAt: timestamp
```

## 🔍 **Log Data Structures by Type**

### Network Logs
```typescript
data: {
  request: {
    method: string,
    url: string,
    headers: object,
    body?: any,
    sentAt: timestamp
  },
  response: {
    statusCode: number,
    headers: object,
    body?: any,
    receivedAt: timestamp,
    duration: number // milliseconds
  },
  error?: {
    type: string,
    message: string,
    code?: string
  }
}
```

### Navigation Logs
```typescript
data: {
  action: 'push' | 'pop' | 'remove' | 'replace',
  routeName?: string,
  arguments?: object,
  previousRoute?: string,
  previousArguments?: object
}
```

### Database Logs
```typescript
data: {
  operation: 'read' | 'write' | 'delete' | 'update',
  target: string, // key/table name
  value?: any,
  source: string, // SharedPreferences, SQLite, etc.
  query?: string
}
```

### Plain Logs
```typescript
data: {
  message: string,
  level: 'debug' | 'info' | 'warn' | 'error',
  source?: string,
  stackTrace?: string,
  tags?: string[]
}
```

## 🔧 **Indexes for Performance**

### Composite Indexes
1. `(userId, timestamp desc)` - User's recent logs
2. `(teamId, timestamp desc)` - Team's recent logs  
3. `(appId, timestamp desc)` - App's recent logs
4. `(userId, type, timestamp desc)` - User's logs by type
5. `(sessionId, timestamp asc)` - Session timeline
6. `(userId, type, timestamp desc)` - Filtered user logs

### Single Field Indexes
- `userId` (ascending)
- `teamId` (ascending)
- `appId` (ascending)
- `sessionId` (ascending)
- `timestamp` (descending)
- `type` (ascending)

## 🏷️ **Document ID Patterns**

- **logs**: `{userId}_{timestamp}_{randomId}` 
- **sessions**: `{userId}_{startTimestamp}`
- **users**: `{authUserId}` or `{phoneNumber}` or `{customUserId}`
- **teams**: `team_{randomId}`
- **apps**: `{packageName}_{randomId}`

## 📈 **Collection Sharding Strategy**

For high-volume apps, consider date-based sharding:
```
logs_2024_01/{logId}
logs_2024_02/{logId}
...
```

This enables:
- Easier cleanup of old data
- Better query performance
- Reduced index maintenance
