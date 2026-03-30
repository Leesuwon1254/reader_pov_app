from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional, Literal, Dict, Any, Tuple

import os
import re
import json
from dotenv import load_dotenv
from openai import OpenAI, AsyncOpenAI

# -------------------------------------------------------
# 0) ENV / OpenAI Client
# -------------------------------------------------------
load_dotenv(override=True)

def _get_api_key() -> str:
    raw = os.getenv("OPENAI_API_KEY", "")
    key = (raw or "").strip()

    if (len(key) >= 2) and ((key[0] == key[-1]) and key.startswith(("'", '"'))):
        key = key[1:-1].strip()

    return key

def _get_openai_client() -> OpenAI:
    api_key = _get_api_key()
    if not api_key:
        raise HTTPException(
            status_code=500,
            detail="OPENAI_API_KEY not set. Check backend/.env (no quotes, no extra spaces), and restart uvicorn."
        )
    return OpenAI(api_key=api_key, timeout=300.0)

# -------------------------------------------------------
# 1) ENUM / Models
# -------------------------------------------------------

Option = Literal[
    "DETAIL",
    "INTENSE",
    "ADD_SIDE_CHAR",
    "DIALOGUE_HEAVY",
    "TWIST",
    "EMOTION_DEEP",
    "WORLD_EXPAND",
]

class FlutterGenerateRequest(BaseModel):
    # ✅ v3: prompt 최우선 입력
    prompt: Optional[str] = ""

    synopsis: Optional[str] = ""
    genre: Optional[str] = "drama"
    tone: Optional[str] = "normal"
    length_hint: Optional[int] = 5000

    request: Optional[str] = ""
    guide: Optional[str] = ""
    mode: Optional[Any] = ""
    option: Optional[Any] = ""

class GenerateRequest(BaseModel):
    project_title: str
    genre_tone: str
    target_length: int = 5000

    banned_elements: Optional[str] = None
    keywords: Optional[str] = None

    character_bible: str
    previous_summary: Optional[str] = None

    episode_goal: str
    must_include: List[str] = []
    avoid: List[str] = []
    user_request_text: Optional[str] = None

    options: List[Option] = []

class GenerateResponse(BaseModel):
    content: str
    prompt_text: str
    style_options_block: str
    normalized: Dict[str, Any]
    meta: Dict[str, Any] = {}

# -------------------------------------------------------
# 2) Prompt Builder (구형 fallback용)
# -------------------------------------------------------

OPTION_ORDER = [
    "DETAIL",
    "EMOTION_DEEP",
    "DIALOGUE_HEAVY",
    "INTENSE",
    "ADD_SIDE_CHAR",
    "WORLD_EXPAND",
    "TWIST",
]

OPTION_TEXT = {
    "DETAIL": "- 장면 묘사를 풍부하게(시각/청각/후각/촉각 중 최소 2개), 인물의 미세한 표정·버릇·시선 처리를 자주 넣어라.",
    "INTENSE": "- 갈등 강도를 높이고, 너에게 불리한 선택을 강요하는 상황을 넣어라. 단, 수위는 안전하게 유지하라.",
    "ADD_SIDE_CHAR": "- 새 인물 1~2명을 추가 등장시키고, 전개에 기능적 역할(조력/방해/미스터리)을 부여하라.",
    "DIALOGUE_HEAVY": "- 대화 비중을 높여라(전체 분량 중 대화 50% 이상). 대사로 긴장과 정보가 전달되게 하라.",
    "TWIST": "- 마지막 15% 구간에 자연스러운 반전 1개를 넣어라(억지 금지). 앞부분에 복선 1개를 반드시 심어라.",
    "EMOTION_DEEP": "- 주인공의 감정 변화가 단계적으로 느껴지도록 내적 독백과 신체 반응(호흡/심장/손끝 등)을 배치하라.",
    "WORLD_EXPAND": "- 세계관 단서(규칙/조직/사건의 흔적)를 1~2개 추가하되, 설명 과다는 피하고 장면 속에 녹여라.",
}

DEFAULT_STYLE_LINE = "- 문체는 간결하고 몰입감 있게, 장면 전환을 빠르게 하라."

