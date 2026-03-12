"""
run_improvement_loop.py
25개 소설 주제 × 3화 자동 생성 + 품질 평가 루프
결과: backend/improvement_log.txt
"""
import sys, os, re, time, json, traceback
sys.path.insert(0, os.path.dirname(__file__))

from main import (
    _get_openai_client,
    _generate_with_continuation,
    _guard_validate,
    _strip_quoted_dialogue,
    _FORBIDDEN_NARRATION_TOKENS,
)

# ──────────────────────────────────────────────────────────
# 25개 템플릿 (templates_repo.dart 그대로)
# ──────────────────────────────────────────────────────────
TEMPLATES = [
    # DRAMA
    {"n": 1,  "genre": "드라마",      "title": "승자와 패자",          "logline": "금수저 vs 노력파, 그리고 권력의 균열",   "skeleton": "신용호는 탄탄한 배경으로 승승장구한다. 정수는 이를 악물고 올라서며 가정을 지킨다. 시간이 흐르고, 정수의 아이가 검사로 성장해 신용호의 주변을 파고든다. 성공의 정점에서 균열이 시작된다."},
    {"n": 2,  "genre": "드라마",      "title": "담장 너머의 계약서",   "logline": "한 장의 문서가 관계를 갈라놓는다",       "skeleton": "협력사와의 계약이 갱신되는 날, 조항 하나가 조용히 바뀌어 있다. 그 변경은 한 사람의 책임이 되고, 팀 전체의 신뢰가 흔들린다. 누가 바꿨는지, 왜 지금인지, 답을 찾아야 한다."},
    {"n": 3,  "genre": "드라마",      "title": "회색 회의실",          "logline": "말보다 표정이 먼저 결론을 낸다",         "skeleton": "회의실의 공기가 무겁게 가라앉는다. 안건은 단순하지만, 이해관계는 복잡하다. 짧은 침묵과 시선이 오가며, 한 사람이 고립된다. 결정은 이미 내려진 듯 보이지만, 아직 뒤집을 여지가 남아 있다."},
    {"n": 4,  "genre": "드라마",      "title": "이름 없는 추천서",     "logline": "누군가의 한 줄이 인생을 바꾼다",         "skeleton": "지원서가 통과될 리 없다고 생각한 순간, 익명의 추천서가 도착한다. 도움이었을까, 덫이었을까. 추천서를 쓴 사람을 찾는 과정에서 과거의 빚과 관계가 드러난다."},
    {"n": 5,  "genre": "드라마",      "title": "유리 천장 아래",       "logline": "성장과 질투가 같은 속도로 커진다",       "skeleton": "성과는 분명히 쌓였는데, 평가는 늘 한 발 늦다. 동료의 승진 소식이 들리고, 축하와 불편함이 동시에 밀려온다. 다음 선택은 관계를 지킬지, 목표를 앞당길지로 갈린다."},
    # ROMANCE
    {"n": 6,  "genre": "로맨스",      "title": "비 오는 날의 계약",    "logline": "서로를 싫어하던 두 사람이 계약으로 엮인다", "skeleton": "급하게 돈이 필요한 날, 완벽하지만 냉정한 사람이 나타난다. 우연히 시작된 계약 관계는 사소한 일상 속에서 조금씩 흔들리기 시작한다. 서로의 약한 부분을 보게 되는 순간, 관계의 정의가 바뀐다."},
    {"n": 7,  "genre": "로맨스",      "title": "같은 시간대의 메시지", "logline": "밤마다 도착하는 한 줄이 마음을 흔든다",   "skeleton": "매일 같은 시간, 알림이 울린다. 짧은 안부와 사소한 농담. 처음엔 우연이라 생각하지만, 반복될수록 의미가 생긴다. 만나야 할지, 계속 멀리서 지켜볼지 선택이 필요해진다."},
    {"n": 8,  "genre": "로맨스",      "title": "서랍 속 영수증",       "logline": "잊고 있던 날짜가 다시 떠오른다",         "skeleton": "서랍을 정리하다 오래된 영수증 한 장이 나온다. 날짜와 장소가 선명하다. 그 날의 말투, 표정, 공기가 되살아난다. 연락을 해야 하는지, 그냥 덮어야 하는지 마음이 갈린다."},
    {"n": 9,  "genre": "로맨스",      "title": "낮은 목소리의 약속",   "logline": "작게 한 말이 오래 남는다",               "skeleton": "사람이 많은 자리에서 낮게 속삭인 약속 하나가 마음을 붙잡는다. 가벼운 말이었는지 확인하고 싶어지지만, 먼저 다가가기가 어렵다. 거리와 타이밍이 계속 엇갈리며 감정이 깊어진다."},
    {"n": 10, "genre": "로맨스",      "title": "연습실의 불빛",        "logline": "같은 공간에서 조금씩 가까워진다",       "skeleton": "연습실에 남아 불을 끄려던 순간, 누군가가 들어온다. 서로의 습관과 약점을 보게 되며 경계가 풀린다. 호흡이 맞기 시작하면, 마음도 따라 움직인다."},
    # THRILLER
    {"n": 11, "genre": "스릴러",      "title": "문 앞의 쪽지",         "logline": "사라진 사람, 그리고 혼자만 알아챈 단서", "skeleton": "평범한 하루를 시작하려다 문 앞의 쪽지를 발견한다. 쪽지에는 숨겨 둔 사실을 정확히 찌르는 내용이 적혀 있다. 실종 사건이 일상과 연결되어 있고, 누군가 지켜보고 있다는 감각이 점점 선명해진다."},
    {"n": 12, "genre": "스릴러",      "title": "꺼지지 않는 알림",     "logline": "읽지 않았는데 읽힌다",                   "skeleton": "메시지를 열지 않았는데 상대는 이미 읽었다고 말한다. 통화기록, 위치기록, 사진의 메타데이터가 어긋나기 시작한다. 단순 오류가 아니라는 확신이 들면서, 주변이 낯설어진다."},
    {"n": 13, "genre": "스릴러",      "title": "빈 좌석",              "logline": "늘 있던 사람이 없다",                    "skeleton": "늘 같은 자리에 앉던 사람이 어느 날 보이지 않는다. 주변은 아무렇지 않게 굴지만, 공기만 달라져 있다. 작은 단서들을 따라가면, 사라진 이유가 예상보다 가까이에 있다."},
    {"n": 14, "genre": "스릴러",      "title": "검은 우산의 남자",     "logline": "비가 오면 나타난다",                     "skeleton": "비가 오는 날마다 같은 우산이 시야에 걸린다. 우연이라 넘기려 했지만, 동선이 정확히 겹친다. 확인하려는 순간, 뒤에서 발소리가 멈춘다."},
    {"n": 15, "genre": "스릴러",      "title": "파일명: final_final_3","logline": "지워도 다시 생긴다",                      "skeleton": "컴퓨터에 정체불명의 파일이 반복해서 생성된다. 열어보면 기록은 없고, 대신 익숙한 문장 한 줄이 남아 있다. 지우려 할수록 더 깊은 곳에서 다시 떠오른다."},
    # FANTASY
    {"n": 16, "genre": "판타지",      "title": "봉인된 규칙",          "logline": "규칙을 알면 살고, 모르면 죽는다",        "skeleton": "어느 날 낯선 공간에서 깨어난다. 벽엔 단 하나의 규칙만 적혀 있다: '밤 12시엔 절대 거울을 보지 마라.' 규칙을 어기는 순간, 세계가 처벌한다. 살아남기 위해 규칙의 진짜 의미를 찾아야 한다."},
    {"n": 17, "genre": "판타지",      "title": "균열의 지하철",        "logline": "한 정거장만 지나면 세계가 바뀐다",       "skeleton": "평소 타던 노선인데, 어느 날 안내 방송이 다르게 들린다. 창밖 풍경이 한 번 흔들리더니 낯선 도시로 이어진다. 되돌아가려면 '진짜 역명'을 찾아야 한다."},
    {"n": 18, "genre": "판타지",      "title": "빛을 먹는 서점",       "logline": "책을 펼치면 현실이 얇아진다",            "skeleton": "낡은 서점에 들어서자 조명이 한 단계 어두워진다. 책장을 넘길수록 주변의 소리가 사라지고, 문자들이 공중으로 뜬다. 한 권을 끝까지 읽으면, 되돌릴 수 없는 선택이 열린다."},
    {"n": 19, "genre": "판타지",      "title": "손목의 문양",          "logline": "표식은 능력이 아니라 부름이다",          "skeleton": "손목에 없던 문양이 생긴다. 만지면 미세하게 뜨겁다. 같은 문양을 가진 사람들이 하나둘 눈에 띄기 시작한다. 문양이 완성되는 순간, '호출'이 시작된다."},
    {"n": 20, "genre": "판타지",      "title": "잠들지 못하는 마을",   "logline": "밤이 오지 않는다",                      "skeleton": "해가 지지 않는 마을에 들어선다. 시계는 움직이는데 어둠은 오지 않는다. 사람들은 웃지만 눈가가 말라 있다. 밤을 되찾기 위해선 마을의 금기를 건드려야 한다."},
    # SLICE OF LIFE
    {"n": 21, "genre": "일상",        "title": "오늘의 온도",          "logline": "작은 변화가 쌓여 사람을 바꾼다",        "skeleton": "반복되는 하루가 이어진다. 출근길, 익숙한 카페, 같은 사람들. 하지만 사소한 사건 하나가 감정을 흔들고, 스스로를 다시 보게 된다."},
    {"n": 22, "genre": "일상",        "title": "늦은 점심",            "logline": "말하지 못한 마음이 식지 않는다",        "skeleton": "점심 시간이 자꾸 밀린다. 누군가는 늘 먼저 먹고, 누군가는 늘 남는다. 남은 자리에서 흘러나오는 말들이 마음에 걸린다. 사소한 한마디가 하루의 결을 바꾼다."},
    {"n": 23, "genre": "일상",        "title": "창가 자리",            "logline": "같은 풍경이 조금 다르게 보인다",        "skeleton": "늘 앉던 창가 자리에 앉는다. 같은 음악, 같은 향, 같은 메뉴. 그런데 오늘은 유난히 시선이 오래 머문다. 변한 건 풍경이 아니라 마음쪽일지도 모른다."},
    {"n": 24, "genre": "일상",        "title": "정리의 기술",          "logline": "버릴수록 가벼워진다",                    "skeleton": "방을 정리하다가 오래된 물건들이 나온다. 버리려 들었다가 손이 멈춘다. 정리는 결국, 무엇을 남길지 결정하는 일이 된다."},
    {"n": 25, "genre": "일상",        "title": "퇴근길의 노래",        "logline": "한 곡이 하루를 붙잡는다",               "skeleton": "퇴근길에 우연히 들은 노래가 하루 종일 맴돈다. 가사 한 줄이 마음을 정확히 건드린다. 집에 도착할 때쯤, 작은 결심이 생긴다."},
]

