import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 1000 }, // Ramp up to 1000 users
    { duration: '10m', target: 1000 }, // Stay at 1000 users
    { duration: '2m', target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95% < 500ms, 99% < 1s
    http_req_failed: ['rate<0.01'], // Error rate < 1%
    errors: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:3000/api';

// Test data
const users = [
  { email: 'test1@example.com', password: 'Test123!' },
  { email: 'test2@example.com', password: 'Test123!' },
  { email: 'test3@example.com', password: 'Test123!' },
];

export function setup() {
  // Login and get tokens for test users
  const tokens = users.map(user => {
    const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify(user), {
      headers: { 'Content-Type': 'application/json' },
    });
    return JSON.parse(loginRes.body).accessToken;
  });
  return { tokens };
}

export default function (data) {
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };

  // Scenario 1: Get lessons list (most common)
  let res = http.get(`${BASE_URL}/lessons`, { headers });
  check(res, {
    'lessons list status 200': (r) => r.status === 200,
    'lessons list response time < 200ms': (r) => r.timings.duration < 200,
  }) || errorRate.add(1);
  sleep(1);

  // Scenario 2: Get lesson detail
  const lessonId = Math.floor(Math.random() * 10) + 1;
  res = http.get(`${BASE_URL}/lessons/${lessonId}`, { headers });
  check(res, {
    'lesson detail status 200': (r) => r.status === 200,
    'lesson detail response time < 300ms': (r) => r.timings.duration < 300,
  }) || errorRate.add(1);
  sleep(2);

  // Scenario 3: Get user progress
  res = http.get(`${BASE_URL}/progress`, { headers });
  check(res, {
    'progress status 200': (r) => r.status === 200,
    'progress response time < 200ms': (r) => r.timings.duration < 200,
  }) || errorRate.add(1);
  sleep(1);

  // Scenario 4: Get leaderboard
  res = http.get(`${BASE_URL}/gamification/leaderboard?period=weekly`, { headers });
  check(res, {
    'leaderboard status 200': (r) => r.status === 200,
    'leaderboard response time < 500ms': (r) => r.timings.duration < 500,
  }) || errorRate.add(1);
  sleep(2);

  // Scenario 5: Save progress (write operation)
  const progressData = {
    lessonId,
    score: Math.floor(Math.random() * 100),
    completed: Math.random() > 0.5,
  };
  res = http.post(`${BASE_URL}/progress`, JSON.stringify(progressData), { headers });
  check(res, {
    'save progress status 201': (r) => r.status === 201,
    'save progress response time < 500ms': (r) => r.timings.duration < 500,
  }) || errorRate.add(1);
  sleep(3);
}

export function teardown(data) {
  console.log('Load test completed');
}
