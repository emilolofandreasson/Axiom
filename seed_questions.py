"""
seed_questions.py — Nightly question bank seeder for Axiom

Checks global_questions coverage per (language, cefr_level) combination.
For any pair with fewer than MIN_QUESTIONS questions, generates a batch via
Gemini and inserts them into Supabase.

Required env vars (set as GitHub Secrets → passed via workflow env: block):
  SUPABASE_URL            — https://<ref>.supabase.co
  SUPABASE_SERVICE_KEY    — service_role key (bypasses RLS)
  GEMINI_SEED_API_KEY     — dedicated Gemini key, separate from user key

For local testing, export the variables in your shell before running.
"""

import os
import json
import uuid
import time
import sys
import requests  # only stdlib + requests needed — no extra deps

# ---------------------------------------------------------------------------
# Validate required env vars before doing anything else
# ---------------------------------------------------------------------------

REQUIRED_VARS = ["SUPABASE_URL", "SUPABASE_SERVICE_KEY", "GEMINI_SEED_API_KEY"]
missing = [v for v in REQUIRED_VARS if not os.environ.get(v)]
if missing:
    print(f"ERROR: Missing required environment variables: {', '.join(missing)}")
    print("Set them as GitHub Secrets (SUPABASE_URL, SUPABASE_SERVICE_KEY, GEMINI_SEED_API_KEY)")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SUPABASE_URL      = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_KEY      = os.environ["SUPABASE_SERVICE_KEY"]
GEMINI_API_KEY    = os.environ["GEMINI_SEED_API_KEY"]
GEMINI_MODEL      = "gemini-2.0-flash-lite"   # 30 RPM free tier vs 15 for flash
GEMINI_ENDPOINT   = (
    f"https://generativelanguage.googleapis.com/v1beta/models/"
    f"{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"
)

MIN_QUESTIONS     = 50    # target floor per (language, cefr_level)
BATCH_SIZE        = 10    # questions generated per Gemini call
MAX_BATCHES       = 10    # max Gemini calls per run
RETRY_DELAY_S     = 15    # seconds between retries on rate-limit
INTER_CALL_DELAY  = 8     # seconds between successful calls (~7 RPM, well under 30)

# Languages and CEFR levels to maintain
TARGETS = [
    ("es", "A1"), ("es", "A2"), ("es", "B1"), ("es", "B2"),
    ("fr", "A1"), ("fr", "A2"), ("fr", "B1"),
    ("de", "A1"), ("de", "A2"), ("de", "B1"),
    ("it", "A1"), ("it", "A2"),
    ("pt", "A1"), ("pt", "A2"),
    ("ja", "A1"), ("ja", "A2"),
    ("ko", "A1"), ("ko", "A2"),
    ("zh", "A1"), ("zh", "A2"),
    ("ru", "A1"), ("ru", "A2"),
    ("nl", "A1"), ("sv", "A1"), ("no", "A1"),
    ("da", "A1"), ("pl", "A1"), ("tr", "A1"),
]

LANGUAGE_NAMES = {
    "es": "Spanish",        "fr": "French",          "de": "German",
    "it": "Italian",        "pt": "Portuguese",      "ja": "Japanese",
    "ko": "Korean",         "zh": "Mandarin Chinese", "ar": "Arabic",
    "ru": "Russian",        "nl": "Dutch",           "sv": "Swedish",
    "no": "Norwegian",      "da": "Danish",          "pl": "Polish",
    "tr": "Turkish",        "hi": "Hindi",           "el": "Greek",
    "he": "Hebrew",         "vi": "Vietnamese",
}

# Skill tags rotated per CEFR level to ensure diverse vocabulary
SKILL_TAGS_BY_CEFR = {
    "A1": [
        "vocabulary/greetings", "vocabulary/numbers", "vocabulary/colors",
        "vocabulary/family", "vocabulary/food", "vocabulary/animals",
        "grammar/basic-verbs",
    ],
    "A2": [
        "vocabulary/daily-life", "vocabulary/time", "vocabulary/weather",
        "vocabulary/body", "vocabulary/clothes", "vocabulary/transport",
        "grammar/present-tense", "conversation/questions",
    ],
    "B1": [
        "vocabulary/travel", "vocabulary/work", "vocabulary/health",
        "vocabulary/emotions", "vocabulary/environment",
        "grammar/past-tense", "grammar/future-tense", "conversation/opinions",
    ],
    "B2": [
        "vocabulary/abstract", "vocabulary/culture", "vocabulary/politics",
        "grammar/subjunctive", "grammar/conditionals",
        "conversation/debates", "conversation/formal",
    ],
}