MASTER_TEMPLATE = """너는 **“2인칭 독자시점(Reader POV)” 연재 소설**을 쓰는 전문 작가다.  
사용자는 이야기의 주인공이며, 모든 서술은 **독자 체험 중심**으로 진행한다.  
아래 정보를 바탕으로 **이번 회차(1화 분량)**를 작성하라.

[HARD RULES]  
1) 시점은 2인칭 독자시점으로 유지한다. (문장마다 '너는'을 반복할 필요는 없으며, 자연스러운 2인칭 흐름을 우선한다.)  
2) 독자가 직접 보고·듣고·느끼고·선택한 정보만 서술한다  
   (전지적 설명, 타인의 속마음 직접 서술 금지).  
3) 기존 설정/인물/사건과 모순되는 전개 금지.  
4) 설명보다 장면(행동·대화·감각 묘사) 중심으로 전개한다.  
5) 과격한 묘사·성인 수위·혐오 표현은 배제하고 긴장감 중심으로 연출.
6) 분량 목표: **{target_length}자 내외**(±15%).  
7) 결과는 반드시 [OUTPUT FORMAT]을 준수한다.

[PROJECT INFO]  
- 작품명: {project_title}  
- 장르/톤: {genre_tone}  
- 시점: 2인칭 독자시점(고정)  
- 금지 요소: {banned_elements}  
- 핵심 키워드: {keywords}

[CHARACTER BIBLE]  
(주인공을 제외한 인물만 기술)  
{character_bible}

[STORY SO FAR / 이전 회차 요약]  
{previous_summary}

[THIS EPISODE REQUEST / 이번 회차 요청]  
- 이번 회차 목표(한 줄): {episode_goal}  
- 반드시 넣을 요소: {must_include}  
- 피하고 싶은 요소: {avoid}  
- 추가 요구사항(원문): {user_request_text}

[STYLE OPTIONS]  
{style_options_block}

[OUTPUT FORMAT - 반드시 준수]  
#TITLE: 한 줄 제목  
#SUMMARY: 5~8줄 요약  
#CHARACTERS: 이번 회차에 등장한 인물과 역할 bullet 정리  
#EPISODE: 본문 (2인칭 독자 체험 중심)  
#NEXT_HOOK: 다음 화를 보고 싶게 만드는 2~4줄 훅
"""

def _norm_text(v: Optional[str], default: str) -> str:
    if v is None:
        return default
    s = str(v).strip()
    return s if s else default

def _norm_list(items: List[str], default: str) -> str:
    cleaned = [x.strip() for x in items if x and x.strip()]
    return ", ".join(cleaned) if cleaned else default

def build_style(options: List[str]) -> str:
    if not options:
        return DEFAULT_STYLE_LINE
    order = {k: i for i, k in enumerate(OPTION_ORDER)}
    uniq = []
    seen = set()
    for o in options:
        if o not in seen:
            seen.add(o)
            uniq.append(o)
    uniq.sort(key=lambda x: order.get(x, 999))
    lines = [OPTION_TEXT[o] for o in uniq if o in OPTION_TEXT]
    return "\n".join(lines) if lines else DEFAULT_STYLE_LINE

def build_prompt(req: GenerateRequest) -> Dict[str, Any]:
    banned = _norm_text(req.banned_elements, "없음")
    keywords = _norm_text(req.keywords, "없음")
    prev = _norm_text(req.previous_summary, "(없음 - 1화)")
    user_req = _norm_text(req.user_request_text, "(추가 없음)")
    must = _norm_list(req.must_include, "(특이사항 없음)")
    avoid = _norm_list(req.avoid, "(특이사항 없음)")
    style = build_style(req.options)

    prompt_text = MASTER_TEMPLATE.format(
        target_length=req.target_length,
        project_title=req.project_title,
        genre_tone=req.genre_tone,
        banned_elements=banned,
        keywords=keywords,
        character_bible=req.character_bible,
        previous_summary=prev,
        episode_goal=req.episode_goal,
        must_include=must,
        avoid=avoid,
        user_request_text=user_req,
        style_options_block=style,
    )

    return {
        "prompt_text": prompt_text,
        "style_options_block": style,
        "normalized": {
            "banned_elements": banned,
            "keywords": keywords,
            "previous_summary": prev,
            "user_request_text": user_req,
            "must_include": must,
            "avoid": avoid,
            "options": req.options,
            "target_length": req.target_length,
        }
    }

