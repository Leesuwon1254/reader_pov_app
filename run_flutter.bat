@echo off
setlocal EnableExtensions

chcp 65001 > nul
title Reader POV Flutter Web

echo ==================================
echo Reader POV Flutter Starting...
echo ==================================

REM 프로젝트 루트로 이동 (bat 파일이 있는 폴더)
cd /d "%~dp0"

echo.
echo [0] flutter location check...
REM where 결과는 그냥 출력만 하고, 에러 여부는 ERRORLEVEL로만 판단
where flutter > "%temp%\flutter_where.txt" 2>nul
set "_where_rc=%errorlevel%"

type "%temp%\flutter_where.txt"
del "%temp%\flutter_where.txt" >nul 2>&1

if not "%_where_rc%"=="0" (
  echo.
  echo [ERROR] flutter command not found.
  echo - Flutter SDK bin path should be in PATH
  echo - Example: C:\src\flutter\bin
  echo.
  pause
  exit /b 1
)

echo.
echo [1/2] flutter pub get ...
call flutter pub get
if errorlevel 1 (
  echo.
  echo [ERROR] flutter pub get failed.
  pause
  exit /b 1
)

echo.
echo [2/2] flutter run (Edge, port 3002) ...
call flutter run -d edge --web-port 3002
if errorlevel 1 (
  echo.
  echo [ERROR] flutter run failed.
  pause
  exit /b 1
)

echo.
echo ==================================
echo Flutter process ended.
echo ==================================
pause



