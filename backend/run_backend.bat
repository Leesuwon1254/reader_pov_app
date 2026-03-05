@echo off
title Reader POV Backend Server
chcp 65001 > nul

REM 현재 파일 위치 기준으로 backend 폴더로 이동
cd /d "%~dp0"

echo ==============================
echo  Reader POV Backend Starting
echo ==============================
echo.

REM .venv 활성화
if exist ".venv\Scripts\activate.bat" (
    echo [INFO] .venv 활성화 중...
    call ".venv\Scripts\activate.bat"
) else (
    echo [WARN] .venv 폴더가 없습니다. 전역 Python을 사용합니다.
)

REM requirements.txt 설치 여부 확인
echo.
set /p _install="requirements.txt 패키지를 설치/업데이트할까요? (y/N): "
if /i "%_install%"=="y" (
    echo [INFO] pip install -r requirements.txt 실행 중...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] pip install 실패. 확인 후 다시 시도하세요.
        pause
        exit /b 1
    )
    echo [INFO] 설치 완료.
)

REM OpenAI API 키 확인
echo.
if "%OPENAI_API_KEY%"=="" (
    echo [WARN] 환경변수 OPENAI_API_KEY 가 설정되어 있지 않습니다.
    echo        .env 파일에 키가 있으면 uvicorn 실행 시 자동으로 로드됩니다.
)

echo.
echo [INFO] 서버 주소: http://0.0.0.0:8001
echo [INFO] 로컬 접속: http://127.0.0.1:8001
echo [INFO] API 문서:  http://127.0.0.1:8001/docs
echo.

REM 브라우저로 health 체크 페이지 오픈 (서버 기동 후 새로고침 필요)
echo [INFO] 브라우저에서 health 페이지를 엽니다. 서버 기동 후 새로고침하세요.
start "" "http://127.0.0.1:8001/health"

echo.
echo [INFO] uvicorn 시작 중... (종료: Ctrl+C)
echo.

python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload

echo.
echo [INFO] 서버가 종료되었습니다.
pause
