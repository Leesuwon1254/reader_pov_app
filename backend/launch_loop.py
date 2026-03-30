"""
launch_loop.py
Windows DETACHED_PROCESS로 run_improvement_loop.py를 실행.
부모 프로세스(터미널/Claude)가 종료되어도 계속 실행됨.
"""
import subprocess
import sys
import os

BASE_DIR = r"C:\Users\USER\Desktop\reader_pov_app_v2.8_ing\backend"
SCRIPT   = os.path.join(BASE_DIR, "run_improvement_loop.py")
STDOUT   = os.path.join(BASE_DIR, "loop_stdout.txt")

def main():
    with open(STDOUT, "a", encoding="utf-8") as out:
        proc = subprocess.Popen(
            [sys.executable, SCRIPT],
            stdout=out,
            stderr=out,
            cwd=BASE_DIR,
            # Windows 전용: 부모와 완전히 분리된 독립 프로세스
            creationflags=(
                subprocess.DETACHED_PROCESS
                | subprocess.CREATE_NEW_PROCESS_GROUP
            ),
        )
    print(f"[launch_loop] PID={proc.pid} 시작됨")
    print(f"[launch_loop] 로그: {os.path.join(BASE_DIR, 'improvement_log.txt')}")
    print(f"[launch_loop] stdout: {STDOUT}")

if __name__ == "__main__":
    main()