# -------------------------------------------------------
# 3) Flutter 옵션 → enum 매핑
# -------------------------------------------------------
def _safe_str(v: Any) -> str:
    """
    Flutter Web에서 option/mode가 {}(dict)로 들어오는 케이스 방지.
    """
    if v is None:
        return ""
    if isinstance(v, str):
        return v.strip()
    return ""

def map_flutter_to_options(req: FlutterGenerateRequest) -> List[str]:
    candidates = [
        _safe_str(req.mode),
        _safe_str(req.option),
        _safe_str(req.request),
        _safe_str(req.guide),
        _safe_str(req.tone),
    ]
    blob = " ".join([c for c in candidates if c])
    blob_l = blob.lower()

    options: List[str] = []

    if ("구체" in blob) or ("detail" in blob_l) or ("detailed" in blob_l):
        options.append("DETAIL")

    if ("자극" in blob) or ("intense" in blob_l) or ("spicy" in blob_l):
        options.append("INTENSE")

    if ("주변" in blob) or ("인물" in blob) or ("확장" in blob) or ("side" in blob_l):
        options.append("ADD_SIDE_CHAR")

    uniq = []
    seen = set()
    for o in options:
        if o not in seen:
            seen.add(o)
            uniq.append(o)
    return uniq

# -------------------------------------------------------
# 4) Server-level Guard (Step 2) - 무인칭 정책 버전
#    - 목표: "서술"에서 2인칭(너/네/너의/당신 등) 0회
#    - 대사("...")는 검사 제외(허용)
#    - 자동 수정은 위험하므로 최소화: 메타라인 제거만 수행
#    - 위반 발견 시 "재생성"이 기본
# -------------------------------------------------------

# 서술에서 금지할 토큰(무인칭)
_FORBIDDEN_NARRATION_TOKENS: List[re.Pattern] = [
    re.compile(r"\b너\b"),
    # \b네\b 제거: 한국어에서 "네"(yes/긍정)가 서술에 자연히 나와 false positive 다발
    re.compile(r"\b너의\b"),
    re.compile(r"\b너에게\b"),
    re.compile(r"\b너는\b"),
    re.compile(r"\b당신\b"),
    re.compile(r"\b당신의\b"),
    re.compile(r"\b당신에게\b"),
    re.compile(r"\b귀하\b"),
    re.compile(r"\b독자(님|분)\b"),
]

# 줄 전체 삭제가 안전한 메타 표현(문학적 의미 판단 없이 제거 가능)
_SAFE_DROP_LINE_PATTERNS: List[re.Pattern] = [
    re.compile(r"^\s*#\s*SUMMARY\s*:?", re.IGNORECASE),
    re.compile(r"^\s*#\s*CHARACTERS\s*:?", re.IGNORECASE),
    re.compile(r"^\s*#\s*NEXT_HOOK\s*:?", re.IGNORECASE),
    # (선택) "독자님" 같은 메타 호칭 줄
    re.compile(r"독자(님|분)\b"),
]

def _strip_quoted_dialogue(text: str) -> str:
    """
    가장 단순한 휴리스틱:
      - "..." / “...” / '...' / ‘...’ 구간을 제거해서 '서술만' 남김
    """
    out = []
    in_quote = False
    quote_chars = {'"', "“", "”", "'", "‘", "’"}
    toggle_chars = {'"', "“", "'", "‘"}  # 열림만 토글로 취급

    for ch in text:
        if ch in toggle_chars:
            in_quote = not in_quote
            continue
        # 닫힘 문자 처리(“” 따옴표는 방향이 다를 수 있어 toggle로 처리했음)
        if ch in {'”', '’'}:
            # 이미 toggle로 처리했을 가능성이 있지만, 안전상 무시
            continue

        if not in_quote:
            out.append(ch)

    return "".join(out)

def _remove_safe_meta_lines(text: str) -> Tuple[str, bool]:
    changed = False
    out_lines: List[str] = []

    for line in text.splitlines():
        if any(p.search(line) for p in _SAFE_DROP_LINE_PATTERNS):
            changed = True
            continue
        out_lines.append(line)

    return ("\n".join(out_lines)).strip(), changed

