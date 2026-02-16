from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

class MemoryInput(BaseModel):
    shown_words: list[str]
    recalled_words: list[str]
    time_taken: float

@router.post("/memory-test")
def memory_test(data: MemoryInput):
    correct = len(set(data.shown_words) & set(data.recalled_words))
    score = correct * 20

    if data.time_taken > 30:
        score -= 5

    return {"memory_score": max(score, 0)}
