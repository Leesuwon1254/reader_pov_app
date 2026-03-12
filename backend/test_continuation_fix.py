"""
수정된 _generate_with_continuation 테스트 (target=5000자)
결과를 test_continuation_result.txt에 저장
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(__file__))

from main import _get_openai_client, _generate_with_continuation

TARGET = 5000

PROMPT = """무인칭 몰입 POV 연재소설을 작성한다. 독자는 장면을 직접 겪는 위치에 놓이며, 한국어 소설 문체로 자연스럽게 전개한다.

[HARD RULES]
- 서술은 독자 체험 중심(보고/듣고/느끼고/선택한 정보만).
- 설명/요약/회상으로 때우지 말고 장면(행동·대화·감각)으로 전개.
- 기존 설정/인물/사건과 모순 금지.
- 과격한 묘사·성인 수위·혐오 표현은 배제하고 긴장감 중심으로 연출.
- 서술에 2인칭(너/네/너의/너에게/너는/당신) 절대 사용 금지. 무인칭만 사용.

[POV / STYLE]
- 독자가 장면 안에 직접 들어와 있는 것처럼 느껴지게 쓴다.
- 주어는 생략하거나, 상황·행동·감각 중심으로 자연스럽게 이어 간다.
- 번역투를 피하고 한국어 소설 문체로 매끄럽게 쓴다.

[PROJECT SEED]
- 제목: 빈 좌석
- 로그라인: 늘 있던 사람이 없다
- 장르: 스릴러
- 기본 뼈대: 늘 같은 자리에 앉던 사람이 어느 날 보이지 않는다. 주변은 아무렇지 않게 굴지만, 공기만 달라져 있다. 작은 단서들을 따라가면, 사라진 이유가 예상보다 가까이에 있다.

[OUTPUT]
- 1화를 작성하라. 반드시 {target}자 이상 작성할 것. 분량이 부족하면 장면을 더 추가하라. 절대 중간에 끊지 말 것.
""".format(target=TARGET)

def main():
    client = _get_openai_client()
    t0 = time.perf_counter()
    text, calls, regen, safe_fix, reason, _ = _generate_with_continuation(
        client=client,
        model="gpt-4o-mini",
        base_prompt=PROMPT,
        target_chars=TARGET,
        max_continuations=3,
    )
    elapsed = time.perf_counter() - t0

    result = (
        f"{'='*60}\n"
        f"target={TARGET}자 | 실제={len(text)}자 | calls={calls} | "
        f"regen={regen} | elapsed={elapsed:.1f}s\n"
        f"5000자 달성: {'OK' if len(text) >= 5000 else 'FAIL'}\n"
        f"{'='*60}\n\n"
        f"{text}\n"
    )

    out = os.path.join(os.path.dirname(__file__), "test_continuation_result.txt")
    with open(out, "w", encoding="utf-8") as f:
        f.write(result)

    print(result[:300])
    print(f"\n→ 전체 저장: {out}")

if __name__ == "__main__":
    main()