def _find_first_forbidden_in_narration(text: str) -> Optional[str]:
    narration_only = _strip_quoted_dialogue(text)
    for pat in _FORBIDDEN_NARRATION_TOKENS:
        m = pat.search(narration_only)
        if m:
            return f"FORBIDDEN_NARRATION:{m.group(0)}"
    return None

def _guard_validate(text: str) -> Tuple[bool, Optional[str]]:
    reason = _find_first_forbidden_in_narration(text)
    return (reason is None), reason

def _guard_suffix_instruction() -> str:
    # 재생성 시에만 추가 (원본 prompt 훼손 최소화)
    return (
        "\n\n[GUARD STRICT - NO PRONOUN NARRATION]\n"
        "- 서술문에서 '너/네/너의/너에게/너는/당신/당신의/당신에게/귀하/독자님'을 절대 사용하지 말 것.\n"
        "- 대사(\"...\") 안의 '너'는 허용되지만, 대사 직후 서술은 반드시 무인칭으로 시작할 것.\n"
        "- 인칭이 필요해질 경우, 주어 생략/행동/감각 묘사로 해결할 것.\n"
    )

def _call_openai_text(client: OpenAI, model: str, input_text: str) -> str:
    resp = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": input_text},
        ],
        max_tokens=10000,
        temperature=0.85,
    )
    story_text = (resp.choices[0].message.content or "").strip()
    if not story_text:
        raise RuntimeError("Empty content from OpenAI chat completion.")
    return story_text

def _generate_with_guard(
    client: OpenAI,
    model: str,
    base_prompt: str,
    max_attempts: int = 3
) -> Tuple[str, int, bool, bool, Optional[str], str]:
    """
    returns:
      content,
      attempts_used,
      did_regenerate,
      did_safe_fix,
      last_reason,
      used_input_prompt
    """
    did_regenerate = False
    did_any_safe_fix = False
    last_reason: Optional[str] = None

    used_input_prompt = base_prompt
    last_text = ""

    for attempt in range(1, max_attempts + 1):
        raw = _call_openai_text(client, model, used_input_prompt)

        # 안전한 범위의 "메타 줄 제거"만 수행
        fixed, did_safe_fix = _remove_safe_meta_lines(raw)
        did_any_safe_fix = did_any_safe_fix or did_safe_fix

        ok, reason = _guard_validate(fixed)
        if ok:
            return fixed, attempt, did_regenerate, did_any_safe_fix, None, used_input_prompt

        # 위반 발견 → 재생성
        last_reason = reason
        did_regenerate = True
        last_text = fixed

        used_input_prompt = base_prompt + _guard_suffix_instruction()

    # max_attempts 모두 실패 → 마지막 결과 반환(메타 포함)
    return (last_text or fixed), max_attempts, did_regenerate, did_any_safe_fix, last_reason, used_input_prompt

# -------------------------------------------------------
# 5) 분할 생성 (Continuation)
# -------------------------------------------------------

def _call_openai_continuation(
    client: OpenAI,
    model: str,
    base_prompt: str,
    current_text: str,
    remaining_chars: int,
) -> str:
    """
    기존 생성 텍스트에 이어서 continuation 생성.
    원본 프롬프트 + 지금까지의 본문 + 이어쓰기 지시를 단일 system 메시지로 구성해
    모델이 '완결된 이야기'로 인식하는 것을 방지한다.
    """
    # 직전 맥락은 마지막 300자만 사용 (토큰 절약 + 집중도 향상)
    tail = current_text[-300:] if len(current_text) > 300 else current_text

    # 핵심 5줄 지시만 전송 (base_prompt 전체 제거)
    continuation_prompt = (
        f"[이어쓰기 지시] 한국어 웹소설 본문을 아래 규칙으로 계속 작성하라.\n"
        f"- 무인칭 몰입 POV. 서술에 2인칭(너/네/너의/너에게/너는) 절대 사용 금지.\n"
        f"- 반드시 {remaining_chars}자 이상 새로 작성할 것. 분량 미달 시 장면을 추가하라.\n"
        f"- 마무리/결말/에필로그 금지. 이야기를 계속 전개하라.\n"
        f"- 직전 본문을 요약하거나 반복하지 말고, 바로 이어서 써라.\n"
        f"- 장면은 행동·대화·감각 묘사 중심으로 전개하라.\n\n"
        f"[직전 본문 끝부분 (이 다음부터 이어서 쓸 것)]\n"
        f"{tail}\n\n"
        f"[이어서 작성 시작 →]"
    )
    resp = client.chat.completions.create(
        model=model,
        messages=[{"role": "system", "content": continuation_prompt}],
        max_tokens=10000,
        temperature=0.85,
    )
    text = (resp.choices[0].message.content or "").strip()
    if not text:
        raise RuntimeError("Empty content from OpenAI continuation.")
    return text