TARGET = 5000
MIN_CHARS = 4500
MAX_FORBIDDEN = 2
MAX_REGEN = 2
LOG_PATH = os.path.join(os.path.dirname(__file__), "improvement_log.txt")

# ──────────────────────────────────────────────────────────
# 프롬프트 빌더
# ──────────────────────────────────────────────────────────
HARD_RULES = """[HARD RULES]
- 서술은 독자 체험 중심(보고/듣고/느끼고/선택한 정보만).
- 설명/요약/회상으로 때우지 말고 장면(행동·대화·감각)으로 전개.
- 과격한 묘사·성인 수위·혐오 표현 배제.
- 서술에 2인칭(너/네/너의/너에게/너는/당신) 절대 사용 금지.
- 감정은 행동·신체반응·대화로만 표현(느껴진다/파고든다 등 추상 감정동사 금지).
- 매 화 첫 문장은 반드시 행동 또는 대화로 시작할 것.
- 이번 화 안에서 반드시: 새로운 정보 발견 또는 관계 변화 또는 주인공의 선택이 일어나야 한다.
- 반드시 {target}자 이상 작성할 것. 분량 미달 시 장면을 추가하라."""

POV_STYLE = """[POV / STYLE]
- 무인칭 몰입 POV. 독자가 장면 안에 직접 들어와 있는 것처럼 쓴다.
- 주어 생략 또는 행동·감각 중심으로 자연스럽게 이어 간다.
- 번역투 피하고 한국어 소설 문체로 매끄럽게 쓴다."""


