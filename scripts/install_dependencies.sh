#!/bin/bash
# ⭐️ 배포 경로 수정
cd /data/yroun/server/janggi-server

# 1. lsof 설치 (Amazon Linux용 yum 사용)
echo "🛠️ Installing lsof..."
sudo yum install -y lsof

# 2. 가상환경 생성
echo "📦 Setting up Python environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# 3. 의존성 설치
source venv/bin/activate
pip install -r requirements.txt

# 4. 실행 권한 부여
echo "🔑 Granting execution permissions..."
chmod +x scripts/*.sh
if [ -f "bin/fairy-stockfish" ]; then
    chmod +x bin/fairy-stockfish
fi

echo "✅ Dependencies installed."
