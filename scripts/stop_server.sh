#!/bin/bash

PORT=8000

echo "🔍 Checking for process occupying port $PORT..."

# 1. 포트 점유 중인 PID 찾기
# -t: PID만 출력 (terse mode)
# -i:PORT: 해당 포트 검색
# || true: 프로세스가 없어서 에러가 나도 스크립트가 중단되지 않게 함
PID=$(lsof -t -i:$PORT || true)

if [ -z "$PID" ]; then
  echo "✅ Port $PORT is free. Nothing to stop."
else
  echo "🛑 Found process $PID on port $PORT. Killing it..."

  # 2. 강제 종료 (SIGKILL)
  kill -9 $PID

  # 3. 프로세스가 완전히 죽고 포트가 풀릴 때까지 잠시 대기
  sleep 2

  echo "✅ Process $PID killed and port $PORT released."
fi
