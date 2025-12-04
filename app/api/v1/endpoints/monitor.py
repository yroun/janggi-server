from fastapi import APIRouter
import psutil
import os

router = APIRouter()

@router.get("/memory")
def get_memory_usage():
    # 현재 프로세스 ID 가져오기
    pid = os.getpid()
    process = psutil.Process(pid)

    # 메모리 정보 가져오기 (bytes 단위)
    memory_info = process.memory_info()

    # MB 단위로 변환
    rss_mb = memory_info.rss / 1024 / 1024  # 물리 메모리 점유량 (Resident Set Size)
    vms_mb = memory_info.vms / 1024 / 1024  # 가상 메모리 점유량

    return {
        "pid": pid,
        "memory_rss_mb": f"{rss_mb:.2f} MB", # 실제 사용 중인 물리 메모리 (중요)
        "memory_vms_mb": f"{vms_mb:.2f} MB",
        "cpu_percent": f"{process.cpu_percent()}%"
    }