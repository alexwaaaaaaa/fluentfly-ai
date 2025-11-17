# Video Call Analytics and Monitoring

This document describes the analytics and monitoring features implemented for the video call system.

## Overview

The RTC module now includes comprehensive analytics tracking and monitoring capabilities to help track user progress, system health, and identify issues.

## Analytics Service

The `AnalyticsService` provides detailed analytics about video call usage and user performance.

### User Analytics

Track individual user metrics:

**Endpoint**: `GET /api/rtc/analytics/user`

**Metrics**:
- Total calls
- Average call duration
- Total speaking time vs listening time
- Average words per minute
- Average fluency score
- Fluency improvement over time (%)
- First and last call dates

**Example Response**:
```json
{
  "userId": 1,
  "totalCalls": 15,
  "averageCallDuration": 300,
  "totalSpeakingTime": 2700,
  "totalListeningTime": 1800,
  "averageWordsPerMinute": 120,
  "averageFluencyScore": 75,
  "fluencyImprovement": 15.5,
  "lastCallDate": "2024-01-15T10:30:00Z",
  "firstCallDate": "2024-01-01T09:00:00Z"
}
```

### Fluency Trend

Track fluency improvement over time:

**Endpoint**: `GET /api/rtc/analytics/fluency-trend?limit=20`

**Returns**: Array of data points showing fluency score, WPM, and call duration over time.

### Conversation Statistics

Track conversation patterns:

**Endpoint**: `GET /api/rtc/analytics/conversation-stats`

**Metrics**:
- Total conversation turns
- Average turns per call
- Average words per turn
- Total words spoken

### Period Analytics

Get analytics for a specific time period:

**Endpoint**: `GET /api/rtc/analytics/period?startDate=2024-01-01&endDate=2024-01-31`

**Metrics**:
- Total calls in period
- Total duration
- Average duration
- Unique users
- Average fluency score

### Daily Analytics

Get daily breakdown for the last N days:

**Endpoint**: `GET /api/rtc/analytics/daily?days=30`

**Returns**: Array of daily metrics for the specified period.

### Leaderboards

Get top users by various metrics:

**Endpoints**:
- `GET /api/rtc/analytics/top-users/calls?limit=10` - Top users by call count
- `GET /api/rtc/analytics/top-users/fluency?limit=10` - Top users by fluency score

## Monitoring Service

The `MonitoringService` tracks system health, errors, and performance metrics.

### System Health

Get overall system health status:

**Endpoint**: `GET /api/rtc/monitoring/health`

**Metrics**:
- Status: healthy | degraded | unhealthy
- Active calls count
- Error rate (errors per hour)
- Average AI response time
- System uptime

**Health Thresholds**:
- Degraded: Error rate > 10/hour OR response time > 5000ms
- Unhealthy: Error rate > 20/hour OR response time > 10000ms

**Example Response**:
```json
{
  "status": "healthy",
  "activeCalls": 5,
  "errorRate": 2,
  "averageResponseTime": 1500,
  "uptime": 86400,
  "lastChecked": "2024-01-15T10:30:00Z"
}
```

### Error Metrics

Track and analyze errors:

**Endpoint**: `GET /api/rtc/monitoring/errors`

**Metrics**:
- Total errors (last hour)
- Error rate (errors per hour)
- Errors grouped by type
- Recent errors (last 10)

**Automatic Alerts**:
- High error rate alert when errors exceed 10/hour
- Alerts stored in Redis for 24 hours

### Performance Metrics

Track AI response performance:

**Endpoint**: `GET /api/rtc/monitoring/performance`

**Metrics**:
- Average AI response time
- P95 response time (95th percentile)
- P99 response time (99th percentile)
- Slowest responses (top 5)

**Automatic Logging**:
- Slow response warning when response time > 5000ms

### Connection Statistics

Track connection events:

**Endpoint**: `GET /api/rtc/monitoring/connections`

**Metrics**:
- Connect events
- Disconnect events
- Reconnect events
- Error events

## Event Logging

The monitoring service automatically logs:

### Connection Events
- Token generation (connect)
- Session end (disconnect)
- Reconnection attempts
- Connection errors

### Error Events
- AI response generation failures
- Connection failures
- Timeout errors
- Any system errors

### Performance Events
- AI response times for every interaction
- Slow response warnings (> 5 seconds)

## Data Storage

### Redis Storage
- Connection events: 7 days
- Error events: 7 days
- Response times: 24 hours
- Alerts: 24 hours
- Hourly counters: Reset every hour

### Database Storage
- Video call sessions: Permanent
- Conversation turns: Permanent
- Analytics calculated from database records

## Usage Examples

### Check System Health
```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/rtc/monitoring/health
```

### Get User Analytics
```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/rtc/analytics/user
```

### Get Error Report
```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/rtc/monitoring/errors
```

### Get Performance Metrics
```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/rtc/monitoring/performance
```

## Integration

### In AI Agent Service

The AI agent service automatically:
- Logs response times for every AI interaction
- Logs errors when response generation fails
- Tracks response time and alerts on slow responses

### In RTC Controller

The RTC controller automatically:
- Logs connection events when tokens are generated
- Logs disconnect events when sessions end
- Tracks all connection lifecycle events

## Maintenance

### Clearing Old Metrics

The monitoring service includes a `clearOldMetrics()` method that should be called periodically (e.g., via cron job) to prevent memory buildup:

```typescript
// Example: Clear old metrics daily
@Cron('0 0 * * *')
async clearOldMetrics() {
  await this.monitoringService.clearOldMetrics();
}
```

## Future Enhancements

Potential improvements:
1. Real-time dashboard using WebSockets
2. Email/SMS alerts for critical errors
3. Integration with external monitoring tools (Datadog, New Relic)
4. Machine learning for anomaly detection
5. Automated performance optimization recommendations
6. User behavior analytics and insights
