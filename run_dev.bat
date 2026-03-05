@echo off
chcp 65001 > nul
title Reader POV Dev

echo ==================================
echo  Reader POV 개발 환경 시작
echo ==================================
echo.

REM [A] Backend 새 창으로 실행
echo [1/2] Backend 서버 시작 (새 창)...
start "Reader POV Backend" cmd /k ""%~dp0backend\run_backend.bat""

REM [B] 3초 대기
echo [대기] Flutter 시작 전 3초 대기 중...
timeout /t 3 /nobreak > nul

REM [C] Flutter 새 창으로 실행
echo [2/2] Flutter 시작 (새 창)...
start "Reader POV Flutter" cmd /k ""%~dp0run_flutter.bat""

echo.
echo 백엔드와 Flutter가 각각 새 창에서 실행되고 있습니다.
echo 이 창은 닫아도 됩니다.
echo.
pause