# ---------------------------------------------------------------------------
# Supabase helpers
# ---------------------------------------------------------------------------

HEADERS = {
    "apikey":        SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type":  "application/json",
    "Prefer":        "return=representation",
}


def get_counts():
    """Returns dict {(language, cefr_level): count} for non-defective questions."""
    url = f"{SUPABASE_URL}/rest/v1/global_questions?select=language,cefr_level&is_defective=eq.false"
    resp = requests.get(url, headers=HEADERS, timeout=30)
    if not resp.ok:
        print(f"  Supabase error {resp.status_code}: {resp.text[:300]}")
        print("  Hint: SUPABASE_SERVICE_KEY must be the service_role key, not the anon key.")
        resp.raise_for_status()
    rows = resp.json()
    print(f"  Supabase: fetched {len(rows)} total question records")
    counts = {}
    for row in rows:
        key = (row["language"], row["cefr_level"])
        counts[key] = counts.get(key, 0) + 1
    return counts


def insert_questions(rows: list[dict]) -> int:
    """Inserts rows into global_questions. Returns number inserted."""
    if not rows:
        return 0
    url = f"{SUPABASE_URL}/rest/v1/global_questions"
    resp = requests.post(url, headers=HEADERS, json=rows, timeout=30)
    resp.raise_for_status()
    return len(rows)


# ---------------------------------------------------------------------------
# Gemini helpers
# ---------------------------------------------------------------------------

PROMPT_SCHEMA = (
    'Return ONLY a valid JSON array — no markdown fences, no explanation.\n'
    'Schema:\n'
    '[\n'
    '  {"type":"multiple_choice","prompt":"...","options":["wrong","wrong","correct","wrong"],'
    '"correct_index":2,"hint":null},\n'
    '  {"type":"word_order","prompt":"Arrange into a correct sentence.",'
    '"translation":"English meaning of the sentence",'
    '"shuffled_words":["...","...","..."],"correct_order":[1,0,2]}\n'
    ']\n'
    'Rules:\n'
    '- Mix multiple_choice and word_order questions roughly 60/40.\n'
    '- correct_index MUST vary across MC questions (use 0, 1, 2, 3).\n'
    '- shuffled_words: 3-6 words per word_order question.\n'
    '- correct_order: INTEGER INDICES (0-based) into shuffled_words.\n'
    '- translation: English meaning of the complete target-language sentence.\n'
    '- Vary vocabulary — no repeated words across questions in this batch.\n'
    '- All prompts and options must be in the target language unless the prompt '
    'asks to translate FROM English.'
)


def build_prompt(language_name: str, language_code: str, cefr: str,
                 skill_tag: str, count: int) -> str:
    return (
        f"Generate exactly {count} language learning exercises for a student "
        f"learning {language_name} ({language_code}) at CEFR level {cefr}. "
        f"Skill focus: {skill_tag}. "
        f"Keep all content strictly at {cefr} difficulty — not easier, not harder. "
        f"{PROMPT_SCHEMA}"
    )


def call_gemini(prompt: str, retries: int = 3) -> list[dict] | None:
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.8, "maxOutputTokens": 2048},
    }
    for attempt in range(retries):
        try:
            resp = requests.post(GEMINI_ENDPOINT, json=body, timeout=60)
            if resp.status_code == 429:
                wait = RETRY_DELAY_S * (attempt + 1)
                print(f"  Rate limited (429), waiting {wait}s... (attempt {attempt+1}/{retries})")
                time.sleep(wait)
                continue
            if not resp.ok:
                print(f"  Gemini error {resp.status_code}: {resp.text[:300]}")
                print(f"  Model used: {GEMINI_MODEL}")
                print("  Hint: Ensure GEMINI_SEED_API_KEY is valid and has access to this model.")
                break
            resp.raise_for_status()
            text = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
            clean = text.strip().lstrip("```json").lstrip("```").rstrip("```").strip()
            return json.loads(clean)
        except Exception as e:
            print(f"  Gemini attempt {attempt + 1} failed: {e}")
            if attempt < retries - 1:
                time.sleep(RETRY_DELAY_S)
    return None


