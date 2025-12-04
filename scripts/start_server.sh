#!/bin/bash

# --- ⚙️ Configuration Variables ---
BASE_PATH="/data/yroun"
PROJECT_NAME="janggi-server"

# 경로 설정 (기본 경로 + 프로젝트명 조합)
DEPLOY_DIR="${BASE_PATH}/server/${PROJECT_NAME}"
LOG_DIR="${BASE_PATH}/log/${PROJECT_NAME}"
LOG_FILE="${LOG_DIR}/app.log"

# 서버 설정
APP_MODULE="app.main:app"
HOST="0.0.0.0"
PORT="8000"
# ----------------------------------

# 1. 배포 경로로 이동
# 경로에 혹시 공백이 있을 수 있으니 따옴표("")로 감싸는 것이 안전합니다.
cd "$DEPLOY_DIR"

# 2. 가상환경 활성화
source venv/bin/activate

# 3. 로그 디렉토리 생성 (안전장치)
# 변수를 재사용하므로 오타 날 확률이 줄어듭니다.
mkdir -p "$LOG_DIR"

# 4. 서버 시작
echo "🚀 Starting $APP_MODULE on port $PORT..."
nohup uvicorn "$APP_MODULE" --host "$HOST" --port "$PORT" > "$LOG_FILE" 2>&1 &