def _generate_with_continuation(
    client: OpenAI,
    model: str,
    base_prompt: str,
    target_chars: int,
    max_continuations: int = 3,
    max_guard_attempts: int = 3,
) -> Tuple[str, int, bool, bool, Optional[str], str]:
    """
    1차 생성 후 분량(target_chars * 0.8) 미달 시 자동 이어쓰기.
    Guard(금지어 체크)는 최종 합본에만 적용.

    returns:
      content, total_calls, did_regenerate, did_safe_fix, last_reason, used_input_prompt
    """
    import time as _time
    t_total = _time.perf_counter()

    threshold = target_chars          # 목표 분량 자체를 기준으로 (0.8 완화 제거)
    parts: List[str] = []
    did_any_safe_fix = False
    continuation_count = 0

    # ── 1차 생성 ──────────────────────────────────────────
    t0 = _time.perf_counter()
    raw = _call_openai_text(client, model, base_prompt)
    t1 = _time.perf_counter()
    fixed, sf = _remove_safe_meta_lines(raw)
    did_any_safe_fix = did_any_safe_fix or sf
    parts.append(fixed)
    print(f"[TIMING] 1차 OpenAI 호출: {t1-t0:.1f}s | 생성 분량: {len(fixed)}자 | 임계값: {threshold}자", flush=True)

    # ── 이어쓰기 (최대 max_continuations회) ──────────────
    while len("".join(parts)) < threshold and continuation_count < max_continuations:
        current_text = "\n\n".join(parts)
        remaining = target_chars - len(current_text)
        print(f"[TIMING] 이어쓰기 {continuation_count+1}차 시작 (현재 {len(current_text)}자, 부족 {remaining}자)", flush=True)
        tc0 = _time.perf_counter()
        cont_raw = _call_openai_continuation(
            client=client,
            model=model,
            base_prompt=base_prompt,
            current_text=current_text,
            remaining_chars=remaining,
        )
        tc1 = _time.perf_counter()
        cont_fixed, sf2 = _remove_safe_meta_lines(cont_raw)
        did_any_safe_fix = did_any_safe_fix or sf2
        parts.append(cont_fixed)
        continuation_count += 1
        print(f"[TIMING] 이어쓰기 {continuation_count}차 완료: {tc1-tc0:.1f}s | 추가 분량: {len(cont_fixed)}자", flush=True)

    merged = "\n\n".join(parts)
    total_calls = 1 + continuation_count
    print(f"[TIMING] 합본 분량: {len(merged)}자 (총 {total_calls}회 호출)", flush=True)

    # ── Guard: 최종 합본에만 적용 ──────────────────────────
    tg0 = _time.perf_counter()
    ok, reason = _guard_validate(merged)
    tg1 = _time.perf_counter()
    print(f"[TIMING] Guard 체크: {(tg1-tg0)*1000:.1f}ms | ok={ok} reason={reason}", flush=True)
    if ok:
        print(f"[TIMING] 전체 총 소요: {_time.perf_counter()-t_total:.1f}s", flush=True)
        return merged, total_calls, False, did_any_safe_fix, None, base_prompt

    # 금지어 위반 → guard suffix 붙여서 재생성 + continuation 유지
    guard_prompt = base_prompt + _guard_suffix_instruction()
    last_reason: Optional[str] = reason
    last_merged = merged

    for regen_i in range(max_guard_attempts):
        # 1차 재생성
        print(f"[TIMING] Guard 재생성 {regen_i+1}차 시작", flush=True)
        tr0 = _time.perf_counter()
        raw2 = _call_openai_text(client, model, guard_prompt)
        tr1 = _time.perf_counter()
        fixed2, sf3 = _remove_safe_meta_lines(raw2)
        did_any_safe_fix = did_any_safe_fix or sf3
        total_calls += 1
        print(f"[TIMING] Guard 재생성 {regen_i+1}차: {tr1-tr0:.1f}s | {len(fixed2)}자", flush=True)

        # 분량 부족하면 continuation도 적용
        guard_parts = [fixed2]
        cont_count = 0
        while len("".join(guard_parts)) < threshold and cont_count < max_continuations:
            current_g = "\n\n".join(guard_parts)
            remaining_g = target_chars - len(current_g)
            tc0 = _time.perf_counter()
            cont_g = _call_openai_continuation(
                client=client, model=model,
                base_prompt=guard_prompt,
                current_text=current_g,
                remaining_chars=remaining_g,
            )
            tc1 = _time.perf_counter()
            cont_g_fixed, sf4 = _remove_safe_meta_lines(cont_g)
            did_any_safe_fix = did_any_safe_fix or sf4
            guard_parts.append(cont_g_fixed)
            total_calls += 1
            cont_count += 1
            print(f"[TIMING] Guard 이어쓰기 {cont_count}차: {tc1-tc0:.1f}s | {len(cont_g_fixed)}자", flush=True)

        merged2 = "\n\n".join(guard_parts)
        ok2, reason2 = _guard_validate(merged2)
        if ok2:
            print(f"[TIMING] 전체 총 소요: {_time.perf_counter()-t_total:.1f}s", flush=True)
            return merged2, total_calls, True, did_any_safe_fix, None, guard_prompt
        last_reason = reason2
        last_merged = merged2

    print(f"[TIMING] 전체 총 소요(Guard 실패): {_time.perf_counter()-t_total:.1f}s", flush=True)
    return last_merged, total_calls, True, did_any_safe_fix, last_reason, guard_prompt


