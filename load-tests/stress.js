import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

// Stress test - Push system beyond normal capacity
export const options = {
  stages: [
    { duration: '2m', target: 1000 }, // Ramp up to 1000
    { duration: '5m', target: 3000 }, // Ramp up to 3000
    { duration: '10m', target: 5000 }, // Push to 5000 users
    { duration: '5m', target: 5000 }, // Hold at 5000
    { duration: '5m', target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000', 'p(99)<2000'],
    http_req_failed: ['rate<0.05'], // Allow 5% error rate under stress
    errors: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:3000/api';

export default function () {
  // Simulate heavy load on most critical endpoints
  
  // 1. Lessons list (cached, should handle well)
  let res = http.get(`${BASE_URL}/lessons`);
  check(res, {
    'lessons status ok': (r) => r.status === 200 || r.status === 429,
  }) || errorRate.add(1);
  
  // 2. Leaderboard (expensive query)
  res = http.get(`${BASE_URL}/gamification/leaderboard?period=all-time`);
  check(res, {
    'leaderboard status ok': (r) => r.status === 200 || r.status === 429,
  }) || errorRate.add(1);
  
  // 3. Health check
  res = http.get(`${BASE_URL}/../health`);
  check(res, {
    'health check ok': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  sleep(0.5); // Aggressive load
}
