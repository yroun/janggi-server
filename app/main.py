import psutil
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.endpoints import analyze, monitor

app = FastAPI(title="Janggi Analysis Service")

# --- CORS 설정 (브라우저 접근 허용) ---
origins = [
    "http://localhost:3000",   # Play Site
    "http://localhost:4300",   # Janggi App (독립 실행)
    "http://127.0.0.1:4300",
    "http://127.0.0.1:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,      # 허용할 출처 목록
    allow_credentials=True,     # 쿠키 등 인증 정보 허용
    allow_methods=["*"],        # 모든 HTTP Method (GET, POST...) 허용
    allow_headers=["*"],        # 모든 Header 허용
)

# --- 라우터 등록 ---
app.include_router(monitor.router, prefix="/api/v1/monitor", tags=["System"])
app.include_router(analyze.router, prefix="/api/v1")


@app.middleware("http")
async def log_memory_usage(request: Request, call_next):
    process = psutil.Process(os.getpid())
    mem_before = process.memory_info().rss / 1024 / 1024

    response = await call_next(request)

    mem_after = process.memory_info().rss / 1024 / 1024
    diff = mem_after - mem_before

    # 메모리 변화가 있을 때만 로그 출력 (혹은 항상 출력)
    if diff > 0:
        print(f"⚠️ Memory increased by {diff:.2f} MB during {request.url.path}")

    return response


@app.get("/")
def health_check():
    return {"status": "ok", "service": "Janggi AI"}