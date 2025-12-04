# ==========================================
# Stage 1: 엔진 빌드 (Builder)
# ==========================================
FROM ubuntu:22.04 AS builder

# 패키지 설치 (캐싱됨)
RUN apt-get update && apt-get install -y \
    build-essential git curl unzip g++ make

WORKDIR /build

# 1. 소스 & NNUE 다운로드
RUN curl -L -o fairy_xq.zip https://github.com/fairy-stockfish/Fairy-Stockfish/archive/refs/tags/fairy_sf_14_0_1_xq.zip && \
    unzip -q fairy_xq.zip && \
    mv Fairy-Stockfish-fairy_sf_14_0_1_xq src

WORKDIR /build/src/src
RUN curl -L -o xiangqi-83f16c17fe26.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/xiangqi-83f16c17fe26.nnue && \
    curl -L -o janggi-85de3dae670a.nnue https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/janggi-85de3dae670a.nnue

# 2. 빌드 (병렬 처리 추가)
RUN sed -i '1i#define LARGEBOARD' types.h && \
    make clean && \
    make build ARCH=x86-64-modern CXXFLAGS="-std=c++17 -DLARGEBOARD -DALL_VARIANTS" -j$(nproc)

# ==========================================
# Stage 2: 서비스 실행 (Runtime)
# ==========================================
FROM python:3.11-slim

WORKDIR /app

# 1. 시스템 의존성 설치
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# 2. Python 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. [핵심] 소스 코드 복사 (engine 폴더가 아니라 app 폴더를 복사)
COPY app ./app

# 4. 엔진 가져오기
COPY --from=builder /build/src/src/stockfish /app/bin/fairy-stockfish
RUN chmod +x /app/bin/fairy-stockfish

# 5. 환경변수 및 실행
ENV FAIRY_STOCKFISH_PATH="/app/bin/fairy-stockfish"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