# -------------------------------------------------------
# 6) FastAPI app
# -------------------------------------------------------
app = FastAPI(title="Reader POV Backend v2.3 (Prompt-first + Guard, NO-PRONOUN)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.options("/{full_path:path}")
def preflight_handler(full_path: str):
    return Response(status_code=204)

@app.get("/health")
def health():
    return {"ok": True}

def _clamp_length_hint(v: Optional[int]) -> int:
    try:
        n = int(v) if v is not None else 5000
    except Exception:
        n = 5000
    if n < 3000:
        return 3000
    if n > 10000:
        return 10000
    return n

# -------------------------------------------------------
# 6) Generate Endpoint
# -------------------------------------------------------
# -------------------------------------------------------
# 7) Streaming Generate Endpoint (/generate/stream)
# -------------------------------------------------------

def _get_async_openai_client() -> AsyncOpenAI:
    api_key = _get_api_key()
    if not api_key:
        raise ValueError("OPENAI_API_KEY not set")
    return AsyncOpenAI(api_key=api_key, timeout=300.0)


@app.post("/generate/stream")
async def generate_stream(req: FlutterGenerateRequest):
    """
    SSE 스트리밍 엔드포인트.
    Render 무료 플랜 30초 HTTP 타임아웃을 우회하기 위해
    연결을 끊지 않고 청크 단위로 스트리밍.

    SSE 이벤트 타입:
      {"type":"chunk",       "text":"..."}            - OpenAI 토큰
      {"type":"continuation","index":N, ...}          - 이어쓰기 시작
      {"type":"guard_retry", "attempt":N,"reason":""} - 금지어 재생성
      {"type":"done",        "meta":{...}}            - 완료
      {"type":"error",       "message":"..."}         - 오류
    """
    final_prompt = _norm_text(req.prompt, "").strip()
    target_length = _clamp_length_hint(req.length_hint)

    # 프롬프트 없을 때 fallback (기존 /generate와 동일)
    if not final_prompt:
        synopsis_text = _norm_text(req.synopsis, "").strip()
        options = map_flutter_to_options(req)
        mapped = GenerateRequest(
            project_title="승자와 패자",
            genre_tone=f"{_norm_text(req.genre, 'drama')} / {_norm_text(req.tone, 'normal')}",
            target_length=target_length,
            banned_elements="없음",
            keywords="없음",
            character_bible="- (미정): v2에서 인물카드 연동 예정",
            previous_summary=synopsis_text,
            episode_goal="다음 화 작성",
            must_include=[],
            avoid=[],
            user_request_text=_norm_text(
                f"{_safe_str(req.request)}\n{_safe_str(req.guide)}".strip(),
                "(추가 없음)",
            ),
            options=options,
        )
        final_prompt = build_prompt(mapped)["prompt_text"]

    async def event_generator():
        try:
            client = _get_async_openai_client()
        except ValueError as e:
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"
            return

        model = "gpt-4o-mini"
        max_continuations = 3
        max_guard_attempts = 3
        used_prompt = final_prompt
        merged = ""
        reason: Optional[str] = None

        for guard_attempt in range(max_guard_attempts):
            parts: List[str] = []

            # ── 1차 생성 (스트리밍) ──────────────────────────────
            chunks: List[str] = []
            try:
                stream = await client.chat.completions.create(
                    model=model,
                    messages=[{"role": "system", "content": used_prompt}],
                    max_tokens=10000,
                    temperature=0.85,
                    stream=True,
                )
                async for token in stream:
                    delta = (token.choices[0].delta.content or "") if token.choices else ""
                    if delta:
                        chunks.append(delta)
                        yield f"data: {json.dumps({'type': 'chunk', 'text': delta})}\n\n"
            except Exception as e:
                yield f"data: {json.dumps({'type': 'error', 'message': f'OpenAI error: {e}'})}\n\n"
                return

            fixed, _ = _remove_safe_meta_lines("".join(chunks))
            parts.append(fixed)

            # ── Continuation (분량 보충) ──────────────────────────
            cont_count = 0
            while len("".join(parts)) < target_length and cont_count < max_continuations:
                cont_count += 1
                current_text = "\n\n".join(parts)
                remaining = target_length - len(current_text)

                yield f"data: {json.dumps({'type': 'continuation', 'index': cont_count, 'current_chars': len(current_text), 'target_chars': target_length})}\n\n"

                tail = current_text[-300:] if len(current_text) > 300 else current_text
                cont_prompt = (
                    f"[이어쓰기 지시] 한국어 웹소설 본문을 아래 규칙으로 계속 작성하라.\n"
                    f"- 무인칭 몰입 POV. 서술에 2인칭(너/네/너의/너에게/너는) 절대 사용 금지.\n"
                    f"- 반드시 {remaining}자 이상 새로 작성할 것. 분량 미달 시 장면을 추가하라.\n"
                    f"- 마무리/결말/에필로그 금지. 이야기를 계속 전개하라.\n"
                    f"- 직전 본문을 요약하거나 반복하지 말고, 바로 이어서 써라.\n"
                    f"- 장면은 행동·대화·감각 묘사 중심으로 전개하라.\n\n"
                    f"[직전 본문 끝부분 (이 다음부터 이어서 쓸 것)]\n"
                    f"{tail}\n\n"
                    f"[이어서 작성 시작 →]"
                )

                cont_chunks: List[str] = []
                try:
                    cont_stream = await client.chat.completions.create(
                        model=model,
                        messages=[{"role": "system", "content": cont_prompt}],
                        max_tokens=10000,
                        temperature=0.85,
                        stream=True,
                    )
                    async for token in cont_stream:
                        delta = (token.choices[0].delta.content or "") if token.choices else ""
                        if delta:
                            cont_chunks.append(delta)
                            yield f"data: {json.dumps({'type': 'chunk', 'text': delta})}\n\n"
                except Exception as e:
                    yield f"data: {json.dumps({'type': 'error', 'message': f'Continuation error: {e}'})}\n\n"
                    return

                cont_fixed, _ = _remove_safe_meta_lines("".join(cont_chunks))
                parts.append(cont_fixed)

            merged = "\n\n".join(parts)
            ok, reason = _guard_validate(merged)

            if ok:
                yield f"data: {json.dumps({'type': 'done', 'meta': {'total_chars': len(merged), 'total_calls': 1 + cont_count, 'did_regenerate': guard_attempt > 0, 'guard_ok': True}})}\n\n"
                return

            # Guard 실패 → 재시도 알림 후 suffix 추가
            if guard_attempt < max_guard_attempts - 1:
                yield f"data: {json.dumps({'type': 'guard_retry', 'attempt': guard_attempt + 1, 'reason': reason or ''})}\n\n"
                used_prompt = final_prompt + _guard_suffix_instruction()

        # 모든 guard 시도 소진 → 마지막 결과라도 반환
        yield f"data: {json.dumps({'type': 'done', 'meta': {'total_chars': len(merged), 'guard_ok': False, 'last_reason': reason}})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",   # nginx/Render 버퍼링 비활성화
            "Connection": "keep-alive",
        },
    )