def build_ep1_prompt(t: dict) -> str:
    return f"""무인칭 몰입 POV 연재소설 1화를 작성한다.

{HARD_RULES.format(target=TARGET)}

{POV_STYLE}

[PROJECT SEED]
- 제목: {t['title']}
- 장르: {t['genre']}
- 로그라인: {t['logline']}
- 기본 뼈대: {t['skeleton']}

[OUTPUT]
- 1화(이야기의 시작 장면)를 작성하라.
- 반드시 {TARGET}자 이상. 절대 중간에 끊지 말 것.
- 장면은 결정 직전에서 끊어라."""


def build_ep2_prompt(t: dict, ep1_tail: str) -> str:
    return f"""무인칭 몰입 POV 연재소설 2화를 작성한다. 직전 화에서 바로 이어진다.

{HARD_RULES.format(target=TARGET)}

{POV_STYLE}

[PROJECT SEED]
- 제목: {t['title']} (2화)
- 장르: {t['genre']}
- 로그라인: {t['logline']}
- 기본 뼈대: {t['skeleton']}

[PREV EPISODE TAIL]
아래는 1화 마지막 장면이다. 이 지점에서 바로 이어서 시작하라.
---
{ep1_tail}
---

[OUTPUT]
- 2화를 작성하라. 1화보다 이야기가 앞으로 나아가야 한다.
- 이전 화 결정을 다시 고민하거나 반복하지 말 것.
- 반드시 {TARGET}자 이상. 절대 중간에 끊지 말 것."""


