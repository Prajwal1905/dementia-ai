from fastapi import APIRouter
from pydantic import BaseModel
import random

router = APIRouter()

# pool of words (doctor-style cognitive test words)
WORD_POOL = [
    "Apple","Train","Blue","Garden","Chair","River","Market","School","Doctor","Bottle",
    "Paper","Cloud","Window","Pencil","Forest","Mountain","Bread","Phone","Table","Flower"
]

# ---------- STEP 1: GET RANDOM WORDS ----------
@router.get("/memory-words")
def get_memory_words():
    words = random.sample(WORD_POOL, 5)
    return {"words": words}


# ---------- STEP 2: SUBMIT MEMORY ----------
class MemoryInput(BaseModel):
    shown_words: list[str]
    recalled_words: list[str]
    time_taken: float


@router.post("/memory-test")
def memory_test(data: MemoryInput):

    # normalize words (important for humans)
    shown_clean = [w.strip().lower() for w in data.shown_words]
    recalled_clean = [w.strip().lower() for w in data.recalled_words]

    correct = len(set(shown_clean) & set(recalled_clean))
    memory_score = correct * 20

    # time penalty (real cognitive screening logic)
    if data.time_taken > 30:
        memory_score -= 10

    memory_score = max(memory_score, 0)

    return {
        "correct_words": correct,
        "memory_score": memory_score
    }
