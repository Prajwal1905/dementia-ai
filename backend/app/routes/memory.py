from fastapi import APIRouter
from pydantic import BaseModel
import random
from app.services.memory_score import calculate_memory_score

router = APIRouter(prefix="/memory", tags=["Memory"])

WORD_POOL = [
    "Apple","Train","Blue","Garden","Chair","River","Market","School","Doctor","Bottle",
    "Paper","Cloud","Window","Pencil","Forest","Mountain","Bread","Phone","Table","Flower"
]

# ---------- GET WORDS ----------
@router.get("/words")
def get_memory_words():
    words = random.sample(WORD_POOL, 5)
    return {"words": words}


# ---------- INPUT ----------
class MemoryInput(BaseModel):
    shown_words: list[str]
    recalled_words: list[str]
    time_taken: float


# ---------- TEST ----------
@router.post("/test")
def memory_test(data: MemoryInput):

    score, correct = calculate_memory_score(
        data.shown_words,
        data.recalled_words,
        data.time_taken
    )

    return {
        "correct_words": correct,
        "memory_score": score
    }