import subprocess
import threading
import time
from typing import List, Optional
from app.core.config import settings

# --------------------------------------------------------------------
# 1. JanggiEngine (단일 프로세스 관리)
# --------------------------------------------------------------------

class JanggiEngine:
    """단일 장기 엔진 프로세스를 시작하고 유지하며, 상태를 관리합니다."""

    def __init__(self, engine_path: str):
        self.engine_path = engine_path

        # ⭐️ 프로세스 시작 및 파이프 저장
        self.process = subprocess.Popen(
            engine_path,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        # ⭐️ 초기 UCI 핸드쉐이크 (인스턴스 생성 시 단 한 번만 실행)
        self._initialize_uci()

    def _send_command(self, cmd):
        # ⭐️ self.process를 사용
        self.process.stdin.write(f"{cmd}\n")
        self.process.stdin.flush()

    def _read_until(self, keyword: str, timeout: int = 5) -> str:
        start_time = time.time()
        while True:
            if time.time() - start_time > timeout:
                # ⭐️ [안정성] 타임아웃 발생 시 에러 발생
                raise TimeoutError(f"Engine did not respond with '{keyword}' within {timeout}s.")

            line = self.process.stdout.readline()
            if not line: break

            line = line.strip()
            if keyword in line:
                return line
            if "Error" in line or "Unknown" in line or "Invalid" in line:
                raise ValueError(f"Engine reported an error: {line}")
        return ""

    def _initialize_uci(self):
        """엔진을 UCI 장기 모드로 설정하고 준비합니다."""
        self._send_command("uci")
        self._read_until("uciok")
        self._send_command("setoption name UCI_Variant value janggi")
        self._send_command("isready")
        self._read_until("readyok") # 설정 적용 대기

    def get_best_move(self, fen: str = "startpos", time_limit: int = 3000):
        try:
            # 1. 게임 초기화
            self._send_command("ucinewgame")

            # ⭐️ [핵심 수정] 이 줄이 빠져서 멈췄던 겁니다!
            # ucinewgame 만으로는 응답이 안 오므로, isready를 보내서 응답을 강제해야 합니다.
            self._send_command("isready")

            self._read_until("readyok") # 이제 여기서 막히지 않고 넘어갑니다.

            # 2. 배치 설정
            if fen == "startpos":
                self._send_command("position startpos")
            else:
                self._send_command(f"position fen {fen}")

            # 3. 분석 시작
            self._send_command(f"go movetime {time_limit}")

            best_move = None

            while True:
                # ⭐️ [수정] self.process 사용 (이미 고치셨지만 확인 차원)
                line = self.process.stdout.readline()
                if not line: break

                line = line.strip()
                # print(f"Engine: {line}")

                if line.startswith("bestmove"):
                    parts = line.split()
                    best_move = parts[1] if len(parts) > 1 else None
                    break

            # process.terminate()는 절대 호출하면 안 됨 (풀링 유지)
            return best_move

        except Exception as e:
            print(f"Engine Error: {e}")
            # 에러 발생 시 엔진 상태가 꼬일 수 있으므로 재시작 로직이 필요할 수 있음
            # 일단은 None 반환
            return None

# --------------------------------------------------------------------
# 2. JanggiEnginePool (엔진 상주 풀)
# --------------------------------------------------------------------

import queue
import contextlib
# ... (JanggiEngine 클래스는 기존 유지) ...

class JanggiEnginePool:
    """
    Queue를 사용한 안전한 엔진 풀.
    엔진을 빌려가면 Queue에서 빠지고, 다 쓰면 다시 채워넣습니다.
    """
    def __init__(self, num_engines: int = 2):
        engine_path = settings.ENGINE_PATH
        self.queue = queue.Queue()

        # 엔진을 생성해서 큐에 미리 넣어둡니다.
        for _ in range(num_engines):
            engine = JanggiEngine(engine_path)
            self.queue.put(engine)

    @contextlib.contextmanager
    def acquire(self):
        """
        Context Manager를 사용하여 엔진을 안전하게 대여/반납합니다.
        사용법: with pool.acquire() as engine: ...
        """
        # 1. 대출: 큐에서 엔진 하나를 꺼냅니다. (없으면 생길 때까지 기다림)
        engine = self.queue.get()
        try:
            yield engine # 2. 사용: 호출한 곳으로 엔진을 빌려줍니다.
        finally:
            # 3. 반납: 사용이 끝나거나 에러가 나도 무조건 다시 넣습니다.
            self.queue.put(engine)

# 전역 인스턴스
global_engine_pool = JanggiEnginePool(num_engines=2)