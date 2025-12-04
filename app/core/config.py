import shutil
import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Janggi AI Analysis"

    # 1. .env 파일에서 이 변수를 자동으로 읽어옵니다. (없으면 None)
    FAIRY_STOCKFISH_PATH: str | None = None

    # 설정을 .env 파일에서 읽겠다는 선언 (Pydantic 기능)
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    @property
    def ENGINE_PATH(self) -> str:
        """
        우선순위에 따라 엔진 경로를 결정하고 반환합니다.
        """
        # 1순위: .env에 설정된 경로 (아까 빌드한 파일 경로)
        if self.FAIRY_STOCKFISH_PATH:
            if os.path.exists(self.FAIRY_STOCKFISH_PATH):
                return self.FAIRY_STOCKFISH_PATH
            else:
                print(f"⚠️ 경고: .env에 지정된 경로에 파일이 없습니다: {self.FAIRY_STOCKFISH_PATH}")

        # 2순위: 시스템 명령어 (brew install 등)
        system_path = shutil.which("fairy-stockfish")
        if system_path:
            return system_path

        # 3순위: 프로젝트 내부 bin 폴더 (배포용)
        # apps/janggi/bin/fairy-stockfish
        # (현재 파일 위치: apps/janggi/app/core/config.py 이므로 부모x3)
        local_path = Path(__file__).parent.parent.parent / "bin" / "fairy-stockfish"
        if local_path.exists():
            # 실행 권한 자동 부여 (Mac/Linux 필수)
            if not os.access(local_path, os.X_OK):
                os.chmod(local_path, 0o755)
            return str(local_path)

        # 다 찾아봤는데 없으면 에러
        raise FileNotFoundError(
            "❌ 장기 엔진(fairy-stockfish)을 찾을 수 없습니다.\n"
            "1. .env 파일에 FAIRY_STOCKFISH_PATH를 설정하거나,\n"
            "2. 프로젝트 루트의 /bin 폴더에 실행 파일을 넣으세요."
        )

settings = Settings()