#!/bin/bash
# 배포 경로
PROJECT_ROOT="/data/yroun/server/janggi-server"
cd "$PROJECT_ROOT"

# 1. lsof 설치 (기존 유지)
echo "🛠️ Installing lsof..."
sudo yum install -y lsof

# 2. 가상환경 및 의존성 (기존 유지)
echo "📦 Setting up Python environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt

# 3. 실행 권한 부여 (기존 유지)
echo "🔑 Granting execution permissions..."
chmod +x scripts/*.sh
if [ -f "bin/fairy-stockfish" ]; then
    chmod +x bin/fairy-stockfish
fi

# -----------------------------------------------------------
# ⭐️ [NEW] 4. Nginx 설정 배포 및 적용
# -----------------------------------------------------------
echo "🌐 Configuring Nginx..."

SRC_CONF="$PROJECT_ROOT/nginx/conf.d/play-janggi-server.conf"
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
    if sudo nginx -t; then
        echo "   - Reloading Nginx..."
        sudo systemctl reload nginx
        echo "✅ Nginx configuration updated and reloaded."
    else
        echo "❌ Nginx configuration failed syntax check. Reload skipped."
        # 설정 파일이 잘못되어도 배포 자체를 실패 처리할지 결정 (여기서는 경고만 하고 넘어감)
    fi
else
    echo "⚠️ Warning: Nginx config file not found at $SRC_CONF"
fi

echo "✅ Deployment dependencies setup complete."
