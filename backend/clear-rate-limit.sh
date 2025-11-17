#!/bin/bash

# Clear rate limit for a specific user
# Usage: ./clear-rate-limit.sh <userId>

if [ -z "$1" ]; then
  echo "Usage: ./clear-rate-limit.sh <userId>"
  echo "Example: ./clear-rate-limit.sh 144"
  exit 1
fi

USER_ID=$1
REDIS_KEY="rtc:token:ratelimit:${USER_ID}"

echo "Clearing rate limit for user ${USER_ID}..."
redis-cli DEL "$REDIS_KEY"

if [ $? -eq 0 ]; then
  echo "✅ Rate limit cleared successfully for user ${USER_ID}"
else
  echo "❌ Failed to clear rate limit. Make sure Redis is running."
  exit 1
fi
