@echo off
title Reader POV Backend Server

REM UTF-8 설정
chcp 65001

REM 현재 파일 위치 기준으로 backend 폴더 이동
cd /d %~dp0

echo ==============================
echo Reader POV Backend Starting...
echo ==============================
echo.

REM OpenAI API 키 확인
if "%OPENAI_API_KEY%"=="" (
    echo [ERROR] OPENAI_API_KEY is NOT set.
    echo Please set your OpenAI API key first.
    pause
    exit
)

REM FastAPI 서버 실행
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000

pause