# ---------------------------------------------------------------------------
# Question parsing
# ---------------------------------------------------------------------------

def parse_questions(items: list[dict], language: str, cefr: str,
                    skill_tag: str) -> list[dict]:
    """Converts Gemini JSON items to global_questions rows."""
    rows = []
    for item in items:
        q_type = item.get("type")
        if q_type not in ("multiple_choice", "word_order"):
            continue

        if q_type == "multiple_choice":
            options = item.get("options", [])
            correct = item.get("correct_index", 0)
            if not isinstance(options, list) or len(options) < 2:
                continue
            correct = max(0, min(correct, len(options) - 1))
            content = {
                "type":          "multiple_choice",
                "prompt":        item.get("prompt", ""),
                "options":       options,
                "correct_index": correct,
                "hint":          item.get("hint"),
            }

        else:  # word_order
            words = item.get("shuffled_words", [])
            order = item.get("correct_order", [])
            if not words or not order:
                continue
            # Normalise order to ints
            if order and isinstance(order[0], str):
                order = [words.index(w) if w in words else 0 for w in order]
            order = [int(i) for i in order if 0 <= int(i) < len(words)]
            if not order:
                continue
            content = {
                "type":          "word_order",
                "prompt":        item.get("prompt", "Arrange into a correct sentence."),
                "translation":   item.get("translation"),
                "shuffled_words": words,
                "correct_order": order,
            }

        rows.append({
            "id":               str(uuid.uuid4()),
            "language":         language,
            "cefr_level":       cefr,
            "skill_tag":        skill_tag,
            "type":             q_type,
            "content":          content,
            "difficulty_score": 0.5,
            "total_attempts":   0,
            "correct_attempts": 0,
            "is_defective":     False,
        })
    return rows


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("=== Axiom Question Bank Seeder ===")
    print(f"Target: {MIN_QUESTIONS} questions per (language, cefr_level)\n")

    counts   = get_counts()
    batches_used = 0
    total_inserted = 0

    for lang, cefr in TARGETS:
        current = counts.get((lang, cefr), 0)
        needed  = MIN_QUESTIONS - current
        print(f"[{lang.upper()} {cefr}] {current}/{MIN_QUESTIONS} questions", end="")

        if needed <= 0:
            print(" — OK, skipping")
            continue

        print(f" — needs {needed} more")

        skill_tags = SKILL_TAGS_BY_CEFR.get(cefr, ["vocabulary/general"])
        lang_name  = LANGUAGE_NAMES.get(lang, lang)
        generated  = 0

        while generated < needed and batches_used < MAX_BATCHES:
            skill = skill_tags[generated % len(skill_tags)]
            batch_count = min(BATCH_SIZE, needed - generated)

            print(f"  Generating {batch_count} questions [{skill}]...")
            prompt = build_prompt(lang_name, lang, cefr, skill, batch_count)
            items  = call_gemini(prompt)

            if not items:
                print("  Failed to get response, skipping batch.")
                break

            rows = parse_questions(items, lang, cefr, skill)
            if rows:
                inserted = insert_questions(rows)
                generated    += inserted
                total_inserted += inserted
                print(f"  Inserted {inserted} questions (total for pair: {current + generated})")
            else:
                print("  No valid questions parsed from response.")

            batches_used += 1
            if batches_used >= MAX_BATCHES:
                print(f"\nReached MAX_BATCHES ({MAX_BATCHES}), stopping early.")
                break

            time.sleep(INTER_CALL_DELAY)  # polite pacing between calls

    print(f"\nDone. Total inserted: {total_inserted}. Gemini calls: {batches_used}.")
    if total_inserted == 0 and batches_used == 0:
        print("All language/CEFR pairs already above threshold — nothing to do.")


if __name__ == "__main__":
    main()