def build_ep3_prompt(t: dict, ep2_tail: str) -> str:
    return f"""무인칭 몰입 POV 연재소설 3화를 작성한다. 직전 화에서 바로 이어진다.

{HARD_RULES.format(target=TARGET)}

{POV_STYLE}

[PROJECT SEED]
- 제목: {t['title']} (3화)
- 장르: {t['genre']}
- 로그라인: {t['logline']}
- 기본 뼈대: {t['skeleton']}

[PREV EPISODE TAIL]
아래는 2화 마지막 장면이다. 이 지점에서 바로 이어서 시작하라.
---
{ep2_tail}
---

[OUTPUT]
- 3화를 작성하라. 2화보다 이야기가 앞으로 나아가야 한다.
- 반드시 {TARGET}자 이상. 절대 중간에 끊지 말 것.
- 긴장감이 최고조에 달하는 장면으로 마무리하라."""


# ──────────────────────────────────────────────────────────
# 품질 평가
# ──────────────────────────────────────────────────────────
def count_forbidden(text: str) -> int:
    narration = _strip_quoted_dialogue(text)
    count = 0
    for pat in _FORBIDDEN_NARRATION_TOKENS:
        count += len(pat.findall(narration))
    return count


def has_event(text: str) -> bool:
    """단순 휴리스틱: 대화(" ") 또는 핵심 사건 키워드 포함 여부"""
    if '"' in text or '"' in text or '"' in text:
        return True
    event_keywords = [
        "발견", "단서", "쪽지", "파일", "메시지", "균열", "결정", "선택",
        "멈췄다", "잡았다", "뛰었다", "열었다", "닫았다", "말했다", "물었다",
        "도망", "쫓", "사라", "나타났", "변했", "깨달", "알아챘", "확인",
        "계약", "서명", "신호", "경고", "비밀", "폭로"
    ]
    return any(kw in text for kw in event_keywords)


def get_first_sentence(text: str) -> str:
    stripped = text.strip()
    for sep in ['. ', '.\n', '!" ', '?" ', '!"\n', '?"\n']:
        idx = stripped.find(sep)
        if idx != -1 and idx < 80:
            return stripped[:idx + 1]
    return stripped[:80]


def quality_check(text: str) -> dict:
    chars = len(text)
    forbidden = count_forbidden(text)
    event = has_event(text)
    first_sent = get_first_sentence(text)
    passed = (chars >= MIN_CHARS) and (forbidden <= MAX_FORBIDDEN) and event
    return {
        "chars": chars,
        "forbidden": forbidden,
        "event": event,
        "first_sent": first_sent,
        "passed": passed,
    }


# ──────────────────────────────────────────────────────────
# 로그 유틸
# ──────────────────────────────────────────────────────────
def log_append(line: str):
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\n")
    print(line, flush=True)