# -------------------------------------------------------
# 6-b) 기존 동기 Generate Endpoint (하위 호환 유지)
# -------------------------------------------------------
@app.post("/generate", response_model=GenerateResponse)
def generate(req: FlutterGenerateRequest):
    client = _get_openai_client()
    model = "gpt-4o-mini"

    # ✅ 1) prompt 최우선
    final_prompt = _norm_text(req.prompt, "").strip()

    # ✅ 공통 파라미터
    options = map_flutter_to_options(req)
    target_length = _clamp_length_hint(req.length_hint)

    # (디버깅) 실제 들어오는 prompt 확인용(필요 없으면 지워도 됨)
    # print("=== REQ.PROMPT (first 300) ===")
    # print((final_prompt or "")[:300])

    # ---------------------------------------------------
    # A) PROMPT-ONLY (v3)
    # ---------------------------------------------------
    if final_prompt:
        try:
            story_text, total_calls, did_regen, did_safe_fix, last_reason, used_input = _generate_with_continuation(
                client=client,
                model=model,
                base_prompt=final_prompt,
                target_chars=target_length,
                max_continuations=3,
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"OpenAI request failed: {e}")

        return GenerateResponse(
            content=story_text,
            prompt_text=final_prompt,
            style_options_block="",
            normalized={
                "mode": "PROMPT_ONLY",
                "used_prompt": True,
                "target_length": target_length,
                "mapped_options": options,
            },
            meta={
                "mode": "PROMPT_ONLY",
                "model": model,
                "target_length": target_length,
                "mapped_options": options,
                "guard": {
                    "total_calls": total_calls,
                    "did_regenerate": did_regen,
                    "did_safe_fix": did_safe_fix,
                    "last_reason": last_reason,
                    "used_guard_suffix": (used_input != final_prompt),
                },
            },
        )

    # ---------------------------------------------------
    # B) FALLBACK (구형: synopsis/request/guide 기반)
    # ---------------------------------------------------
    synopsis_text = _norm_text(req.synopsis, "").strip()

    mapped = GenerateRequest(
        project_title="승자와 패자",
        genre_tone=f"{_norm_text(req.genre, 'drama')} / {_norm_text(req.tone, 'normal')}",
        target_length=target_length,
        banned_elements="없음",
        keywords="없음",
        character_bible="- (미정): v2에서 인물카드 연동 예정",
        previous_summary=synopsis_text,
        episode_goal="다음 화 작성",
        must_include=[],
        avoid=[],
        user_request_text=_norm_text(
            f"{_safe_str(req.request)}\n{_safe_str(req.guide)}".strip(),
            "(추가 없음)"
        ),
        options=options,
    )

    result = build_prompt(mapped)
    prompt_text = result["prompt_text"]

    try:
        story_text, total_calls, did_regen, did_safe_fix, last_reason, used_input = _generate_with_continuation(
            client=client,
            model=model,
            base_prompt=prompt_text,
            target_chars=target_length,
            max_continuations=2,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OpenAI request failed: {e}")

    return GenerateResponse(
        content=story_text,
        prompt_text=prompt_text,
        style_options_block=result["style_options_block"],
        normalized=result["normalized"],
        meta={
            "mode": "STORY_GENERATION_FALLBACK",
            "mapped_options": options,
            "target_length": target_length,
            "model": model,
            "guard": {
                "total_calls": total_calls,
                "did_regenerate": did_regen,
                "did_safe_fix": did_safe_fix,
                "last_reason": last_reason,
                "used_guard_suffix": (used_input != prompt_text),
            },
        },
    )



