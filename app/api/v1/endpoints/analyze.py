from fastapi import APIRouter, HTTPException
from app.services.engine import global_engine_pool
# ⭐️ [NEW] 비동기 작업을 위한 라이브러리 추가
import asyncio

router = APIRouter()

@router.get("/best-move")
async def get_best_move(fen: str = 'startpos'):

    # ⭐️ [핵심 변경] with 문을 사용하여 엔진을 빌리고, 자동으로 반납합니다.
    # 다른 요청이 엔진을 다 쓰고 반납할 때까지 여기서 안전하게 기다립니다.
    with global_engine_pool.acquire() as engine:

        try:
            # 엔진 작업은 오래 걸리므로 여전히 비동기 쓰레드로 돌립니다.
            best_move = await asyncio.to_thread(engine.get_best_move, fen=fen)
        except Exception as e:
            print(f"Engine execution failed: {e}")
            raise HTTPException(status_code=500, detail="Engine error")

    if not best_move:
        raise HTTPException(status_code=500, detail="Failed to get move")

    return {"best_move": best_move}