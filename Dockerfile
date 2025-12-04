# ---------------------------------------------------------
# Stage 1: 엔진 빌드 (Builder)
# 최신 Ubuntu 환경에서 Fairy-Stockfish를 빌드합니다.
# ---------------------------------------------------------
FROM ubuntu:22.04 AS builder

# 필수 패키지 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    unzip \
    g++ \
    make

WORKDIR /build

# 1. 소스코드 다운로드 (14.0.1 XQ)
RUN curl -L -o fairy_xq.zip https://github.com/fairy-stockfish/Fairy-Stockfish/archive/refs/tags/fairy_sf_14_0_1_xq.zip && \
    unzip -q fairy_xq.zip && \
    mv Fairy-Stockfish-fairy_sf_14_0_1_xq src

# 2. NNUE 파일 다운로드 (src 폴더 내부에 위치해야 함)
WORKDIR /build/src/src
RUN curl -L -o xiangqi-83f16c17fe26.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/xiangqi-83f16c17fe26.nnue && \
    curl -L -o janggi-85de3dae670a.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/janggi-85de3dae670a.nnue

# 3. 빌드 (Largeboard, C++17)
# Make clean 후 빌드
RUN make clean && \
    make build ARCH=x86-64-modern largeboard=yes CXXFLAGS="-std=c++17 -DLARGEBOARD -DALL_VARIANTS"

# ---------------------------------------------------------
# Stage 2: 서비스 실행 (Runtime)
# 가벼운 Python 이미지에 엔진을 가져와서 실행합니다.
# ---------------------------------------------------------
FROM python:3.11-slim

WORKDIR /app

# 1. 시스템 의존성 설치 (lsof 등)
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# 2. Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. 소스 코드 복사
COPY engine .

# 4. [핵심] 빌드된 엔진 가져오기 (Builder -> Runtime)
# 엔진을 /app/bin 폴더에 배치합니다.
COPY --from=builder /build/src/src/fairy-stockfish /app/bin/fairy-stockfish
# 혹시 이름이 stockfish로 됐을 경우를 대비해 둘 다 시도 (보통 fairy-stockfish임)
# (Docker 빌드 특성상 명확한 경로 복사가 좋음)

# 실행 권한 부여
RUN chmod +x /app/bin/fairy-stockfish

# 5. 환경 변수 설정 (코드에서 이 경로를 참조함)
ENV FAIRY_STOCKFISH_PATH="/app/bin/fairy-stockfish"

# 6. 서버 실행 (8001번 포트)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
