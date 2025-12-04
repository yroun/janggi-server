#!/bin/bash

# 에러 발생 시 즉시 중단
set -e

echo "🚀 Fairy-Stockfish (Janggi Largeboard) 설치를 시작합니다..."

# 1. 시스템 패키지 업데이트 및 필수 도구 설치
echo "📦 필수 패키지 및 최신 컴파일러(GCC 10) 설치 중..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "amzn" || "$ID" == "centos" || "$ID" == "rhel" ]]; then
        sudo yum update -y
        sudo yum groupinstall -y "Development Tools"
        # ⭐️ [필수] C++17 지원을 위해 gcc10 및 c++ 라이브러리 설치
        sudo yum install -y git curl wget unzip gcc10 gcc10-c++
    elif [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
        sudo apt-get update
        sudo apt-get install -y build-essential git curl wget unzip
    fi
fi

# 2. 작업 경로 설정 (/data/lib)
WORK_DIR="/data/lib"
SOURCE_FOLDER_NAME="Fairy-Stockfish-fairy_sf_14_0_1_xq"

# 디렉토리 생성 및 권한 설정
echo "📂 작업 디렉토리 준비: $WORK_DIR"
sudo mkdir -p "$WORK_DIR"
sudo chown -R $(whoami) "$WORK_DIR"

cd "$WORK_DIR"

# 3. 소스코드 다운로드
echo "📥 소스코드 다운로드 중..."
if [ -d "$SOURCE_FOLDER_NAME" ]; then
    rm -rf "$SOURCE_FOLDER_NAME"
fi

curl -L -o fairy_xq.zip https://github.com/fairy-stockfish/Fairy-Stockfish/archive/refs/tags/fairy_sf_14_0_1_xq.zip
unzip -q fairy_xq.zip

# 소스 디렉토리로 이동
cd "$SOURCE_FOLDER_NAME/src"

# 4. NNUE 파일 다운로드 (필수)
echo "🧠 AI 두뇌(NNUE) 파일 다운로드 중..."
curl -L -o xiangqi-83f16c17fe26.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/xiangqi-83f16c17fe26.nnue
curl -L -o janggi-85de3dae670a.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/janggi-85de3dae670a.nnue

# 5. 빌드 (Largeboard + AVX2 최적화 + GCC 10)
echo "🔨 빌드 시작 (Largeboard)..."

# ⭐️ [핵심 수정] 컴파일러 변수 설정
# Amazon Linux일 경우 g++10을 강제로 사용하도록 변수 설정
COMPILER="g++"
if command -v g++10 &> /dev/null; then
    echo "✅ GCC 10이 감지되었습니다. g++10을 사용합니다."
    COMPILER="g++10"
fi

make clean

# ⭐️ [핵심 수정] CXX=$COMPILER 를 make 인자로 전달하여 강제 적용
# ARCH=x86-64-modern : EC2 인스턴스에 최적화
make build ARCH=x86-64-modern largeboard=yes CXX="$COMPILER" CXXFLAGS="-std=c++17 -DLARGEBOARD -DALL_VARIANTS"

# 6. 설치 (실행 파일 이동)
echo "🚚 실행 파일 배치 중..."
TARGET_FILE=""
if [ -f "fairy-stockfish" ]; then
    TARGET_FILE="fairy-stockfish"
elif [ -f "stockfish" ]; then
    TARGET_FILE="stockfish"
else
    echo "❌ 빌드 실패: 실행 파일을 찾을 수 없습니다."
    exit 1
fi

# 이동
mv "$TARGET_FILE" "$WORK_DIR/fairy-stockfish"
chmod +x "$WORK_DIR/fairy-stockfish"

# 7. 정리 (Cleanup)
echo "🧹 임시 파일 정리 중..."
cd "$WORK_DIR"
rm -f fairy_xq.zip
rm -rf "$SOURCE_FOLDER_NAME"

echo "✅ 설치 완료!"
echo "📂 설치 경로: $WORK_DIR/fairy-stockfish"
echo "💡 테스트: $WORK_DIR/fairy-stockfish 실행 후 'uci' 입력 시 'var janggi' 확인"