def already_done(topic_n: int) -> bool:
    """improvement_log.txt에서 해당 주제가 이미 완료됐는지 확인"""
    if not os.path.exists(LOG_PATH):
        return False
    with open(LOG_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    marker = f"[주제 {topic_n}/25]"
    if marker not in content:
        return False
    # 해당 주제 블록 뒤에 "완전통과" 또는 "부분통과"가 있으면 완료
    idx = content.rfind(marker)
    block = content[idx:idx+800]
    return ("완전통과" in block or "부분통과" in block)


# ──────────────────────────────────────────────────────────
# 단일 화 생성 (최대 MAX_REGEN+1회 시도)
# ──────────────────────────────────────────────────────────
def generate_episode(client, prompt: str) -> tuple:
    """
    returns: (text, qc, regen_count)
    qc: quality check dict
    regen_count: 재생성 횟수
    """
    regen_count = 0
    for attempt in range(MAX_REGEN + 1):
        text, calls, did_regen, _, reason, _ = _generate_with_continuation(
            client=client,
            model="gpt-4o-mini",
            base_prompt=prompt,
            target_chars=TARGET,
            max_continuations=3,
        )
        qc = quality_check(text)
        if qc["passed"]:
            return text, qc, regen_count
        if attempt < MAX_REGEN:
            regen_count += 1
    return text, qc, regen_count


# ──────────────────────────────────────────────────────────
# 메인 루프
# ──────────────────────────────────────────────────────────
def run_loop():
    client = _get_openai_client()

    # 로그 파일 헤더 (없을 때만)
    if not os.path.exists(LOG_PATH):
        log_append(f"=== 소설 품질 개선 루프 시작: {time.strftime('%Y-%m-%d %H:%M:%S')} ===")
        log_append(f"목표: 25개 주제 × 3화 | target={TARGET}자 | min={MIN_CHARS}자 | 금지어≤{MAX_FORBIDDEN}")
        log_append("=" * 60)

    total_pass = 0
    total_topics = len(TEMPLATES)

    for t in TEMPLATES:
        n = t["n"]

        if already_done(n):
            print(f"[SKIP] 주제 {n}/25 이미 완료됨", flush=True)
            total_pass += 1
            continue

        log_append(f"\n[주제 {n}/25] {t['title']} ({t['genre']})")
        log_append(f"로그라인: {t['logline']}")

        ep_texts = []
        ep_qcs = []
        total_regen = 0
        topic_all_pass = True

        try:
            # ── 1화 ──
            p1 = build_ep1_prompt(t)
            text1, qc1, regen1 = generate_episode(client, p1)
            ep_texts.append(text1)
            ep_qcs.append(qc1)
            total_regen += regen1
            if not qc1["passed"]:
                topic_all_pass = False
            log_append(
                f"  1화: {qc1['chars']}자 | 금지어 {qc1['forbidden']}회 | "
                f"사건 {'O' if qc1['event'] else 'X'} | "
                f"{'통과' if qc1['passed'] else '실패'}"
                f"{' (재생성 '+str(regen1)+'회)' if regen1 > 0 else ''}"
            )

            # ── 2화 ──
            ep1_tail = text1[-400:]
            p2 = build_ep2_prompt(t, ep1_tail)
            text2, qc2, regen2 = generate_episode(client, p2)
            ep_texts.append(text2)
            ep_qcs.append(qc2)
            total_regen += regen2
            if not qc2["passed"]:
                topic_all_pass = False
            log_append(
                f"  2화: {qc2['chars']}자 | 금지어 {qc2['forbidden']}회 | "
                f"사건 {'O' if qc2['event'] else 'X'} | "
                f"{'통과' if qc2['passed'] else '실패'}"
                f"{' (재생성 '+str(regen2)+'회)' if regen2 > 0 else ''}"
            )

            # ── 3화 ──
            ep2_tail = text2[-400:]
            p3 = build_ep3_prompt(t, ep2_tail)
            text3, qc3, regen3 = generate_episode(client, p3)
            ep_texts.append(text3)
            ep_qcs.append(qc3)
            total_regen += regen3
            if not qc3["passed"]:
                topic_all_pass = False
            log_append(
                f"  3화: {qc3['chars']}자 | 금지어 {qc3['forbidden']}회 | "
                f"사건 {'O' if qc3['event'] else 'X'} | "
                f"{'통과' if qc3['passed'] else '실패'}"
                f"{' (재생성 '+str(regen3)+'회)' if regen3 > 0 else ''}"
            )

            # ── 첫 문장 패턴 체크 ──
            sents = [qc["first_sent"] for qc in ep_qcs]
            unique_starts = len(set(s[:20] for s in sents))
            pattern_ok = unique_starts == 3
            log_append(
                f"  첫문장 패턴: {'모두 다름(OK)' if pattern_ok else '반복 있음(주의)'}"
            )

            final_status = "완전통과" if topic_all_pass else "부분통과"
            if topic_all_pass:
                total_pass += 1
            log_append(
                f"  수정 횟수: {total_regen}회 | 최종: {final_status}"
            )
            log_append("  ---")

        except Exception as e:
            err_msg = traceback.format_exc()
            log_append(f"  [ERROR] 주제 {n} 처리 중 오류: {e}")
            log_append(f"  {err_msg[:300]}")
            log_append(f"  수정 횟수: {total_regen}회 | 최종: 오류")
            log_append("  ---")

    # ── 최종 요약 ──
    log_append("\n" + "=" * 60)
    log_append(
        f"완료: {total_pass}/{total_topics} 통과 | "
        f"종료: {time.strftime('%Y-%m-%d %H:%M:%S')}"
    )
    log_append("=== 전체 완료 ===")


if __name__ == "__main__":
    run_loop()
