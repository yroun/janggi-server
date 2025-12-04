#!/bin/bash

# 에러 발생 시 즉시 중단
set -e

echo "🚀 Fairy-Stockfish (Janggi Largeboard) 설치를 시작합니다..."

# 1. 시스템 패키지 업데이트 및 필수 도구 설치
echo "📦 필수 패키지 설치 중..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "amzn" || "$ID" == "centos" || "$ID" == "rhel" ]]; then
        sudo yum update -y
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y git curl wget unzip
    elif [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
        sudo apt-get update
        sudo apt-get install -y build-essential git curl wget unzip
    else
        echo "⚠️ 지원되지 않는 OS입니다. 수동으로 의존성을 설치해주세요."
    fi
fi

# 2. 작업 디렉토리 및 설치 경로 설정
WORK_DIR="$HOME/fairy-stockfish-build"
INSTALL_DIR="/data/lib"  # ⭐️ 요청하신 설치 경로

# 디렉토리 생성 (권한 문제 방지를 위해 sudo 사용)
mkdir -p "$WORK_DIR"
sudo mkdir -p "$INSTALL_DIR"
# ec2-user가 /data/lib에 접근할 수 있도록 소유권 조정 (필요 시)
sudo chown -R $(whoami) "$INSTALL_DIR"

cd "$WORK_DIR"

# 3. 소스코드 다운로드 (장기 전용 14.0.1 XQ 버전)
echo "📥 소스코드 다운로드 중..."
if [ -d "Fairy-Stockfish-fairy_sf_14_0_1_xq" ]; then
    rm -rf Fairy-Stockfish-fairy_sf_14_0_1_xq
fi
curl -L -o fairy_xq.zip https://github.com/fairy-stockfish/Fairy-Stockfish/archive/refs/tags/fairy_sf_14_0_1_xq.zip
unzip -q fairy_xq.zip
cd Fairy-Stockfish-fairy_sf_14_0_1_xq/src

# 4. NNUE 파일 다운로드 (필수)
echo "🧠 AI 두뇌(NNUE) 파일 다운로드 중..."
curl -L -o xiangqi-83f16c17fe26.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/xiangqi-83f16c17fe26.nnue
curl -L -o janggi-85de3dae670a.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/janggi-85de3dae670a.nnue

# 5. 빌드 (Largeboard + AVX2 최적화)
# AWS EC2 (Intel/AMD) 환경에 맞춰 x86-64-modern 사용
echo "🔨 빌드 시작 (Largeboard)..."
make clean
make build ARCH=x86-64-modern largeboard=yes CXXFLAGS="-std=c++17 -DLARGEBOARD -DALL_VARIANTS"

# 6. 설치 (이동)
echo "🚚 실행 파일 이동 중..."
# 생성된 파일명이 stockfish 또는 fairy-stockfish 일 수 있음
TARGET_FILE=""
if [ -f "fairy-stockfish" ]; then
    TARGET_FILE="fairy-stockfish"
elif [ -f "stockfish" ]; then
    TARGET_FILE="stockfish"
else
    echo "❌ 빌드 실패: 실행 파일을 찾을 수 없습니다."
    exit 1
fi

# /data/lib 으로 이동 (덮어쓰기)
sudo mv "$TARGET_FILE" "$INSTALL_DIR/fairy-stockfish"
sudo chmod +x "$INSTALL_DIR/fairy-stockfish"

# 7. 정리
cd "$HOME"
rm -rf "$WORK_DIR"

echo "✅ 설치 완료!"
echo "📂 설치 경로: $INSTALL_DIR/fairy-stockfish"
echo "💡 테스트: $INSTALL_DIR/fairy-stockfish 실행 후 'uci' 입력 시 'var janggi' 확인"
