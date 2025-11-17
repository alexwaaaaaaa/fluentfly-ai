import http from 'k6/http';
import { check } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

// Spike test - Sudden traffic surge
export const options = {
  stages: [
    { duration: '10s', target: 100 }, // Normal load
    { duration: '30s', target: 10000 }, // SPIKE to 10K users!
    { duration: '1m', target: 10000 }, // Hold spike
    { duration: '10s', target: 100 }, // Drop back
    { duration: '30s', target: 100 }, // Recovery
  ],
  thresholds: {
    http_req_failed: ['rate<0.1'], // Allow 10% errors during spike
    errors: ['rate<0.1'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:3000/api';

export default function () {
  // Test if system can handle sudden spike
  const res = http.get(`${BASE_URL}/lessons`);
  check(res, {
    'status ok or rate limited': (r) => 
      r.status === 200 || r.status === 429 || r.status === 503,
  }) || errorRate.add(1);
}
