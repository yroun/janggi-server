import unittest
import subprocess
import os
import time
from app.core.config import settings

class TestJanggiEngine(unittest.TestCase):
    process: subprocess.Popen = None

    def setUp(self):
        """각 테스트 실행 전 엔진 프로세스를 시작합니다."""
        self.engine_path = settings.ENGINE_PATH

        # 엔진 파일 존재 여부 확인
        if not os.path.exists(self.engine_path):
            self.skipTest(f"❌ 엔진 파일이 없습니다: {self.engine_path}")

        # 엔진 프로세스 시작
        # stderr=subprocess.STDOUT : 에러 메시지도 stdout으로 캡쳐해서 확인
        self.process = subprocess.Popen(
            self.engine_path,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )

    def tearDown(self):
        """테스트 종료 후 엔진 프로세스를 정리합니다."""
        if self.process:
            self.process.terminate()
            self.process.wait()

    def _send_command(self, cmd: str):
        """엔진에 명령어를 전송하고 로그를 남깁니다."""
        print(f"👉 [Send] {cmd}")
        if self.process and self.process.stdin:
            self.process.stdin.write(f"{cmd}\n")
            self.process.stdin.flush()

    def _read_until(self, keyword: str, timeout: int = 5) -> str:
        """특정 키워드가 나올 때까지 출력을 읽고, 모든 로그를 화면에 찍습니다."""
        start_time = time.time()
        print(f"   ⏳ '{keyword}' 기다리는 중...")

        while True:
            # 타임아웃 방지
            if time.time() - start_time > timeout:
                self.fail(f"Timeout waiting for keyword: '{keyword}'")

            line = self.process.stdout.readline()
            if not line:
                break

            line = line.strip()
            print(f"   🤖 [Engine] {line}")  # 엔진의 답변 출력

            if keyword in line:
                return line

            # [중요] 에러 메시지 포착
            if "Error" in line or "Unknown" in line or "Invalid" in line:
                print(f"   🚨 엔진 에러 감지: {line}")

        return ""

    def test_engine_understands_janggi_rules(self):
        """
        테스트 시나리오: 포(Cannon)가 다리를 넘어 장군을 부를 수 있는지 확인
        """
        print("\n--- 엔진 디버깅 시작 ---")

        # 1. 장기 모드 설정
        self._send_command("uci")
        self._send_command("setoption name UCI_Variant value janggi")

        # 여기서 uciok가 나오기 전에 에러가 뜨는지 잘 봐야 함
        self._read_until("uciok")

        self._send_command("isready")
        self._read_until("readyok")

        # self._send_command("ucinewgame")
        # self._send_command("isready")
        # self._read_until("readyok")

        # 2. 상황 세팅 (포가 넘어 장군 쳐야 하는 상황)
        # 원래: 4k4/9/9/9/4P4/9/9/9/4C4/9
        # 뒤집음: 9/4C4/9/9/9/4P4/9/9/9/4k4 w - - 0 1
        test_fen = "4k4/9/9/9/4P4/9/9/9/4C4/4K4 w - - 0 1"
        self._send_command(f"position fen {test_fen}")

        # 3. 분석 시작
        self._send_command("go movetime 2000")
        self._send_command("d")

        # 4. 결과 확인
        result_line = self._read_until("bestmove", timeout=5)
        self.assertTrue(result_line.startswith("bestmove"), "엔진이 bestmove를 출력하지 않았습니다.")

        # bestmove e1e9 ponder ...
        move = result_line.split()[1]

        # e1e9: 포가 다리를 넘어 왕을 잡는 수 (좌표계에 따라 e0e9 등)
        valid_moves = ["e1e9", "e8e0", "e9e1", "e0e8"]

        is_valid = any(valid in move for valid in valid_moves)

        print(f"\n🎯 최종 추천 수: {move}")

        self.assertTrue(
            is_valid,
            f"엔진이 장기 룰(포 넘기)을 이해하지 못했습니다. 추천 수: {move}, 예상 수: {valid_moves}"
        )

if __name__ == "__main__":
    unittest.main()