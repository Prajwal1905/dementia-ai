from fastapi import APIRouter,Depends
from app.db import SessionLocal
from app.models.assessment import Assessment
from app.services.dependencies import get_current_user

router = APIRouter()

@router.get("/history")
def get_history(user_id: int = Depends(get_current_user)):
    db = SessionLocal()
    records = (
        db.query(Assessment)
        .filter(Assessment.user_id == user_id)
        .order_by(Assessment.created_at.asc())
        .all()
    )

    db.close()

    return [
        {
            "date": r.created_at,
            "memory_score": r.memory_score,
            "time_taken": r.time_taken,
            "decline_rate": r.decline_rate,
            "avg_sentence_length": r.avg_sentence_length,
            "vocab_richness": r.vocab_richness,
            "hesitation_ratio": r.hesitation_ratio,
            "repetition_ratio": r.repetition_ratio,
            "prediction": r.ml_prediction,
            "confidence": r.confidence,
            "risk_level": r.risk_level
        }
        for r in records
    ]
