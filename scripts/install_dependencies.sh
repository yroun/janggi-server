#!/bin/bash

# 배포된 프로젝트 경로
PROJECT_ROOT="/data/yroun/server/janggi-server"

echo "🐳 1. Docker 환경 설정 중..."

# 1-1. Docker 설치 (Amazon Linux 2023 / 2 기준)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum update -y
    sudo yum install -y docker
fi

# 1-2. Docker 서비스 시작
sudo service docker start
sudo usermod -a -G docker ec2-user

# 1-3. Docker Compose 플러그인 설치
if ! docker compose version > /dev/null 2>&1; then
    echo "Installing Docker Compose..."
    sudo mkdir -p /usr/local/lib/docker/cli-plugins/
    sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

echo "✅ Docker setup complete."

# -----------------------------------------------------------
# ⭐️ [복구됨] 2. Nginx 설정 배포 및 적용
# -----------------------------------------------------------
echo "🌐 2. Configuring Nginx..."

# 소스 파일 (프로젝트 내)
SRC_CONF="$PROJECT_ROOT/nginx/conf.d/play-janggi-server.conf"
# 타겟 파일 (시스템 Nginx 설정 폴더)
DEST_CONF="/etc/nginx/conf.d/play-janggi-server.conf"

if [ -f "$SRC_CONF" ]; then
    # (1) 설정 파일 복사 (sudo 필요)
    echo "   - Copying config file to $DEST_CONF"
    sudo cp "$SRC_CONF" "$DEST_CONF"

    # (2) 권한 설정 (root 소유, 644 권한)
    sudo chown root:root "$DEST_CONF"
    sudo chmod 644 "$DEST_CONF"

    # (3) 문법 검사 및 리로드
    echo "   - Testing Nginx configuration..."
    # nginx -t로 문법 검사 후 성공 시에만 리로드
    if sudo nginx -t; then
        echo "   - Reloading Nginx..."
        sudo systemctl reload nginx
        echo "✅ Nginx configuration updated and reloaded."
    else
        echo "❌ Nginx configuration failed syntax check. Reload skipped."
        # 설정 파일이 깨졌을 때 배포를 실패하게 하려면 exit 1을 추가하세요.
    fi
else
    echo "⚠️ Warning: Nginx config file not found at $SRC_CONF"
fi

echo "✅ Deployment dependencies setup complete."

# 기존

## 배포 경로
#PROJECT_ROOT="/data/yroun/server/janggi-server"
#cd "$PROJECT_ROOT"
#
## 1. lsof 설치 (기존 유지)
#echo "🛠️ Installing lsof..."
#sudo yum install -y lsof
#
## 2. 가상환경 및 의존성 (기존 유지)
#echo "📦 Setting up Python environment..."
#if [ ! -d "venv" ]; then
#    python3 -m venv venv
#fi
#source venv/bin/activate
#pip install -r requirements.txt
#
## 3. 실행 권한 부여 (기존 유지)
#echo "🔑 Granting execution permissions..."
#chmod +x scripts/*.sh
#if [ -f "bin/fairy-stockfish" ]; then
#    chmod +x bin/fairy-stockfish
#fi
#
